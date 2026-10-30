---
title: "寻找不小于给定整数的最小的 2 的幂方"
url: https://liam.page/2019/02/14/find-smallest-power-of-2-that-is-not-less-than-a-given-integer/
date: 2019-02-14
categories: ["Algorithm and Computer Science"]
tags: ["C++"]
---

这是一篇简单的记录。

最近在写 YTL 的过程中遇到这样一个子问题：需要定义一个函数 uint32_t func(uint32_t num)，返回不小于 num 的最小的 2 的幂方。例如

```cpp
1 == func(1);
2 == func(2);
4 == func(3);
4 == func(4);
// ……
```

一开始我想了个用位运算的奇技淫巧，自我感觉还不错：

```cpp
uint32_t func(uint32_t num) {
  uint32_t res = 1;
  while (res < num) {
    res <<= 1;
  }
  return res;
}
```

后来一想，「不要在编译器面前装屄」，于是发现老实用 std::log2 来计算的话，效率要高出五倍多：

```cpp
// #include <cmath>
uint32_t func(uint32_t num) {
  return 1 << static_cast<int>(std::ceil(std::log2(num)));
}
```

再一想，std::ceil 本来就快，std::log2 有快速解法。那么如果把 1 << foo 换成 std::pow(2.0, foo) 会怎样呢？结果发现，大概是由于 std::pow 是为浮点数运算设计的，所以没为 2 的幂方做优化，所以效率还不如位运算：

```cpp
// #include <cmath>
uint32_t func(uint32_t num) {
  return std::pow(2.0, std::ceil(std::log2(num)));
}
```

以上。