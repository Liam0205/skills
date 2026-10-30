---
title: "Alias Method: 在常数时间复杂度内非均匀地随机抽取元素"
url: https://liam.page/2019/12/02/non-uniform-random-choice-in-constant-time-complexity/
date: 2019-12-02
categories: ["Algorithm and Computer Science"]
tags: ["Random", "Choice"]
---

这篇文章要讨论的问题很简单：给定一个集合，要你在常数时间复杂度内，从中以给定的概率分布随机抽取其中的元素。

## 问题的抽象

这里我们以 C++ 语言描述，我们需要实现这样一个可调用的类模板：

```cpp
template <typename T>
struct discrete_random_variable {
 private:
  const std::vector<T> values_;
  // other internal assets

 public:
  discrete_random_variable(const std::vector<T>& val, const std::vector<double>& prob);
  T operator()(void);
};
```

这里，构造函数完成初始化工作，函数调用运算符完成随机抽取元素的工作。

## Trival 版本

最平凡的想法可以是：

- 根据概率分布计算累积分布，将 $[0, 1]$ 分成若干段；

- 然后通过一个 $[0, 1]$ 之间的均匀随机生成器，随机生成一个 $[0, 1]$ 之间的浮点数；

- 最后通过**判断**随机数落在哪一个分段中，输出相应的元素。

这里的 (1) 和 (2) 都可以在常数时间内完成，(3) 最快可以用二分或者二叉搜索树的方法在对数时间内完成。这里实现一版利用二分查找的方案。

```cpp
#include <cassert>
#include <cmath>
#include <iostream>
#include <random>
#include <algorithm>
#include <limits>
#include <functional>
#include <map>
#include <vector>

template <typename T>
class discrete_random_variable {
 private:
  const std::vector<T>         values_;
  const std::vector<double>    cumulative_;
  mutable std::random_device   rd_;
  mutable std::mt19937         gen_{rd_()};
  mutable std::uniform_real_distribution<double> dis_{0.0, 1.0};

 public:
  discrete_random_variable(const std::vector<T>& val, const std::vector<double>& prob) :
      values_(val), cumulative_(generate_cumulative(prob)) {
    assert(val.size() == prob.size());
    assert(std::fabs(1.0 - cumulative_.back()) < std::numeric_limits<double>::epsilon());  // *
  }

  T operator()() const {
    const double rand = dis_(gen_);
    const size_t idx  = bsearch_last_not_greater_than(cumulative_.begin(), cumulative_.end(), rand);
    assert(idx < values_.size());
    return values_[idx];
  }

 private:
  std::vector<double> generate_cumulative(const std::vector<double>& prob) {
    std::vector<double> cumulative;
    cumulative.reserve(prob.size() + 1);
    cumulative.emplace_back(0);
    std::transform(prob.begin(), prob.end(), std::back_inserter(cumulative),
        [&](const double p) { return p + cumulative.back(); } );
    return cumulative;
  }

  template <typename iter_t,
            typename value_t = typename std::iterator_traits<iter_t>::value_type,
            typename binpred_t = std::less<value_t>>
  size_t bsearch_last_not_greater_than(const iter_t begin,
                                       const iter_t end,
                                      const value_t target,
                                          binpred_t binpred = binpred_t()) const {
    iter_t first = begin, last = end;
    while (first < last) {
      iter_t mid = first + std::distance(first, last) / 2;
      if (not(binpred(target, *mid)) and
            (std::next(mid) == last or binpred(target, *(std::next(mid))))) {
        return std::distance(begin, mid);
      } else if (binpred(target, *mid)) {
        last = mid;
      } else {
        first = std::next(mid);
      }
    }
    return std::distance(begin, end);
  }
};

int main() {
  std::vector<int> values{1, 2, 3, 4};
  std::vector<double> probs{0.05, 0.25, 0.35, 0.35};

  discrete_random_variable<int> drv{values, probs};

  std::map<int, size_t> counter;

  for (size_t i = 0; i != 400000; ++i) {
    int x = drv();
    assert(std::find(values.begin(), values.end(), x) != values.end());
    ++counter[x];
  }
  for (auto pair : counter) {
    std::cout << pair.first << "[" << pair.second << "]" << ": \t";
    for (size_t i = 0; i != pair.second / 2500; ++i) {
      std::cout << '=';
    }
    std::cout << std::endl;
  }

  return 0;
}
```

## Walker-Vose Alias Method

