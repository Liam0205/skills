---
title: "在 LaTeX 中实现一个简易的进度条"
url: https://liam.page/2018/08/29/colored-progress-bar-in-LaTeX/
date: 2018-08-29
categories: ["LaTeX"]
tags: ["Progress Bar", "Resume"]
---

进度条是很有用的工具。它可以表示 slides 放映的进度，也可以表示某种技能的熟练度。特别地，在制作简历时，使用「精通」、「熟练」之类的词就不如用一个进度条给所有技能一个统一的标准去衡量。不仅美观，而且直观。

使用 calc 宏包搭配 xcolor 宏包，我们就能用 TeX 自带的标尺来绘制进度条了。

```tex
\documentclass{ctexart}
\usepackage{xcolor}
\usepackage{calc}

\definecolor{color1}{rgb}{0.22,0.45,0.70}  % light blue
\definecolor{color2}{rgb}{0.45,0.45,0.45}  % dark grey

\newcommand{\progressbar}[2][2cm]{%
    \textcolor{color1}{\rule{#1 * \real{#2} / 100}{1.5ex}}%
    \textcolor{color2!15}{\rule{#1 - #1 * \real{#2} / 100}{1.5ex}}}

\begin{document}
Office 三件套 \hfill \progressbar{70}

LaTeX \hfill \progressbar{90}
\end{document}
```

这里，\rule 命令用来绘制标尺——可以理解为色块。它的第一个参数是宽度，第二个参数是高度。两个标尺分别用两种颜色表示「熟练」和「不熟练」，或者「完成」和「未完成」的部分。两个标尺的宽度利用了 calc 宏包提供的功能进行计算。

效果如下。

![](/uploads/images/LaTeX/colored_progress_bar.png)