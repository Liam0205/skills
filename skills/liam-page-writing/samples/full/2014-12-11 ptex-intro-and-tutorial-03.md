---
title: "日文 LaTeX 系统介绍 - 最简示例"
url: https://liam.page/2014/12/11/ptex-intro-and-tutorial-03/
date: 2014-12-11
categories: ["LaTeX"]
tags: ["pTeX", "Japanese", "Demo"]
---

本文为译文，原文载于[这里](http://www.preining.info/blog/2014/12/writing-japanese-in-latex-part-3-simple-documents/)。欢迎关注本系列的文章。

[上一篇文章](http://www.preining.info/blog/2014/12/writing-japanese-in-latex-part-2-characters-and-encodings/)（[译文](http://liam0205.me/2014/12/08/ptex-intro-and-tutorial-02/)）我们探讨了关于字符集和编码的一些细节，今次我们继续讨论如何在 LaTeX 中书写日文。今天的内容需要动手操作试试，要用不同的引擎和宏包写一些 Hello world 类型的文档。

![](/images/pTeX-intro/nihongo-latex.jpg)

今天的内容同样会涉及到一些配置 TeX 环境的内容，会讲一讲如何在 [TeX Live](http://tug.org/texlive/) 里配置书写日文的环境。

## 配置日文 TeX 环境

我们假设，你已经在计算机上安装好了类似 TeX Live 2014 的 TeX 系统。你可以在下列 TeX 系统中选择其一安装。

- TeX Live 的原始版本 (Upstream TeX Live installation) - 完整的安装步骤，请参考 [TeX Live 的文档（中文版）](http://tug.org/texlive/doc/texlive-zh-cn/texlive-zh-cn.pdf)的第三章。对于 [Linux](http://tug.org/texlive/quickinstall.html) 和 [Windows](http://tug.org/texlive/windows.html) 系统，也可以参照相应的快速安装教程。对于 Mac OS X 的用户，则建议安装基于 TeX Live 的 [MacTeX](http://tug.org/mactex/)。

- 发行版里的 TeX Live (Distribution’s TeX Live) - 具体的安装取决于你使用的发行版。如果你用的是 Debian/jessie 或者 Debian/sid，那么你只需要运行 apt-get install texlive-full 即可。其他发行版 (Fedora, RedHat, SuSE) 的用户请注意检查发行版里当前的 TeX Live 版本。在老版本的环境下，后文中的例子可能无法得到预期的结果。

- W32TeX - [W32TeX](http://w32tex.org/index-zh.html) 是 Akira KAKUTO 针对 Windows 系统制作的 TeX 发行版，其中的宏包也专门为 Windows 系统筛选过。W32TeX 对日文的配置可能是最周全的，不过我没有亲身体验过。

- 其他 TeX 发行版 - [MiKTeX](http://miktex.org/) 是另一个重要的 TeX 发行版。MiKTeX 是 Windows 平台上高度集成的优秀发行版。不过因为打包和依赖脚本的差异，特别是涉及到 udpmap 的部分与 TeX Live 完全不同，MiKTeX 在我手头的一些设备上并不能很好地运行。

我的建议是，如果你的发行版足够新，那最好使用软件源里的 TeX Live；不然的话最好是使用 TUG 上的 TeX Live，包括 MacTeX。

## 最简示例

言归正传。接下来我们来写几个「Hello world」文档。当然，「Hello world」这几个字母里并没有日文字，所以文章的正文部分看起来会是这个样子：

```tex
\begin{document}
\LaTeX で日本語を書きましょう！
\end{document}
```

在进行下一步之前，有必要说一下关于编码的问题。请按以下规则，在保存文件的时候选择正确的编码：

- Unix-like 系统以及 Mac OS X 系统：总是保存为 UTF-8 编码

- Windows 系统：在测试 pLaTeX 的时候使用 ShiftJIS 编码，其他时候使用 UTF-8 编码

这样做的原因在于：在 Windows 系统上，pTeX 以 ShiftJIS 编码作为默认编码；在其他系统上以 UTF-8 编码作为默认编码。当然，你也可以在 Windows 上把 pLaTeX 的测试文档以 UTF-8 编码保存，但是在编译的时候你得加上 -kanji utf8 这样的参数。

### pLaTeX 以及 upLaTeX

这是最简单的情况，我们只需要加上 \documentclass 就好了。

```tex
\documentclass{article}
\begin{document}
\LaTeX で日本語を書きましょう！
\end{document}
```

以正确的编码将其保存为 hello-ptex.tex，然后运行 platex，UTF-8 编码的控制台会有类似于如下的输出：

```plaintext
$ platex hello-ptex.tex
This is e-pTeX, Version 3.14159265-p3.5-130605-2.6 (utf8.euc) (TeX Live 2014) (preloaded format=platex)
 restricted \write18 enabled.
entering extended mode
(./hello-ptex.tex
pLaTeX2e <2006/11/10> (based on LaTeX2e <2014/05/01> patch level 0)
Babel <3.9k> and hyphenation patterns for 79 languages loaded.
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/article.cls
Document Class: article 2007/10/19 v1.4h Standard LaTeX document class
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/size10.clo)) (./hello-ptex.aux
) [1] (./hello-ptex.aux) )
Output written on hello-ptex.dvi (1 page, 384 bytes).
Transcript written on hello-ptex.log.
```

Windows 系统上的输出与此类似，只不过在版本号后面的不是 utf8.euc 而是 sjis。

如你所见，输出结果是一个 DVI 文件。注意，此处**不要**使用 dvips 将其转换为 PostScript 文件，dvips 也许能够工作，但是 PS 文件却无法正常显示；请总是使用 dvipdfmx 将 pTeX/upTeX 输出的 DVI 文件转换为 PDF 文件。

因此，我们输入命令

```plaintext
$ dvipdfmx hello-ptex.dvi
hello-ptex.dvi -> hello-ptex.pdf
[1]
7636 bytes written
```

接下来，使用 PDF 阅读器打开得到的 PDF 文档，效果类似于下：

![输出效果](/images/pTeX-intro/hello-ptex.jpg)

如果觉得字体效果看起来稍有不同，也暂时不用担心，之后对此会有解释。但不论如何，你应该能看到日文字符，不然就说明有哪里错了。

类似的步骤在 upTeX 下同样奏效：

```plaintext
$ uplatex hello-ptex.tex
This is e-upTeX, Version 3.14159265-p3.5-u1.11-130605-2.6 (utf8.uptex) (TeX Live 2014) (preloaded format=uplatex)
 restricted \write18 enabled.
entering extended mode
(./hello-ptex.tex
pLaTeX2e <2011/05/07u00>+0 (based on LaTeX2e <2014/05/01> patch level 0)
Babel <3.9k> and hyphenation patterns for 79 languages loaded.
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/article.cls
Document Class: article 2007/10/19 v1.4h Standard LaTeX document class
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/size10.clo)) (./hello-ptex.aux
) [1] (./hello-ptex.aux) )
Output written on hello-ptex.dvi (1 page, 380 bytes).
Transcript written on hello-ptex.log.
$ dvipdfmx hello-ptex.dvi
hello-ptex.dvi -> hello-ptex.pdf
[1]
7638 bytes written
```

输出结果与之前应当完全相同。

多简单啊~

### XeLaTeX

如果你用 XeLaTeX 编译同样的代码，输出结果里就不会有日文字符。这里我们要多写一点代码。这里我会展示使用 [xeCJK](http://ctan.org/pkg/xecjk) 和 [ZXjatype](http://ctan.org/pkg/zxjatype) 的最简示例。这两个宏包在 TeX Live 里都有，你可以选择其一。

不管你用哪个宏包，你都得选择一个日文字体，不然的话日文字符就不会输出。

#### xeCJK

对于 xeCJK 来说，你得这么写：

```tex
\documentclass{article}
\usepackage{xeCJK}
\setCJKmainfont{ipaexm.ttf}
\begin{document}
\LaTeX で日本語を書きましょう！
\end{document}
```

将其以 UTF-8 编码保存为 hello-xetex.tex，之后运行 xelatex:

```plaintext
$ xelatex hello-xetex.tex
This is XeTeX, Version 3.14159265-2.6-0.99991 (TeX Live 2014) (preloaded format=xelatex)
 restricted \write18 enabled.
entering extended mode
(./hello-xetex.tex
LaTeX2e <2014/05/01>
Babel <3.9k> and hyphenation patterns for 79 languages loaded.
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/article.cls
Document Class: article 2007/10/19 v1.4h Standard LaTeX document class
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/size10.clo))
(/home/norbert/tl/2014/texmf-dist/tex/xelatex/xecjk/xeCJK.sty
(/home/norbert/tl/2014/texmf-dist/tex/latex/l3kernel/expl3.sty
.....
(./hello-xetex.aux) (/home/norbert/tl/2014/texmf-dist/tex/latex/tipa/t3cmr.fd)
[1] (./hello-xetex.aux) )
Output written on hello-xetex.pdf (1 page).
Transcript written on hello-xetex.log.
```

直接就能得到 PDF 文档。

#### ZXjatype

对于 ZXjatype 来说，你得这么写：

```tex
\documentclass{article}
\usepackage{zxjatype}
\setjamainfont{ipaexm.ttf}
\begin{document}
\LaTeX で日本語を書きましょう！
\end{document}
```

### pdfLaTeX

接下来，我们看看在 pdfLaTeX 底下怎么使用。pdfTeX 引擎可能是全球范围内使用最广泛的引擎了。这里，我们也将讨论两个宏包的使用方法：Werner Lemberg 的 [CJK](http://cjk.ffii.org/) 宏包和 Takayuki Yato 的 [BXcjkjatype](http://www.ctan.org/pkg/bxcjkjatype)。

#### CJK

译注：这里作者用了一个很别扭的方式来构建文档，已改用通常习惯的方式。

```tex
\documentclass{article}
\usepackage{CJKutf8}
\begin{document}
\begin{CJK*}{UTF8}{min}
\LaTeX で日本語を書きましょう！
\end{CJK*}
\end{document}
```

将其以 UTF-8 编码保存为 hello-cjk.tex，之后运行 pdflatex:

```plaintext
$ pdflatex hello-cjk.tex
This is pdfTeX, Version 3.14159265-2.6-1.40.15 (TeX Live 2014) (preloaded format=pdflatex)
 restricted \write18 enabled.
entering extended mode
(./hello-cjk.tex
LaTeX2e <2014/05/01>
Babel <3.9k> and hyphenation patterns for 79 languages loaded.
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/article.cls
Document Class: article 2007/10/19 v1.4h Standard LaTeX document class
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/size10.clo))
(/home/norbert/tl/2014/texmf-dist/tex/latex/cjk/texinput/CJKutf8.sty
...
t/fonts/type1/wadalab/dmj/dmjkk.pfb></home/norbert/tl/2014/texmf-dist/fonts/typ
e1/wadalab/dmj/dmjsy.pfb>
Output written on hello-cjk.pdf (1 page, 29574 bytes).
Transcript written on hello-cjk.log.
```

如果你仔细观察的话，你会发现：LaTeX 几个字母后的空距和之前的输出不大一样。尽管代码看起来有些麻烦，不过，如果你只是想在非日文的文档里嵌入一小段日文，这仍然是个不错的方案。

译者注：实际上，用下面的代码，也能得到正确的 CJK-western 空距。这应该是原作者不熟悉 CJK 导致的。

```tex
\documentclass{article}
\usepackage{CJKutf8}
\usepackage{CJKspace}
\begin{document}
\begin{CJK*}{UTF8}{min}
\LaTeX{} で日本語を書きましょう！
\end{CJK*}
\end{document}
```

#### BXcjkjatype

如果上面的代码看起来十分冗长，那么 BXcjkjatype 则提供了一种更简洁也更好的封装。这里只需要用下面简单的代码就能得到输出了：

```tex
\documentclass{article}
\usepackage[whole]{bxcjkjatype}
\begin{document}
\LaTeX で日本語を書きましょう！
\end{document}
```

输出结果和之前 CJK 方式的结果类似。不过，嵌入的字体和之前有所不同。BXcjkjatype 默认使用 IPAex 字体。使用此方式请注意：不要在文档中使用任何非 ASCII 字符。

### LuaLaTeX

LuaTeX 是一个嵌入了 Lua 解释器的新的 TeX 引擎，这使得我们可以使用 Lua 语言来控制和调整许多 TeX 内部的行为。尽管它还不能完全取代 pdfTeX，但是至少拿来输出文档还是可以的。一些日本 TeX 同好为其开发了 [LuaTeX-ja](http://ctan.org/pkg/luatexja) 宏包，用以在 LuaTeX 里使用日文。最简示例是这样的：

```tex
\documentclass{article}
\usepackage{luatexja}
\begin{document}
\LaTeX で日本語を書きましょう！
\end{document}
```

运行 lualatex 之后，你可能要等上不少时间。这是因为第一次运行 LuaLaTeX 的时候，系统需要刷新字体，耐心等待就好。最终在控制台终端上，你大概会得到下面的输出内容：

```plaintext
$ lualatex hello-luatexja.tex
This is LuaTeX, Version beta-0.79.1 (TeX Live 2014) (rev 4971)
 restricted \write18 enabled.
(./hello-luatexja.tex
LaTeX2e <2014/05/01>
Babel <3.9k> and hyphenation patterns for 79 languages loaded.
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/article.cls
Document Class: article 2007/10/19 v1.4h Standard LaTeX document class
(/home/norbert/tl/2014/texmf-dist/tex/latex/base/size10.clo))
(/home/norbert/tl/2014/texmf-dist/tex/luatex/luatexja/luatexja.sty
...
 1923 words of node memory still in use:
   6 hlist, 1 vlist, 3 rule, 3 glue, 10 kern, 1 glyph, 241 attribute, 299 glue_s
pec, 16 attribute_list, 1 write nodes
   avail lists: 1:1,2:888,3:5,4:40,5:4,6:25,7:3,9:12
<</home/norbert/tl/2014/texmf-dist/fonts/type1/public/amsfonts/cm/cmr10.pfb><</h
ome/norbert/tl/2014/texmf-dist/fonts/type1/public/amsfonts/cm/cmr7.pfb>
Output written on hello-luatexja.pdf (1 page, 17058 bytes).
Transcript written on hello-luatexja.log.
```

输出结果同样取决于你系统里的默认字体，但和之前的截图应该差不多。

## 总结

文章介绍了在不同 TeX 引擎和宏包下的最简日文示例。如果你能够运行这些示例，那么更复杂的文档你也应该能够运行，你的 TeX 系统完全可以进行日文排版。

不过，仍然还有不少问题需要讨论。比如：字体选择，插图，多语种混排以及非 ASCII 字符的使用。这些我们之后再讨论。

## 译者续

在 pdfLaTeX 编译的情况下，还有一种排版 CJK 文字的方法。可以使用刘海洋前辈的 [zhmCJK](http://www.ctan.org/tex-archive/language/chinese/zhmcjk) 宏包。这个宏包因为一些原因暂时没有收录到 TeX Live 中，不过，这系列文章的作者正好是 TeX Live 的开发者之一，我最近正在和他沟通这件事情。

zhmCJK 宏包提供了类似于 xeCJK 宏包的接口，相应的功能也完全类似。因此可以看做是不能使用 XeLaTeX 而必须使用 pdfLaTeX 的情况下的一个替代。对应于文章中 xeCJK 的例子，最简示例是：

```tex
\documentclass{article}
\usepackage{zhmCJK}
\setCJKmainfont{ipaexm.ttf}
\begin{document}
\LaTeX{} で日本語を書きましょう！
\end{document}
```

LaTeX 新手可以将宏包内的文件解压，释放到和你的 .tex 文件同目录下；有经验的 LaTeX 使用者，可以按照宏包文档，将宏包文件放在 TEXMF 中的合适位置，然后刷新 TeX 系统。

另外，正如刘海洋前辈和李清前辈（他们是当前 xeCJK 宏包的维护者）[所言](http://www.zhihu.com/question/26705259)，xeCJK 虽然取名如此，但实际上只是对中文的支持比较完善。因此用 xeCJK 来排版日文在细节上还是会有一些问题的，特别是对日文排版规则的处理。此外，原作者提到的 ZXjatype 宏包，实际上是在 xeCJK 基础上再开发的结果。由于 xeCJK 的局限，ZXjatype 也不可避免地会有一些问题。