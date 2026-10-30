---
title: "在 LaTeX 中实现定理的重述"
url: https://liam.page/2015/09/12/primed-theorems/
date: 2015-09-12
categories: ["LaTeX"]
tags: ["Theorem", "Numbering", "Restate"]
---

[之前的文章](/2013/12/04/LaTeX-Recalling-a-theorem/)中，我们介绍了如何复写定理。这里我们讨论如何实现定理的重述。

所谓定理的重述，是这样的情况：在文章的某处，我们陈述了一个定理；接下来，我们在文章的其他地方，陈述了一个与之等价但叙述方式不同的定理。此时，如果第一个定理的编号是 Theorem 7，那么第二个的编号就应该是 Theorem 7'。

我们来观察一下这个需求，不难发现有以下特征：

- 原定理的位置不确定；

- 原定理的编号不确定；

- 重述定理的编号和原定理的编号相同，只不过多了一个撇（Prime）。

对 LaTeX 有一定了解的用户，可能会发现，这些特征和「交叉引用」非常相似。交叉引用的 \label 位置和编号也是不确定的（只有在第一遍编译之后才确定）；交叉引用的结果 \ref 显示的内容应当与 \label 标记的锚点编号一致。

因此，我们考虑用交叉引用来处理这个问题。

对于定理重述，另一个显而易见的事情是：除了编号，定理重述的格式应当与定理本身保持一致。因此，定理重述的环境应该在定理环境的基础上做修改，而不是全盘推翻重做。

考虑到这些需求，有经验的 LaTeX 用户不难写出以下代码：

```tex
\newtheorem{thm}{Theorem}
\newenvironment{thmbis}[1]
  {\renewcommand{\thethm}{\ref{#1}$'$}%
   \addtocounter{thm}{-1}%
   \begin{thm}}
  {\end{thm}}
```

这里，我们用 \renewcommand 修改了计数器 thm 的显示方式 \thethm：首先对原定理做引用，然后加上一个撇。随后，在 thm 的当前值上减 1。这是因为，在之后的 \begin{thm} 中会给 thm 计数器自加 1，这里作为「补偿」，需要预先减去 1。

完整的例子可见：

```tex
\documentclass[a4paper]{article}

\newtheorem{thm}{Theorem}
\newenvironment{thmbis}[1]
  {\renewcommand{\thethm}{\ref{#1}$'$}%
   \addtocounter{thm}{-1}%
   \begin{thm}}
  {\end{thm}}

\begin{document}
\begin{thm}
$1+1=2$
\end{thm}
\begin{thm}\label{comm}
$a+b=b+a$
\end{thm}
\begin{thmbis}{comm}
$x+y=y+x$
\end{thmbis}
\begin{thm}
$0\ne0$
\end{thm}
\end{document}
```