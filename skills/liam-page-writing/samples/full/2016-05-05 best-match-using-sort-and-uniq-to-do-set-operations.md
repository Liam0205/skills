---
title: "最佳搭档：利用 sort 和 uniq 做集合运算"
url: https://liam.page/2016/05/05/best-match-using-sort-and-uniq-to-do-set-operations/
date: 2016-05-05
categories: ["Computer Skills"]
tags: ["sort", "uniq", "Set", "Operation"]
---

工作中遇到一些需要做集合运算的场景。这种时候，写个 Python 脚本当然是个选择；然而，我却嫌弃太重量级。因此，在 Linux 工具中寻找到了能够胜任这一工作的 sort 和 uniq 两个命令。

## sort: 生而为排序

sort 命令的用法很简单。最基本的用法有两种：

```bash
cat <filename> | sort
sort <file1> [<file2> [<file3> [...]]]
```

二者意义相同：sort 会逐行读入文件内容；然后依 ASCII 编码的顺序，升序排列文件的行；最后输出到标准输出（通常是屏幕）。注意，sort 可以连续读入多个文件，而后合在一起排序。

如果希望将 sort 结果保存到文件，则需要用到 -o 选项（当然，大多数情况也可以用 > 重定向）：

```bash
sort <input> -o <output>
```

如果希望倒序排列，则需要用到 -r 选项：

```bash
sort -r <filename>
```

对于数字来说，按照 ASCII 编码排列就不合适了，此时可以用到 -n 选项：

```bash
sort -n <filename>
```

其他选项：

```bash
-u      去除重复行
-t      指定分隔符（通常与 -k 联用）
-k      指定用于排序的列号
-f      忽略大小写
-M      能够排序月份
-b      忽略行首空白
```

## uniq: 专治重复，一针见效

uniq 的作用可以描述为：针对相邻的重复行，进行相应的动作。

这句话中，有两个地方需要注意。首先，针对的是**相邻的重复行**。因此，uniq 对于不相邻的重复行是不起作用的。其次，进行**相应的**动作。这意味着，uniq 可以做的事情很多，不止一样。

不带任何参数的时候 uniq 的动作是：对相邻的重复行进行去除。例如：

```bash
cat <filename> | sort | uniq
```

我们已经见过了 sort 的作用，那么上面命令的作用就很显然了：将 <filename> 按照 ASCII 升序排序；然后去除重复出现的行；最后将这个没有重复行的内容输出到标准输出。

给 uniq 加上参数，就能解锁更多姿势。

```bash
cat <filename> | sort | uniq -d     # 只显示重复的行，每行只显示一次
cat <filename> | sort | uniq -D     # 只显示重复的行
cat <filename> | sort | uniq -i     # 忽略大小写
cat <filename> | sort | uniq -u     # 只显示只出现一次的行
cat <filename> | sort | uniq -c     # 统计每行重复的次数
```

## 集合运算

接下来，我们强行将 sort 和 uniq 凑到一起，看看会发生什么。

### 求交集

交集就是两个集合都出现的那些元素。放到我们的场景里，就是两个文件重复出现过的行。毫无疑问，我们需要 uniq 的 -d 选项。

```bash
sort <file1> <file2> | uniq -d      # 交集
```

### 求并集

并集就是两个集合的元素加起来，去掉重复的部分。uniq 就是为此而生的。

```bash
sort <file1> <file2> | uniq         # 并集
```

### 求差集

$A \setminus B = {x\mid x \in A \wedge x \not\in B}$，也就是存在于 $A$ 但不存在于 $B$ 的那些。简而言之，这是一个在集合 $A$ 中找到最高贵冷艳的元素的过程。

只要重复了，那就不叫高贵冷艳。同时我们知道，重复一次叫重复；重复两次，那也还是重复。因此，我们只需要将 <file1> 和两份 <file2> 放在一起，寻找只出现过一次的行就可以了。

```bash
sort <file1> <file2> <file2> | uniq -u  # 差集
```

### 求对称差

$A \bigtriangleup B = (A \cup B) - (A \cap B)$。上面已经求得了并集和交集，所以在此基础上求一个差集就好了对吧——你疯啦！？

对称差，就是要找到两个集合放在一起，也只出现了一次的那些元素。因此只需要简单的 -u 选项就好了。

```bash
sort <file1> <file2> | uniq -u  # 对称差集
```

好了，这就是用 Linux 命令做集合运算的故事了。:)