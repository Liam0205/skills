---
title: "LaTeX 插图时对文件扩展名的处理"
url: https://liam.page/2019/01/27/keep-single-dot-in-image-filename-for-LaTeX/
date: 2019-01-27
categories: ["LaTeX"]
tags: ["Graphicx"]
---

这是一篇简单的记录，缘起于有人在 XeLaTeX 中插入 .png 格式的图片，但提示 no boundingbox。这与我的认知不同：这一错误通常只在 LaTeX 方式编译时才会出现，而且加上 bmpsize 宏包结合 DVIPDFMx 驱动就能解决。但这次问题出现在 XeLaTeX 下，我感到很奇怪，也引起了我的兴趣。

## MWE

最小工作示例如下：

```tex
% compile with XeLaTeX
\documentclass{article}
\usepackage{graphicx}
\begin{document}
  \includegraphics{foo.bar.png}   % reports error (no boundingbox)
\end{document}
```

报错如下：

```plaintext
! LaTeX Error: Cannot determine size of graphic in foo.bar.png (no BoundingBox)
.

See the LaTeX manual or LaTeX Companion for explanation.
Type  H <return>  for immediate help.
 ...

l.5   \includegraphics{foo.bar.png}
                                      % reports error (no boundingbox)
?
```

## 分析

如前所述，这就很奇怪了。我第一反应是图片本身有什么问题。但多方检查都没发现有什么问题。考虑到同样的代码在 pdfLaTeX 下编译理应也能通过并顺利输出，故执行命令 pdflatex test.tex，并观察现象。

```plaintext
! LaTeX Error: Unknown graphics extension: .bar.png.

See the LaTeX manual or LaTeX Companion for explanation.
Type  H <return>  for immediate help.
 ...

l.5   \includegraphics{foo.bar.png}
                                      % reports error (no boundingbox)
?
```

出乎意料，本该顺利通过的代码，在 pdfLaTeX 下也报错了。不过，这次报错的问题和使用 XeLaTeX 时还不太一样。pdfLaTeX 提示说不认识名为 .bar.png 的图片扩展名。

这给了我新的提示。显然 pdfLaTeX 在处理图片时，以第一个 . 作为分割，之后的部分都是扩展名；而后根据图片文件的扩展名去处理。推测 XeLaTeX 也会做类似的操作，只是细节上有所不同，XeLaTeX 没有在遇见 .bar.png 这个扩展名的第一时间报错，而是延迟到了计算边界框尺寸时发现没有匹配该扩展名（.bar.png）时才报错。如果确实如此，那么在 graphicx.sty 当中应该有所体现。追溯到 graphicx.sty 依赖的 graphics.sty 当中：

```tex
\def\Ginclude@graphics#1{%
  \begingroup
  \let\input@path\Ginput@path
  \filename@parse{#1}%
  \ifx\filename@ext\relax
% ...
```

显然，\filename@parse 是在解析图片文件的文件名。这是一个定义在 LaTeX2e 中的底层命令，根据其文档，它会将解析结果保存在 \filename@area, \filename@base, \filename@ext 三个宏当中。在 \filename@parse 的定义中，解析扩展名是通过利用 TeX 的宏定义式的技巧来实现的：

```tex
\def\filename@simple#1.#2
```

在调用 \filename@simple 时，会将遇到的第一个 . 之前的内容当做 #1 而把 . 之后的内容当做 #2。这个 #2 最后被保存在了 \filename@ext 当中，作为文件扩展名。

## 解决办法

了解了问题的根源，解决起来就容易了。

最简单的绕过办法，是保持图片文件的文件名当中只有一个句点，用于区分文件名及其扩展名。这样 TeX 就不会被误导了。例如，将 MWE 中的文件名从 foo.bar.png 改为 foo_bar.png，再尝试于 LaTeX 当中插入。

如果不想修改文件名，那么可以利用 TeX 的分组，将真实的文件名包裹在一对分组花括号当中。也就是写成形如这样的代码 {foo.bar}.png。这样，在 \filename@simple 处理参数的过程中，由于 foo.bar 被放在一个分组当中，整个被当成是一个 token，因而不会被打散，也因而能解析到正确的扩展名 png。