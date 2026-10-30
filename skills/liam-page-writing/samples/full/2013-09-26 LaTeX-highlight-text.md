---
title: "【LaTeX Tips】How to highlight text."
url: https://liam.page/2013/09/26/LaTeX-highlight-text/
date: 2013-09-26
categories: ["LaTeX"]
tags: ["Highlight", "Ulem", "Robust"]
---

If anyone wanna highlight text in LaTeX file using the package soul, they may counter some problems, such as lineberak, since package soul is very fragile. 在使用宏包 soul 进行高亮操作的时候，可能因其代码的脆弱性，导致许多问题，例如无法正确换行。

Using more robust ulem package to define a new \hl command is a good way.[^1](%5Bhttp://tex.stackexchange.com/questions/48501/soul-broken-highlighting-with-xcolor-when-using-selectcolormodel/48549#48549%5D(http://tex.stackexchange.com/questions/48501/soul-broken-highlighting-with-xcolor-when-using-selectcolormodel/48549#48549)) 使用更加健壮的 ulem 宏包去定义一个新的 \hl 命令是个不错的选择。

```tex
\documentclass{article}
\usepackage{xcolor}
\usepackage[normalem]{ulem} % use normalem to protect \emph
\newcommand\hl{\bgroup\markoverwith
  {\textcolor{yellow}{\rule[-.5ex]{2pt}{2.5ex}}}\ULon}

\begin{document}
This is a test \hl{for highlighting} text.
\end{document}
```