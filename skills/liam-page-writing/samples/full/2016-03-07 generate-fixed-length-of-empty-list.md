---
title: "Python 中生成包含空列表的特定长度的列表"
url: https://liam.page/2016/03/07/generate-fixed-length-of-empty-list/
date: 2016-03-07
categories: ["Algorithm and Computer Science"]
tags: ["Python", "List", "List Comprehensions"]
---

最近用 Python 的时候，踩了一个坑。

主需求，是将横向排列为主的二维数组，读入序列化为纵向排列为主的二维数组。为此，需要先确定原数据的列数，然后建立一个特定长度的空列表:

```python
[[], [], [], ... [], []]
```

## 这是个坑

Python 的乘法非常神奇。比如有：

```python
>>> a = [[]] * 2
>>> a
[[], []]
```

这个方式非常优雅，所以我首先想到的，就是用这样的乘法生成符合要求的二维空数组。

```python
width = 3
a = [list()] * 3
b = range (width + 1)
for i in xrange (width):
    a[i].append (b[i + 1])
print a
```

预想中，最后的 print a 应该输出 [[1], [2], [3]]，然而实际上却输出了

```python
[[1, 2, 3], [1, 2, 3], [1, 2, 3]]
```

看到这个结果，我直接懵逼了。

## 出坑

原来，Python 里的乘法创建的是**实例的引用**。也就是说，[list()] * 3 里的（作为元素的）列表，实际是一个实例：修改其中之一，会同步修改到剩余所有的引用。也就是有：

```python
>>> a = [[1]] * 2
>>> a
[[1], [1]]
>>> a[0][0] = 2
>>> a
[[2], [2]]
```

因此，为了达到我最开始的目的，不能用「魔术乘法」，只能老实地用列表推导式。如：

```python
width = 3
a = [list() for i in xrange (width)]
b = range (width + 1)
for i in xrange (width):
    a[i].append (b[i + 1])
print a
```

得到预期：

```python
[[1], [2], [3]]
```