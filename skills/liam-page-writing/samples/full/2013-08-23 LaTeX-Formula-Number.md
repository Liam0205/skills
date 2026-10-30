---
title: "【LaTeX Tips】LaTeX 中公式编号括号样式及章节关联的方法"
url: https://liam.page/2013/08/23/LaTeX-Formula-Number/
date: 2013-08-23
categories: ["LaTeX"]
tags: ["Equation number"]
---

## 章节关联

使用 amsmath 宏包的时候，我们可以利用 amsmath 宏包提供的 \numberwithin{<sub-counter>}{<counter>} 命令来实现公式与章节关联。效果形如 1.1

```tex
\documentclass{article}
\usepackage{amsmath}
\numberwithin{equation}{section}
\begin{document}
\section{Test}
\begin{equation}
E = mc^2
\end{equation}
\end{document}
```

当我们不使用 amsmath 宏包的时候，或者需要别的样式的时候，就必须修改 \theequation 的输出样式了。如下代码可以生成形如 1-1 的效果

```tex
\documentclass{article}
\makeatletter
\@addtoreset{equation}{section}
\makeatother
\renewcommand\theequation{\arabic{section}-\arabic{equation}}
\begin{document}
\section{Test}
\begin{equation}
E = mc^2
\end{equation}
\end{document}
```

## 修改括号的样式

使用 amsmath 宏包的时候，可以借助 mathtools 宏包提供的命令来修改公式编号的括号样式。可以去掉 LaTeX 公式编号的括号，或者变成别的样式——比如方括号/特别的文字。

mathtools 宏包提供了两个命令，用于定义和应用公式编号的括号的样式。

```tex
\newtagform{form-name}[Number-Style]{left}{right}
\usetagform{form-name}
```

用 \newtagform 来定义样式，用 \usetagform 来应用。

```tex
\documentclass{article}
\usepackage{amsmath}

\usepackage{mathtools}
\newtagform{test}[\textbf]{\textbf{\small Equation~}}{}
\usetagform{test}

\begin{document}

\section{Test}

\begin{equation}
E = mc^2
\end{equation}

\end{document}
```

这段代码可以产生形如 **Equation 1.1** 的公式编号效果。