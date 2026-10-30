---
title: "【LaTeX Tips】绘制平行四边形符号"
url: https://liam.page/2013/04/13/LaTeX-parallelogram/
date: 2013-04-13
categories: ["LaTeX"]
tags: ["Parallelogram"]
---

平行四边形符号不是国际标准符号，而是我国「自造」的一个符号，所以在LaTeX本身以及常用符号宏包中都是未定义的。最方便的方法就是「自造」一个符号，利用 Ti*k*Z 之类的绘图工具。以下是代码：

```tex
\documentclass{article}
\usepackage{amsmath}
\usepackage{tikz}
\newcommand\parallelogram{%
    \mathord{\text{%
        \tikz[baseline] \draw (0,.1ex) -- (.8em,.1ex) -- (1em,1.6ex) -- (.2em,1.6ex) -- cycle;}}}
\begin{document}
\[ \parallelogram ABCD \]
\[ E_{\parallelogram ABCD} \]
\end{document}
```

以下是效果：
![](/uploads/images/LaTeX/parallelogram.jpg)