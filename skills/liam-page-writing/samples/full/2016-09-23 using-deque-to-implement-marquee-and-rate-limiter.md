---
title: "用双向队列实现跑马灯和频率限制器"
url: https://liam.page/2016/09/23/using-deque-to-implement-marquee-and-rate-limiter/
date: 2016-09-23
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Collections", "Marquee", "QPS", "Rate Limiter"]
---

工作中涉及到的数据，其数量越来越大。这就是说，我用 Python 写的工具，需要更高的性能。今天琢磨着把小工具的性能一下子提升了一个数量级，每秒能发出、接收和处理 800 次请求。所谓「事无好坏，过则成灾」，800 QPS 虽然不至于将线上服务压垮，但是多少会对线上服务造成一定的影响（比如响应时间显著延长）。这是不好的。

为了防止架构组的同学过来撕，有必要给我的小工具加上 EVA 的[拘束器](https://zh.wikipedia.org/wiki/EVA_(%E6%88%B0%E9%AC%A5%E6%A9%9F%E6%A2%B0%E4%BA%BA))，限制一下 QPS。

## 思路

Y 是 QA 组的同学，开发了一系列的平台，对此比较有经验。和 Y 的讨论中，他提出，应该实时监控远程服务的响应时间，动态调整发出请求的速度和工作的进程数量，将 QPS 固定住。

从研究的角度来说，这是一个比较精确的思路。但是要给上述工具加上这样一层壳，工作量还是有一些的。这样，不符合补丁「短平快」的要求。

为了找到更合适的方案，我重新理了一下需求：我只需要给 QPS 设置一个上限，防止压力过大影响线上服务就可以了，并不需要将 QPS 固定在定值上。这样一来，动态监控远程服务的响应时间，就变得不重要了。

那么怎样解决这个问题呢？

让我们先回顾一下 QPS 的含义。所谓 QPS，就是单位时间（$\tau$）的请求次数（$k$）。限制 QPS，就是要限制单位时间 $\tau$ 内的请求次数 $k$。换而言之，**我们需要保证，在接踵而来的请求中，任意连续的 $k+1$ 个请求，其首尾的时间间隔都严格大于 $\tau$**。

因此，我们需要用一个数据结构，顺序保存最近的 $k$ 个请求发生的时间戳。当第 $k + 1$ 个请求来临时，我们需要对比它和保存的时间戳中的最早者之间的时间间隔 $t$。

- 如果 $t > \tau$，那么对该请求放行，将当前时间戳保存到数据结构并淘汰掉最早的那个时间戳；

- 如果 $t \leqslant \tau$，那么抛弃或阻塞该请求，等待下一次调用。

算法浅显易懂，而实现起来，我们只需要一个固定长度的双向队列即可。

## collections 库中的 deque

在 Python 的 list 基础上加上一些限制条件，当然可以满足我们的需要。不过 list 是用线性表实现的；而在我们的环境里，需要频繁快速地进行元素的插入和删除操作。所以，我们对选用 list 作为基础数据结构需要慎重考虑。

Python 的标准库 collections 是一组高性能的容器，其中提供了 deque 的双向队列。deque 使用链表实现的，因此能够在 O(1) 时间复杂度内进行队列首尾的插入和删除操作。从性能上说，deque 在我们的问题里，完胜 list。

### 插入和删除首尾的元素

deque 提供了简便的方法，在队列首尾增减元素。

```python
In [1]: from collections import deque

In [2]: q = deque(['a', 'b', 'c'])

In [3]: q.append('x')       # 在队尾增加元素 'x'

In [4]: q.appendleft('y')   # 在队首增加元素 'y'

In [5]: q
Out[5]: deque(['y', 'a', 'b', 'c', 'x'])

In [6]: q.pop()             # 删除队尾元素并返回它的值
Out[6]: 'x'

In [7]: q
Out[7]: deque(['y', 'a', 'b', 'c'])

In [8]: q.popleft()         # 删除队首元素并返回它的值
Out[8]: 'y'

In [9]: q
Out[9]: deque(['a', 'b', 'c'])
```

### 限制长度

在初始化一个 deque 的时候，可以指定它的最大长度（maxlen）。这个长度一旦指定，就是该 deque 实例的只读属性。当实例的长度达到设定的最大长度后

- 执行 append(element) 会先执行 popleft() 删除队首元素，再将 element 加在队尾；

- 执行 appendleft(element) 会先执行 pop() 删除队尾元素，再将 element 加在队首。

这真是**大快人心的大好事**啊，完美符合我们的需求。

### 轮转

deque 还提供了一个有趣的成员函数，名字是 rotate(step)。其作用是：

- 当 step 是正整数时，从队首到队尾，循环挪动 step 步；

- 当 step 是负整数时，从队尾到队首，循环挪动 step 步。

通过 rotate 函数，我们可以实现一个有趣是跑马灯程序。

```python
import sys
import time
from collections import deque

marquee = deque('>>-----' * 10)

while True:
    print '\r%s' % ''.join(marquee),
    marquee.rotate(1)
    sys.stdout.flush()
    time.sleep(0.04)
```

## 实现频率限制器

有了上面的分析，又有了 deque 这一好用的工具，实现一个这样的限制器，是很容易的。我们将它封装成一个类，方便调用。

```python
from collections import deque
import time

class RateLimiter:
    def __init__(self, maxCount = 5, timeUnit = 1):
        self.timeUnit = timeUnit
        self.deque    = deque (maxlen = maxCount)

    def __call__(self):
        if self.deque.maxlen == len(self.deque):
            cTime = time.time()
            if cTime - self.deque[0] > self.timeUnit:
                self.deque.append (cTime)
                return False
            else:
                return True
        self.deque.append (time.time())
        return False

if __name__ == '__main__':
    import random

    checkLim = RateLimiter(maxCount = 8)

    for i in xrange(50):
        rTime = random.uniform(0, 0.2)
        time.sleep(rTime)
        print i, "block[%f]" % (rTime) if checkLim() else "pass[%f]" % (rTime)
```

代码很简单，唯一可能有趣的是 __call__ 这个函数。它和一般的函数在功能上没有什么不同，但是有特别的作用：让 RateLimiter 这个类的实例成为可以调用的函数。这就是为什么我们可以用 if checkLim() 的原因。

代码的输出如下（由于加入了随机数，在你的计算机上执行可能不会完全相同），pass 表示被放行，block 表示频率过快，受到限制。

```plaintext
0 pass[0.109310]
1 pass[0.090743]
2 pass[0.038481]
3 pass[0.086077]
4 pass[0.101313]
5 pass[0.173419]
6 pass[0.159947]
7 pass[0.135079]
8 block[0.011212]
9 block[0.070294]
10 block[0.029171]
11 block[0.018660]
12 pass[0.080185]
13 pass[0.143896]
14 pass[0.191853]
15 pass[0.188746]
16 pass[0.198628]
17 pass[0.123896]
18 pass[0.144908]
19 pass[0.107941]
20 pass[0.080700]
21 pass[0.006529]
22 pass[0.171683]
23 block[0.040397]
24 pass[0.187498]
25 block[0.047226]
26 pass[0.124452]
27 pass[0.103683]
28 pass[0.153917]
29 block[0.021065]
30 pass[0.196360]
31 pass[0.042572]
32 pass[0.093290]
33 pass[0.113496]
34 pass[0.178457]
35 pass[0.079711]
36 pass[0.129189]
37 block[0.025027]
38 pass[0.130345]
39 block[0.037810]
40 block[0.020917]
41 pass[0.171373]
42 pass[0.031104]
43 pass[0.089182]
44 pass[0.175822]
45 pass[0.137213]
46 block[0.018022]
47 block[0.003023]
48 pass[0.167048]
49 pass[0.120170]
```