---
title: "【LaTeX Tips】定义新环境时，花括号意外匹配的解决"
url: https://liam.page/2013/05/14/LaTeX-environ/
date: 2013-05-14
categories: ["LaTeX"]
tags: ["Environ", "Newenvironment"]
---

## 问题

### 环境

XP sp3, TeX Live 2012, TeX studio.

### 测试代码

```tex
\documentclass{book}
\usepackage{tikz}
\usetikzlibrary{shapes,snakes}
\usepackage{amsmath,amssymb}

\usepackage{xcolor}
\definecolor{main}{HTML}{66CCFF}

\tikzstyle{newthemsty} = [draw=main, fill=yellow!20,very thick, rectangle,
	rounded corners, inner sep=10pt, inner ysep=20pt]
\tikzstyle{newthemstytitle} = [rounded corners, fill=main, text=white]

\newenvironment{tikzthm}[1]{
\begin{tikzpicture}
\node [newthemsty] (box){
}{
};
\node[newthemstytitle, right=10pt] at (box.north west) {\textbf{#1}};
\end{tikzpicture}
}

\begin{document}
\begin{tikzpicture}
\node [newthemsty] (box){blah blah.};
\node[newthemstytitle, right=10pt] at (box.north west) {\textbf{thmtitle}};
\end{tikzpicture}

\begin{tikzthm}{thmtitle}
blah blah.
\end{tikzthm}
\end{document}
```

pdfLaTeX 编译效果如图

![](http://ww1.sinaimg.cn/large/818901c1jw1e4n8bmkrn2j20a308et8p.jpg)

### 描述

尝试定义环境 tikzthm, 实现编译效果中上边的样式，但实际定义出来效果是下边的样子。

初步分析，定义环境的时候，花括号意外地被匹配了。

```tex
\newenvironment{tikzthm}[1]{
\begin{tikzpicture}
\node [newthemsty] (box){
}{
};
\node[newthemstytitle, right=10pt] at (box.north west) {\textbf{#1}};
\end{tikzpicture}
}
```

这里的第四行中的 }{ 应当是 \newenvironment{nam}[args]{begdef}{enddef} 中 begdef 和 enddef 之间的两个花括号。但事实上，因为 TikZ 中 \node 的作用，这里的前一个右花括号和 \node 的左花括号配对了，后一个左花括号和本来应该是 \node 的右花括号配对了。实际效果应该是下面这个样子：

```tex
\newenvironment{tikzthm}[1]{
\begin{tikzpicture}
\node [newthemsty] (box){}
{};
\node[newthemstytitle, right=10pt] at (box.north west) {\textbf{#1}};
\end{tikzpicture}
}
```

这就使得 \node 无法接收到内容，而且 \newenvironment 少了一个参数（如果后面接着什么东西的话，会出现奇怪的错误的。。）。

## 解决

已经解决，方案来自 [stackexchange](http://tex.stackexchange.com/questions/29825/environment-definition-separates-matching-braces).

如果期待 \formatcommand{ foo } 形式的代码作用于环境的 body, 则因为花括号匹配的问题会出错:

```tex
\newenvironment{testenv}{
	\formatcommand{
}{
	}
}
```

解决方案可以用 environ 包提供的新命令 \NewEnviron 定义环境。举例如下：

```tex
\documentclass{book}
\usepackage{environ}
\usepackage{tikz}
\usetikzlibrary{shapes,snakes}
\usepackage{amsmath,amssymb}

\usepackage{xcolor}
\definecolor{main}{HTML}{66CCFF}

\tikzstyle{newthemsty} = [draw=main, fill=yellow!20,very thick, rectangle,
	rounded corners, inner sep=10pt, inner ysep=20pt]
\tikzstyle{newthemstytitle} = [rounded corners, fill=main, text=white]

\NewEnviron{tikzthm}[1]{
\begin{tikzpicture}
\node [newthemsty] (box){\BODY};
\node[newthemstytitle, right=10pt] at (box.north west) {\textbf{#1}};
\end{tikzpicture}
}
\begin{document}
\begin{tikzthm}{thmtitle}
blah blah.
\end{tikzthm}
\end{document}
```

与 LaTeX 提供的 \newenvironment 不同，\NewEnviron 要求用 \BODY 显示地标明环境的 body 出现的位置。这样就避免了花括号错误匹配的问题。