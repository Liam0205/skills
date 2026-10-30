---
title: "【LaTeX Tips】在文本的同一行开始一个列表环境"
url: https://liam.page/2013/12/02/LaTeX-How-to-start-itemize-on-same-line-as-text/
date: 2013-12-02
categories: ["LaTeX"]
tags: ["List"]
---

有时我们会希望在文本的同一行开始一个列表环境，而非是使用默认的在下一行开始。同时，我们会希望列表环境的标签仍旧在垂直方向上对齐。

LaTeX 提供的 itemize 环境和 enumerate 环境事实上都是 list 环境的一种，但 itemize 和 enumerate 不允许修改 \labelsep 等距离。因此，要达到我们的目的，我们要么使用原始的 list 环境，要么使用 description 环境——它允许修改这些距离。

代码：

```tex
\documentclass{article}
\usepackage{enumitem}
\usepackage{lipsum} % just for the example

\newlength{\jeroenlen}
\newenvironment{example}
 {\settowidth{\jeroenlen}{\textbf{Example:}}%
  \begin{description}[leftmargin=\jeroenlen,labelwidth=0pt,labelsep=0pt]
  \item[\textbf{Example:}]%
  \begin{itemize}[leftmargin=1.5em,labelsep=.5em]}
 {\end{itemize}\end{description}}

\begin{document}
\lipsum[2]
\begin{example}
\item Such and such
\item So and so
\item Enough
\end{example}
\lipsum[3]
\end{document}
```

效果：

![](http://i.stack.imgur.com/xbCIc.png)

Sometimes, we hope that an itemize environment could start at the same line of certain text, rather than start at the next line as the default does. Moreover, the labels should be vertically aligned.

The itemize and enumerate environment provided by the standard LaTeX are both descendant of list environment, however, length, such as \labelsep, are prevented from modifying. Thus, we have two choices: using list or using description whose length chould be modified.

Code:

```tex
\documentclass{article}
\usepackage{enumitem}
\usepackage{lipsum} % just for the example

\newlength{\jeroenlen}
\newenvironment{example}
 {\settowidth{\jeroenlen}{\textbf{Example:}}%
  \begin{description}[leftmargin=\jeroenlen,labelwidth=0pt,labelsep=0pt]
  \item[\textbf{Example:}]%
  \begin{itemize}[leftmargin=1.5em,labelsep=.5em]}
 {\end{itemize}\end{description}}

\begin{document}
\lipsum[2]
\begin{example}
\item Such and such
\item So and so
\item Enough
\end{example}
\lipsum[3]
\end{document}
```

And the output:

![](http://i.stack.imgur.com/xbCIc.png)