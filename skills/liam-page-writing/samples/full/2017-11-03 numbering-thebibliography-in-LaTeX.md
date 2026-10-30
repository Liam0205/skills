---
title: "在 LaTeX 中为参考文献的标题编号"
url: https://liam.page/2017/11/03/numbering-thebibliography-in-LaTeX/
date: 2017-11-03
categories: ["LaTeX"]
tags: ["Section", "Numbering", "Bibliography"]
---

一般来说，参考文献、索引等章节的标题在论文中是不编号的。但是，在一些特殊情况下，我们可能也需要为这些标题做章节编号。

这边文章介绍如何处理此类情况。

对参考文献来说，不论采取何种方式，大体上最终都是用 LaTeX 提供的 [thebibliography 环境](/2016/01/23/using-bibtex-to-generate-reference/#%E5%AE%9E%E9%99%85%E6%93%8D%E4%BD%9C%E7%9C%8B%E7%9C%8B)来排版参考文献列表。这个环境一方面打印参考文献标题，另一方面打印参考文献列表。而打印参考文献标题的方式，就是调用 \section*（在 article 文档类中）或 \chapter*（在 book 类中）。

因此，我们需要做的事情，就是重定义 thebibliography 环境，使其调用 \section 或 \chapter，而不是带星号的版本。

在 LaTeX2e 当中，定义名为 foo 的环境，实际上定义了两个命令：\foo 和 \endfoo。前者用于开始环境，而后者用于结束环境。显而易见，thebibliography 环境对应的两个命令是 \thebibliography 和 \endthebibliography；而 \section* 或 \chapter* 的调用位于 \thebibliography 当中。因此，我们只需要使用 xpatch/etoolbox 宏包提供的 \xpatchcmd/\patchcmd 对 \thebibliography 打上补丁即可。

\xpatchcmd/\patchcmd 的介绍和用法可以参见[这里](/2015/04/22/cancle-clearpage-in-chapter/#%E6%89%93%E8%A1%A5%E4%B8%81)和[这里](/2017/04/11/justifying-in-beamer-s-lists/#patchcmd)。

以下是在 article 文档类中的最简示例。

```tex
\documentclass{article}
\usepackage{xpatch}
\xpatchcmd{\thebibliography}{\section*}{\section}{}{}
\begin{document}
\begin{thebibliography}{0}
    \bibitem{citekey} test
\end{thebibliography}
\end{document}
```

生成带编号的索引标题可以采用类似的方案操作，此处不表。