---
title: "Python 中的 random 库速查表"
url: https://liam.page/2016/09/23/Python-random/
date: 2016-09-23
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Cheatsheet", "random"]
---

工作中，时不时需要产生一些随机数或者用到和随机数相关的操作。Python 标准库 random 自带了一些很实用的功能。这里对常用的几个函数（方法）做一个小结，加强记忆，也作为速查表使用。

## 名字和引入

Python 中的随机库，名字就叫做 random，取的是英文中「随机的」之单词。和大多数 Python 库一样，可以用 import 关键字引入。

```python
import random
```

## 产生一个简单的随机数

random 库中有几个函数可以产生随机数。

```python
random.random()         # 在 [0.0, 1.0) 的左闭右开区间中产生一个随机的实数
random.uniform(a, b)    # 相当于 a + (b-a) * random.random()
random.randint(a, b)    # 在 [a, b] 的闭区间中产生一个随机的整数
```

## 产生特定分布的随机数

random 库还可以按照特定的[分布](https://zh.wikipedia.org/wiki/%E6%A6%82%E7%8E%87%E5%88%86%E5%B8%83)产生随机数。

```python
# 取决于实现方式，guass(mu, sigma) 比 normalvariate(mu, sigma) 快一些
random.gauss(mu, sigma)         # 高斯分布：以 mu 为均值，sigma 为标准差
random.normalvariate(mu, sigma) # 正态分布：以 mu 为均值，sigma 为标准差
random.lognormvariate(mu, sigma)# 对数正态分布
```

## 对列表类型的操作

random 库支持对非空的列表类型（包括列表、字符串和元组）的一些随机操作。

```python
random.choice(seq)                  # 从列表类型中随机选取一个元素返回
random.shuffle(seq[, random-func])  # 对 seq 进行洗牌，默认用 random.random()
random.sample(seq, k)               # 从 seq 中随机选取一个子集并返回
```

## 示例

```python
import random

print random.random()
print random.uniform(1, 10)
print random.randint(1, 10)
print random.choice('abcdefghij')
items = [1, 2, 3, 4, 5, 6, 7]
random.shuffle(items)
print items
print random.sample([1, 2, 3, 4, 5], 3)
print items
```

输出

```plaintext
0.972813721789
8.42128946824
10
e
[1, 4, 6, 3, 5, 2, 7]
[3, 1, 5]
[1, 4, 6, 3, 5, 2, 7]
```