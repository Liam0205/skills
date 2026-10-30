---
title: "【LaTeX Tips】如何正确定义中文段落缩进"
url: https://liam.page/2013/05/15/LaTeX-Chinese-parindent/
date: 2013-05-15
categories: ["LaTeX"]
tags: ["Chinese", "Parindent"]
---

## 段落缩进的中文习惯

### 引

中文行文有在每个自然段段首缩进两个字符的习惯。但是 LaTeX 是美国人做的，CJK 宏包是德国人做的，在段落缩进这方面设计得并不符合中国人的使用习惯。

为了解决这个问题，通常的解决方案是将 \parindent 这个宏设置为某一个特殊的值。比如在 12pt 的模式下，设置 \setlength\parindent{2.45em}，看起来中文正好缩进了两个字符。但实际上这种方式治标不治本——比如你将模式改为 10pt，就会发现缩进过头了。

### 讨论

中文缩进和英文缩进有不同，为了解决问题，我们首先应当搞清楚，究竟应该缩进多少，而非是在一次次地尝试中「大概」完成任务。

缩进两个字符，准确地说，应该是*段首的第一* 个文字的*左沿* 和该段第*二* 行第三个文字的*左沿* 切齐**。

于是*缩进长度 = 两个字符的宽度* ？

错！！

一个字符在排版中所占的宽度并不等于它本身的宽度，因为字符和字符之间还有一定的空隙——不可能每个字符毫无间隙地黏在一起。所以若是缩进两个字符的宽度，那么看起来缩进将会有些「不够」。亦即段首第一个文字的左沿看起来在第二行第三个文字左沿的左边。

因此我们定义 字宽 = 字符宽度 + 字符间距 = 相邻两字符中心的间距。

因此，缩进长度 = 2 * 字宽。

### 解决步骤

- 获取当前字符宽度；

- 获取当前字符间距大小；

- 定义字宽（上述二者相加）；

- 定义缩进长度（两倍字宽）。

## LaTeX 实现

### 获取当前字符宽度

```tex
%----CJK字符宽度
%\f@size = 当前字符大小数值（pt/pt）
%\p@ = 1pt
\def\elegant@CJKChar@size{\hskip \f@size \p@}
```

这里的\f@size和\p@均是 LaTeX 内部定义的宏，前者存储了当前字符大小（以 pt 为单位的数值；不带单位；注意这是个*数字* ），后者代表 1pt. 因此 \elegant@CJKChar@size 被定义为了带单位（pt）的字符宽度，这正是我们需要的。

### 获取当前字符间距大小

在 LaTeX 的中文支持中（CJK 和 xeCJK是如此；CCT 及天元系统不了解，不过也不会有人用了吧），字符间距被定义为CJKglue，我们可以直接使用这个宏。

### 定义字宽

```tex
%字宽 = 字符宽度 + 字符间距 = 相邻字符中心的间距
\newdimen\elegant@CJKChar@size@dimen
\settowidth\elegant@CJKChar@size@dimen{\elegant@CJKChar@size\CJKglue}
```

第一行，定义了一个 dimen 类型的长度宏，名字是 \elegant@CJKChar@size@dimen。第二行，将它设置为字符宽度与字符间距之和。这正是我们需要的。

### 定义缩进长度

LaTeX 的缩进长度被存储在 \parindent 这个宏之中，用 \parindent2\elegant@CJKChar@size@dimen 将之设置为字宽的二倍。

至此，基本的代码已经构建完成，原理也已经讲述清楚。下面是添加用户接口的代码。

### 完整代码

```tex
\ProvidesPackage{cjkindent}
%-----字宽/缩进-----
%----CJK字符宽度
%\f@size = 当前字符大小数值（pt/pt）
%\p@ = 1pt
\def\elegant@CJKChar@size{\hskip \f@size \p@}
%----定义字宽
%字宽 = 字符宽度 + 字符间距 = 相邻字符中心的间距
\newdimen\elegant@CJKChar@size@dimen
\settowidth\elegant@CJKChar@size@dimen{\elegant@CJKChar@size\CJKglue}
%----用户接口
%负责刷新字宽和段落缩进
\newcommand{\CJKsetfontspace}{
%刷新字宽
\settowidth\elegant@CJKChar@size@dimen{\elegant@CJKChar@size\CJKglue}%
%刷新段落缩进
%判断段落缩进是否被设置为0（如果是表示要求不缩进）
\ifdim\parindent=0pt%
\relax%
\else%
\parindent2\elegant@CJKChar@size@dimen%
\fi%
}
\newcommand{\Eindent}{\CJKsetfontspace\parindent2\elegant@CJKChar@size@dimen}
\newcommand{\Enoindent}{\parident\z@}
%----自动执行
\RequirePackage{indentfirst}
\AtBeginDocument{\Eindent}
%-----字宽/缩进-----
```

#### 用法

- 将该段代码另存为 cjkindent.sty，保存在当前目录；
在导言区使用命令 \usepackage{cjkindent}；
正文部分立即能按照中文习惯缩进。

- 使用 \Eindent 命令，可以使得该段缩进；

- 使用 \Enoindent 命令，可以使得该段不缩进。