---
title: "用 caption 宏包修复浮动体超链接不准的问题"
url: https://liam.page/2015/11/21/using-the-caption-package-to-justify-the-link-anchor/
date: 2015-11-21
categories: ["LaTeX"]
tags: ["Hyperref", "Caption"]
---

[前文](/2015/07/27/using-hypcap-to-justify-the-link-point/) 我介绍了使用 hypcap 宏包修复图标超链接不准的问题。具体来说，是修复了将 \caption 放在 \includegraphics 后面，然后在文中对图片进行引用的话，点击超链接后将跳转到图片标题位置而不是浮动体顶部的问题。

之后，[shengwenbo](http://weibo.com/u/1277361954) 在文后评论说，caption 宏包也能实现这一功能。本文就来介绍，如何使用 caption 宏包来实现这一效果。

## 基本用法

最基本的用法很简单，只需要在加载插图宏包（graphicx）和超链接宏包（hyperref）之余，加载 caption 宏包即可。具体来说，代码如下。

```tex
\documentclass{article}
\usepackage{graphicx}
\usepackage{hyperref}
\usepackage{caption}

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

这样一来，当点击第二页 Figure 之后的「1」之后，就能跳转至图片的开始位置（而不是标题位置）。

![跳转位置](/uploads/images/LaTeX/Anchor-Point-Caption.png)

## 细节

caption 宏包用于控制浮动体超链接跳转位置的功能，实际上由宏包选项 hypcap 控制。默认情况下，hypcap = true，即打开这一功能。

除此之外，caption 宏包还提供了 hypcapspace 选项，用来控制浮动体跳转的具体位置。具体来说，hypcapspace 选项接收一个 TeX 长度，跳转的位置则被设置为浮动体开始位置前的该长度；它的默认值为 hypcapspace = 0.5\baselineskip。比如说：

```tex
\documentclass{article}
\usepackage{graphicx}
\usepackage{hyperref}
\usepackage[hypcap = true, hypcapspace = 2cm]{caption}

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

![hypcapspace 设置为 2cm 时的效果](/uploads/images/LaTeX/Anchor-Point-Caption-2cm.png)

## 优势

相较之前介绍过的 hypcap 宏包，由 caption 宏包完成这项工作，显得更加自然。毕竟，对浮动体标题的操作是一个常见需求，因而加载 caption 宏包很多时候是理所当然的；而 hypcap 宏包则更像是一个补丁。具体到功能上，caption 相较 hypcap 宏包有以下一些优势：

- hypcap 宏包只支持 LaTeX 自带的 figure 和 table 两个浮动体环境，而 caption 则支持更多。

- hypcap 宏包不能与 caption 宏包定义的 \captionsetup{type = <type>} + \caption 联用，而 caption 对自家定义的宏当然支持良好。