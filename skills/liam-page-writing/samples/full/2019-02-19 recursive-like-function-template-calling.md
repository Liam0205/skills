---
title: "像递归一样的函数模板调用"
url: https://liam.page/2019/02/19/recursive-like-function-template-calling/
date: 2019-02-19
categories: ["Algorithm and Computer Science"]
tags: ["Template", "C++"]
---

遇到一个蛮奇葩的问题：在 C++ 中如何不用循环和递归，打印从 1 至 N 的自然数？

想了想，用模板元编程可以解决——让编译器在编译期把该打印的东西都展开就好了。

直接上代码好了……

```c++
#include <iostream>

template <int N>
void counting(std::ostream& os) {
  counting<N - 1>(os);  // *
  os << N << std::endl;
}

template <>
void counting<1>(std::ostream& os) {
  os << 1 << std::endl;
}

int main() {
  const int N = 10;
  counting<N>(std::cout);
  return 0;
}
```

这里，(*) 处有类似递归的调用。但由于 counting 是函数模板，所以 counting<N> 调用的 counting<N - 1> 并非自身，因此不是递归。

编译器在实例化 counting<N> 的时候，由于它调用了 counting<N - 1>，所以在编译期会递归地实例化下去——直到遇见全特化的 counting<1> 为止。这段代码利用了编译器在编译期的递归替代运行期的递归，巧妙地绕过了原始问题的限制。

类似的手段也可以运用在类模板上。在 YTL 的 traits 库当中就有这样的运用。

不过要注意，既然是递归，就有可能爆栈。编译器递归实例化的深度是有限制的。clang 3.4 的默认限制是 256 层而 gcc 8.2 的默认限制是 900 层。超过这一限制会引发编译器 Fatal error 而编译失败。