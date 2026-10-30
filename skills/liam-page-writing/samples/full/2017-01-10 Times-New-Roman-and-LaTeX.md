---
title: "Times New Roman 与 LaTeX"
url: https://liam.page/2017/01/10/Times-New-Roman-and-LaTeX/
date: 2017-01-10
categories: ["LaTeX"]
tags: ["Font", "Times"]
---

本文又名：**你对真正的 Times 字体一无所知**。

Times New Roman 在很长时间内是 Windows 平台上 M$ Word 的默认西文字体。所以，很多机构要求作者在文章中使用 Times New Roman 作为西文字体，于是这些作者就开始到处问：怎样在 LaTeX 中使用 Times New Roman 字体。

## 各种版本

这是一个最早由 Stanley Morison、Starling Burgess 和 Victor Lardent 共同创造的[衬线字体](https://zh.wikipedia.org/wiki/%E8%A1%AC%E7%BA%BF%E4%BD%93)，由 Monotype 公司于1932年发表，并为英国的《泰晤士报》首次采用。这是一个经典的、中规中矩的字体，所以经常被选为西文的标准字体之一。

Windows 中使用的 Times New Roman 是 Monotype 在最初字形上稍加修改（字宽方面）得到的。macOS 系统中使用的 Times Roman 是 Linotype 公司出品的，它与 Monotype 家的 Times New Roman 除了个别字形稍有区别之外（相信你看不出来），几乎完全相同。开源系统中对应的字体，则是 URW 的 Nimbus Roman No9 L 字体，它在 GPL 许可下发布。

简单来说，你在 Windows 里接触最多的 Times 字体是 Monotype 出品的 Times New Roman；在 macOS 里接触的是 Linotype 家的 Times Roman；开源环境你能见到最多的是 URW 的 Nimbus Roman No9 L 字体。而它们几乎没有差别。

## 在 LaTeX 里使用

在 LaTeX 里使用 Times 字体，有几种方式。值得一提的是**在这里没有介绍的方式，基本都是过时的方式（或者不方便初学者使用的方式）**。

### 使用 fontspec 系列宏包

fontspec 系列宏包是为 XeLaTeX 和 LuaLaTeX 设计的。借由它，用户可以直接选取系统中的字体。因此，你可以准确而直接地选择 Times New Roman 而不是其他近似（在 macOS 下只能用 Times Roman 了）。这是最推荐的方法。

```tex
\documentclass{article}
\usepackage{mathspec}
\setmainfont{Times New Roman}
\setmathsfont{Times New Roman}
\begin{document}
This is the typeface Times New Roman.

Enjoy!
\end{document}
```

### 使用 mathptmx 宏包

mathptmx 是一个为 LaTeX 设计的字体宏包，它会将默认 rmfamily 设置为 Nimbus Roman No9 L；而将数学字体设置为对应的 Italic 字形（不足的部分使用了 CM/RSFS/Adobe Symbol 等字体）。这是同时修改默认文本字形和默认数学字形为 Times 字形最干净的宏包。

使用它可能需要借助 fontenc 宏包来辅助设置字体编码。

```tex
\documentclass{article}
\usepackage[T1]{fontenc}
\usepackage{mathptmx}
\begin{document}
This is the typeface Nimbus Roman No9 L, and fontface for mathematics has been modified to the Italic counterpart.

Enjoy!
\end{document}
```

### 使用 newtx 系列宏包

本质上，newtx 系列宏包是为了代替陈旧的 txfonts 宏包而设计的。它最大的特色是分为两部分——分别改变文本字体和数学字体，而不需要同时使用：

- newtxtext，

- newtxmath。

和 mathptmx 宏包类似，newtx 系列宏包也使用 Nimbus Roman No9 L 及其 Italic 字形。不过，他们还会做额外的工作：

- 将正文 Sans Serif 字体设置为 Helvetica（的开源近似版）；

- 将正文 Monospace (Typewriter) 字体设置为 Times 的等宽版本。

```tex
\documentclass{article}
\usepackage[T1]{fontenc}
\usepackage{newtxtext, newtxmath}
\begin{document}
This is the typeface Nimbus Roman No9 L, and fontface for mathematics has been modified to the Italic counterpart.
\textsf{The sans serif family is Helvetica} and \texttt{the monospace family is also Times}.

Enjoy!
\end{document}
```