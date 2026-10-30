---
title: "【LaTeX Tips】为所有的浮动体一次性设置浮动选项"
url: https://liam.page/2014/05/08/float-setting/
date: 2014-05-08
categories: ["LaTeX"]
tags: ["Float"]
---

节选自 [elegantlatex](http://elegantlatex.tk/2014/04/02/float-setting/).

在我们插图或者插入表格到 LaTeX 文档中，我们会碰到一个概念——浮动体，有时候，我们在文中用到的 table 或者 figure 环境的浮动选项都是相同的，比如 htbp，并且对 table 内、或者 figure 中的内容居中对齐（\centering），本文将介绍如何统一设置浮动体的浮动选项，以及居中设置。本文以 table 环境为例，figure 类似。

可以借助 floatrow 宏包来达到目的。

```tex
\documentclass{article}

\usepackage{floatrow}        % this automatically centers all floats
\floatplacement{table}{hbtp} % all tables are given the [hbtp] option

\begin{document}

\begin{table}
\begin{tabular}{lll}
1 & 2 & 3\\
a & b & c\\
\end{tabular}
\end{table}

\end{document}
```