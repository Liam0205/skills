---
title: "LaTeX 中的浮动体：处理超宽问题"
url: https://liam.page/2017/03/22/floats-in-LaTeX-handle-overfull-floats/
date: 2017-03-22
categories: ["LaTeX"]
tags: ["Floats", "Overfull"]
---

[前文](/2017/03/11/floats-in-LaTeX-basic/)说了，浮动体主要是处理高度比较大，又不方便分割的内容：比如图片和表格。实际上，此类内容除了在高度上可能很高，它们也可能很宽。LaTeX 在水平方向，会贴着版芯的左边边界，开始排列内容。因此，如果一张图片或者表格的宽度超过了版芯的宽度，那么看起来就像是没有居中，而是偏右。

此篇我们讲一下如何处理此类情况。

## 缩小

对付内容过大，最直接的办法，就是把它们缩小。对于图片，如果使用了 graphicx 宏包，我们可以使用 width = \linewidth 的参数将图片缩放到正好填满页面宽度的大小，避免「超宽」。对于表格等其他内容，我们可以使用 graphicx 提供的 \resizebox 命令来处理。

```tex
\documentclass{article}
\usepackage{showframe}
\usepackage{graphicx}
\begin{document}
\begin{table}[!htb]
\centering
\caption{Oh, this table is overfull!}\label{tab:overfull}
\rule{1.1\linewidth}{3cm}
\end{table}

\begin{table}[!htb]
\centering
\caption{Imagine that this is a table.}\label{tab:resized}
\resizebox{\linewidth}{!}{\rule{1.1\linewidth}{3cm}}
\end{table}

\begin{figure}[!htb]
\centering
\includegraphics[width = \linewidth]{example-image}
\caption{A fit figure.}\label{fig:example-image}
\end{figure}
\end{document}
```

![用缩小的办法处理超宽的内容](/uploads/images/LaTeX/overfull_01.png)

## 想办法居中

上述通过缩小解决问题，是一种办法。但是，在很多情况下，也会存在问题；比如

- 表格内容缩小之后，就看不清了；

- \verb 之类的内容，不能放在大多数 box 之内。

为此，我们需要用别的办法，尝试解决这些问题。

实际上，大多数用户对于这类问题最大的诉求在于：为什么这些超宽的图表不局中了？所以，我们只要解决「居中」的问题，可能就覆盖了绝大部分用户的需求。而这些内容无法居中的原因，我们在介绍部分也说过了：LaTeX 在水平方向，会贴着版芯的左边边界，开始排列内容。因此，如果我们能让 LaTeX 不从版芯的最左边开始排列内容，就有可能解决这个问题。

决定 LaTeX 从何处开始排列内容的，是 \leftskip 这个宏。在 LaTeX2e 中，它被默认定义为 \z@。也就是说，从版芯的左边边界处开始排列内容。我们可以修改这个宏，比如改为 \setlength{\leftskip}{-20pt}，那么 LaTeX 将从版芯左边边界左边的 20pt 的位置开始排列内容。

```tex
\documentclass{article}
\usepackage{showframe}
\usepackage{graphicx}
\begin{document}
\begin{table}[!htb]
\centering
\caption{Oh, this table is overfull!}\label{tab:overfull}
\setlength{\leftskip}{-20pt}
\rule{1.1\linewidth}{3cm}
\end{table}
\end{document}
```

![leftskip 示例](/uploads/images/LaTeX/overfull_02.png)

同理，我们有 \rightskip，用于确定水平方向排版的终止位置与版芯右边界之间的距离。

我们知道，TeX 的 skip 是所谓的「弹簧」，允许在一定程度上进行缩放；而所谓的居中，实际上就是在版芯两侧，有两个力量相等的无限弹簧，同时向中间挤压内容。因此，我们不难得到对 \leftskip 和 \rightskip 的几个要求：

- 默认情况，应该贴着两侧边界；

- 最差的情况，应该允许内容向左右两侧延伸，超过版芯但不超过纸张宽度；

- 同时具有让内容居中的能力。

因此，我们可以将它们设置为（粗略地）：

```tex
\setlength{\leftskip}{0pt plus 1fil minus \marginparwidth}
\setlength{\rightskip}{\leftskip}
```

为了让它更好用，我们可以把他们收纳在一个新的命令当中（包含了一些额外的工作）：

```tex
\documentclass{article}
\usepackage{showframe}
\usepackage{graphicx}
\makeatletter
\newcommand*{\centerfloat}{%
  \parindent \z@
  \leftskip \z@ \@plus 1fil \@minus \marginparwidth
  \rightskip \leftskip
  \parfillskip \z@skip}
\makeatother
\begin{document}
\begin{table}[!htb]
\centerfloat
\caption{Oh, this table is adjusted!}\label{tab:adjusted}
\rule{1.1\linewidth}{3cm}
\end{table}
\end{document}
```

![巧妙地设置 leftskip 及 rightskip](/uploads/images/LaTeX/overfull_03.png)

当然，你也可以通过 \makebox 命令来达成目标，不过这样依然无法容纳含有类似 \verb 的内容：

```tex
\documentclass{article}
\usepackage{showframe}
\usepackage{graphicx}
\begin{document}
\begin{table}[!htb]
\centering
\caption{Oh, this table is adjusted!}\label{tab:adjusted}
\makebox[0pt][c]{\rule{1.1\linewidth}{3cm}}
\end{table}
\end{document}
```

## 使用 adjustbox 宏包

[Martin Scharrer](mailto:martin@scharrer-online.de) 有发布名为 adjustbox 的宏包，提供了类似 graphicx 宏包中 \includegraphics 命令的 key-value 参数，用以实现各类 box 效果。值得一提的是，宏包提供的几个宏、环境，都可以容纳 \verb 之类的内容。很是好用。

```tex
\documentclass{article}
\usepackage{showframe}
\usepackage{adjustbox}
\begin{document}
\begin{table}[!htb]
\centering
\caption{Oh, this table is adjusted by the package adjustbox!}\label{tab:adjusted}
\adjustbox{center}{\rule{1.1\linewidth}{3cm}}
\end{table}
\end{document}
```

效果和使用我们定义的 \centerfloat 命令类似，这里就不重复贴图了。

## 倘若把它倒过来……

上面的介绍，基本都仅限于处理 overfull 程度不大、超出版芯程度不多的情形。如果你有一个大胖娃娃，他/她使得版芯宽度严重超载，那么你可能要考虑把它旋转九十度了。

rotating 宏包提供了 sidewaystable 和 sidewaysfigure 环境（以及带 * 的版本，用于在双栏模式下通栏排版），分别作为对应 table 和 figure 的工具。使用这些环境，能使图表旋转 90° 摆放。

```tex
\documentclass{article}
\usepackage{showframe}
\usepackage{rotating}
\begin{document}
\begin{sidewaystable}[!htb]
\centering
\caption{Let's rock!}\label{tab:rotated}
\rule{0.8\linewidth}{3cm}
\end{sidewaystable}
\end{document}
```

需要注意的是，当旋转过来之后，「长宽」就交换了。因此，我们这里使用 0.8\linewidth 实际上是相对版芯的高度的 0.8 倍。此外，rotating 宏包默认将内容逆时针旋转了 90°，你也可以在调用宏包时传入 clockwise 参数，得到顺时针旋转的版本。

![旋转、跳跃，我闭着眼](/uploads/images/LaTeX/overfull_04.png)