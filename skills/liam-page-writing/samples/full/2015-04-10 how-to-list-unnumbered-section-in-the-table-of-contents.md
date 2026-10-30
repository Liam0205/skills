---
title: "在 LaTeX 中将不编号的章节列入目录"
url: https://liam.page/2015/04/10/how-to-list-unnumbered-section-in-the-table-of-contents/
date: 2015-04-10
categories: ["LaTeX"]
tags: ["Section", "Sectioning", "Numbering", "Table of Contents"]
---

LaTeX 标准文档类提供了 \section 和 \section* 等两组命令，用于排版章节标题。其中不带星号的版本有章节编号，会列入目录，同时修改章节标记。带星号的版本只有章节标题格式而不编号，不列入目录，也不会修改章节标记。

有时，我们会希望将不编号的章节标题列入目录。这种情况使用 \section 或 \section* 都不大合适。本文将对这些问题做出分析，并给出解决方案。

LaTeX 标准文档类的 \section 命令做四件事情：

- 编号自增 1

- 输出章节标题

- 处理目录（和 PDF 书签）

- 做页眉的章节标记

相应地，\section* 命令只做上述第二件事情，其余三件都不做。

因此，我们的思路很简单，有两个方向。第一，使用 \section*，手工做目录的处理；第二，使用 \section，但是抑制编号。

## 思路一

LaTeX 处理目录需要编译两次。在第一次编译的过程中，\section 命令将目录信息写入 .aux 文件。随后，在第二次编译的过程中，LaTeX 读取 .aux 文件中的相应信息，形成目录。因此，我们只需要模仿 \section 写入 .aux 文件的过程就可以了。

LaTeX 提供了 \addcontentsline{<辅助文件后缀>}{<章节等级>}{名字} 命令来做这样的工作。我们来看一个例子。

```tex
\documentclass{ctexart}
\begin{document}
\tableofcontents
\section*{不编号的章节标题}
\addcontentsline{toc}{section}{不编号的章节标题}
\end{document}
```

## 思路二

LaTeX 标准文档类中的 \appendix 命令，会使得后续的章节标题从 0 开始编号，同时将编号格式从阿拉伯数字修改为大写英文字母。\appendix 命令虽然不符合我们的需求，但是产生的效果却和我们需要的效果类似：修改了章节标题编号。我们可以对这个命令做适当的修改，达成我们的目的。

我们来看一下 article.cls 里的 \appendix 是如何定义的。

```tex
\newcommand\appendix{\par
  \setcounter{section}{0}%
  \setcounter{subsection}{0}%
  \gdef\thesection{\@Alph\c@section}}
```

接下来，我们仿造它，定义一个新的命令 \specialsectioning。

```tex
\documentclass[hyperref]{ctexart}
\newcommand\specialsectioning{\par
  \setcounter{section}{0}%
  \setcounter{subsection}{0}%
  \renewcommand\thesection{\relax}}
\begin{document}
\tableofcontents
\section{正常编号的章节标题}
\specialsectioning
\section{不编号的章节标题}
\end{document}
```

编译之后我们会发现，在 \specialsectioning 之后的 \section 虽然不带星花，但已然不编号了，并且出现在了目录当中。

不过，正常标题的编号和标题正文之间是有一定的空距的。我们现在虽然将编号取消了，但是这个空距依然存在。虽然它不明显，但是毕竟是个问题。作为一个精益求精的完美主义者，我们要解决它。

正文中编号的格式由 LaTeX 内部宏 \@seccntformat 控制，默认是在编号后面加一个 \quad，我们把它去掉。

```tex
\def\@seccntformat##1{\@nameuse{the##1}}
```

此外，目录中的编号和章节标题之间也有距离，我们通过 tocloft 宏包来将这个距离设置为 0pt。

```tex
\addtocontents{toc}{\def\cftsecnumwidth{0pt}}
```

这样，完整的代码变成：

```tex
\documentclass{ctexart}
\usepackage{tocloft}
\makeatletter
\newcommand\specialsectioning{\par
  \setcounter{section}{0}%
  \setcounter{subsection}{0}%
  \renewcommand\thesection{\relax}%
  \def\@seccntformat##1{\@nameuse{the##1}}%
  \addtocontents{toc}{\def\cftsecnumwidth{0pt}}}
\makeatother
\begin{document}
\tableofcontents
\section{正常编号的章节标题}
\specialsectioning
\section{不编号的章节标题}
\end{document}
```

问题解决了，不过思路二这样做未免麻烦。在这个思路下，会不会有更简单的方法呢？答案是肯定的。

在 LaTeX 标准文档类中，secnumdepth 这个计数器是用来控制章节编号深度的。在 article 中，这个计数器的值默认是 3，对应的章节命令是 \subsubsection。也就是说，默认情况下，article 将会对 \subsubsection 及其之上的所有章节标题进行编号，也就是 \part, \section, \subsection, \subsubsection。

LaTeX 标准文档类中，最大的标题是 \part。它在 book 和 report 类中的层级是「-1」，在 article 类中的层级是「0」。因此，我们只需要将计数器设置为 -2，之后章节命令都不会编号了，从而解决问题。

我们来看一下代码。

```tex
\documentclass{ctexart}
\makeatletter
\newcommand\specialsectioning{\setcounter{secnumdepth}{-2}}
\makeatother
\begin{document}
\tableofcontents
\section{正常编号的章节标题}
\specialsectioning
\section{不编号的章节标题}
\end{document}
```

怎么样？是不是简单多了？