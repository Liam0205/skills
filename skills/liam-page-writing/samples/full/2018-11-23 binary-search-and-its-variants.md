---
title: "谈谈二分搜索及其变体"
url: https://liam.page/2018/11/23/binary-search-and-its-variants/
date: 2018-11-23
categories: ["Algorithm and Computer Science"]
tags: ["Binary Search"]
---

在前作讨论[基于比较的排序算法的复杂度下界](/2018/08/28/lower-bound-of-comparation-based-sort-algorithm/)时，我们提及了二分搜索算法。

二分搜索是一个效率很高的算法。一个良好实现的二分搜索算法，其时间复杂度可以达到 $\Theta(\log n)$，而空间复杂度只有 $O(1)$。特别地，二分搜索算法的描述十分简洁。作为程序员，总是喜欢 clean and powerful 的东西。因此，二分搜索无疑对程序员有巨大的吸引力。

按照 Knuth 的说法，「尽管第一个二分搜索算法早在1946年就被发表，但第一个没有bug的二分搜索算法却是在12年后才被发表出来」。

此篇我们讨论二分搜索算法的原理及其各种变体的实现。

## 算法描述

二分搜索是针对支持随机访问的有序数据集进行查找操作的算法。最基本的二分搜索，查找的是等于目标元素的元素在数据集中的位置。它的描述十分简单：

- 折半取中，判断元素与目标元素的大小关系
小于——往前继续折半
大于——往后继续折半
等于——返回

此处要注意二分搜索的适用场景：

- 依赖顺序表结构

- 数据本身必须有序

- 数据量相对比较元素的开销要足够大——不然遍历即可

- 数据量相对内存空间不能太大——不然顺序表装不下

## 二分搜索的实现

```cpp
#include <iterator>
#include <functional>

template <typename IterT,
          typename ValueT = typename std::iterator_traits<IterT>::value_type,
          typename Compare = std::less<ValueT>>
IterT bsearch(IterT first,
              IterT last,
             ValueT target,
            Compare comp = Compare()) {
    IterT result = last;
    while (std::distance(first, last) > 0) {
        IterT mid = first + std::distance(first, last) / 2;
        if (comp(*mid, target)) {
            first = mid + 1;
        } else if (comp(target, *mid)) {
            last = mid;
        } else {  // equal
            result = mid;
            break;
        }
    }
    return result;
}
```

这一实现有一些技巧值得说一说。

首先，搜索范围是由 first 和 last 构成的左闭右开区间。在编程中，坚持使用左闭右开区间，能够避免大多数索引越界的问题。这是个好习惯，值得一说。

其次，这一实现以 mid = low + (high - low) / 2 的方式来确定折半点。与之相对，还有一种写法是 mid = (low + high) / 2。在数学的角度，这两种写法完全相同。但是在计算机的角度，后者可能涉及到整数的溢出。因此，为了避免溢出，我们应当优先采用实现当中的写法。

最后，这一实现以 while 循环替代递归，节省了函数的递归调用带来的开销。与之搭配，在未能找到目标时，通过调整区间首尾实现折半动作。这种实现方式是处于效率的考量。

## 二分搜索的变体

单就查找等于目标的元素来说，这一任务还有哈希表和查找树等数据结构能高效地完成。相较二分搜索，它们的限制更少——不需要数据集本身有序，也不需要分配连续的大块内存。如此看来，二分搜索似乎只是看起来美好，实际用途应该不广。

但事实上，二分搜索还有若干变体。这些变体实现的功能，上述这些数据结构通常很难以较低的时间复杂度完成。这些变体才是最能体现二分搜索威力的场景。这里介绍常见的四个变体：

- 查找支持随机访问的有序数据集中，第一个等于给定值的元素

- 查找支持随机访问的有序数据集中，最后一个等于给定值的元素

- 查找支持随机访问的有序数据集中，第一个不小于给定值的元素

- 查找支持随机访问的有序数据集中，最后一个不大于给定值的元素

这些变体的实现也不难。在上述标准二分搜索的基础上，只需要稍加改造即可。需要关注的核心点，就是在不同条件下，区间的首尾应该如何变化。以下是我以 C++ 实现的这些变体。这份实现里值得一提的地方，在基础款的二分搜索实现中已经提过，便不再赘述。

```cpp
#include <iterator>
#include <functional>

enum class BsearchPolicy { UNSPECIFIED, FIRST, LAST, FIRST_NOT_LESS, LAST_NOT_GREATER };

template <typename IterT,
          typename ValueT = typename std::iterator_traits<IterT>::value_type,
          typename Compare>
IterT bsearch(IterT first,
              IterT last,
             ValueT target,
            Compare comp,
      BsearchPolicy policy = BsearchPolicy::UNSPECIFIED) {
    IterT result = last;
    while (std::distance(first, last) > 0) {
        IterT mid = first + std::distance(first, last) / 2;
        if (policy == BsearchPolicy::FIRST_NOT_LESS) {
            if (!comp(*mid, target)) {
                if (mid == first or comp(*(mid - 1), target)) {
                    result = mid;
                    break;
                } else {
                    last = mid;
                }
            } else {
                first = mid + 1;
            }
        } else if (policy == BsearchPolicy::LAST_NOT_GREATER) {
            if (comp(target, *mid)) {
                last = mid;
            } else {
                if (std::distance(mid, last) == 1 or comp(target, *(mid + 1))) {
                    result = mid;
                    break;
                } else {
                    first = mid + 1;
                }
            }
        } else {  // policy == UNSPECIFIED or FIRST or LAST
            if (comp(*mid, target)) {
                first = mid + 1;
            } else if (comp(target, *mid)) {
                last = mid;
            } else {  // equal
                if (policy == BsearchPolicy::FIRST) {
                    if (mid == first or comp(*(mid - 1), *mid)) {
                        result = mid;
                        break;
                    } else {
                        last = mid;
                    }
                } else if (policy == BsearchPolicy::LAST) {
                    if (std::distance(mid, last) == 1 or comp(*mid, *(mid + 1))) {
                        result = mid;
                        break;
                    } else {
                        first = mid + 1;
                    }
                } else {
                    result = mid;
                    break;
                }
            }
        }
    }
    return result;
}

template <typename IterT,
          typename ValueT = typename std::iterator_traits<IterT>::value_type,
          typename Compare = std::less<ValueT>>
IterT bsearch(IterT first,
              IterT last,
             ValueT target,
      BsearchPolicy policy = BsearchPolicy::UNSPECIFIED) {
        return bsearch(first, last, target, Compare(), policy);
}
```