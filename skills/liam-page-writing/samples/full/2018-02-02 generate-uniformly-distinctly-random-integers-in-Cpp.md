---
title: "产生不重复的均匀随机整数"
url: https://liam.page/2018/02/02/generate-uniformly-distinctly-random-integers-in-Cpp/
date: 2018-02-02
categories: ["Algorithm and Computer Science"]
tags: ["Random", "Dinstinct", "Uniform"]
---

[前文](/2018/01/12/Mersenne-twister/)介绍了梅森旋转算法；该算法可用于产生高质量的长周期随机数。不过，随机数生成算法并不保证在一定连续长度内产生的随机数都是不重复的。即，有可能出现这样的随机数序列：

```plaintext
1 1 2 8 6 ...
```

实际生产中，我们也会需要有能力生成不重复的均匀随机整数。此篇用 C++ 实现，做一个简单的记录。

## 不考虑不重复性

在 C++ 中，不考虑不重复性，标准库（C++ 11 及以上）提供的设施已足够完成任务。

```cpp
#include <iostream>
#include <random>

int main() {
    std::random_device rd;                        // 1.
    std::mt19937 gen(rd());                       // 2.
    std::uniform_int_distribution<> dis(1, 100);  // 3.

    for (int n = 0; n != 10; ++n)
        std::cout << dis(gen) << ' ';             // 4.
    std::cout << '\n';
}
```

这里，(1) 是一个由实现决定的非确定性随机数生成器（一般与硬件有关）；(2) 借由 rd 产生的随机数种子，初始化了标准的梅森旋转生成器；(3) 则定义了 [1, 6] 之间的均匀整数分布。最后，(4) 将梅森旋转生成器输出的随机数转换为均匀整数分布。

## 加入不重复性

保证不重复性有两种解决方案：

- 随机数生成器的算法本生保证了一定连续数量的随机结果不重复；

- 通过外部数据结构提供「重复生成」这样的信息。

对于高质量随机数生成器来说，保证一定连续数量的随机结果不重复会严重影响周期性。因此第一种方案实际上是不可取的。于是，我们需要第二个方案。

```cpp
#include <unordered_set>
#include <random>

template <typename IntType = int>
class distinct_uniform_int_distribution {
 public:
  using result_type = IntType;

 private:
  using set_type    = std::unordered_set<result_type>;
  using distr_type  = std::uniform_int_distribution<result_type>;

 public:
  distinct_uniform_int_distribution(result_type inf, result_type sup) :  // 1.
    inf_(inf),
    sup_(sup),
    range_(sup_ - inf_ + 1),                                             // 2.
    distr_(inf_, sup_)
    {}
  void reset() {                                                         // 3.
    uset_.clear();
    distr_.reset();
  }

  template <typename Generator>
  result_type operator()(Generator& engine) {                            // 4.
    if (not(uset_.size() < range_)) { std::terminate(); }                // *.
    result_type res;
    do { res = distr_(engine); } while (uset_.count(res) > 0);           // 5.
    uset_.insert(res);
    return res;
  }

  result_type min() const { return inf_; }
  result_type max() const { return sup_; }

 private:
  const result_type inf_;
  const result_type sup_;
  const size_t      range_;
  distr_type        distr_;
  set_type          uset_;
};
```

首先，(1) 处在构造时必须要知道生成的整数范围是多少。而后，由于我们希望分布产生不重复的随机数，故而能产生这样的随机数是有上限的，我们于 (2) 处将这个范围保存在 range_ 中。仿照 std::uniform_int_distribution，(3) 也给出了用于清理内部状态的函数 reset：一方面将计数集合 uset_ 清空，另一方面重置内部 distr_type 的状态。(4) 重载了函数调用运算符，它是一个函数模板，接受一个随机数生成器。由于我们需要知道产生的随机数是否已经出现过，所以我们必须维护一个集合，用于保存已经输出过的整数。(5) 借助这个集合，保证了输出的不重复性。特别地，(*) 处检查了已输出不重复随机整数的数量，避免 (5) 处陷入死循环。

对它的调用也很简单，与 std::uniform_int_distribution 基本一致。

```cpp
#include <iostream>
#include <random>

int main() {
    std::random_device rd;                            // 1.
    std::mt19937 gen(rd());                           // 2.
    distinct_uniform_int_distribution<> dis(1, 100);  // 3.

    for (int n = 0; n != 10; ++n)
        std::cout << dis(gen) << ' ';                 // 4.
    std::cout << '\n';
}
```