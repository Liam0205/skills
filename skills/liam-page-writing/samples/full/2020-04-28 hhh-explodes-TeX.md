---
title: "嘿嘿嘿使 TeX 爆炸"
url: https://liam.page/2020/04/28/hhh-explodes-TeX/
date: 2020-04-28
categories: ["LaTeX"]
tags: ["Mode"]
---

TeX 里有 \leavevmode 用来从竖直模式中切出去，那么有没有 \leavehmode 呢？一定会有好奇宝宝好奇这个奇怪的问题的。

答案是：嘿嘿嘿使 TeX 爆炸不存在。

TeX 总是从竖直模式开始，然后一旦遇到水平命令时，就会离开竖直模式，然后开始构建段落。除非结束这个段落，TeX 是不会离开水平模式的。

怎么结束这个段落？当然是你熟知的 \par 命令。实际上，任何会导致 TeX 离开水平模式的命令，都会调用 \par 这个命令——这里的 \par 是最原始到那个 \par 原语。如果你把 \par 定义成了一个不包含原语版的 \par 的时候，所有导致 TeX 离开水平模式的命令都会导致死循环。比如下面代码：

```tex
\def\par{}
x\vskip 1pt
```

（你看，让 TeX 死循环就这么简单）

所以，不存在 \leavehmode 这种东西。能让 TeX 离开水平模式的只有 \par。

不过，存在一种情况下，TeX 可以部分地离开模式——\vadjust 命令。在水平模式中遇到 \vadjust 时，TeX 会把它的参数中的所有竖直元素打包在一起暂存，然后等到断行成段之后，TeX 再把 \vadjust 里的内容插入到 \vadjust 存在的那一行之后。比如：

```tex
\documentclass{ctexart}
\usepackage{zhlipsum}
\begin{document}
嘿嘿嘿\vadjust{\vskip 3ex}\zhlipsum[3]
\end{document}
```

![](/uploads/images/LaTeX/vadjust.jpg)

那么为什么「嘿嘿嘿使 TeX 爆炸」呢？因为当你把 \par 定义成「嘿嘿嘿」的时候，TeX 就会因为陷入死循环而不断地把「嘿嘿嘿」塞入内存，然后就炸掉了。

```tex
\documentclass{ctexart}
\begin{document}
\def\par{嘿嘿嘿}
x\vskip 1pt
\end{document}
```

日志如下：

```text
(./ltxtest.aux) ABD: EverySelectfont initializing macros
! TeX capacity exceeded, sorry [main memory size=5000000].
<to be read again>
                   \vskip
l.4 x\vskip
            1pt
No pages of output.
Transcript written on ltxtest.log.
```