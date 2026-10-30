---
title: "【LaTeX Tips】利用 TikZ 在 LaTeX 文档中制作水印效果"
url: https://liam.page/2014/04/22/LaTeX-watermark/
date: 2014-04-22
categories: ["LaTeX"]
tags: ["Watermark"]
---

本文最早发布于[知乎专栏](http://zhuanlan.zhihu.com/LaTeX/19734756)，略有修改.

**在未获得本人书面许可的情况下，禁止任何形式的「合理使用」、转载、分享以及将链接发至知乎主站外任何网站或 App （包括知乎日报），外泄斩立决。智商欠奉，中文阅读障碍或微博控患者, 请在监护人及医师协助下学习本段落，谢谢合作。**

制作水印基本上需要解决下面几个问题：

- 水印应该叠放在正文的下面，不得覆盖文字

- 水印应该放置在合适的位置

- 水印的颜色应该足够淡，因此不会影响（太多）文章正文的阅读

在 LaTeX 中，可以用 [eso-pic 宏包](http://www.ctan.org/pkg/eso-pic)提供的 \AddToShipoutPictureBG 命令，来将内容叠放在正文的下面；使用 [Ti*k*Z 宏包](http://www.ctan.org/pkg/pgf)（这是绘图工具 PGF 的前端）来为水印文字定位；使用 [xcolor 宏包](http://www.ctan.org/pkg/xcolor)设置水印的颜色。

同时，我们会希望：

- 设定水印文字内容

- 设定水印文字大小

- 设定水印文字偏转角度

- 能够在合适的位置开启水印效果

于是我们有了下面这样的实现：

```tex
\newcommand{\watermark}[3]{\AddToShipoutPictureBG{
\parbox[b][\paperheight]{\paperwidth}{
\vfill%
\centering%
\tikz[remember picture, overlay]%
  \node [rotate = #1, scale = #2] at (current page.center)%
    {\textcolor{gray!80!cyan!30}{#3}};
\vfill}}}
\newcommand{\watermarkoff}{\ClearShipoutPictureBG}
```

一个可供测试的完整例子是：

```tex
\documentclass{article}
\usepackage{tikz}
\usepackage{xcolor}
\usepackage{eso-pic}

\newcommand{\watermark}[3]{\AddToShipoutPictureBG{
\parbox[b][\paperheight]{\paperwidth}{
\vfill%
\centering%
\tikz[remember picture, overlay]%
  \node [rotate = #1, scale = #2] at (current page.center)%
    {\textcolor{gray!80!cyan!30}{#3}};
\vfill}}}

\usepackage{blindtext}

\begin{document}
\watermark{60}{10}{DRAFT}
\blinddocument
\clearpage
\end{document}
```

以上。