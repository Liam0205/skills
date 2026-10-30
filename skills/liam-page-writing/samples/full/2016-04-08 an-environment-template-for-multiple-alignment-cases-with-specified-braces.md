---
title: "定义一个支持多列对齐的花式 cases 环境"
url: https://liam.page/2016/04/08/an-environment-template-for-multiple-alignment-cases-with-specified-braces/
date: 2016-04-08
categories: ["LaTeX"]
tags: ["AMS", "mathtools", "Alignment", "Cases"]
---

现有的 cases 环境，只支持：

- 左侧的花括号

- 一个对齐符号 &

如果在 cases 环境里需要多个对齐符号 &，或者希望在它左右有不同风格的括号，就要动一番脑筋了。

## 定义

以下代码借用了 amsmath 和 mathtools 的内部代码，可谓「站在巨人肩膀上」。

不过，也因为借用了内部代码，随着这两个宏包的更新，下列代码可能失效。然而，这两个宏包几乎是 LaTeX 数学公式输出的「基石」，不会经常改动，因此下列代码也多少有些意义。

但无论如何，还是建议在看懂代码的情况下使用；如果看不懂，请慎用，因为我可能不会再维护这段代码（万一以后出问题了的话）。

```tex
\usepackage{amsmath}
\usepackage{mathtools}
\MHInternalSyntaxOn
\def\MT_start_cases_ams:n #1{%
  \RIfM@\else
   \nonmatherr@{\begin{\@currenvir}}
  \fi
  \MH_group_align_safe_begin:
  \left#1
  \alignedat@a
}
\def\MH_end_cases_ams:{%
  \endaligned
  \MH_group_align_safe_end:
}
\newcommand*\defcases[3]{%
 \newenvironment{#1}
   {\MT_start_cases_ams:n {#2}}
   {\MH_end_cases_ams:\right#3}
}
\MHInternalSyntaxOff
```

这里定义了一个命令 \defcases，它接受 3 个参数。

- 新定义的环境的名字

- 左边的定界符（可自动伸缩）

- 右边的定界符（同上）

定义出来的环境，接受 1 个参数，用于指定环境中对齐符号 & 的最大数量。

## 使用

代码：

```tex
\documentclass{article}
\usepackage{amsmath}
\usepackage{mathtools}
\MHInternalSyntaxOn
\def\MT_start_cases_ams:n #1{%
  \RIfM@\else
   \nonmatherr@{\begin{\@currenvir}}
  \fi
  \MH_group_align_safe_begin:
  \left#1
  \alignedat@a
}
\def\MH_end_cases_ams:{%
  \endaligned
  \MH_group_align_safe_end:
}
\newcommand*\defcases[3]{%
 \newenvironment{#1}
   {\MT_start_cases_ams:n {#2}}
   {\MH_end_cases_ams:\right#3}
}
\MHInternalSyntaxOff
\defcases{mylcases}{\lbrace}{.}
\defcases{myrcases}{.}{\rbrace}
\defcases{mybcases}{\lbrace}{\rbrace}
\defcases{mylrcases}{[}{\rbrace}
\begin{document}
\[
    \begin{mylcases}{2}
      a &{} = b &{} = c \\
      a &{} = b &{} = c \\
      a &{} = b &{} = c
    \end{mylcases}\qquad
    \begin{myrcases}{2}
      a &{} = b &{} = c \\
      a &{} = b &{} = c \\
      a &{} = b &{} = c
    \end{myrcases}\qquad
    \begin{mybcases}{2}
      a &{} = b &{} = c \\
      a &{} = b &{} = c \\
      a &{} = b &{} = c
    \end{mybcases}\qquad
    \begin{mylrcases}{2}
      a &{} = b &{} = c \\
      a &{} = b &{} = c \\
      a &{} = b &{} = c
    \end{mylrcases}
\]
\end{document}
```

![](/uploads/images/LaTeX/cases.png)