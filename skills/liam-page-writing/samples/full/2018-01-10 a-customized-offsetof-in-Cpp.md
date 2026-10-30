---
title: "谈谈 C/C++ 中的 offsetof"
url: https://liam.page/2018/01/10/a-customized-offsetof-in-Cpp/
date: 2018-01-10
categories: ["Algorithm and Computer Science"]
tags: ["Macro", "C++", "C", "offsetof"]
---

此篇讲一讲 C/C++ 中的 offsetof。

## 介绍

offsetof 是源自 C 语言的宏，它接受两个参数（类型名和成员名），返回一个 std::size_t 类型的常量表达式。offsetof 的返回值是成员在该类型对象中以字节计算的的偏移量。其中，传入计算的类型名，必须满足标准内存布局的要求；即

- 所有非 static 数据成员的访问控制权限相同；

- 没有虚函数；

- 不从虚基类继承；

- 所有非 static 数据成员都不是引用类型；

- 所有非 static 数据成员类型和基类都满足上述要求。

若传入计算的类型名不满足内存布局的要求，或者求解的成员是 static 成员或成员函数，则调用该宏是未定义行为（Undefined Behaviour）。

## 实现

按照定义，有

- offsetof(s, m) 的值只与类型和成员有关，也就是说，在计算 offsetof(s, m) 的时候，不应传入 s 类型具体某个对象，也不应为计算该值而临时构造一个对象；

- offsetof(s, m) 的值，其单位是字节；

- offsetof(s, m) 的值应是 std::size_t 类型。

offsetof 的这三个特性，也是实现 offsetof 宏的三个难点。为了解决这些问题，首先，实现应当让编译器相信在某处存在一个「虚拟的」但是「可用的」对象。而后，根据该虚拟对象，可以取得目标成员 m 的地址。随后，利用 m 的地址与该虚拟对象的起始地址做差，即可得知 m 的偏移量；为了求得以字节为单位的 ptrdiff_t，需将 m 的地址转变为 char 类型的指针。最后，只需将 ptrdiff_t 转换为 std::size_t 即可。

因此，有如下 C++ 实现：

```cpp
#define offsetof(s, m) (reinterpret_cast<size_t>(&reinterpret_cast<const volatile char&>(static_cast<s*>(nullptr)->m)))
```

此处，通过 static_cast<s*>(nullptr)，编译器相信在 nullptr 处（0x0）有一个真实存在的 s 类型的对象。此处使用 static_cast 而非 reinterpret_cast 是因为 C++ 标准不允许将 nullptr 通过 reinterpret_cast 转换成其他类型的指针；此类转换应用 static_cast。由于 static_cast<s*>(nullptr) 返回指向 s 类型对象的指针，因此 static_cast<s*>(nullptr)->m 就是一个虚拟但在编译器看来可用的成员变量 m。为了求得以字节为单位的 ptrdiff_t，实现中通过 &reinterpret_cast<const volatile char&>(static_cast<s*>(nullptr)->m) 获得一个 const volatile char* 类型的变量。由于在该实现中，虚拟的变量位于 0x0 位置，故而 &reinterpret_cast<const volatile char&>(static_cast<s*>(nullptr)->m) 即是 m 在 s 类型对象当中相对对象起始地址的偏移量。最后，只需将它转换为 size_t 类型的值即可：reinterpret_cast<size_t>(&reinterpret_cast<const volatile char&>(static_cast<s*>(nullptr)->m))。

同样，可以有 C 风格的实现：

```c
#define offsetof(s, m) (size_t)((char*)(&((s*)0)->m))
```

## 测试

```cpp
#include <stdio.h>
#define offsetof(s, m) (reinterpret_cast<size_t>(&reinterpret_cast<const volatile char&>(static_cast<s*>(nullptr)->m)))

struct S {
    char c;
    double d;
    char cc;
};

int main(void) {
    printf("the first element is at offset %zu\n", offsetof(struct S, c));
    printf("the double is at offset %zu\n", offsetof(struct S, d));
    printf("the third element is at offset %zu\n", offsetof(struct S, cc));
}
```

上述测试代码的结果是：

```bash
$ ./a.out
the first element is at offset 0
the double is at offset 8
the third element is at offset 16
```