---
title: "LaTeX 中的宽度"
url: https://liam.page/2015/08/17/width-in-latex/
date: 2015-08-17
categories: ["LaTeX"]
tags: ["Table", "Width", "Figure", "Minipage"]
---

使用 LaTeX 的过程中，如果需要插入图片、表格，我们有时会用到页面宽度。那么，在 LaTeX 中都有哪些常用的宽度？它们有什么区别？分别又该在什么时候使用呢？

LaTeX 里存在一些长度宏，保存着与页面尺寸有关的长度。涉及到页面宽度，有这么几个：

- \linewidth - 当前行的宽度

- \columnwidth - 当前分栏的宽度

- \textwidth - 整个页面版芯的宽度

- \paperwidth - 整个页面纸张的宽度

- \hsize - Plain TeX 的宏，是 TeX 在行末考虑分词换行时使用的宽度

这些宽度里，\hsize 是 Plain TeX 的宏，不推荐 LaTeX 用户使用，简单地当它不存在就好了。在单栏文本中，\columnwidth 和 \textwidth 保持一致；在多栏文本中 \textwidth = n * \columnwidth + (n - 1) * \columnsep（其中 n 是分栏数）。

在 minipage 环境中，除了 \paperwidth 之外，其它三个 \****width 都会根据 minipage 的宽度发生改变（因为虚拟出了一个小的纸张页面），然后在 minipage 环境结束的时候恢复原样。在 parbox 中，\textwidth 和 \columnwidth 不会改变，不过 \linewidth 会发生变化。

\linewidth 是相对最灵活的宽度值。在 list 环境里（包括 enumerate 和 itemize 等环境），在 \parbox 里，\linewidth 都会发生变化。

总的来说，当

- 需要在列表环境中使用表格、图片等宽度的时候，用 \linewidth

- 需要充满整个页面宽度的时候，用 \textwidth （比如 figure*/table* 等）

- 需要充满整个分栏的时候，用 \columnwidth （比如 figure/table/tabularx/tabu 等）