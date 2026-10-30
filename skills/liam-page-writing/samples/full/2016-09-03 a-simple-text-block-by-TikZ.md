---
title: "一个用 TikZ 实现的简易文本框"
url: https://liam.page/2016/09/03/a-simple-text-block-by-TikZ/
date: 2016-09-03
categories: ["LaTeX"]
tags: ["TikZ"]
---

在知乎上看到[一个问题](https://www.zhihu.com/question/50270196)，求一个简易的文本框。恰好之前在群里用 Ti*k*Z 给朋友实现过一个类似的，所以就做了一个回答。一些值得说的东西，记录在这里。

首先是代码。

```tex
\documentclass[UTF8]{ctexart}
\usepackage{tikz}
\usepackage{calc}
\usetikzlibrary{calc}

\newlength{\framelinewidth}
\newlength{\horizonextendwidth}
\newlength{\verticalextendwidth}
\setlength{\framelinewidth}{2pt}
\setlength{\horizonextendwidth}{3pt}
\setlength{\verticalextendwidth}{3pt}
\newenvironment{tblock}
{\par\medskip\noindent
\begin{tikzpicture}
  \node[inner sep = 0pt] (box) \bgroup%
    \begin{minipage}[t]{\textwidth-\framelinewidth-2\horizonextendwidth}%
}{%
    \end{minipage}%
  \egroup;
  \draw[black, line width=\framelinewidth]
    ( $ (box.north east) + (\horizonextendwidth,-\verticalextendwidth) $ ) -- ( $ (box.north east) + (\horizonextendwidth,\verticalextendwidth) $ ) -- ( $ (box.north west) + (-\horizonextendwidth,\verticalextendwidth) $ ) -- + (0,-2\verticalextendwidth);
  \draw[black, line width=\framelinewidth]
    ( $ (box.south east) + (\horizonextendwidth,\verticalextendwidth) $ ) -- ( $ (box.south east) + (\horizonextendwidth,-\verticalextendwidth) $ ) -- ( $ (box.south west) + (-\horizonextendwidth,-\verticalextendwidth) $ ) -- + (0,2\verticalextendwidth);
\end{tikzpicture}
\par\medskip}

\usepackage{mwe}
\begin{document}

\begin{tblock}
\blindtext
\end{tblock}

\end{document}
```

有几个地方值得一说。

主体当然是用 \newenvironment{tblock} 定义的 tblock 环境。这个环境里的文本部分是 tikzpicture 里用 \node 实现的，内里的换行用了 minipage。minipage 的宽度是 \textwidth-\framelinewidth-2\horizonextendwidth，这里利用了 calc 宏包提供的特性——直接做长度运算。为了让整个文本框宽度恰好是 \textwidth，内里的文本部分宽度必须减去框线两边延伸的宽度（2\horizonextendwidth）以及两边框线本身的粗细（2 * 0.5\framelinewidth）。

再就是 \node[inner sep = 0pt] (box) {} 的形式被修改为 \node[inner sep = 0pt] (box) \bgroup \egroup 的形式。这是为了避免在定义新环境时花括号不匹配的问题。详细可以看 [TeX.sx 上的讨论](http://tex.stackexchange.com/a/1932/38350)。

最后就是引入了 \usetikzlibrary{calc}，这个库允许我们在 Ti*k*Z 里对点的坐标做运算。因此我们可以写出类似 ( $ (box.south east) + (\horizonextendwidth,\verticalextendwidth) $ ) 的代码，来表示 box 右下角偏移 (\horizonextendwidth,\verticalextendwidth) 的那个点。

大体就是如此了。