平凡的解法，效率最高也只能做到对数时间复杂度。不过，既然目标很明确，希望能在「常数时间」内完成任务；那我们就思考一下，有什么类似的场景，可以在常数时间内解决的。显而易见，在标准库设施 std::uniform_int_distribution 的帮助下，对于均匀随机采样，我们可以在常数时间内完成任务。因此，若能在常数时间内，完成均匀和到非均匀的映射，我们就可以借助它来完成任务。

回过头来看「效率最高也只能做到对数时间复杂度」这句话。在目前用到的信息的条件下，这句话是正确的。也就是，在第 (3) 步在没有其他辅助的情况下，对数时间复杂度已经是最优解。因此，若想要继续优化，就必须「找其他辅助」。

我们注意用 * 标注出来的断言。在平凡的解法中，概率分布加和为 1 这一性质，我们只是用来验证概率分布合法，而没有用到它来辅助计算。为了用到这一性质，我们需要注意到以下一些事实：

- 虽然非均匀分布的平凡解法最好能做到对数时间复杂度，但对于非均匀的伯努利实验（随机变量可能取值只有 2 种），我们仍能在**常数时间**内解决问题。

- 若随机变量的取值可能有 $k$ 个，那必然有部分取值的概率小于 $\frac{1}{k}$，同时有另一些不小于 $\frac{1}{k}$。

- 我们可以通过**拆借**的方法，把概率大于 $\frac{1}{k}$ 的部分借给概率小于 $\frac{1}{k}$ 的部分，使得所有取值上的概率都恰好等于 $\frac{1}{k}$；从而使非均匀采样问题变成均匀采样问题。

经过上网查询，这个算法已经被发明过了，它叫做 [Walker-Vose Alias Method](http://www.keithschwarz.com/darts-dice-coins/)。下面给出它的实现：

```cpp
#include <cassert>
#include <cmath>
#include <iostream>
#include <random>
#include <algorithm>
#include <limits>
#include <functional>
#include <map>
#include <vector>
#include <queue>

template <typename T>
class discrete_random_variable {
 private:
  const std::vector<T> values_;
  const std::vector<std::pair<double, size_t>> alias_;
  mutable std::random_device   rd_;
  mutable std::mt19937         gen_{rd_()};
  mutable std::uniform_real_distribution<double> real_dis_{0.0, 1.0};
  mutable std::uniform_int_distribution<size_t>  int_dis_;

 public:
  discrete_random_variable(const std::vector<T>& vals, const std::vector<double>& probs) :
      values_(vals), alias_(generate_alias_table(probs)), int_dis_(0, probs.size() - 1) {
    assert(vals.size() == probs.size());
    const double sum = std::accumulate(probs.begin(), probs.end(), 0.0);
    assert(std::fabs(1.0 - sum) < std::numeric_limits<double>::epsilon());
  }

  T operator()() const {
    const size_t idx  = int_dis_(gen_);
    if (real_dis_(gen_) >= alias_[idx].first and
          alias_[idx].second != std::numeric_limits<size_t>::max()) {
      return values_[alias_[idx].second];
    } else {
      return values_[idx];
    }
  }

 private:
  std::vector<std::pair<double, size_t>> generate_alias_table(const std::vector<double>& probs) {
    const size_t sz = probs.size();
    std::vector<std::pair<double, size_t>> alias(sz, {0.0, std::numeric_limits<size_t>::max()});
    std::queue<size_t>  small, large;

    for (size_t i = 0; i != sz; ++i) {
      alias[i].first = sz * probs[i];
      if (alias[i].first < 1.0) {
        small.push(i);
      } else {
        large.push(i);
      }
    }

    while (not(small.empty()) and not(large.empty())) {
      auto s = small.front(), l = large.front();
      small.pop(), large.pop();
      alias[s].second = l;
      alias[l].first -= (1.0 - alias[s].first);

      if (alias[l].first < 1.0) {
        small.push(l);
      } else {
        large.push(l);
      }
    }

    return alias;
  }
};

int main() {
  std::vector<int> values{1, 2, 3, 4};
  std::vector<double> probs{0.05, 0.25, 0.35, 0.35};

  discrete_random_variable<int> drv{values, probs};

  std::map<int, size_t> counter;

  for (size_t i = 0; i != 400000; ++i) {
    int x = drv();
    assert(std::find(values.begin(), values.end(), x) != values.end());
    ++counter[x];
  }
  for (auto pair : counter) {
    std::cout << pair.first << "[" << pair.second << "]" << ": \t";
    for (size_t i = 0; i != pair.second / 2500; ++i) {
      std::cout << '=';
    }
    std::cout << std::endl;
  }

  return 0;
}
```