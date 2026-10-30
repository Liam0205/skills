---
title: "使 LaTeX 文稿中的 URL 正确换行"
url: https://liam.page/2017/05/17/help-the-url-command-from-hyperref-to-break-at-line-wrapping-point/
date: 2017-05-17
categories: ["LaTeX"]
tags: ["hyperref", "linebreak", "URL"]
---

大部分稍有经验的 LaTeX 用户，都知道使用 \url 命令在 LaTeX 文稿中插入 URL。更资深一些的用户，会使用 hyperref 宏包，而不是过时的 url 宏包来处理。

然而，不论是否资深，大多数用户应该都有遇到过 LaTeX 无法正确对 URL 进行折行的问题。此篇介绍一下如何处理。

TeX 对于断行和分页，是有专门的算法处理的。通常而言，如果一个单词（一整个 \url 可以看做是一个单词），TeX 不知道从何处进行分词，那么 TeX 就不会在这个单词上断行。对于很长的单词，比如一个 \url，如果 TeX 不能在此处断行，而它又处于某一行的末尾，就很容易出现 overful box。

因此，本质上，这个问题需要让 \url 命令，知道我们允许在何处断行。

hyperref 宏包提供了两个宏，\UrlBreaks 以及 \UrlBigBreaks，用于告知 TeX，用户允许在何处截断 URL 以便换行。二者有一些细微的差别，但此处按下不表——大多数读者只需要使用 \UrlBreaks 即可。

```tex
\documentclass{article}
\usepackage{hyperref}
\makeatletter
\def\UrlAlphabet{%
      \do\a\do\b\do\c\do\d\do\e\do\f\do\g\do\h\do\i\do\j%
      \do\k\do\l\do\m\do\n\do\o\do\p\do\q\do\r\do\s\do\t%
      \do\u\do\v\do\w\do\x\do\y\do\z\do\A\do\B\do\C\do\D%
      \do\E\do\F\do\G\do\H\do\I\do\J\do\K\do\L\do\M\do\N%
      \do\O\do\P\do\Q\do\R\do\S\do\T\do\U\do\V\do\W\do\X%
      \do\Y\do\Z}
\def\UrlDigits{\do\1\do\2\do\3\do\4\do\5\do\6\do\7\do\8\do\9\do\0}
\g@addto@macro{\UrlBreaks}{\UrlOrds}
\g@addto@macro{\UrlBreaks}{\UrlAlphabet}
\g@addto@macro{\UrlBreaks}{\UrlDigits}
\makeatother
\begin{document}
\url{http://foo.bar.com/documentclassarticleusepackagehyperrefbegindocumenturlenddocument}
\end{document}
```

在这里，\UrlOrds 里记录了一些特殊符号（例如 - 和 _），而 \UrlAlphabet 记录了 26 个英文字母的大小写，\UrlDigits 则记录了 10 个阿拉伯数字。

而后，我们使用 LaTeX 内核提供的 \g@addto@marco，依次将上述三个宏的内容，续接在 \UrlBreaks 之后。这就是说，我们允许在上述所有字符处断行。

如此，编译出的结果也是符合预期的。

![能够正确换行的 URL 示例](/uploads/images/LaTeX/url-linebreak.png)