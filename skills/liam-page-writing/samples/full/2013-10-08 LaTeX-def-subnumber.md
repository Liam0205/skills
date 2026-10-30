---
title: "【LaTeX Tips】在 LaTeX 中实现「子定理」"
url: https://liam.page/2013/10/08/LaTeX-def-subnumber/
date: 2013-10-08
categories: ["LaTeX"]
tags: ["Subnumber", "Definition"]
---

问：写了7个definition后，这里第8个definition是分开定义的，即编号为8.1,8.2，8.3 。。。怎么样才能做到？

\newtheorem{myDef}{Definition}

答：

```tex
\documentclass{article}

\usepackage{amsmath}
\newtheorem{myDef}{Definition}
\newtheorem{subDef}{Definition}[myDef]

\begin{document}
\begin{myDef}
content...
\end{myDef}

\stepcounter{myDef}
\begin{subDef}
content...
\end{subDef}
\begin{subDef}
content...
\end{subDef}

\begin{myDef}
content...
\end{myDef}
\end{document}
```