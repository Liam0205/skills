---
title: "为阿拉伯数字和小写字母实现类似 \\mathbb 的效果"
url: https://liam.page/2017/01/08/arabic-numbers-or-lowercase-letters-in-blackboard-bold-doublestroke-font/
date: 2017-01-08
categories: ["LaTeX"]
tags: ["Font", "mathbb", "Blackboard Bold", "Doublestroke"]
---

在 LaTeX 中，我们可以用 \mathbb{R} 输出表示实数集合的字母 $\mathbb{R}$。这一命令来自 amsfonts 宏包。那么如果我们希望输出类似效果的阿拉伯数字或者小写字母，应该怎么办呢？

## amsfonts 中的 \mathbb 命令

翻看 amsfonts 说明书（texdoc amsfonts），我们可以在其中第 3.3 节找到这样的描述：

The amsfonts package defines a “math alphabet” command \mathbb for printing letters of the blackboard bold alphabet that resides in the msbm font. This alphabet is restricted to uppercase only (no lowercase, no numerals). The suggested method for defining a \R command to print a blackboard bold $\mathbb R$ is as follows:

```tex
\usepackage{amsfonts}
\newcommand{\R}{\mathbb{R}}
```

首先，我们知道了 \mathbb 样式字体的正式名称：blackboard bold，即黑板粗体。其次，我们知道了，定义在 amsfonts 宏包中的 \mathbb 命令只支持大写字母，不支持小写字母或者阿拉伯数字。

因此，如果你在 LaTeX 中输入 \mathbb{1}，虽然不会有任何报错提示，但是输出的字符是错误的（如下）。

![](/uploads/images/LaTeX/mathbb1.png)

## bbm 字体

既然 AMS 系的宏包不支持，那么我们就只能另辟蹊径了。实际上，我们只需要找到含有正确小写字母和阿拉伯数字的黑板粗体字体就可以了。索性，在 TeX Live 中有 bbm 系列字体，它提供了更完整的黑板粗体字符。不过，对于阿拉伯数字的支持，也只有数字 1 和 2。使用起来很简单

```tex
\documentclass{article}
\usepackage{bbm}
\begin{document}
\[
  \mathbbm{1234567890}\mathbbm{abcdefghijklmnopqrstuvwxyz}
\]
\end{document}
```

![](/uploads/images/LaTeX/mathbbm.png)