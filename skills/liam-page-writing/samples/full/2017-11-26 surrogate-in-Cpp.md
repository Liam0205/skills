---
title: "谈谈代理类"
url: https://liam.page/2017/11/26/surrogate-in-Cpp/
date: 2017-11-26
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Class", "Surrogate", "Handler"]
---

本文以 C++ 为示例语言，但实际其中思想适用范围远大于 C++ 这一编程语言的范畴。

我们知道，C++ 标准模板类库提供了一系列的容器。诸如 std::vector<ElementType> 的容器需要在声明时指定容器中所储存的元素的类型。例如，我们可以使用 std::vector<int> 声明一个包含整型数字的变长数组；而 std::vector<std::string> 则可以用来声明一个包含 std::string 的变长数组。

显而易见，由于容器在声明时就已指定了其包含的元素的类型，容器内只能包含相同类型的元素。这与面向对象编程（Object-Oriented Programming, OOP, 使用继承和运行时动态绑定的编程方式）的思想似乎是矛盾的。因为 OOP 使用继承和动态绑定，允许程序员将相关但有不同的类的共性部分抽象成基类而将这些不同的部分分别作为子类独有的成员；若是容器内只能包含相同类型的元素，我们就无法直接在一个容器中包含同一个基类不同派生类的对象了——而在实际应用中，这种场景是存在的。

在[前作](/2016/11/26/Introduction-to-CRTP-in-Cpp/)中最后的示例（动物园的例子）中，我们通过保存基类指针（而不是对象本身）部分解决了这个问题。然而，在前例中，我们不可避免地还是需要使用 new 和 delete 来动态分配内存。此篇我们通过构建「代理类」来避免手工动态分配内存。

## 问题重述

我们仍旧以[前作](/2016/11/26/Introduction-to-CRTP-in-Cpp/)中动物园的例子进行讲述；不失一般性，我们忽略 CRTP 惯用法。

```cpp
#include <iostream>
#include <vector>

class Animal {
 public:
    virtual void say () const = 0;
    virtual ~Animal() {}
};

class Cat: public Animal {
 public:
    void say() const override {
        std::cout << "Meow~ I'm a cat." << std::endl;
    }

 private:
    bool valid_cat_{true};
};

class Dog: public Animal {
 public:
    void say() const override {
        std::cout << "Wang~ I'm a dog." << std::endl;
    }

 private:
    bool valid_dog_{true};
};

int main () {
    std::vector<Animal*> zoo;
    zoo.push_back(new Cat());
    zoo.push_back(new Dog());
    for (auto iter = zoo.begin(); iter != zoo.end(); ++iter) {
        (*iter)->say();
    }
    for (auto iter = zoo.begin(); iter != zoo.end(); ++iter) {
        delete (*iter);
    }
    return 0;
}
```

在主函数中，我们通过 Cat 和 Dog 类的默认构造函数，两次动态分配内存，分别构建了 Cat 和 Dog 类的对象；而后将相应的指针加入 std::vector 的末尾。而后，我们就能通过迭代器，依次访问 Cat 和 Dog 了。当然，最后也不能忘记清理动态分配的内存。

我们的目标是将主函数改成类似下面的效果。

```cpp
int main () {
    std::vector<ElementType> zoo;
    Cat cat;
    Dog dog;
    zoo.push_back(cat);
    zoo.push_back(dog);
    for (auto iter = zoo.begin(); iter != zoo.end(); ++iter) {
        iter->say();
    }
    return 0;
}
```

## 问题分析

对比在 zoo 中保存基类指针的方式，我们的目标代码有几点主要的不同。

- 向 zoo 中追加元素时，加入的是 Cat 和 Dog 类的对象本身，而不是它们的指针；

- 向 zoo 中追加的元素保存在栈上（而不是堆上），不需要程序员主动分配和释放内存。

这也就是说，数组 zoo 的元素类型必然不是 Cat 或 Dog，而应该和他们的基类 Animal 有一定关系；另外一方面，在功能上，我们要保证 ElementType 的元素支持动态绑定（能够调用合适的 say 函数）。

