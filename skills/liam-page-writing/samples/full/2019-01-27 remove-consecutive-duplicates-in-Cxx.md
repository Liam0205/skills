---
title: "在 C++ 中移除序列中连续重复的特定值"
url: https://liam.page/2019/01/27/remove-consecutive-duplicates-in-Cxx/
date: 2019-01-27
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Consecutive", "Duplicate"]
---

最近在写 YTL 中的字符串相关辅助函数。实现到 split 函数时，希望能够实现类似 Python 当中的 str.split 方法的功能。

If sep is not specified or is None, a different splitting algorithm is applied: runs of consecutive whitespace are regarded as a single separator, and the result will contain no empty strings at the start or end if the string has leading or trailing whitespace.——[https://docs.python.org/3/library/stdtypes.html#str.split](https://docs.python.org/3/library/stdtypes.html#str.split)

也就是说，在最基本的 split 的基础上，要添加两个功能：

- 删除输入字符串首尾的空白；

- 将字符串中的连续分隔符当成一个分隔符看待。

前一个功能很好实现。将空白符保存在 const char* trim_chars = " \t\n\r\v\f" 当中，然后使用 std::string::find_first_not_of 以及 std::string::find_last_not_of 即可找到有效内容的起止位置，最后再 std::string::erase 一下就好了。

后一个功能也不复杂。但要写得优雅——最好是能利用上标准库的设施——就不那么容易了。

## std::unique 的基本用法

std::unique 是定义在 algorithm 头文件内的容器算法。它有两种基本形式：

```cpp
template< class ForwardIt >
ForwardIt unique( ForwardIt first, ForwardIt last );
template< class ForwardIt, class BinaryPredicate >
ForwardIt unique( ForwardIt first, ForwardIt last, BinaryPredicate p );
```

其中，第一种形式是第二种形式的特例，它等价于 BinaryPredicate p 为连续两元素相等性判断时的第二种形式：

```cpp
template< class ForwardIt,
          class BinaryPredicate =
            std::function<bool(const typename std::iterator_traits<ForwardIt>::value_type&,
              const typename std::iterator_traits<ForwardIt>::value_type&)>
ForwardIt unique( ForwardIt first, ForwardIt last,
            BinaryPredicate p = [](const typename std::iterator_traits<ForwardIt>::value_type& lhs,
                                   const typename std::iterator_traits<ForwardIt>::value_type& rhs) {
                                        return lhs == rhs; });
```

这也就是说，第一种形式的 std::unique 会找到每个连续重复的区间，而后保留这些区间的首个元素，最后返回新序列逻辑上的尾后迭代器。例如，aabbccaa 经过 std::unique 处理之后得到：

```cpp
abca????
    ↑
```

这里用箭头标出的位置，即是 std::unique 的返回值所指向的位置。需要注意的是，经过 std::unique 处理之后，容器的实际大小没有发生改变，甚至逻辑尾后迭代器到容器实际尾后迭代器之间的左闭右开区间内的迭代器仍然是可解引用的（dereferenceable）。但这部分区间内的元素的值是不确定的。因此，在使用 std::unqiue 之后，往往会调用容器的 erase 函数成员，删除逻辑尾后迭代器开始的所有元素。例如：

```cpp
// #include <string>
// #include <algorithm>
std::string source("aabbccaa");
source.erase(std::unique(source.begin(), source.end()), source.end());
std::cout << source << std::endl;  // expect result: abca
```

## 只对特定内容进行 std::unique 操作

回到最开始的问题。我们需要的功能，是针对分隔符 sep 进行操作，将连续出现的 sep 压缩成一个。std::unique 的默认行为则不然，它会将所有连续出现的元素都压缩成一个——不光是 sep。为此，我们需要实现自己的 BinaryPredicate。首先，由于我们要指定具体需要被 std::unique 压缩的元素，我们必然要将其作为函数参数传入函数。于是我们有以下实现：

```cpp
// #include <functional>
template <typename T>
bool AreConsecutiveElements(const T& target, const T& lhs, const T& rhs) {
  return (lhs == rhs) and (lhs == target);
}
```

std::unique 要求一个二元谓词（BinaryPredicate），但此处我们实现的是三元谓词。于是，好在 target 总是应当预先给出的，所以我们可以利用 std::bind 将 target 绑定在 AreConsecutiveElements 的第一个参数上，产生一个二元谓词。

```cpp
// #include <functional>
// using namespace std::placeholders;
// #include <string>
// #include <algorithm>
const char target = 'b'
auto binp = std::bind(AreConsecutiveElements, target, _1, _2);
std::string source("aabbccaa");
source.erase(std::unique(source.begin(), source.end(), binp), source.end());
std::cout << source << std::endl;  // expect result: aabccaa
```

这里，我们将 'b' 作为压缩目标，并将其与 AreConsecutiveElements 绑定在一起，产生一个新的二元谓词。最终输出期待的结果。

## 附：std::unique 的一个可能实现

```cpp
template<class ForwardIt, class BinaryPredicate>
ForwardIt unique(ForwardIt first, ForwardIt last, BinaryPredicate p) {
  if (first == last) {
    return last;
  }

  ForwardIt result = first;
  while (++first != last) {
    if (!p(*result, *first) && ++result != first) {
      *result = std::move(*first);
    }
  }
  return ++result;
}
```