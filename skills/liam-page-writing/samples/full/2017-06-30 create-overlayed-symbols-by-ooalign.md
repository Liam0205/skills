---
title: "LaTeX 黑魔法（二）：使用 \\ooalign 命令创建叠加在一起的记号"
url: https://liam.page/2017/06/30/create-overlayed-symbols-by-ooalign/
date: 2017-06-30
categories: ["LaTeX"]
tags: ["align", "leaders"]
---

TeX 是强大的排版工具，尤其以其数学排版而出名。然而，数学无有止境，有时候我们会需要特别的记号来表达一个新的概念。这些记号，TeX 可能默认没有提供。此时，我们就要自己创造符号了。

创造符号的办法有很多，其中之一就是让两个已经存在的符号「叠加」起来。这篇文章讲讲如何用 \ooalign 命令创造这样叠加的符号。

## \ooalign 命令

\ooalign 命令是一个 plain TeX 级别的命令。同级别类似的命令还有 \halign, \ialign 等。

顾名思义，见到命令中的 align 字样，就知道这个命令是用来将元素按照某种方式对齐的。用 LaTeX 用户比较好理解的方式来说，\ooalign{...} 相当于创建了一个表格：

```tex
\begin{tabular}[t]{@{}l@{}}
  ...
\end{tabular}
```

只不过有两点主要的不同：

- 在 tabular 环境中，换行使用 \\，而在 \ooalign 中使用 \cr；

- \ooalign 中，每一行都复写在上一行之上。

为了避免奇怪的问题，应当养成习惯，总是把 \ooalign 包在一个分组中。

## \hidewidth 命令

\hidewidth 也是一个 plain TeX 级别的命令。它的定义是 \hskip -1000pt plus 1fill。也就是说，它是一个 TeX 水平 skip，其默认长度是 -1000pt（一个非常大的负向距离），加上一个可以无限延伸的正向距离。

考虑到「无穷大减常数还是无穷大」，所以若将 \hidewidth 放在某个东西的左边，那么起作用相当于 \hfill。

另一方面，考虑到 -1000pt 是一个很大的负向距离，正常文档的宽度远小于这个距离。因此，若将 \hidewidth 放在某个东西的右边，那么从显示效果上看相当于在其右侧加上了一个 \hfill。同时，在各类 \align 命令计算宽度时，当前单元格的宽度会被忽略成 0pt。

## 小试身手

```tex
\documentclass{article}
\begin{document}
{\ooalign{$\bigcup$\cr\hidewidth$\bullet$\hidewidth\cr}}

{\ooalign{%
  $\bigcap$\cr
  \hidewidth$\bullet$\hidewidth\cr
  \hidewidth$\bigtriangleup$\hidewidth\cr}%
}
\end{document}
```

这里我们创造了两个符号。第一个符号由 $\bigcup$ 和 $\bullet$ 叠加组成。第二个符号由 $\bigcap$, $\bullet$ 和 $\bigtriangleup$ 三个符号组成。

照着上面的讲解，这些记号是如何组成的，应该不难理解。你可以编译试试看效果，同时看看去掉各个 \hidewidth 会有什么效果。

## 进阶实践：定义一个带点状虚线的组合数符号

amsmath 宏包提供了名为 \genfrac{左定界符}{右定界符}{分数线粗细}{缩放}{分子}{分母} 的宏；它是 amsmath 系所有类似 \frac 效果的母版。例如，组合数 \binom 的定义是 \newcommand{\binom}[2]{\genfrac{(}{)}{0pt}{}{ #1 }{ #2 }}。它表示组合数符号的左右定界符分别是左右圆括号，分数线的粗细为 0pt（也就是不画分数线），大小随着行间公式或者行内公式自动缩放。

为了将分数线替换为点状虚线，首先我们要获得一个形如分式但没有分数线的表达。

```tex
\newcommand{\nolinebinom}[2]{\genfrac{(}{)}{0pt}{0}{#1}{#2} }
```

而后，我们要定义一个点状引导线。

```tex
\newcommand{\dotover}{%
    \leavevmode\kern1ex
    \cleaders\hb@xt@.22em{\hss$\cdot$\hss}\hfill
    \kern1ex}
```

这里 \leavevmode 确保离开 TeX 的垂直模式，进入水平模式；左右的 \kern1ex 表示左右各空出 1ex 的空白；中间的 \cleaders\hb@xt@.22em{\hss$\cdot$\hss}\hfill 则表示用若干个水平盒子 \hbox to .22em{\hss$\cdot$\hss} 填充 \hfill 代表的最终长度。因此，\dotover 会根据允许的长度，绘制一条点状的引导线。

至此，我们可以用 \ooalign 把它们拼起来。

```tex
\newcommand{\dotbinom}[2]{%
    \ooalign{$\nolinebinom{#1}{#2}$\cr\dotover\cr}%
}
```

完整的代码如下。

```tex
\documentclass{article}
\usepackage{amsmath}

\makeatletter
\newcommand{\nolinebinom}[2]{\genfrac{(}{)}{0pt}{0}{#1}{#2} }
\newcommand{\dotover}{%
    \leavevmode\kern1ex
    \cleaders\hb@xt@.22em{\hss$\cdot$\hss}\hfill
    \kern1ex}
\newcommand{\dotbinom}[2]{%
    \ooalign{$\nolinebinom{#1}{#2}$\cr\dotover\cr}%
}
\makeatother

\begin{document}

\[
    \dotbinom{\text{numerator}}{\text{denominator}}
\]

\end{document}
```

![](/uploads/images/LaTeX/dotbinom.png)