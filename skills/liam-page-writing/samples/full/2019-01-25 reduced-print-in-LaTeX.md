---
title: "在 LaTeX 中实现缩印效果"
url: https://liam.page/2019/01/25/reduced-print-in-LaTeX/
date: 2019-01-25
categories: ["LaTeX"]
tags: ["PGF", "Reduce Print"]
---

近日大概重拾了一点对 LaTeX 的兴趣，遇见这样一个问题：如何在 LaTeX 中实现缩印效果（即，将两页或更多页排版在一页纸上），并且实现水印效果的页码？

## 缩印

以朴素的办法实现缩印效果并不困难。例如，可以先以 LaTeX 正常输出文档，再以 pdfpages 宏包将生成的文档载入进来排版。不过，这样的做法扩展性太差，并且需要至少编译两份文档——一份是原始文档，一份是缩印框架文档。

更有技巧的办法，需要深入到 TeX 构建页面输出的过程中去。基本上来说，我们需要让 TeX 按往常一样去构建页面，但是在 TeX 准备将页面输出（shipout）时我们需要插入一个钩子。这个钩子做两件事情：

- 打断输出过程；

- 将整个页面内容保存在一个盒子中备用。

我们将保存在盒子里的页面称为逻辑页面（logic pages）。而后，当保存的页面足够多时，或没有更多页面需要保存时，将这些盒子的内容成比例缩小并列印在页面上。我们将最终输出的页面称之为物理页面。

pgfpages 就是这样做的。它是 PGF 宏集的一部分，因而使用 texdoc pgf 可以看到它的文档（Section 89）。

首先我们从一个简单的例子开始，其效果见[这里](/uploads/iamges/LaTeX/2on1-landscape.png)。

```tex
\documentclass{article}
\usepackage{pgfpages}
\pgfpagesuselayout{2 on 1}[a4paper, landscape, border shrink = 5mm]
\begin{document}
This text is shown on the left.
\clearpage
This text is shown on the right.
\end{document}
```

这里，\pgfpagesuselayout 命令是实现缩印效果的核心命令。参数 2 on 1 的含义不言自明。其后的可选参数：a4paper 表示物理页的尺寸是标准 A4 纸；landscape 表示要将物理页横过来——毕竟是二合一缩印，这很合理；border shink = 5mm 表示被缩印的逻辑页会被继续缩小，并在每个逻辑页的上下左右四周保留宽度为 5mm 的边框。

类似地，你也可以缩印 beamer 幻灯片。不过，由于 beamer 幻灯片的逻辑页本就是横着的，所以此处不需要在加 landscape 参数了。

相应的，4 on 1 需要加，6 on 1 和 8 on 1 不需要加，以及 16 on 1 又需要加。——32 on 1 是不存在的……

```tex
\documentclass{beamer}
\usepackage{pgfpages}
\pgfpagesuselayout{2 on 1}[a4paper, border shrink=5mm]
\begin{document}
\begin{frame}
This text is shown at the top.
\end{frame}
\begin{frame}
This text is shown at the bottom.
\end{frame}
\end{document}
```

## 页码

在当前问题中，TeX 默认的页码机制实际上是作用在各个逻辑页上的。但显然，我们可能会想要为物理页编上页码。这里有两个问题需要解决：

- 物理页的页码如何确定？

- 缩印排版，有效内容字体很小且密集，如何保证物理页页码可见且不影响有效内容的阅读？

对于第一个问题，有两种思路。

一是读取逻辑页页码 page 计数器，然后按 x on 1 的比例做除法，得出物理页的页码。不过，这种方式是有前提的。具体来说，它要求 TeX 的逻辑页页码功能不在缩印的情况下失效，并且它要求 TeX 能正确计算整数除法（向上取整）。总得来说，这是一种快而脏的解法，不推荐。

如果十年以后，你以快而脏的方式做什么事的时候，能想象我在你的肩后看着，然后对自己说：「Dijkstra 不会希望这样的。」那么对我来说，这就和永生一样了。—— Edsger Wybe Dijkstra

另一种思路则更加直接。既然页码本质是由计数器实现的，这一计数器随页面输出而自增，而 pgfpages 影响的正是 TeX 页面输出的逻辑，那么 pgfpages 内必然有什么地方可以下钩子来自增该计数器。

```tex
\newcommand\pgfshipoutphysicalpage{%
  \ifnum\pgf@logicalpages>0\relax%
    \pgfpages@buildshipoutbox%
    \pgfpages@shipoutshipoutbox%
    \pgfpages@performcopying%
    \global\pgfphysicalpageemptytrue%
    \global\pgf@holdingphysicalpagefalse%
  \fi%
}
```

