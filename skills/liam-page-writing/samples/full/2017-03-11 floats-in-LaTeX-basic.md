---
title: "LaTeX 中的浮动体：基础篇"
url: https://liam.page/2017/03/11/floats-in-LaTeX-basic/
date: 2017-03-11
categories: ["LaTeX"]
tags: ["Floats", "Vertical"]
---

此篇介绍一下 LaTeX 中的浮动体基本概念，以及最常见的几个问题。

## 浮动体是什么

在实际撰写文稿的过程中，我们可能会碰到一些占据篇幅较大，但同时又不方便分页的内容。（比如图片和表格，通常属于这样的类型）此时，我们通常会希望将它们**放在别的地方**，避免页面空间不够而强行置入这些内容导致 overfull vbox 或者大片的空白。此外，因为被放在别的地方，所以，我们通常需要对这些内容做一个**简单的描述**，确保读者在看到这些大块的内容时，不至于无从下手去理解。同时，因为此类内容被放在别的地方，所以在文中引述它们时，我们无法用「下图」、「上表」之类的相对位置来引述他们。于是，我们需要对它们进行编号，方便在文中引用。

注意到，使用浮动体的根本目的是**避免不合理的分页或者大块的空白**，为此，我们需要**将大块的内容移至别的地方**。与之相辅相成的是浮动体的一些特性：

- 是一个容器，包含某些不可分页的大块内容；

- 有一个简短的描述，比如图题或者表题；

- 有一个编号，用于引述。

在 LaTeX 中，默认有 figure 和 table 两种浮动体。（当然，你还可以自定义其他类型的浮动体）在这些环境中，可以用 \caption{} 命令生成上述简短的描述。至于编号，也是用 \caption{} 生成的。这类编号遵循了 TeX 对于编号处理的传统：它们会自动编号，不需要用户操心具体的编号数值。

至于「别的地方」是哪里，LaTeX 为浮动体启用了所谓「位置描述符」的标记。基本来说，包含以下几种

- h - 表示 here。此类浮动体称为文中的浮动体（in-text floats）。

- t - 表示 top。此类浮动体会尝试放在一页的顶部。

- b - 表示 bottom。此类浮动体会尝试放在一页的底部。

- p - 表示 float page，浮动页。此类浮动体会尝试单独成页。

LaTeX 会将浮动体与文本流分离，而后按照位置描述符，根据相应的算法插入 LaTeX 认为合适的位置。

```tex
\documentclass{article}
\begin{document}
Figure \ref{fig:dummy} is a dummy figure to show the use of basic floats in \LaTeX{}.

\begin{figure}[htb]
\rule{4cm}{3cm} % a black box, treat it as a dummy figure
\caption{Dummy figure}\label{fig:dummy}
\end{figure}
\end{document}
```

## 限制浮动效果

有些强（chu）迫（nv）症（zuo）宝宝希望保留浮动体的标题以及编号的功能，但是希望浮动体「乖乖待在插入的位置」。

对于这些小朋友，老夫必须说：「这是病，得治」。

说它是「病」，是因为浮动效果本身是好的；相反，禁止浮动效果，可能导致页面出现大片的空白。另一方面，这些小朋友希望浮动体待在原地，很可能是习惯了「下图」、「上表」这样的引述方式；而没有使用科技论文标准的「图 1」、「表 2」的引述方式。

因此，老夫墙裂建议各位小朋友，不要管它，随它浮动去吧。

当然，在一些极端的情况，也会出现 LaTeX 无法很好地处理浮动体放置位置的情况。这时候需要我们做一些辅助工作，帮助和限制 LaTeX 的浮动算法。

如果希望避免浮动体跨过 \section 等章节标题，可以使用 placeins 宏包。它能在章节标题前，强制输出上一章节中尚未输出的浮动体。

```tex
\usepackage[section]{placeins}
```

如果希望彻底禁止某个浮动体的浮动效果，可以使用 float 宏包提供的 H 位置选项。

```tex
\usepackage{float}
% ...
\begin{figure}[H]
% ...
\begin{table}[H]
% ...
```

## 浮动体过多报错

LaTeX 是有底线的上限的。LaTeX 会把所有尚未确定位置的浮动体，放入 \@freelist 中暂存。而 \@freelist 默认情况下，最多能处理 18 个浮动体。因此，在某些极端情况下，如果 LaTeX 暂时无法处理的浮动体数目超过 18 个时，就会报错。

```tex
! LaTeX Error: Too many unprocessed floats.
```

此时有两种解决问题的思路：

- 强制输出所有尚未确定位置的浮动体，清空 \@freelist；

- 增强 LaTeX 的处理能力。

对于第一种思路，我们可以用 \clearpage，或者 placeins 宏包提供的 \FloatBarrier 命令。两个命令都会输出所有尚未输出的浮动体。不同的是，\clearpage 会做一些额外的工作，比如另起一页，继续排版。个人建议使用 \FloatBarrier 命令，遵循「一个命令只做好一件事」的原则。

如果使用了 \FloatBarrier 命令，还是经常会报错提示未处理的浮动体过多，那么就要考虑第二种思路了。对于第二种思路，我们可以使用 morefloats 宏包。\usepackage[morefloats = 18]{morefloats}，来增加 18 个槽位，以便能够向 \@freelist 放入更多的浮动体。

在 2015 年，[David Carlisle](http://tex.stackexchange.com/users/1090/david-carlisle) 在[新版的 LaTeX2e (2015)](https://www.latex-project.org/news/latex2e-news/ltnews22.pdf) 中实现了 \extrafloats 命令，可以方便地新增更多的槽位。具体用法只需在导言区执行该命令即可：\extrafloats{500}。

## 浮动体上下的垂直距离

最近总有人不爽 LaTeX 浮动体与周围文本的默认间距。LaTeX 浮动体相关的定义都可以在 source2e 当中找到，这里罗列重要的间距如下。

- \floatsep - 相邻两个浮动体之间的垂直距离。

- \textfloatsep - 页面中最后一个 t 模式的浮动体与文本的间距；页面中第一个 b 模式的浮动体与文本的间距。

- \intextsep - 页面中共 h 模式的浮动体上下与文本的间距。

因此，你可以通过 \setlength 命令修改上述三个垂直距离，以便调整浮动体与前后文本的距离了。