---
title: "【LaTeX Tips】在 Chapter/Section 等标题中插入脚注"
url: https://liam.page/2013/08/26/LaTeX-Footnote-In-Section-Title/
date: 2013-08-26
categories: ["LaTeX"]
tags: ["Footnote", "Section", "Chapter"]
---

```tex
\documentclass{article}
\begin{document}
\tableofcontents
\section[Section Title]{Section Title\footnote{This is footnote.}}
\end{document}
```

如此即可。