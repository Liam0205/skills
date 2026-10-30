---
title: "避免 \\chapter 命令分页"
url: https://liam.page/2015/04/22/cancle-clearpage-in-chapter/
date: 2015-04-22
categories: ["LaTeX"]
tags: ["Chapter", "Pagebreak"]
---

LaTeX 的 book 类中，\chapter 命令用来标记章节。在生成的 PDF 文稿中，\chapter 总是另起一页；在打开（默认）openright 选项的时候，可能还会空白一页。在实际使用过程中，很多人希望 \chapter 不要换页，紧接着当前页的内容排版。

传统工具没有提供此功能，因此用户需要自行修改 \chapter 的定义。

## 找到 \chapter 的定义

LaTeX 标准文档类的定义写在 classes.pdf 这个文档中，你可以在命令行下使用 texdoc classes 来打开这份文档。

你可以在文档的 7.2.6 节中找到 \chapter 的定义。和我们的问题相关的，就是 \chapter 定义的第一行。

![`\chapter` 的定义](/images/LaTeX/def-of-chapter.png)

得益于 [文学编程](http://liam0205.me/2015/01/23/literate-programming-in-latex/)，我们看到文档中明确地写着「章节总是应该从新的一页开始，因此我们需要调用 \clearpage」。

显然，为了达到目的，我么只需要令 \chapter 定义的第一行失效就好了。

## 打补丁

xpatch 宏包可以用来打补丁。它的 \xpatchcmd 命令接受五个参数：\xpatchcmd{命令}{搜索}{替换}{成功}{失败}

- 命令：待处理的命令

- 搜索：需要被替换的部分

- 替换：将被替换的内容

- 成功：替换成功执行的内容

- 失败：替换失败执行的内容

这里我们需要将 \if@openright\cleardoublepage\else\clearpage\fi 替换掉。用于替换的内容则是：\par\relax。因此我们有代码：

```tex
\usepackage{xpatch}
\makeatletter
\xpatchcmd{\chapter}
  {\if@openright\cleardoublepage\else\clearpage\fi}{\par\relax}
  {}{}
\makeatother
```

注意，符号 @ 是一个保留符号。它在用户编写 .tex 文档的时候和开发者编写宏包/文档类的时候具有不同含义。我们用 \makeatletter 将 @ 的含义切换到开发者模式；在进行修改之后，用 \makeatother 将 @ 的含义切换到用户模式。

这样，\chapter 定义中的换行部分，就被替换成了分段。

完整的示例代码：

```tex
\documentclass{book}
\usepackage{xpatch}
\makeatletter
\xpatchcmd{\chapter}
  {\if@openright\cleardoublepage\else\clearpage\fi}{\par\relax}
  {}{}
\makeatother
\usepackage{blindtext}
\begin{document}
\blindtext
\chapter{test}
\end{document}
```