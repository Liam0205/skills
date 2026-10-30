---
title: "【LaTeX Tips】指定 include 的路径"
url: https://liam.page/2013/11/05/LaTeX-include-path/
date: 2013-11-05
categories: ["LaTeX"]
tags: ["Path", "Include", "Input"]
---

## 问题的描述

在排版很长的文章时，为了便于组织结构，我们通常会将文章的正文部分分章节保存在其它的 .tex 文件中，最后在主控文档中使用 \input 或者 \include 命令来加载这些文档（参见[\input 和 \include 的区别](http://tex.stackexchange.com/questions/246/when-should-i-use-input-vs-include)）。

如果我们将这些章节源文件保存在指定目录下，比如 ./body/, 那么实际使用时，我们必须在每一次调用 \input 或者 \include 时都输入这一目录。这无疑是麻烦的。我们希望找到一种解决方法，可以免去输入路径。

## 解决方法

参考 [qingkuan 的回答](http://bbs.ctex.org/forum.php?mod=redirect&goto=findpost&ptid=77319&pid=454202&fromuid=109739), 我们可以在导言区添加如下内容以达到目的：

```tex
\makeatletter
\providecommand*\input@path{}
\newcommand\addinputpath[1]{
  \expandafter\def\expandafter\input@path
  \expandafter{\input@path{#1}}}
\addinputpath{body/}
\makeatother
```