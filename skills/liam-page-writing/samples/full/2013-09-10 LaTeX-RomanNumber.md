---
title: "【LaTeX Tips】输出罗马数字"
url: https://liam.page/2013/09/10/LaTeX-RomanNumber/
date: 2013-09-10
categories: ["LaTeX"]
tags: ["Roman", "Number"]
---

```tex
%罗马数字演示
\documentclass{ctexart}
\newcommand*{\rmn}[1]{\romannumeral#1}
\newcommand*{\RMN}[1]{\uppercase\expandafter{\romannumeral#1}}
\begin{document}
\RMN{2013}年\RMN{9}月\rmn{10}日
\end{document}
```

如此即可。

![](/uploads/images/LaTeX/roman-number-demo.png)