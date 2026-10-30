---
title: "xeCJK 宏包的隐藏技能：字符映射"
url: https://liam.page/2016/05/12/the-hidden-skill-of-the-xeCJK-package-Mapping/
date: 2016-05-12
categories: ["LaTeX"]
tags: ["xeCJK", "Mapping", "Simplified Chinese", "Traditional Chinese", "Stop Sign"]
---

有段时间没写 LaTeX 相关的文章了，此篇讲一讲 xeCJK 宏包中的 Mapping 功能。

由于中文空心句号是一个小圈，容易与作为下标的数字 0 或字母 o 混淆。因此，在专业数学书籍、论文排版中，最好是使用实心句点 ． 来代替中文空心句号。但是，使用中文空心句号编写中文 LaTeX 手稿是大家的习惯；这样一来，使用查找替换固然是一个方案，但是繁琐且容易出错。这时候，我们就可以用到 xeCJK 宏包提供的 Mapping 选项。

Mapping 实际上是借助了 [TECKit](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=teckit) 来做字符映射。xeCJK 的作者还预先定义了能够实现简体中文和正体中文相互转换的映射表。因此，使用 xeCJK 还能实现中文的简正转换。

## 基本用法

相信你对 xeCJK 宏包的基本用法已经了解，因此我就不对下面的代码作过多的解释。我们来看一下 Mapping 选项的基本用法。

```tex
%!TeX program = xelatex
\documentclass{article}
\usepackage{xeCJK}
\setCJKmainfont[Mapping = fullwidth-stop]{STSong} % 华文宋体
\begin{document}
华文宋体。

可以发现，中文空心句号自动映射成了实心句点。
\end{document}
```

![](/uploads/images/LaTeX/mapping_fullwidth-stop.png)

这里我们为文档主字体调用了 fullwidth-stop 这一映射文件。它的作用是将中文空心句号映射成实心句点，这个文件是 xeCJK 的作者预先定义的。

xeCJK 的作者也有定义作用与之完全相反的映射文件：full-stop。

## 简正转换

除了中文空心句号和实心句点的映射，xeCJK 的作者还提供了 han-trad 和 han-simp 两个映射文件。前者可以将 TeX 手稿中的简体中文字符映射成正体中文字符；后者则相反。

```tex
%!TeX program = xelatex
\documentclass{article}
\usepackage{xeCJK}
\setCJKmainfont[Mapping = han-trad]{STSong} % 华文宋体
\begin{document}
华文宋体。

可以发现，简体中文字符，都被一一地映射为对应的正体中文字符。
\end{document}
```

![](/uploads/images/LaTeX/mapping_han-trad.png)

不过，需要注意的是：在简化汉字的过程中，存在多个正体中文汉字映射到同一个简体中文汉字上的情况；同时，也存在一个正体中文汉字在表达不同含义时映射到不同简体中文汉字的情况。由于技术所限，xeCJK 的映射机制只能做到一一对应，无法实现上述复杂的映射状况。因此，在使用 Mapping = han-trad 时，会出现类似如下的情况：简体的「发挥」和「头发」被转换成正体的「發揮」和「頭發」，但后者应作「頭髮」。

## 再深入一步

xeCJK 只提供了四个预定义的映射文件，如果还想要用这种方式制作更多的效果，就需要自己定义映射文件了。这可以参考 TECKit 的文档：[http://scripts.sil.org/teckit](http://scripts.sil.org/teckit)。