---
title: "复杂度速查表"
url: https://liam.page/2016/06/20/big-O-cheat-sheet/
date: 2016-06-20
categories: ["Algorithm and Computer Science"]
tags: ["Complexities", "Cheatsheet"]
---

本篇基本上是[原作](http://bigocheatsheet.com/)的翻译。转载请保留本段文字。

复杂度通常会使用大-O 记号来表示，比如[快速排序](https://zh.wikipedia.org/wiki/%E5%BF%AB%E9%80%9F%E6%8E%92%E5%BA%8F)的平均时间复杂度是 $O(n \log(n))$。虽然我是「理解派」，但是虽然每个算法/数据结构都理解了，不时仍有可能忘记具体某个算法/数据结构的复杂度（特别是在最好、最坏和平均情形下的复杂度）。因此制作一个速查表是蛮有必要的。

动手前先看看是否已经有轮子是一个好习惯，果不其然，我找到了[原作](http://bigocheatsheet.com/)。

## 图例

最佳好一般不好糟糕

## 抽象数据结构的操作复杂度

数据结构时间复杂度空间复杂度

平均最差最差

访问搜索插入删除访问搜索插入删除

[顺序表](https://zh.wikipedia.org/wiki/%E9%A1%BA%E5%BA%8F%E8%A1%A8)$O(1)$$O(n)$$O(n)$$O(n)$$O(1)$$O(n)$$O(n)$$O(n)$$O(n)$

[栈](https://zh.wikipedia.org/wiki/%E5%A0%86%E6%A0%88)$O(n)$$O(n)$$O(1)$$O(1)$$O(n)$$O(n)$$O(1)$$O(1)$$O(n)$

[单链表](https://zh.wikipedia.org/wiki/%E9%93%BE%E8%A1%A8#.E5.8D.95.E5.90.91.E9.93.BE.E8.A1.A8)$O(n)$$O(n)$$O(1)$$O(1)$$O(n)$$O(n)$$O(1)$$O(1)$$O(n)$

[双链表](https://zh.wikipedia.org/wiki/%E5%8F%8C%E5%90%91%E9%93%BE%E8%A1%A8)$O(n)$$O(n)$$O(1)$$O(1)$$O(n)$$O(n)$$O(1)$$O(1)$$O(n)$

[跳表](https://zh.wikipedia.org/wiki/%E8%B7%B3%E8%B7%83%E5%88%97%E8%A1%A8)$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(n)$$O(n)$$O(n)$$O(n)$$O(n \log(n))$

[散列表](https://zh.wikipedia.org/wiki/%E5%93%88%E5%B8%8C%E8%A1%A8)-$O(1)$$O(1)$$O(1)$-$O(n)$$O(n)$$O(n)$$O(n)$

[二叉搜索树](https://zh.wikipedia.org/wiki/%E4%BA%8C%E5%85%83%E6%90%9C%E5%B0%8B%E6%A8%B9)$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(n)$$O(n)$$O(n)$$O(n)$$O(n)$

[笛卡尔树](https://zh.wikipedia.org/wiki/%E7%AC%9B%E5%8D%A1%E5%B0%94%E6%A0%91)-$O(\log(n))$$O(\log(n))$$O(\log(n))$-$O(n)$$O(n)$$O(n)$$O(n)$

[B-树](https://zh.wikipedia.org/wiki/B%E6%A0%91)$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(n)$

[红黑树](https://zh.wikipedia.org/wiki/%E7%BA%A2%E9%BB%91%E6%A0%91)$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(n)$

[伸展树](https://zh.wikipedia.org/wiki/%E4%BC%B8%E5%B1%95%E6%A0%91)-$O(\log(n))$$O(\log(n))$$O(\log(n))$-$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(n)$

[AVL 树](https://zh.wikipedia.org/wiki/AVL%E6%A0%91)$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(n)$

## 数组排序

算法时间复杂度空间复杂度

最佳平均最差最差

[快速排序](https://zh.wikipedia.org/wiki/%E5%BF%AB%E9%80%9F%E6%8E%92%E5%BA%8F)$O(n \log(n))$$O(n \log(n))$$O(n^2)$$O(\log(n))$

[归并排序](https://zh.wikipedia.org/wiki/%E5%BD%92%E5%B9%B6%E6%8E%92%E5%BA%8F)$O(n \log(n))$$O(n \log(n))$$O(n \log(n))$$O(n)$

[Timsort](http://en.wikipedia.org/wiki/Timsort)$O(n)$$O(n \log(n))$$O(n \log(n))$$O(n)$

[堆排序](https://zh.wikipedia.org/wiki/%E5%A0%86%E6%8E%92%E5%BA%8F)$O(n \log(n))$$O(n \log(n))$$O(n \log(n))$$O(1)$

[冒泡排序](https://zh.wikipedia.org/wiki/%E5%86%92%E6%B3%A1%E6%8E%92%E5%BA%8F)$O(n)$$O(n^2)$$O(n^2)$$O(1)$

[插入排序](https://zh.wikipedia.org/wiki/%E6%8F%92%E5%85%A5%E6%8E%92%E5%BA%8F)$O(n)$$O(n^2)$$O(n^2)$$O(1)$

[选择排序](https://zh.wikipedia.org/wiki/%E9%80%89%E6%8B%A9%E6%8E%92%E5%BA%8F)$O(n^2)$$O(n^2)$$O(n^2)$$O(1)$

[希尔排序](https://zh.wikipedia.org/wiki/%E5%B8%8C%E5%B0%94%E6%8E%92%E5%BA%8F)$O(n)$$O((n\log(n))^2)$$O((n\log(n))^2)$$O(1)$

[桶排序](https://zh.wikipedia.org/wiki/%E6%A1%B6%E6%8E%92%E5%BA%8F)$O(n+k)$$O(n+k)$$O(n^2)$$O(n)$

[基数排序](https://zh.wikipedia.org/wiki/%E5%9F%BA%E6%95%B0%E6%8E%92%E5%BA%8F)$O(nk)$$O(nk)$$O(nk)$$O(n+k)$

## 图操作

节点 / 边界管理存储增加顶点增加边界移除顶点移除边界查询

[邻接表](https://zh.wikipedia.org/wiki/%E9%82%BB%E6%8E%A5%E8%A1%A8)$O(|V|+|E|)$$O(1)$$O(1)$$O(|V| + |E|)$$O(|E|)$$O(|V|)$

[邻接矩阵](https://zh.wikipedia.org/wiki/%E9%82%BB%E6%8E%A5%E7%9F%A9%E9%98%B5)$O(|V|^2)$$O(|V|^2)$$O(1)$$O(|V|^2)$$O(1)$$O(1)$

## 堆操作

类型时间复杂度

建堆查找最大值分离最大值提升键插入删除合并

[（排好序的）链表](https://zh.wikipedia.org/wiki/%E9%93%BE%E8%A1%A8)-$O(1)$$O(1)$$O(n)$$O(n)$$O(1)$$O(m+n)$

[（未排序的）链表](https://zh.wikipedia.org/wiki/%E9%93%BE%E8%A1%A8)-$O(n)$$O(n)$$O(1)$$O(1)$$O(1)$$O(1)$

[二叉堆](https://zh.wikipedia.org/wiki/%E4%BA%8C%E5%8F%89%E5%A0%86)$O(n)$$O(1)$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(\log(n))$$O(m+n)$

[二项堆](https://zh.wikipedia.org/wiki/%E4%BA%8C%E9%A1%B9%E5%A0%86)-$O(1)$$O(\log(n))$$O(\log(n))$$O(1)$$O(\log(n))$$O(\log(n))$

[斐波那契堆](https://zh.wikipedia.org/wiki/%E6%96%90%E6%B3%A2%E9%82%A3%E5%A5%91%E5%A0%86)-$O(1)$$O(\log(n))$$O(1)$$O(1)$$O(\log(n))$$O(1)$

## 大-O 复杂度曲线

![](/uploads/images/Linux/big_O_chart.png)