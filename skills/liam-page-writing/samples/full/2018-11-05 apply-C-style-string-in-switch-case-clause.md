---
title: "在 C++ 中的 switch-case 语句中使用 C 风格字符串"
url: https://liam.page/2018/11/05/apply-C-style-string-in-switch-case-clause/
date: 2018-11-05
categories: ["Algorithm and Computer Science"]
tags: ["C++", "constexpr", "user-defined suffix"]
---

众所周知，C/C++ 语言中的 switch-case 语句只支持整型数字的逻辑分支。因此，当我们需要对整型数字之外的变量进行分支判断时，就只能依赖 if-else 语句了。例如：

```cpp
if (policy == "SINGLE") {
    ;  // do something
} else if (policy == "MULTIPLE") {
    ;  // do something
} else {  // UNSPECIFIED
    ;  // do something
}
```

这种情况下，虽然我们用 if-else 语句实现了类似 switch-case 语句的功能。但一方面写起来未免麻烦，分支多了难以维护；另一方面如果分支很多，那么执行起来需要注意进行字符串相等性判断，效率很低。因此，这篇文章尝试通过一些取巧的方式来解决这个问题。

## HASH

无论如何，语言层面的 swtch-case 限制是绕不开的。因此，我们需要找到一个有效的办法，将字符串与整形数字对应起来。虽然不甚完美，但是 Hash 是一种解决办法。于是我们针对 C 风格的字符串定义 Hash 函数。

```cpp
using hash_t = size_t;
constexpr hash_t prime = 0x100000001B3ull;
constexpr hash_t basis = 0xCBF29CE484222325ull;

hash_t hash_run_time(const char* str) {
    hash_t ret = basis;

    while (*str) {
        ret ^= *str;
        ret *= prime;
        str++;
    }

    return ret;
}
```

如此，我们「似乎」便可以针对字符串使用 switch-case 语句了。

```cpp
void simple_switch(const char* str) {
    switch (hash_run_time(str)) {
        case hash_run_time("first"):
            std::cout << "1st" << std::endl;
            break;
        case hash_run_time("second"):
            std::cout << "2nd" << std::endl;
            break;
        case hash_run_time("third"):
            std::cout << "3rd" << std::endl;
            break;
        default:
            std::cout << "Default..." << std::endl;
    }
}
```

## constexpr 函数

然而，如果你编译这段代码，编译器就会提醒你在 case 处必须使用常量表达式。因此，对于 case 的分支选项，我们不仅要将他们转换为整型 hash_t，还必须保证它们在编译期就能运算完成，从而作为常量表达式。考虑到，在 C++11 中常量表达式函数必须只能有一个 return 语句（在 C++14 之后就没有这个限制了），因此我们需要借助 C++ 中的三元运算符 ?: 将 hash_run_time 函数改造为递归形式。

```cpp
constexpr hash_t hash_compile_time(const char* str, hash_t last_value = basis) {
    return *str ? hash_compile_time(str + 1, (*str ^ last_value) * prime) : last_value;
}
```

同时，simple_switch 函数也需要改造一下：

```cpp
void simple_switch(const char* str) {
    switch (hash_run_time(str)) {
        case hash_compile_time("first"):
            std::cout << "1st" << std::endl;
            break;
        case hash_compile_time("second"):
            std::cout << "2nd" << std::endl;
            break;
        case hash_compile_time("third"):
            std::cout << "3rd" << std::endl;
            break;
        default:
            std::cout << "Default..." << std::endl;
    }
}
```

此时，simple_switch 函数已可通过编译。

事实上，用于处理输入的 hash_run_time 也可以被 hash_compile_time 替代。

## 用户定义的字面值常量后缀

尽管此时代码已经可以通过编译并使用，但在每个 case 处都写一个函数调用未免麻烦。于是我们需要引入[用户定义的字面值常量后缀（User-defined suffix）](https://en.cppreference.com/w/cpp/language/user_literal)简化代码。

```cpp
constexpr hash_t operator "" _hash(const char* p, size_t) {
    return hash_compile_time(p);
}
```

于是，simple_switch 函数可被简化为：

```cpp
void simple_switch(const char* str) {
    switch (hash_run_time(str)) {
        case "first"_hash:
            std::cout << "1st" << std::endl;
            break;
        case "second"_hash:
            std::cout << "2nd" << std::endl;
            break;
        case "third"_hash:
            std::cout << "3rd" << std::endl;
            break;
        default:
            std::cout << "Default..." << std::endl;
    }
}
```

完整的测试代码可见：[https://gist.github.com/25dcb10e55b3cb2306931aa277355bbf](https://gist.github.com/25dcb10e55b3cb2306931aa277355bbf)。