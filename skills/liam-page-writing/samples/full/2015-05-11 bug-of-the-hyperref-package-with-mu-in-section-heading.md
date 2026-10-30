---
title: "hyperref 宏包 psdextra 选项的 bug 及其 quick fix"
url: https://liam.page/2015/05/11/bug-of-the-hyperref-package-with-mu-in-section-heading/
date: 2015-05-11
categories: ["LaTeX"]
tags: ["Bug", "Hyperref", "Psdextra"]
---

今天有人问到下列代码报错：

```tex
\documentclass{article}
%\listfiles
\usepackage[unicode,psdextra]{hyperref}
\usepackage{unicode-math}
\setmathfont{Asana Math}
\begin{document}
\section{$\mu$}
\end{document}
```

提示：

```plaintext
Improper alphabetic constant
```

看了一下，是 hyperref 宏包的 bug。

实际上，在处理 PDF 书签的时候，很多数学命令要被定义成相应的文本模式，比如 \geq 要被定义为 \textgeq。这个工作在 NFSS 里完成。

但是，数学符号那么多，总有 NFSS 定义不全的时候。于是 hyperref 提供了 psdextra 选项。该选项会载入 psdextra.def 这个文件，提供更多的定义。

不过 \mu 在 NFSS 里和 psdextra.def 里都处理错了。psdextra 里是处理了 \mugreek，而实际上应该是 \mu。于是就出问题了。

解决方法也很简单，自己处理一下就好了。

```tex
\documentclass{article}
%\listfiles
\usepackage[unicode, psdextra]{hyperref}
\usepackage{unicode-math}
\setmathfont{Asana-Math.otf}
\usepackage{etoolbox}
\appto{\psdmapshortnames}{\let\mu\textmugreek}
\begin{document}
\section{$\mu$}
\end{document}
```

这里 \appto 命令接受两个参数，\appto{<需要修补的命令>}{<填在命令最后的内容>}。这里我们将 \let\mu\textmugreek 添加在命令 \psdmapshortnames 的最后，这样在处理 PDF 书签的时候，\mu 就能被正确处理了。

该 bug 已提交给 hyperref 宏包的作者。