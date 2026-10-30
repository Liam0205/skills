---
title: "通过虚函数表访问私有函数"
url: https://liam.page/2018/01/23/crack-private-member-function-by-vtable/
date: 2018-01-23
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Class", "Virtual"]
---

一直听说 C++ 继承体系中对虚函数调用的动态绑定是基于虚函数表和虚表指针的，但是因为一些原因，我一直没有去搞清楚。今天想起这件事情，就去翻看了 [C++ 的标准文档](https://github.com/cplusplus/draft/releases)。然而，标准文档只提及了动态绑定的各种规则，却并没有提及任何有关虚函数表或虚表指针的内容。显然，我看的不会是假的标准文档，那么只可能是动态绑定是由编译器实现决定的了。

本想具体详细地写一写虚函数表相关的问题，但已入深夜，就简单记录一份实验的代码吧。详细的内容待后续再讨论。

不多做分析，直接上代码。

```cpp
#include <stddef.h>
#include <iostream>

class Base {
 public:
  virtual void f() {
    std::cout << "Your are calling Base::f (public)." << std::endl;
  }

 private:
  virtual void g() {
    std::cout << "Your are calling Base::g (private)." << std::endl;
  }
};

class Derived : public Base{};

using funcptr_t = void(*)(void);
using ptr_t     = uint64_t*;

funcptr_t fuckcxx(Base* const ptr, const ptrdiff_t offset) {
  ptr_t pvtbl = reinterpret_cast<ptr_t>(ptr);               // 1.
  ptr_t pfunc = reinterpret_cast<ptr_t>(*pvtbl);
  return reinterpret_cast<funcptr_t>(*(pfunc + offset));
}

int main() {
    Derived d;
    auto f = fuckcxx(&d, 0);
    auto g = fuckcxx(&d, 1);                                // 2.
    f(); g();
    return 0;
}
```

编译并执行。

```bash
$ g++-6 --version
g++-6 (Homebrew GCC 6.4.0_1) 6.4.0
Copyright (C) 2017 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

$ g++-6 crack_private.cc
$ ./a.out
Your are calling Base::f (public).
Your are calling Base::g (private).
```

无疑，我们已经成功地访问了 Base 类的私有函数 g。现在我们来看看是怎样做到的。

主函数很简单，无非是取了一个 Derived 类型的变量 d。而后借助它，用 fuckcxx 函数通过偏移量，去获得 Base 的函数指针。最后实现函数调用。这里可以作出几个推断。

- 尽管 Derived 内没有任何数据成员和成员函数，但 Derived 类的对象仍保有虚表指针和类型对应的虚函数表。

- 在 GCC6 中虚表指针保存在类对象的起始处 (1)。

- 类的成员函数在至少是汇编层面与普通的函数没有两样，因此我们才能像 (2) 那样直接调用；尽管道理上说，Base::g 的函数指针类型应该是 void(Base::*)(void)。参见[前作](/2017/02/05/pointer-in-C-and-Cpp/)。

- C++ 类的访问控制，仅限于编译期；由于对 C 语言的兼容，运行期还是和 C 一样的那一套。

还可以细致地分析多重继承以及多级继承时虚函数表和虚表指针的结构是怎样，并运用类似的方法实行函数调用。这些内容读者可自行探索，以及将在后续文章中讨论。

就酱，碎叫。