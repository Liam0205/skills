---
title: "C++ 惯用法 CRTP 简介"
url: https://liam.page/2016/11/26/Introduction-to-CRTP-in-Cpp/
date: 2016-11-26
categories: ["Algorithm and Computer Science"]
tags: ["Template", "Cpp", "Class", "Idiom"]
---

## 虚函数与动态绑定

C++ 通过类的继承与虚函数的动态绑定，实现了多态。这种特性，使得我们能够用基类的指针，访问子类的实例。例如我们可以实现一个名为 Animal 的基类，以及 Cat, Dog 等子类，并通过在子类中重载虚函数 jump，实现不同动物的跳跃动作。而后我们可以通过访问 Zoo 类的实例中存有 Animal 指针的数组，让动物园中所有的动物都跳一遍。

```c++
class Zoo {
 ...
 private:
    std::vector<shared_ptr<Animal>> animals;
 public:
    void () {
        for (auto animal : animals) {
            animal->jump();
        }
    }
 ...
}
```

在每次执行 animal->jump() 的时候，系统会检查 animal 指向的实例实际的类型，然后调用对应类型的 jump 函数。这一步骤需要通过查询虚函数表（vtable）来实现；由于实际 animal 指向对象的类型在运行时才确定（而不是在编译时就确定），所以这种方式称为动态绑定（或者运行时绑定）。

因为每次都需要查询虚函数表，所以动态绑定会降低程序的执行效率。为了兼顾多态与效率，有人提出了 Curiously Recurring Template Pattern 的概念。

## 通过模板实现静态绑定

为了在编译时绑定，我们就需要放弃 C++ 的虚函数机制，而只是在基类和子类中实现同名的函数；同时，为了在编译时确定类型，我们就需要将子类的名字在编译时提前传给基类。因此，我们需要用到 C++ 的模板。

```c++
#include <iostream>

using namespace std;

template<typename T>
class Base {
 public:
    void show () const {
        static_cast<const T*>(this)->show();
    }
};

class Derived: public Base<Derived> {
 public:
    void show () const {
        cout << "Shown in Derived class." << endl;
    }
};

int main () {
    Derived d;
    Base<Derived> *b = &d;
    b->show();
    return 0;
}
```

这是一个简单的 CRTP 的例子，有以下一些特点：

- 基类是一个模板类，接收子类的类型名字；

- 因此子类的继承列表会类似于 Derived: public Base<Derived>；

- 基类的函数在函数体中，使用 static_cast<> 将基类的指针转为（模板）子类的指针，在编译期完成绑定。

因此，在实际执行时，我们用 b->show() 打印出「Shown in Derived class.」的字样，显示我们确实调用了子类的 show 函数。

再举一个稍微复杂一点的例子。

```c++
#include <iostream>

using namespace std;

template<typename T>
class Base {
 public:
    void show () const {
        static_cast<const T*>(this)->show();
    }
    Base<T> operator++() {
        static_cast<T*>(this)->operator++();
    }
};

class Derived: public Base<Derived> {
 public:
    Derived () : val(0) {};
    void show () const {
        cout << "Shown in Derived class." << endl;
        cout << "Val is " << this->val << "." << endl;
    }
    Derived operator++() {
        ++(this->val);
        return *this;
    }
 private:
    int val;
};

int main () {
    Derived d;
    Base<Derived> *b = &d;
    b->show();
    ++(*b);
    b->show();
    return 0;
}
```

这一次，我们在子类中，额外重载了前置的自增运算符（参数列表不带 int）。因此，在基类中，我们首先要将 this 指针转换为 T* 类型，然后调用子类的前置自增运算符（operator++()）。

## 用在哪里？

现在我们考虑这样一个问题。

在使用虚函数的风格中，我们可以把 Cat*, Dog*... 等不同子类的指针，复制给基类的指针 Animal*，然后把基类的指针存入容器中（比如 vector<Animal*>）。但是，在 CRTP 中，我们就做不到这样了。这是因为同样是基类的指针 Animal<Cat>* 和 Animal<Dog>* 是两种完全不同的类型的指针。这样一来，我们就没法构造一个动物园了。

摔！

那么，CRTP 到底应该怎么用呢？我们不妨回过头来想一想，最初我们引入 CRTP 是为了什么。文章开头的第一段，我们提到多态是个很好的特性，但是动态绑定比较慢，因为要查虚函数表。而事实上，动态绑定慢，通常是因为多级继承；如果继承很短，那么查虚函数表的开销实际上也没多大。

在之前举出的例子里，我们运用 CRTP，完全消除了动态绑定；但与此同时，我们也在某种意义上损失了多态性。现在我们希望二者兼顾：保留多态性，同时降低多级继承带来的虚函数表查询开销。答案也很简单：让 CRTP 的模板类继承一个非模板的基类——这相当于这个非模板的基类会有多个平级的不同的子类。一个示例如下。

```cpp
#include <iostream>
#include <vector>

using std::cout; using std::endl;
using std::vector;

class Animal {
 public:
    virtual void say () const = 0;
    virtual ~Animal() {}
};

template <typename T>
class Animal_CRTP: public Animal {
 public:
    void say() const override {
        static_cast<const T*>(this)->say();
    }
};

class Cat: public Animal_CRTP<Cat> {
 public:
    void say() const {
        cout << "Meow~ I'm a cat." << endl;
    }
};

class Dog: public Animal_CRTP<Dog> {
 public:
    void say() const {
        cout << "Wang~ I'm a dog." << endl;
    }
};

int main () {
    vector<Animal*> zoo;
    zoo.push_back(new Cat());
    zoo.push_back(new Dog());
    for (vector<Animal*>::const_iterator iter{zoo.begin()}; iter != zoo.end(); ++iter) {
        (*iter)->say();
    }
    for (vector<Animal*>::iterator iter{zoo.begin()}; iter != zoo.end(); ++iter) {
        delete (*iter);
    }
    return 0;
}
```

这样一来，我们就兼顾了多态性和效率。