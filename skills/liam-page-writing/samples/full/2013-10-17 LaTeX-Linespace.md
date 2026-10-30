---
title: "【LaTeX Tips】关于行距的研究"
url: https://liam.page/2013/10/17/LaTeX-Linespace/
date: 2013-10-17
categories: ["LaTeX"]
tags: ["Linespace", "Baseline", "Baselineskip", "Baselinestretch", "Setspace"]
---

## baseline 是什么

TeX 中的每个字符都放在一个 box 里。每个 box 有 base （参考点）、width（宽度）、height（高度）、depth（深度），其中 height + depth = totalheigth （总高）。

若干字符的 box 组成一个词的 box ，同样这个 box 也有这样几个参数。TeX 断行之后，会把这一行的所有盒子的 base 连接起来，以保证改行的内容在一个基准线上，连接成的线段就是 baseline.

如图所示：
![](http://i.stack.imgur.com/Bw1jE.png)

## LaTeX 的行距机制

每一行都有一条 baseline, 同一段落中相邻两行之间的 baseline 的间距称为行距 (linespace). 一般来说，最终决定两条 baseline 之间的 linespace 距离的，是 LaTeX 的宏 \baselineskip 之中。也就是说，这个长度值，将会是一般情况下的两条 baseline 之间的距离，也就是我们最终的行距。

显然行距应当随着字号的大小变化；若不然，则对于给定的行距数值，较大字号的内容部分显得拥挤不堪。LaTeX 中的字号存储在内部宏 \f@size 之中，而内部宏 \f@baselineskip 则记录了行距中和字号相关的部分。这个宏当中，它的单位和字号的单位一样，都是 pt ( 1pt = 1/72.27 inch ). LaTeX 的默认情况下，\f@baselineskip 的值是当前 \f@size 的 1.2 倍——例如，当 \f@size 为 10pt 时，\f@baselineskip 的值为 12pt.

为了统一对不同字号的内容进行行距的调整，引入了因子的概念，这是一个数值（而不是长度），储存在 \f@linespread 这个宏里面。这是一个与字号无关的值，在 article 文档类中它默认是 1, 在 ctexart 中默认是 1.3. 通常我们修改行距，都是修改这个因子，而不动前段叙述的基础行距。因此就有必要将因子存储在一个外部宏（没有 @ 的宏）之中，它是 \baselinestretch. 于是我们可以大致地认为，\f@linespread 和 \baselinestretch 是一回事。

因此，根据 \baselineskip = \f@baselineskip * \baselinestretch, 在 article 中默认行距是字号的 1.2 倍，而在 ctexart 中默认行距是字号的 1.56 倍。此外，提一下，Word 中的「单倍行距」/「双倍行距」等名词，指的是因子的数值为 1 或者 2 的时候的行距；相反 setspace 宏包的 「单倍」、「一倍半」、「双倍」则是指行距相对于字号的倍数。

## 如何修改行距

\f@linespread 的值一旦给定，会一直作用到文档末尾或者被新的值覆盖；\f@baselineskip 的情况类似。因为 TeX 排版的过程是对一整段文字进行计算，在每个可能的断行点计算总劣度最小的断行模式，然后进行排版。所以每一段段内的行距，由最后被设置的（覆盖了前面的）\f@baselineskip 和 \f@linespread 决定。

修改行距，也就是修改因子，可以直接修改 \baselinestretch 的值（\renewcommand），或者使用 \linespread{} 来修改。然而为了保持与 LaTeX2e 的一致性，推荐使用后一种方法。

```tex
\linespread{<因子>}
```

setspace 宏包提供的 \setstretch 命令似乎做得更多一些：会同时修改数学公式、浮动体等的间距，使之与正文间距适应。

```tex
\setstretch{<因子>}
```

\fontsize{}{} 这类命令，必须在其后添加 \selectfont 才会生效。\setstretch 大致相当于 \linespread, 使用之后直接生效。