---
title: "为 XeLaTeX 所调用时 xDVIPDFMx 的默认参数"
url: https://liam.page/2019/02/12/default-flags-for-xDVIPDFMx/
date: 2019-02-12
categories: ["LaTeX"]
tags: ["Drivers", "xDVIPDFMx"]
---

去年，有人在群里[提及](https://t.me/chinesetex/3441)：

在 macOS 上，同样是使用 STFangSong 字体，使用 LaTeXmk 编译出来的文档在 Windows 上查看会[乱码](/uploads/pdf/latexmk-mac.pdf)，但使用 XeLaTeX 直接编译则[正常](/uploads/pdf/xelatex-mac.pdf)。MWE 是：

```tex
\documentclass{ctexbook}
\begin{document}
\fangsong
中文
\end{document}
```

具体的编译命令分别是：

```bash
latexmk -cd -f -xelatex -interaction=nonstopmode -synctex=1 --output-directory=output foo.tex
xelatex -interaction=nonstopmode -synctex=1 --output-directory=output foo.tex
```

这个问题直至近期查看了 XeLaTeX 的源码才得到了完整答案。

## 字体嵌入

根据 Ao Zhang 的检查，[latexmk-mac.pdf](/uploads/pdf/latexmk-mac.pdf) 当中没有如 [xelatex-mac.pdf](/uploads/pdf/xelatex-mac.pdf) 那样嵌入字体。

![](/uploads/images/LaTeX/no-font-embedding.jpg)

由于找不到相应字体，Windows 上查看文档时，就乱码了。

## 驱动 xDVIPDFMx

XeLaTeX 输出的文件格式是扩展 DVI（eXtended DVI, .xdv）。不过，XeLaTeX 在执行到最后时会调用驱动，将 .xdv 文件转为 .pdf 格式，并将 .xdv 文件删除。默认的驱动是 xDVIPDFMx，它与 DVIPDFMx 系出同源。

使用 LaTeXmk 编译的文档没有嵌入字体，显然与 xDVIPDFMx 有关。经检查，LaTeXmk 考虑到多次编译时，只有最后一次编译需要真正输出 PDF 文件，故而在调用 XeLaTeX 时加上了 -no-pdf 选项，同时在最后一次调用 XeLaTeX 之后去调用 xDVIPDFMx。大致可以理解为 LaTeXmk 会按如下方式执行命令：

```bash
xelatex -no-pdf [other-options] foo.tex
bibtex foo
makeindex foo
xelatex -no-pdf [other-options] foo.tex
xelatex -no-pdf [other-options] foo.tex
xdvipdfmx foo
```

问题出在最后调用 xDVIPDFMx 的时候。若要嵌入字体，应当加上 -E 选项。但是默认情况下，LaTeXmk 没加上这一选项。所以，默认情况下，由 LaTeXmk 编译出来的 PDF 文档不会嵌入字体。具体到我们的例子中，[latexmk-mac.pdf](/uploads/pdf/latexmk-mac.pdf) 在 Windows 上显示为乱码。

## XeLaTeX 调用 xDVIPDFMx 时的默认参数

至此，「在 macOS 上使用 LaTeXmk 编译的文档在 Windows 上乱码」这一问题已经可以解释。但是问题的另一半，即「为什么在 macOS 上使用 XeLaTeX 编译的文档在 Windows 上不会乱码」这一问题还没回答。显然，这仍与 xDVIPDFMx 的调用参数有关。

经查，XeLaTeX 在指定输出驱动为 xDVIPDFMx 时的 C 代码为：

```c
const char *outputdriver = "xdvipdfmx -q -E"; /* default to portable xdvipdfmx driver */
```

可见，调用时添加了 -q 和 -E 两个参数。其中 -q 表示静默模式，即 xDVIPDFMx 不会输出任何回显信息；-E 表示忽略字体版权标记而总是将字体嵌入输出文件。

如此一来，问题的另一半也得到了合理解释。