---
title: "用 hypcap 宏包修复图表超链接不准的问题"
url: https://liam.page/2015/07/27/using-hypcap-to-justify-the-link-point/
date: 2015-07-27
categories: ["LaTeX"]
tags: ["Hyperref", "Hypcap"]
---

LaTeX 中的 hyperref 宏包是一个非常强大的宏包，它提供了和超链接的各种接口。特别地，对于 LaTeX 原生的交叉引用，hyperref 宏包能够在引用位置生成一个超链接——点击之后跳转到相关位置。

不过，如果你将 \caption 放在 \includegraphics 后面，然后在文中对图片进行引用的话，点击超链接后将跳转到图片标题位置。此时，图片本身会被挡住。这多少有点不方便。

德国的 LaTeX 大牛 Heiko Oberdiek 写了一个叫做 hypcap 的宏包，专门用来解决这个问题。加载这个宏包之后，对浮动体（包括 figure/table 等）的引用链接会跳转至浮动体开始的地方。这样一来，figure 环境里的图片就不会被挡住了。

具体用法如下：

```tex
\documentclass{article}
\usepackage{graphicx}
\usepackage{hyperref}
\usepackage[all]{hypcap}
\usepackage{mwe} % for dummy text
\begin{document}
\begin{figure}[!htb]
\centering
\includegraphics[width = 0.6\linewidth]{example-image.jpg}
\caption{dummy figure}\label{fig:test}
\end{figure}
\blindtext
\clearpage
\blindtext

This is the hyper-reference of Figure \ref{fig:test}.
\end{document}
```

注意，这里我给 hypcap 宏包加上了 all 选项，说明 hypcap 宏包会处理全部类型的浮动体（详情请阅读其说明手册）；mwe 宏包（是 Minimal Working Example 的缩写）是为了产生无意义的测试文字而加载的宏包，实际使用时可以去掉。