另一方面，我们也要注意到，由于 cat 和 dog 不是程序员手动分配和释放内存，而是由系统运行时库来自动管理。这样一来，可能存在变长数组 zoo 仍在使用，但 cat 和 dog 已经由于超出生存期而被销毁的现象。因此，在向变长数组 zoo 追加元素时，我们需要考虑拷贝或者移动语义。

## 代码实现

接下来我们分别解决这些问题。

### 拷贝和移动语义

首先我们来实现拷贝和移动语义。

在问题分析一节中，我们提到，数组的元素类型 ElementType 虽不是基类指针，但必然和基类相关。因此，显而易见，拷贝和移动语义的接口应该定义在基类当中。因此，我们首先需要修改基类。

```cpp
class Animal {
 public:
    virtual void say () const = 0;
    virtual Animal* copy() const = 0;
    virtual Animal* move() = 0;
    virtual ~Animal() {}
};
```

而后，我们需要在 Cat 和 Dog 两个派生类中分别实现 copy 和 move 函数。

```cpp
class Cat: public Animal {
 public:
    void say() const {
        std::cout << "Meow~ I'm a cat." << std::endl;
    }

 public:
    Cat() {}
    ~Cat() override { valid_cat_ = false; }
    Cat(const Cat& source) : valid_cat_{source.valid_cat_} {}
    Cat(Cat&& source) : valid_cat_{source.valid_cat_} { source.valid_cat_ = false; }
    Cat& operator=(const Cat& source) {
        this->valid_cat_ = source.valid_cat_;
    }
    Cat& operator=(Cat&& source) {
        this->valid_cat_ = source.valid_cat_;
        source.valid_cat_ = false;
    }
    Animal* copy() const override {
        return dynamic_cast<Animal*>(new Cat(*this));
    }
    Animal* move() override {
        return dynamic_cast<Animal*>(new Cat(std::move(*this)));
    }

 private:
    bool valid_cat_{true};
};

class Dog: public Animal {
 public:
    void say() const {
        std::cout << "Wang~ I'm a dog." << std::endl;
    }

 public:
    Dog() {}
    ~Dog() override { valid_dog_ = false; }
    Dog(const Dog& source) : valid_dog_{source.valid_dog_} {}
    Dog(Dog&& source) : valid_dog_{source.valid_dog_} { source.valid_dog_ = false; }
    Dog& operator=(const Dog& source) {
        this->valid_dog_ = source.valid_dog_;
    }
    Dog& operator=(Dog&& source) {
        this->valid_dog_ = source.valid_dog_;
        source.valid_dog_ = false;
    }
    Animal* copy() const override {
        return dynamic_cast<Animal*>(new Dog(*this));
    }
    Animal* move() override {
        return dynamic_cast<Animal*>(new Dog(std::move(*this)));
    }

 private:
    bool valid_dog_{true};
};
```

此处，通过完整实现 Cat 和 Dog 类的析构函数、拷贝构造函数、拷贝赋值运算符、移动构造函数、移动赋值运算符，我们实现了 copy 和 move 两个函数。

### 定义基类的代理

如问题分析一节中的讨论，我们认为 ElementType 必然和 Cat 和 Dog 的基类 Animal 相关。同时，经过分析，我们发现 ElementType 在构建时，可以直接从 Cat 和 Dog 的实例上构建；在运行时，支持多态。因此，不难发现，ElementType 一方面必须包含一个 Animal 的指针或引用；另一方面它必须有从 Animal 的实例中构造的构造函数（定义从 Animal 到 ElementType 的类型转换）。

这样一来，我们能写出 Animal 类的代理。

