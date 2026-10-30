---
title: "在 MacTeX 中使用中文模板"
url: https://liam.page/2015/04/14/using-chinese-templates-in-mactex/
date: 2015-04-14
categories: ["LaTeX"]
tags: ["Template", "Chinese", "MacTeX"]
---

中国人使用 LaTeX 的一大问题就是为文档添加中文支持。国内很多学校、期刊都有自己的模板，更多的是一些个人配置的勉强成型的小模板。Mac 用户安装 MacTeX 之后，可能会很头疼如何将这些模板移植到自己的电脑上。这篇文章对此做一个方法上的讨论。

在 LaTeX 中使用中文，**不严谨地说**，主要需要解决编码和字体调用的问题。

国内 LaTeX 圈子流行过 GBK 编码和 UTF-8 编码。前者是国标，是过去的主流，但是问题多多。现在推荐使用后者。

字体调用方面，原来的 CCT（新版）、CJK 还有现在的 xeCJK、LuaTeX-ja 和李阿玲的 pTeX-ng 在 TeX Live（MacTeX）底下都能正常工作。只不过，Mac 默认的字体和 Windows 默认的字体有一些不同，在这方面需要做一些调整。

国内期刊的模板大多数是 CCT 和 CJK 方式，其他一些模板可能比较先进，使用 xeCJK 方式。LuaTeX-ja 国内用的少，使用方法和 xeCJK 比较类似；pTeX-ng 尚在开发中。所以这里只介绍使用 CCT、CJK 或 xeCJK 三种中文支持方式在 TeX Live 里如何进行调整。

## xeCJK

xeCJK 通过 \setCJKmainfont 等命令（luatexja-fontspec 则是 \setmainjfont）来调用操作系统内的字体，并设置为文档字体。在 Windows 底下编写的中文模板，惯常使用 Windows 自带的中易系列字体，比如

```tex
\setCJKmainfont[Boldfont = SimHei, ItalicFont = KaiTi]{SimSun}
\setCJKsansfont{SimHei}
\setCJKmonofont{FangSong}
```

这种情况下，可以打开模板文件（.tex、.sty 或 .cls），找到字体设置部分，将其内容改为 Mac 的字体设置即可。比如可以参考配置：

```tex
\setCJKmainfont[BoldFont=STZhongsong, ItalicFont=STKaiti]{STSong}
\setCJKsansfont[BoldFont=STHeiti]{STXihei}
\setCJKmonofont{STFangsong}
```

具体的含义可参考：[为 MacTeX 配置中文支持](/2014/11/02/latex-mactex-chinese-support/)

使用 xeCJK 的模板，应该都保存为 UTF-8 编码，所以不需要进行编码调整。（部分模板使用 GBK 编码，在文档头会有 \XeTeXinputencoding 'CP936' 的 XeTeX 原语。此时最好将文件另存为 UTF-8 编码，并删除这些原语。）

## CJK

在不适用 zhmetrics 技术的时候，CJK 需要 Type 1 字体。将中易字体拆分成许多 sub-fonts 并转换为 Type 1 字体是个费时费力的工作。CTeX 套装打包了已经配置好的 CJK 字体，它的 song、hei、kai、fs、li 和 you 等六套字体，流传甚广。国内使用 CJK 的模板，大都使用了这几套字体。

不过，CJK 宏包本身并不含有这些字体，所以在使用 TeX Live 的时候，直接编译这些模板会报错。

我们看一段最简单的使用 CJK 宏包做中文支持的例子。

```tex
\documentclass{article}
\usepackage{CJKutf8}
\begin{document}
\begin{CJK*}{UTF8}{song}
中文。
\clearpage
\end{CJK*}
\end{document}
```

对于 Windows 系统的 TeX Live 用户而言，最简单的办法是使用 zhmetrics 技术。为此我们只需要在导言区添加一行命令即可，代码变为：

```tex
\documentclass{article}
\usepackage{CJKutf8}
\AtBeginDvi{\input{zhwinfonts}}
\begin{document}
\begin{CJK*}{UTF8}{song}
中文。
\clearpage
\end{CJK*}
\end{document}
```

此时，使用 pdfLaTeX 或 LaTeX - DVIPDFMx 编译文档，即可得到正确的结果。

对于 Mac/Linux 系统的 TeX Live（MacTeX）用户而言，简单地加载 zhwinfonts.tex 是不会奏效的。zhwinfonts.tex 是为 Windows 系统配置的文件，在 Mac/Linux 系统中缺少这些字体。我自己买了方正系列字体在 Mac 上使用，所以写了一个 zhfzfonts.tex 来调用这些字体。

请参考：[手把手教你在 macTeX 上使用 CJK](/2020/04/17/using-CJK-on-macTeX-step-by-step/)。

另外，CJK 支持 GBK，也支持 UTF-8。请注意将文档编码保存为与 CJK 环境相同的编码格式。

## CCT

以系统工程理论与实践为代表的一些国内期刊，使用 CCT 模板。前年为此写过一篇博客，专门讨论此类模板。参见：[国内期刊 CCT 模板编译经验](/2013/10/15/LaTeX-CCT-template/)

CCT 只支持 GBK 编码。

## ctex 宏包/文档类

ctex 宏包/文档类在使用 XeLaTeX 编译的时候，使用 xeCJK 作为中文支持方式；在使用 LaTeX/pdfLaTeX 的时候使用 CJK 作为中文支持方式。因此，使用 ctex 宏包/文档类的模板，在 TeX Live 系统下的配置方式需要根据所选的编译方式做调整。

使用 XeLaTeX 的时候，需要给 ctex 加上 nofonts 选项（将来的 2.0 版本则是 fontset = none），然后再用 \setCJKmainfont 配置字体。

使用 LaTeX/pdfLaTeX 的时候，则可以使用 zhfzfonts.tex 来映射字体。

使用 ctex 宏包/文档类的时候，需要根据所选的编译方式和宏包/文档类选项来确定源文件的编码格式。

- 使用 XeLaTeX 的时候，不论选项为何，源文件都需要保存为 UTF-8 编码。

- 使用 LaTeX/pdfLaTeX 的时候，则需要根据宏包/文档类选项来确定源文件的编码格式。