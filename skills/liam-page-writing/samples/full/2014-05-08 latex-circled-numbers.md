---
title: "【LaTeX Tips】带圈数字与带圈数字列表"
url: https://liam.page/2014/05/08/latex-circled-numbers/
date: 2014-05-08
categories: ["LaTeX"]
tags: ["TikZ", "Circled"]
---

在许多文章中，特别是中文文章中，我们会见到带有圆圈的数字。它们有点是单独出现的，有点作为列表的计数出现。

LaTeX 提供了 \textcircled 命令，但效果并不好。[LaTeX studio](http://www.latexstudio.net/latex-tips-768-defined-for-the-enclosed-list-of-environment/) 曾经提供了一个方法，但缺乏通用性。

这里给出一个利用 Ti*k*Z 绘制的方法，能较好地解决这个问题，但仍需完善。

基本的思路是定义一个新命令，接受一个数字参数，用 Ti*k*Z 在它周围画圈。同时要考虑基线和对齐的问题。一个尝试如下：

```tex
\usepackage{tikz}
\usepackage{etoolbox}
\newcommand{\circled}[2][]{\tikz[baseline=(char.base)]
    {\node[shape = circle, draw, inner sep = 1pt]
    (char) {\phantom{\ifblank{#1}{#2}{#1}}};%
    \node at (char.center) {\makebox[0pt][c]{#2}};}}
\robustify{\circled}
```

这个新定义的命令可以按照 \textcircled 方法在正文中使用，如果需要用在列表中，则因为「脆弱命令」的问题，需要处理一下。这里我们选择使用 etoolbox 宏包提供的 \robustify 来处理一下，同时结合 enumitem 宏包，给出示例用法如下：

```tex
\documentclass{article}
\usepackage{enumitem}
\usepackage{tikz}
\usepackage{etoolbox}
\newcommand{\circled}[2][]{\tikz[baseline=(char.base)]
    {\node[shape = circle, draw, inner sep = 1pt]
    (char) {\phantom{\ifblank{#1}{#2}{#1}}};%
    \node at (char.center) {\makebox[0pt][c]{#2}};}}
\robustify{\circled}
\begin{document}
\mbox{}\rlap{\rule{.7\linewidth}{.4pt}}%
The original version: \circled{1} and \circled{10}.

\mbox{}\rlap{\rule{.7\linewidth}{.4pt}}%
The improved version: \circled[10]{1} and \circled[10]{10}.

\newcommand{\dcircled}[1]{\circled[00]{#1}}
\begin{enumerate}[label=\dcircled{\arabic*}, noitemsep]
\item I
\item am
\item happy
\item to
\item join
\item with
\item you
\item today
\item in
\item what
\item will
\item go
\item down
\item in
\item history
\item as
\item the
\item greatest
\item demonstration
\item for
\item freedom
\item in
\item the
\item history
\item of
\item our
\item nation.
\end{enumerate}
\end{document}
```