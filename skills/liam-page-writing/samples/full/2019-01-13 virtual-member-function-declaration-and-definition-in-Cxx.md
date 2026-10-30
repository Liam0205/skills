---
title: "C++ 中虚函数的声明与定义"
url: https://liam.page/2019/01/13/virtual-member-function-declaration-and-definition-in-Cxx/
date: 2019-01-13
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Virtual Member Function"]
---

多态（Polymorphism）是面向对象程序设计最重要的特性之一。C++ 通过结合虚函数和指针（引用）来实现多态。作为 C++ 用户，你当然知道如何将虚函数和指针（引用）结合起来以实现多态。但在这些概念之间，可能还存在些许模糊地带。例如说，你有思考过下面这个问题吗？

纯虚函数能有实现吗？

此篇讨论 C++ 中虚函数的声明与定义。

## 直接回答问题

能！纯虚函数可以有定义，并且有时我们必须给出纯虚函数的定义。不过有一点需要注意：和其它成员函数不同，纯虚函数的定义必须实现在类定义之外。（见下例）

```cpp
struct Abstract {
    virtual void f() = 0; // pure virtual
    ~Abstract() {
        // f(); // undefined behavior
        Abstract::f(); // OK: non-virtual call
    }
};

// definition of the pure virtual function
void Abstract::f() { std::cout << "A::f()\n"; }

struct Concrete : Abstract {
    void f() override {
        Abstract::f(); // OK: calls pure virtual function
    }
    ~Concrete() {
        f(); // OK: calls Concrete::f()
    }
};
```

## 虚成员函数

我们首先来看看关于虚成员函数生命和定义的一些规则。根据 C++ 标准，虚成员函数应在类定义中生命，且必须有定义（实现）。注意，在类定义外实现虚成员函数时，不能再加 virtual 关键字。

```cpp
struct Foo {
  virtual void foo() {  // declare and define at the same time, inside the class definition.
    std::cout << "Foo::foo()" << std::endl;
  }
};

struct Bar {
  virtual void bar();
};

void Bar::bar() {
  std::cout << "Bar::bar()" << std::endl;
}
```

不过，C++ 标准没有要求必须在编译期对这条规则进行诊断。也就是说，如果没有给出虚成员函数的实现，编译器可能不会报错。不过，链接器可能会提示引用了未定义的符号这样的错误。

## 纯虚成员函数

纯虚函数使类成为「抽象类」。具体来说，我们不能创建抽象类类型的对象，也不能将其作为函数的参数类型、返回类型，也不能作为显式类型转换的目标类型。

因此，我们永远不会有机会调用抽象类中的徐成员函数。另一方面，纯虚函数必然会在派生类中被复写。因此，在大多数情况下，纯虚函数的实现是没什么用处的。也因此，我们可以将一个成员函数声明为纯虚的，但是不给它的定义。

也就是说，对于纯虚函数，我们可以：

- 在类定义中声明纯虚函数，并且不给实现；

- 在类定义中声明纯虚函数，并且在类定义之外给出实现。

不过，这里有两处例外：

- 对于纯虚析构函数，必须提供实现。

- 派生类中的成员函数可以调用抽象类中的纯虚函数，但必须加上抽象类的限定符（Base::some_pure_virtual_function()）。

在这两种情况下，提供纯虚函数的定义是有意义的——也必须提供。