---
title: "【LaTeX Tips】使用 LaTeX 排版试卷挖空的问题"
url: https://liam.page/2013/10/14/LaTeX-Key-to-questions/
date: 2013-10-14
categories: ["LaTeX"]
tags: ["Blank", "Exam"]
---

我们编写试卷的时候，通常会把答案也一并填上，打印的时候却希望按照答案的长度挖空。本文整理了 CTeX 论坛上的一些讨论，尝试解决这个问题。

对于一般的需求，可以用 \iftrue 和 \iffalse 来实现，如下

```tex
\documentclass{article}
\usepackage{ulem}
% 显示答案填入 \iftrue, 不显示答案填入 \iffalse
\iftrue
\newcommand{\myans}[1]{\uline{#1}}
\else
\newcommand{\myans}[1]{\uline{\phantom{#1}}}
\fi
\begin{document}
\myans{This is the key to the question}.
\end{document}
```

更简练的代码，可以参考一下来自[CTeX 论坛提问版](http://bbs.ctex.org/forum.php?mod=redirect&goto=findpost&ptid=77113&pid=453266&fromuid=109739)的方法。

```tex
\documentclass{article}
\usepackage{ctex}
\usepackage{ulem}
\usepackage{tagging}
\usetag{ans}% 注释掉该行语句不显示答案
\newcommand{\answer}[1]{\iftagged{ans}{\uline{#1}}{\uline{\phantom{#1}}}}
\begin{document}
这个问题的答案是\answer{This is the key to the question}.
\end{document}
```

但是这种情况下，\phantom 无法自动断行，对于较长的答案来说是不好用的，因此只能考虑放弃 \phantom 将答案的字体颜色调整为白色，如下：

```tex
\documentclass{ctexart}
\usepackage{tagging}
\usepackage{xcolor}
\usepackage{ulem}
%\usetag{ans} % 注释掉该行语句不显示答案
\newcommand{\answer}[1]{\iftagged{ans}{\uline{#1}}{\uline{\color{white}{#1}}}}
\begin{document}
这个问题的答案是\answer{答案This is the key to the question 这是答案这是答案这是答案这是答}.

Have a try.
\end{document}
```

注意到这种情况下，只有 \answer 后面的第一个字符被挖空了，后面内容并没有挖空（而且断行失败）。出现这种结果的原因，是[因为](http://bbs.ctex.org/forum.php?mod=redirect&goto=findpost&ptid=77124&pid=453316&fromuid=109739) ulem 包依赖 \uline 参数中的空格来断开下划线，并且 \uline 里的分组情况还比较特殊。这种情况的工作示例可以参见[这里](http://bbs.ctex.org/forum.php?mod=viewthread&tid=77124&fromuid=109739).

因此最终的方案只能绕开 ulem 这个包才行，如下：

```tex
\documentclass[fntef]{ctexart}
\usepackage{xcolor}
\usepackage{tagging}
%\usetag{ans}% 注释掉该行语句不显示答案
\renewcommand*\CJKunderlinecolor{\color{black}}
\newcommand{\answer}[1]{\iftagged{ans}{\uline{#1}}{
    {\color{white}\CJKunderline{#1}}}}
\begin{document}
这个问题的答案是\answer{答案This is the key to the question 这是答案这是答案这是答案这是答}.
\end{document}
```

这一解决方案调用了 ctexart 宏包的 fntef 选项，问题得以解决。在纯英文环境下可以这样做：

```tex
\documentclass{article}
\usepackage{xcolor}
\usepackage{tagging}
%\usetag{ans}% 注释掉该行语句不显示答案
\usepackage{ulem}
\newcommand\myuline{\bgroup\markoverwith
	{\textcolor{black}{\rule[-0.5ex]{2pt}{0.4pt}}}\ULon}
\newcommand{\answer}[1]{\iftagged{ans}{\uline{#1}}{
	{\color{white}\myuline{#1}}}}
\begin{document}
Your answer is \answer{Hello, \LaTeX{}. Hello, \LaTeX{}. Hello, \LaTeX{}. Hello, \LaTeX{}. Hello, \LaTeX{}.}
\end{document}
```

当然这一方法同样适用于有中文的情况。