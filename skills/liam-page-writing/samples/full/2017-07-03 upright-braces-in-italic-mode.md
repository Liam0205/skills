---
title: "使斜体中的括号保持直立"
url: https://liam.page/2017/07/03/upright-braces-in-italic-mode/
date: 2017-07-03
categories: ["LaTeX"]
tags: ["Emphesis", "Italic", "Brace", "Bracket"]
---

在使用 \emph, \textit, \textsl 等命令时，我们往往希望西文字符倾斜，但括号保持直立。这是因为，括号并不是字母，让它们也倾斜一则没有意义，二则看起来奇怪。

Clemens 提供的 embrac 宏包解决了这个问题。

## 基本用法

宏包的基本用法十分简单，只需要加载它就好了。默认情况下，圆括号和方括号已经设置好直立了。

```tex
\documentclass{article}
\usepackage{embrac}
\begin{document}
\textit{[(italic)]}

\textsl{[(slant)]}

\emph{[(emphasis)]}
\end{document}
```

![](/uploads/images/LaTeX/embrac.png)

## 开关

有时，我们可能需要在部分情况下，让括号也变成倾斜的。这时候，我们需要组合使用 \EmbracOff 和 \EmbracOn 两个命令。

```tex
\documentclass{article}
\usepackage{embrac}
\begin{document}
\textit{[(italic)]}

\EmbracOff
\textsl{[(slant)]}
\EmbracOn

\emph{[(emphasis)]}
\end{document}
```

![](/uploads/images/LaTeX/embrac_switch.png)

## 花括号

宏包默认没有将花括号也设置为直立体，按文档的说法，可以通过 \AddEmph 命令设置实现。但我的尝试没有成功。

- **Update 2017-7-4**: 下列代码在 pdfLaTeX 下能编译得到预期结果，但在 XeLaTeX 下则不然。

- **Update 2017-7-4**: 经过[反馈](https://bitbucket.org/cgnieder/embrac/issues/8/cannot-treat-curly-braces-upright)，作者确认这是一个 bug，并已修复。同时宏包版本号升为 0.7。在新版本中，一切正常。

```tex
\documentclass{article}
\usepackage{embrac}
\AddEmph{\{}[-.04em]{\}}[,-.15em]
\begin{document}

\textit{\{[(italic)]\}}

\textsl{\{[(slant)]\}}

\emph{\{[(emphesis)]\}}
\end{document}
```

![](/uploads/images/LaTeX/embrac_curly_braces.png)

## 注意事项

embrac 是通过修改 \emph, \textit, \textsl，实现这一目的的。因此，\em, \itshape, \slshape 命令依旧保留了斜体的括号。