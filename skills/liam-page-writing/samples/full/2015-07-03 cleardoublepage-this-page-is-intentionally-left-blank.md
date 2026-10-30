---
title: "在 LaTeX 的 book 类中实现章节间空白页「This page is intetionally left blank」的效果"
url: https://liam.page/2015/07/03/cleardoublepage-this-page-is-intentionally-left-blank/
date: 2015-07-03
categories: ["LaTeX"]
tags: ["Chapter", "Cleardoublepage"]
---

很多书籍在设计版式的时候，会要求 \chapter 从奇数页码开始：上一章节在奇数页结束则留白一页，而后再从奇数页码继续排版。为了避免给读者造成「这里的内容缺失了」的印象，通常会写上「This page is intetionally left blank」的字样。

本文来实现这种效果。

LaTeX 的 book 文档类实现章首页从奇数页码开始，是借助 \cleardoublepage 命令实现的。原始的 \cleardoublepage 命令首先会调用 \clearpage 结束当前页，然后会检查页码状态：

- 如果是奇数页码，那么什么也不做，直接开始排版

- 如果是偶数页码，则再一次另起一页，从下一页开始排版

我们可以在 source2e.pdf 中找到这一定义：

![LaTeX2e 内核中 \cleardoublepage 的定义](/images/LaTeX/def-of-cleardoublepage.png)

我们只需要修改这一定义即可。

```tex
\documentclass[UTF8]{ctexbook}
\usepackage{tikz}
\makeatletter
\renewcommand{\cleardoublepage}{\relax
  \clearpage
  \if@twoside \ifodd\c@page\relax\else
  \thispagestyle{empty}%
  \tikz[remember picture, overlay] \node  at (current page.center)
    {\large 广告位招租};\newpage\fi\fi}
\makeatother
\begin{document}
\chapter{测试}
\chapter{测试}
\clearpage
测试
\chapter{测试}
\end{document}
```

在这里，我们重定义了 \cleardoublepage 命令：

- 用 \clearpage 结束当前页

- 检测文档类模式，如果是双面模式，则继续检测，反之则结束操作

- 继续检测当前页码，当前页码是奇数，则继续排版，反之则将当前页面风格设置为 empty 并用 TikZ 在页面中心写下「广告位招租」几个字

![实际效果](/images/LaTeX/intentionlly-left-blank.png)

注意，需要编译两遍才能得到正确的结果。