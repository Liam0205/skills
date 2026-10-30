---
title: "在 C++ 中类的构造函数中使用 this 指针"
url: https://liam.page/2021/03/17/using-this-pointer-in-ctor/
date: 2021-03-17
categories: ["Algorithm and Computer Science"]
tags: ["C++", "this", "Constructor"]
---

遇见一个有趣的问题。

C++ 里面，在类的 constructor 当中使用 this 指针访问成员，是否是安全的？在哪些情况下安全？在哪些情况下不安全？

Ao Shen 给了一个[标准答案](https://isocpp.org/wiki/faq/ctors#using-this-in-ctors)，跟我之前的认知一致：只要对类内成员初始化顺序，以及对基类子类初始化顺序熟悉，就很容易理解了。

因为类内成员初始化顺序和类内成员声明顺序一致，基类总是在子类之前初始化。所以

- 在父类初始化列表当中，使用 this 引用更早声明的变量初始化是安全的。

- 在父类构造函数体当中，使用 this 指针引用类内成员是安全的（不包括子类成员）。

- 在父类构造函数体当中，down-cast this 指针为子类指针，这一行为本身是安全的；但是使用 down-casted 指针访问子类成员是不安全的。

- 在子类初始化列表当中，使用 this 指针引用父类成员总是安全的。

- 访问函数的情况，则看对应的函数访问的类内成员是否已经初始化。