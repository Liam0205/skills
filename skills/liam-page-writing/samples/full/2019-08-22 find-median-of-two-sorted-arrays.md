---
title: "找到两个有序数组的中位数"
url: https://liam.page/2019/08/22/find-median-of-two-sorted-arrays/
date: 2019-08-22
categories: ["Algorithm and Computer Science"]
tags: ["LeetCode", "bsearch"]
---

这是 LeetCode 的[第 4 题](https://leetcode.com/problems/median-of-two-sorted-arrays/)，@linjie 问到我说，这题网上的解答看完都迷迷糊糊的，希望我能写篇博客重新讲一下。于是有此篇。

## 题目

现有不同时为空的非降序排列的数组 A 和 B，其长度分别是 m 和 n。不失一般性，假设 m <= n。记 A 和 B 的中位数为 x。要求写代码实现，在 $\Theta(\log(m + n))$ 的时间复杂度内找到 x。

## 分析

见到时间复杂度要求中有 $\log$，就肯定要想到二分搜索。

二分搜索的本质是在一个有序 randomly accessible array 中，寻找一个满足某种跟元素顺序相关的条件的元素的方法。这个「跟元素顺序相关的条件」，在最初的版本里是「等于某个数值」，扩展版本可以是「第一个不小于给定数值的值」之类的（参考[前作](https://liam.page/2018/11/23/binary-search-and-its-variants/)）。展开来说，满足以下 4 个要素时，可以用到二分搜索：

- array 只有 1 个，或者可以将多个 array 问题简化成 1 个 array 的问题；

- array 是 randomly accessible 的；

- array 是有序的；

- 搜索 array 中的元素时，限制条件是跟元素顺序有关的。

因此，为了利用二分搜索，我们必须要想办法：

- 变两个序列的问题为 1 个序列的问题；

- 找到某个「跟元素顺序相关的条件」。

首先考虑 (1)。

设 i 是 A 中的下标，而 j 是 B 中的下标：A[i] 是 A 中第一个大于等于中位数 x 的元素；同时 B[j] 是 B 中第一个大于等于中位数 x 的元素。当 A 中元素全部小于 x 时，i = m；同理，当 B 中元素全部小于 x 时，j = n。

这意味着，A 中小于 x 的元素数量为 i，B 中小于 x 的元素数量为 j；A 中大于等于 x 的元素数量为 m - i，B 中大于等于 x 的元素数量为 n - j。满足条件：

- 当 m + n 是偶数：i + j = (m - i) + (n - j)，此时 j = (m + n) / 2 - i。

- 当 m + n 是奇数：i + j = (m - i) + (n - j) - 1，此时 j = (m + n - 1) / 2 - i = (m + n) / 2 - i（考虑整数除法除不尽时向零取整）。

所以 j 有统一的表达式 (m + n) / 2 - i。这样一来，我们就建立了两个序列下标之间的对应关系，从而将两个序列的问题变为了 1 个序列的问题。

接着考虑 (2)。

考虑 x 是中位数，而 A[i] 和 B[j] 分别是 A 和 B 两个序列中第一个大于等于中位数 x 的元素。因此有：

- A[i - 1] < x <= A[i]；

- A[i - 1] < x <= B[j]；

- B[j - 1] < x <= A[i]；

- B[j - 1] < x <= B[j]。

其中 (1) 和 (4) 是 trivial 的。考虑 (2) 和 (3)，即得到目标「条件」：(i == 0 or A[i - 1] < x <= B[j]) and (i == m or B[j - 1] < x <= A[i])。

因此有伪代码：

```plaintext
for i in range(0, m + 1):
  bsearch to find i, s.t.:
    (i == 0 or A[i - 1] < x <= B[j]) and (i == m or B[j - 1] < x <= A[i])

if (m + n) % 2 == 0:
  # carefully handle index out-of-bound
  return static_cast<double>(max(A[i - 1], B[j - 1]) + min(A[i], B[j])) / 2.0
else:
  # carefully handle index out-of-bound
  return min(A[i], B[j])
```

算法的时间复杂度是 $\Theta(\log(\min(m, n)))$，空间复杂度是 $\Theta(1)$。

## C++ 实现

给一个 C++ 版本的完整实现：

```c++
static const auto io_sync_off = []() {
  std::ios::sync_with_stdio(false);
  std::cin.tie(nullptr);
  return nullptr;
} ();

class Solution {
 public:
  double findMedianSortedArrays(const std::vector<int>& A, const std::vector<int>& B) {
    if (A.empty()) {
      return findMedianInSortedArray(B);
    } else if (B.empty()) {
      return findMedianInSortedArray(A);
    } else {
      return bsearchWrapper(A, B);
    }
  }

 private:
  inline double findMedianInSortedArray(const std::vector<int>& v) {
    size_t len = v.size();
    if (len % 2 == 0) {
      return static_cast<double>(v[len / 2] + v[len / 2 - 1]) / 2.0;
    } else {
      return v[len / 2];
    }
  }

  inline double bsearchWrapper(const std::vector<int>& A, const std::vector<int>& B) {
    const size_t m = A.size(), n = B.size();
    if (m <= n) {
      return bsearchHelper(A, B);
    } else {
      return bsearchHelper(B, A);
    }
  }

  inline double bsearchHelper(const std::vector<int>& A, const std::vector<int>& B) {
    const size_t m = A.size(), n = B.size();
    size_t left = 0, right = m + 1;
    size_t i, j;
    while (left < right) {
      i = left + (right - left) / 2;
      j = (m + n) / 2 - i;
      if (not(i == m or B[j - 1] < A[i])) {
        left = i + 1;
      } else if (not(i == 0 or A[i - 1] < B[j])) {
        right = i;
      } else {
        break;
      }
    }
    if ((m + n) % 2 == 0) {
      double mx = (i == m) ? B[j] : ((j == n) ? A[i] : std::min(A[i], B[j]));
      double mn = (i == 0) ? B[j - 1] : ((j == 0) ? A[i - 1] : std::max(A[i - 1], B[j - 1]));
      return (mn + mx) / 2.0;
    } else {
      return (i == m) ? B[j] : ((j == n) ? A[i] : std::min(A[i], B[j]));
    }
  }
};
```