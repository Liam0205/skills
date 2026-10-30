---
title: "Beamer frame 中的抄录环境"
url: https://liam.page/2019/08/26/verbatim-environments-and-frame-in-beamer/
date: 2019-08-26
categories: ["LaTeX"]
tags: ["Beamer", "Verbatim", "Fragile"]
---

今天 @Butui Hu 在群里问了一个老问题：怎么在 Beamer 的 frame 当中使用 minted 环境？

这个问题的答案很简单：其实不论是 minted 还是 lstlisting 还是基本的 verbatim，这些「抄录」环境与 frame 联用时，统统都需要给 frame 加上 fragile 参数，形如：

```tex
\begin{frame}[fragile]
% verbatim-like environment.
\end{frame}
```

但问题是，为啥事情会变成这个样子？这篇文章简单讨论一下。

## 抄录环境是怎么实现的？

首先我们要解决的第一个问题是，类似 verbatim 的抄录环境是怎么实现的？

基本上说，抄录环境有这么一些特征：

- 使用等宽字符字族 \ttfamily 排版内容；

- 排版所有空格，而非[让输入处理器进入 S 状态忽略空格](/2018/01/31/TeX-by-Topic-the-Structure-of-the-TeX-processor/#%E5%AD%97%E7%AC%A6%E7%9A%84%E8%BE%93%E5%85%A5)；

- 在每个回车处换行；

- 原样抄录**每一个**字符。

当然，对于 minted 和 lstlisting 之类的环境，还会有为特定字符、词组渲染颜色的功能。但这些都是「锦上添花」，我们要关注的核心还是上面四条。

很显然，抄录环境对于输入内容的处理方式与正常内容的处理方式有很大差异。比如，反斜线 \ 原本作为 TeX 默认的转义字符，此时却要原样输出。我们知道，TeX 中之所以有诸多特殊用途的字符（\, {, }, $ 等等），其原因在于[输入处理器读入内容时，会为每个字符分配分类码](/2018/05/05/TeX-by-Topic-Category-Codes-and-Internal-States/)。输入处理器会根据字符和字符的分类码，将输入内容处理成记号流（token stream），交由展开处理器继续处理。显然，抄录环境要改变 TeX 中特殊用途的字符的行为，就必须要改变他们的分类码。实际上，这些字符的分类码，在抄录环境中，都会被设置为 12（other）。

此外，为了恢复这些特殊用途的字符，TeX 要在合适的位置重新设置这些字符的分类码。对于 LaTeX 使用者来说，很显然这个「时机」就应该是 \end{verbatim} 出现时了。这个论断说对也对，说不对也不完全对。考虑到，进入抄录环境之后，诸如 \ 的分类码已经改变，因此 \end{verbatim} 不会像正常的「结束环境」的标志那样被 TeX 识别并处理。于是，为了达到预期效果，你必须把 \end{verbatim} 单独成行，作为恢复分类码的标志。也就是说，\end{verbatim} 在这里起到的是一个纯粹的标志作用，而不是通常意义上「结束环境」的作用。

```tex
\begingroup
\catcode `|=0 \catcode `[= 1 \catcode`]=2
\catcode `\{=12 \catcode `\}=12 \catcode`\\=12
|gdef|@xverbatim#1\end{verbatim}[#1|end[verbatim]]
|gdef|@sxverbatim#1\end{verbatim*}[#1|end[verbatim*]]
|endgroup
```

上面这段代码是 LaTeX2e 中有关抄录环境结束的命令的定义。在由 begingroup 和 endgroup 形成的 semi-group 分组中，我们将 | 定义为转义字符（0），[] 分别定义为分组开始和结束的字符（1, 2），然后把 {}\ 都定义为「其他字符」（12）。虽有，用 |gdef（相当于平时的 \gdef）超出 semi-group 的范围，定义控制序列 @xverbatim，它接受 1 个参数，这个参数以 \end{verbatim} 这串字符结尾，同时将它的内容替换成实际内容 #1，以及有实际含义的 |end[verbatim]（后者会被展开成 \endverbatim 命令，负责真正的「结束环境」的工作）。

一顿操作猛如虎，最终还靠分类码。而最最重要的是我们得知道，**分类码是由输入处理器在读入文件时设置的**。

## 脆弱命令是怎么回事？

在输入处理器把文本流变成记号流之后，展开处理器和执行处理器就开始工作啦！通常来说，展开处理器会拼了老命将记号展开成更加底层的记号，直到不可展开，然后执行处理器开始执行各个不可展开的底层记号。

但某些情况下，这个流程会有问题。其中一个典型的例子，就是所谓的「移动参数」问题。

考虑 \section{} 命令。它做四件事：

- 编号自增 1

- 输出章节标题

- 处理目录（和 PDF 书签）

- 做页眉的章节标记

其中 (3) 依赖于将标题内容和编号写入 <jobname>.toc 文件，当 TeX 第二遍编译时，从 <jobname>.toc 文件读入内容再去排版目录。也就是说，此类命令的具体含义在两次编译过程中是不一样的，而具体它是什么含义（最终效果），要等排版完成之后才能确定。

问题在于：

- TeX 在写文件时，会将宏——此处特别注意 \section{} 参数中可能包含的宏——完全展开；

- 但完全展开写入文件之后，又要重新为 TeX 所读入，这时可能造成奇怪的错误。

比方说，\(\) 展开后会包含很多带有 @ 的内容，如果将这些内容写入文件，再重新读入，就会因为 @ 的分类码是 12 而非 11 不能作为控制序列的一部分而报错。

我们将提前展开和延后展开的最终效果不一样的命令，称之为脆弱命令（fragile commands）。与之对应的，就是健壮命令（robust commands）。

## 这和 frame 有什么关系？

为此我们需要查看 Beamer 的文档。文档 12.9 节提到：

If you wish to use a {verbatim} environment in a frame, you have to add the option [fragile] to the {frame} environment. In this case, [...] and the \end{frame} must be alone on a single line. Using this option will cause the frame contents to be written to an external file and the read back.

这段提到了在 frame 当中使用抄录环境，必须制定 fragile 参数。但仍然没有解释「为啥要用」。继续找到文档 8.1 节：

If a frame contains fragile text, different internal mechanisms are used to typeset the frame to ensure that inside the frame the character codes can be reset. The price of switching to another internal mechanism is that either you cannot use overlays or an external file needs to be written and read back (which is not always desirable).
In detail, the following happens when this option is given for normal (pdf)LaTeX: The contents of the frame is scanned and then written to a special file named ⟨jobname⟩.vrb or, if a label has been assigned to the frame, ⟨jobname⟩.⟨current frame number⟩.vrb. Then, the frame is started anew and the content of this file is read back. Since, upon reading of a file, the character codes can be modified, this allows you to use both verbatim text and overlays.
To determine the end of the frame, the following rule is used: The first occurence of a single line containing exactly \end{⟨frame environment name⟩} ends the frame. The ⟨environment name⟩ is normally frame, but it can be changed using the environment option. This special rule is needed since the frame contents is, after all, not interpreted when it is gathered.

这样我们就明白了。frame 在某种程度上限制了环境内容对分类码的修改。因此，对于抄录环境这样需要修改分类码来实现目的的「脆弱内容」，我们要指定 fragile 参数，然后 Beamer 会将这些内容写入到外部文件（为此 frame 环境变成了脆弱命令）。然后，在再次读入这些内容时，让输入处理器有机会正确处理分类码。如此一来，才能顾全这些「脆弱内容」的渲染，和 Beamer 的 overlay 效果。