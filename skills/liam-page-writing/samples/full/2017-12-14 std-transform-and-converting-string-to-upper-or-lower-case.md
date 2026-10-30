---
title: "利用 std::transform 对字符串进行大小写转换"
url: https://liam.page/2017/12/14/std-transform-and-converting-string-to-upper-or-lower-case/
date: 2017-12-14
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Transform", "Lower Case", "Upper Case"]
---

对字符串的操作一直被认为是程序员的基本功之一。对于一个英文的字符串来说，最简单的操作，就是进行大小写转换了。这不是什么难事，但这里我们讨论的是 C++ 风格的写法。

## std::transform

[std::transform](http://en.cppreference.com/w/cpp/algorithm/transform) 是定义在头文件 algorithm 当中的一个函数模板。它和标准库中大多数其他函数模板一样，是对迭代器进行操作的函数。在 C++11 中，它有两个函数签名。

```cpp
template <typename InputIt,
          typename OutputIt,
          typename UnaryOperation >
OutputIt transform(InputIt first,          // 1.
                   InputIt last,
                  OutputIt d_first,
            UnaryOperation unary_op);

template <typename InputIt1,
          typename InputIt2,
          typename OutputIt,
          typename BinaryOperation >
OutputIt transform(InputIt1 first1,         // 2.
                   InputIt1 last1,
                   InputIt2 first2,
                   OutputIt d_first,
            BinaryOperation binary_op );
```

从功能上说，std::transform 和 Python 当中的内建函数 map() 非常相似。

(1) 接收两个 InputIt 类型的迭代器，界定了待处理的元素的范围（左闭右开区间），被一元操作 unary_op 处理之后，依次保存在 OutputIt 对应的容器当中。这基本上就是 Python 当中的 map(lambda x: return <do_something>, <iterable>)。只不过，Python 当中的 map() 将结果作为返回值返回，而 std::transform 将结果保存在 d_first 对应的容器中。

有了 (1) 的知识，(2) 也就不难理解了。(2) 的输入接受两组迭代器。第一组迭代器与 (1) 中的情形相同，第二组迭代器则只有一个起始位置 first2而没有尾后截止。这样一来，我们必须保证第二组迭代器对应的容器足够大；即 std::distance(first1, last1) <= std::distance(first2, c2.end())，其中 c2.end() 表示 first2 对应的容器的尾后迭代器。(2) 与 (1) 还有一处不同在于，(1) 接受一个 UnaryOperation，而 (2) 接受一个 BinaryOperation。因此，(2) 通过两个输入迭代器分别获取一个元素，经过 BinaryOperation 处理之后，保存在输出迭代器 d_frist 当中。这与 Python 当中的 map(lambda x, y: return <do_something>, <iterable_1>, <iterable_2>) 类似。

我们用如下代码说明 std::transform 的用法。

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <iterator>

int main() {
    std::vector<int> vec{1, 2, 3, 4, 5};
    for (const auto& e : vec) {
        std::cout << e << ' ';
    }
    std::cout << '\n';

    std::vector<int> vec_out;
    vec_out.reserve(vec.size());                                // 1.

    std::transform(vec.begin(), vec.end(),                      // 2.
                   std::back_inserter(vec_out),                 // 3.
                   [](int i){ return i * i; });                 // 4.
    for (const auto& e : vec_out) {
        std::cout << e << ' ';
    }
    std::cout << '\n';

    std::vector<int> vec_res;
    vec_res.reserve(vec.size());

    std::transform(vec.begin(), vec.end(),                      // 5.
                   vec_out.begin(),                             // 6.
                   std::back_inserter(vec_res),                 // 7.
                   [](int lhs, int rhs){ return rhs - lhs; });  // 8.
    for (const auto& e : vec_res) {
        std::cout << e << ' ';
    }
    std::cout << '\n';

    return 0;
}
```

这里，(1) 为 vec_out 预留好了足够的空间，避免在后续不断 push_back 的过程中动态扩容，降低效率。在实际工程中，若一个向量的长度是预计确定的，或者能够预估的，那么提前预留好空间能大幅提高效率。

在 (2)(3)(4) 处，我们调用了 std::transform 函数。(2) 处输入了待处理序列的起止位置迭代器（左闭右开）；(3) 处输入了结果保存位置的迭代器；(4) 则以 C++ 的 Lambda 函数创建了一个临时的一元函数（求平方）。

在 (5)(6)(7)(8) 处，我们再次调用了 std::transform 函数。(5) 处输入了第一个待处理序列的起止位置迭代器（左闭右开）；(6) 处输入了第二个待处理序列的起始位置迭代器（两个 std::vector<int> 长度相同，因而合法）；(7) 照例输入了结果保存位置的迭代器；(8) 则以 C++ 的 Lambda 函数创建了一个临时的二元函数（求差）。

这样一来，结果应该是：

```bash
$ ./a.out
1 2 3 4 5
1 4 9 16 25
0 2 6 12 20
```

## std::tolower 和 std::toupper

[std::tolower](http://en.cppreference.com/w/cpp/string/byte/tolower) 和 [std::toupper](http://en.cppreference.com/w/cpp/string/byte/toupper) 是定义在头文件 cctype 当中的两个函数。它们的函数签名分别是

```cpp
int tolower(int ch);
int toupper(int ch);
```

需要额外注意的是，两个函数对参数是有要求的。ch 必须不能是 EOF，并且必须能转换为 unsigned char。

## 对字符串进行大小写转换

考虑到 std::string 和 std::vector 类似，都可以用迭代器进行逐元素地操作；我们可以利用 std::transform 和 std::tolower 及 std::toupper 对整个字符串进行大小写转换。

```cpp
#include <iostream>
#include <string>
#include <algorithm>

namespace std {
std::string tolower(std::string str) {
    std::transform(str.begin(), str.end(),
                   str.begin(),
                   [](unsigned char ch){ return tolower(ch); });
    return std::move(str);
}

std::string toupper(std::string str) {
    std::transform(str.begin(), str.end(),
                   str.begin(),
                   [](unsigned char ch){ return toupper(ch); });
    return std::move(str);
}
}  // namespace std

int main() {
    std::string str = "Hello World!";

    std::cout << "original:\t" << str << std::endl;
    std::cout << "tolower:\t" << std::tolower(str) << std::endl;
    std::cout << "toupper:\t" << std::toupper(str) << std::endl;

    return 0;
}
```

有了之前的知识，这份代码是不言自明的。它的输出应该是：

```bash
$ ./a.out
original:       Hello World!
tolower:        hello world!
toupper:        HELLO WORLD!
```