```cpp
class AnimalSurrogate {
 public:
    AnimalSurrogate() {}
    explicit AnimalSurrogate(const AnimalSurrogate& animal_surrogate) :
        animal_{animal_surrogate.animal_ ? animal_surrogate.animal_->copy() : nullptr} {}
    explicit AnimalSurrogate(AnimalSurrogate&& animal_surrogate) :
        animal_{animal_surrogate.animal_ ? animal_surrogate.animal_->move() : nullptr} {
        animal_surrogate.animal_ = nullptr;
    }
    AnimalSurrogate& operator=(const AnimalSurrogate& animal_surrogate) {
        animal_ = animal_surrogate.animal_ ? animal_surrogate.animal_->copy() : nullptr;
        return (*this);
    }
    AnimalSurrogate& operator=(AnimalSurrogate&& animal_surrogate) {
        animal_ = animal_surrogate.animal_ ? animal_surrogate.animal_->move() : nullptr;
        animal_surrogate.animal_ = nullptr;
        return (*this);
    }
    ~AnimalSurrogate() {
        delete animal_;
        animal_ = nullptr;
    }

 public:
    AnimalSurrogate(const Animal& animal) : animal_{animal.copy()} {}
    AnimalSurrogate(Animal&& animal) : animal_{animal.move()} {}
    AnimalSurrogate& operator=(const Animal& animal) {
        this->animal_ = animal.copy();
        return (*this);
    }
    AnimalSurrogate& operator=(Animal&& animal) {
        this->animal_ = animal.move();
        return (*this);
    }

 public:
    void say() const {
        animal_->say();
        return;
    }

 private:
    Animal* animal_{nullptr};
};
```

这里，我们定义了 Animal 类的代理类 AnimalSurrogate。在它的一系列构造函数中，我们保证了 AnimalSurrogate 类的实例本身能够拷贝、移动。同时我们允许从 Animal 向 AnimalSurrogate 的类型转换：从左值引用中拷贝以及从右值引用中移动。特别地，由于 Animal 是抽象类，不存在 Animal 类的对象，因此这两个构造函数不应声明为 explicit。这是因为，如果声明为 explicit，则每次使用都必须使用 dynamic_cast 进行显式的类型转换。

另一方面，由于 AnimalSurrogate 类中包含了一个 Animal 类的指针，通过该指针，我们在 AnimalSurrogate::say() 函数中，可以实现多态。

### 实际执行看看

这样一来，我们的主函数就应当写作以下两种形式之一：

```cpp
int main () {
    std::vector<AnimalSurrogate> zoo;
    Cat cat;
    Dog dog;
    // AnimalSurrogate::AnimalSurrogate(const Animal& animal) is called
    zoo.push_back(cat);
    zoo.push_back(dog);
    for (std::vector<AnimalSurrogate>::const_iterator iter{zoo.begin()}; iter != zoo.end(); ++iter) {
        iter->say();
    }
    return 0;
}
```

```cpp
int main () {
    std::vector<AnimalSurrogate> zoo;
    Cat cat;
    Dog dog;
    // AnimalSurrogate::AnimalSurrogate(Animal&& animal) is called
    zoo.push_back(std::move(cat));
    zoo.push_back(std::move(dog));
    for (std::vector<AnimalSurrogate>::const_iterator iter{zoo.begin()}; iter != zoo.end(); ++iter) {
        iter->say();
    }
    return 0;
}
```

此处，第一种情况，我们在向 zoo 追加元素时，C++ 会调用 AnimalSurrogate::AnimalSurrogate(const Animal& animal)；以便从 animal 中拷贝内容（调用 copy() 函数）。第二种情况，我们在想 zoo 追加元素时，C++ 会调用 AnimalSurrogate::AnimalSurrogate(Animal&& animal)；以便运用移动语义，从 animal 中「窃取」资源。

需要注意的是，在两种情况下，zoo 中的元素都与外部的 cat 和 dog 无关。不论 cat 和 dog 如何变化（甚至销毁），都不影响 zoo 中的元素。不同的是，在第二种情况下，外部的 cat 和 dog 中的资源被窃取，因此 cat 和 dog 已处于不可用的状态（代码中使用 valid_cat_ 和 valid_dog_ 来表示这种现象）——我们不能对移走的 cat 和 dog 中的资源的状态做任何假设。具体可参见[谈谈 C++ 中的右值引用](/2016/12/11/rvalue-reference-in-Cpp/)。

执行结果如下：

```bash
$ ./a.out
Meow~ I'm a cat.
Wang~ I'm a dog.
```

如此一来，我们就实现了在同一容器中，（间接地）容纳不同类型的实例；同时在保留多态的情况下，避免让程序员手动分配和释放内存。

代理类和 CRTP 是不矛盾的，读者可以试着将二者联系起来，一起使用。