通过翻阅 pgfpages.sty 的源码，我们不难发现有以上代码和物理页输出有关。可以说，PGF 宏集的代码风格相当好，一眼就能看明白代码在做什么。显然，\pgfpages@shipoutshipoutbox 是在输出物理页，而它之前的 \pgfpages@buildshipoutbox 就是将逻辑页构建成物理页的过程了。因此，我们需要在 \pgfpages@buildshipoutbox 当中下钩子；此时我们又要用到老朋友 etoolbox 当中的 \patchcmd 了。

```tex
% require packages: pgfpages, etoolbox

\newcounter{physicalpage}
\makeatletter
\patchcmd{\pgfpages@buildshipoutbox}{%
  \pgfsys@beginpicture
}{%
  \pgfsys@beginpicture
  \stepcounter{physicalpage}%
}{}{}
\makeatother
```

第二个问题可能有多种解决思路。我偏好于在页面中央以水印的形式加一个大大的页码。四年多以前，我利用 TikZ 实现了[水印功能](/2014/04/22/LaTeX-watermark/)。TikZ 也是 PGF 宏集的一部分，用在这里正好。于是，我们的代码变为

```tex
% require packages: pgfpages, etoolbox, xcolor, tikz
\newcommand{\boxedcontent}[5]{\parbox[b][\paperheight]{\paperwidth}{%
  \vfill%
  \centering%
  \tikz[remember picture, overlay]%
    \node [rotate = #1, scale = #2] at (#3)%
      {\textcolor{#4}{#5}};
  \vfill}}

\newcounter{physicalpage}
\makeatletter
\patchcmd{\pgfpages@buildshipoutbox}{%
  \pgfsys@beginpicture
}{%
  \pgfsys@beginpicture
  \stepcounter{physicalpage}%
  \setbox0\vbox{\makebox[0pt][c]{\boxedcontent{0}{30}{current page.center}{gray!80!cyan!30}{\arabic{physicalpage}}}}%
  \pgfsys@beginscope
  \pgflowlevel{\pgftransformshift{\pgfpoint{0\pgfphysicalwidth}{0\pgfphysicalheight}}}%
  \pgfsys@hbox0%
  \pgfsys@endscope
}{}{}
\makeatother
```

## 实际效果

将以上代码综合起来，我做了一个简单的 demo。

```tex
\documentclass[12pt]{article}
\usepackage{mwe}

\pagestyle{empty}
\usepackage{multicol}
\setlength{\columnseprule}{0.4pt}

\usepackage{geometry}
\geometry{a4paper, scale = 1, includeall,
  margin = 0pt, marginparwidth = 0pt, marginparsep = 0pt,
  headheight = 0pt, headsep = 0pt, footskip = 0pt}

\usepackage{pgfpages}
\pgfpagesuselayout{4 on 1}[a4paper, border shrink = 1.5mm]

\usepackage{tikz}
\usepackage{xcolor}
\usepackage{eso-pic}
\usepackage{etoolbox}

\newcommand{\boxedcontent}[5]{\parbox[b][\paperheight]{\paperwidth}{%
  \vfill%
  \centering%
  \tikz[remember picture, overlay]%
    \node [rotate = #1, scale = #2] at (#3)%
      {\textcolor{#4}{#5}};
  \vfill}}
\newcommand{\watermark}[3]{\AddToShipoutPictureBG{%
  \boxedcontent{#1}{#2}{current page.center}{gray!80!cyan!30}{#3}}}

\newcounter{physicalpage}
\makeatletter
\patchcmd{\pgfpages@buildshipoutbox}{%
  \pgfsys@beginpicture
}{%
  \pgfsys@beginpicture
  \stepcounter{physicalpage}%
  \setbox0\vbox{\makebox[0pt][c]{\boxedcontent{0}{30}{current page.center}{gray!80!cyan!30}{\arabic{physicalpage}}}}%
  \pgfsys@beginscope
  \pgflowlevel{\pgftransformshift{\pgfpoint{0\pgfphysicalwidth}{0\pgfphysicalheight}}}%
  \pgfsys@hbox0%
  \pgfsys@endscope
}{}{}
\makeatother

\begin{document}
\begin{multicols}{3}
  \lipsum[1-79]
\end{multicols}
\end{document}
```

![](/uploads/images/LaTeX/demo-reduced-print.png)