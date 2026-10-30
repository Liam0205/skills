---
title: "循环列表中的最大子序列和问题"
url: https://liam.page/2016/05/12/max-subsequence-sum-in-circular-list/
date: 2016-05-12
categories: ["Algorithm and Computer Science"]
tags: ["Dynamic Programming", "Max Subsequence Sum", "Max Subarray Sum", "Circular List", "Kadane Algorithm"]
---

序列的最大子序列和问题，说的是：给定一个包含若干整数（正负不限）的序列，寻找其中的一个子序列，使得该子序列元素之和在所有子序列的和中最大。

这一经典的问题，可由动态规划（中的 Kadane 算法）在 $O(n)$ 的时间内解决。

如果我们将给定的序列首尾相连，成为一个环状列表。同样的问题，就变得复杂起来。不过，在巧妙的思路下，问题仍然可以在 $O(n)$ 时间内解决。

下面我们先复习一下 Kadane 算法；然后看看怎样在线性时间内，解决循环列表中的最大子序列和问题。

## Kadane 算法

该算法由 CMU 的 Jay Kadane 提出，运用了动态规划的思想。

动态规划是求解最优化问题的一种思想，它的核心，是要寻找一种看待问题的方式：

- 这种看待问题的方式，将问题可能的中间过程，划分为若干状态；

- 对于每个状态来说，能取得的值可以有多个，但我们只关注其中的最优解；

- 随着解题过程向前推进，在每个阶段之间，状态之间可能发生转移；

- 在转移的过程中，各个状态在下一个阶段的最优解，可以由上一个阶段某些状态的最优解，经过某种确定的方式得到；

- 这种方式，只与上一阶段的状态有关，而与上一阶段的状态是如何得到的无关。

这样一来，如果我们能够在某个阶段找到确定的最优解，就能够逐层递推，找到原问题的最优解。

在这里：

- 有限的阶段，即是子问题；

- 每个阶段各个状态的最优解，共同构成了当前阶段的局部最优解；

- 最优解在阶段之间的递推关系，叫做最优子结构；

- 最优子结构只与上一阶段的状态本身有关，这个性质叫做无后效性。

也就是说，动态规划的核心，是要寻找一种具有最优子结构的无后效的问题拆解方式。

在 Kadane 算法中，

- 我们将从前往后扫描序列，每次扫描到一个新的整数，就是一个阶段；

- 对于每个阶段来说，我们只关注一个状态，这个时候阶段和状态的概念是等价的：**以当前整数结尾的子序列的和**；

- 对于每个阶段来说，和最大的那个子序列，就是局部最优解；

- 在转移过程中，下一个阶段的局部最优解很容易构造：如果上一阶段的最优解小于零，则下一个阶段的局部最优解就是下一个整数本身；如果上一阶段的局部最优解不小于零，则下一个阶段的局部最优解，只需要在上一阶段的局部最优解的基础上，加上下一个整数即可。

这样，我们就找到了一个无后效性的最优子结构。

据此，我们不难写出如下代码（Python）：

```python
def maxSubArraySum (nums):
    if not nums:
        return None
    elif 1 == len (nums):
        return nums[0]

    local_max, global_max = nums[0], nums[0]

    for i in xrange (1, len (nums)):
        local_max  = max (local_max + nums[i], nums[i])
        global_max = max (local_max, global_max)

    return global_max

if __name__ == '__main__':
    test_cases = [[], [0], [1], [1, 2, 3], [-3, -1, -2],
                  [9, 8, 5, 2, -5, 6, 2, -2]]
    for nums in test_cases:
        print "The maxSubArraySum of", nums, "is", maxSubArraySum (nums)
```

## 循环列表中的最大子序列和问题

对于一个循环列表来说，求解最大子序列和的问题，时间复杂度不会超过 $O(n^2)$。这是因为，我们可以依次移动长度为 $n$ 的窗口，然后用 Kadane 算法求解当前窗口的最大子序列和；而后再将这些窗口分别的最大子序列和做比较，求得其中的最大者。由于窗口数量最大为 $n$，而 Kadane 算法是线性的，所以这种平凡的解法，时间复杂度是 $O(n^2)$。

不过，问题也可以在线性时间内解决。考虑一个循环序列：

```plaintext
arr[0], arr[1], arr[2], ..., arr[n]
```

其最大子序列和对应的子序列，有两种情况：

- 子序列不跨过 arr[n], arr[0]，即不 wrap 的情况。此时问题退化为普通序列的最大子序列和问题，我们可以在线性时间内解决。

- 子序列跨过 arr[n], arr[0]，即 wrap 的情况。此时，我们有 最大子序列和 = 全序列和 - 序列中不 wrap 的子序列的和。显而易见，全序列和 是一个常数，要 wrap 的子序列和尽可能大，就需要中间不 wrap 的子序列和尽可能小。这时候，如果我们将整个序列正负号翻转，那么求得该翻转后的序列的最大子序列和，就对应了翻转前的最小子序列和。因此，这种情况也可以在线性时间内解决。

据此，我们不难得到：

```python
def kadane (nums):
    if not nums:
        return None
    elif 1 == len (nums):
        return nums[0]

    local_max  = nums[0]
    global_max = nums[0]

    for i in xrange (1, len (nums)):
        local_max  = max (local_max + nums[i], nums[i])
        global_max = max (local_max, global_max)

    return global_max

def maxCircularSum (nums):
    if not nums:
        return None
    elif 1 == len (nums):
        return nums[0]

    max_kadane = kadane (nums)

    if max_kadane <= 0:
        return max_kadane

    max_wrap = sum (nums)
    nums     = [-x for x in nums]

    cur_kadane = kadane (nums)
    max_wrap += cur_kadane

    if max_wrap > max_kadane:
        return max_wrap
    else:
        return max_kadane

if __name__ == '__main__':
    test_cases = [[], [0], [1], [1, 2, 3], [-3, -1, -2],
                  [11, 10, -20, 5, -3, -5, 8, -13, 10]]
    for nums in test_cases:
        print "The maxCircularSum of", nums, "is", maxCircularSum (nums)
```

运行结果：

```plaintext
The maxCircularSum of [] is None
The maxCircularSum of [0] is 0
The maxCircularSum of [1] is 1
The maxCircularSum of [1, 2, 3] is 6
The maxCircularSum of [-3, -1, -2] is -1
The maxCircularSum of [11, 10, -20, 5, -3, -5, 8, -13, 10] is 31
```