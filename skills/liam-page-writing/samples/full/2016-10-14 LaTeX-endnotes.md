---
title: "尾注的处理"
url: https://liam.page/2016/10/14/LaTeX-endnotes/
date: 2016-10-14
categories: ["LaTeX"]
tags: ["Endnotes"]
---

LaTeX 中的 \footnote 命令可以产生脚注——在正文位置留下一个编号，在当前页的底部输出实际的注释内容。这个功能很好用，但是在一些情况下，可能产生意想不到的情况。

- 数量少而大段的尾注导致尾注先于标记出现；

- 数量多而小段的尾注导致尾注晚于标记出现。

这些不太寻常的注释会导致 LaTeX 标注文档类没有办法很好地处理脚注。这里，后者可以通过 footmisc 宏包的 para 选项来挽救，但是前者就没有什么好办法了。于是，我们想到了尾注。

## 简介

尾注，即将注释与标记分离，写在文档的末尾。LaTeX 标准文档类没有提供尾注的功能，而由 endnotes 宏包提供。

尾注的用法和脚注基本相同，只需要

- 将原本需要使用 \footnote 命令的地方替换成 \endnote；

- 在需要输出尾注的地方，执行 \theendnotes 命令。

## 给尾注加上类似 \footnote 的横线

默认的尾注标题，只有一个光秃秃的 Notes 字样，和默认的脚注样式不太一样。我们可以通过修改 \enoteheading 命令来修改这个样式。这里我们以 book 类为例（article 类应该将 \section* 改为 \subsection*）。

```tex
\documentclass{book}
\usepackage{endnotes}
\makeatletter
\def\enoteheading{\section*{\notesname
  \@mkboth{\MakeUppercase{\notesname}}{\MakeUppercase{\notesname}}}%
  \mbox{}\par\vskip-2.3\baselineskip\noindent\rule{.5\textwidth}{0.4pt}\par\vskip\baselineskip}
\makeatother
\begin{document}

\chapter{First}
Testing.\endnote{First test.} Hello \LaTeX{}.\endnote{LaTeX}
\theendnotes
\end{document}
```

![](/uploads/images/LaTeX/endnotes_01.png)

## 在每个章节后输出尾注

不难发现，其实尾注输出的位置取决于 \theendnotes 命令的位置。因此我们只需要在每个 \chapter 命令之前（book 类，article 类是 \section 命令）加上 \theendnotes 命令就好了。

不过，由于 \endnote 是在全文范围内编号的，如果希望尾注的编号在输出章节尾注后重新开始，那么我们需要在调用 \theendnotes 之后将计数器置零——当然你也可以使用 \counterwithin 之类的命令来实现。这里我们用 etoolbox 提供的 \csappto 命令来实现这个效果。

```tex
\documentclass{book}
\usepackage{endnotes}
\usepackage{etoolbox}
\makeatletter
\def\enoteheading{\section*{\notesname
  \@mkboth{\MakeUppercase{\notesname}}{\MakeUppercase{\notesname}}}%
  \mbox{}\par\vskip-2.3\baselineskip\noindent\rule{.5\textwidth}{0.4pt}\par\vskip\baselineskip}
\makeatother
\csappto{theendnotes}{\setcounter{endnote}{0}}
\begin{document}

\chapter{First}
Testing.\endnote{First test.} Hello \LaTeX{}.\endnote{LaTeX}
\theendnotes

\chapter{Next}
Again.\endnote{Second test.}
\theendnotes

\end{document}
```

![](/uploads/images/LaTeX/endnotes_02.png)