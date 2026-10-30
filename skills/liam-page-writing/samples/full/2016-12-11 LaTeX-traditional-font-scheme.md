---
title: "LaTeX 字体机制简介"
url: https://liam.page/2016/12/11/LaTeX-traditional-font-scheme/
date: 2016-12-11
categories: ["LaTeX"]
tags: ["Font", "Scheme"]
---

一直有很多人闹不清 .def, .fd, .pfb 之类文件的作用，这里正好看到 [egreg](http://tex.stackexchange.com/users/4427/egreg) 的回答，感觉很好，就翻译过来。

原文地址：[http://tex.stackexchange.com/a/119501/38350](http://tex.stackexchange.com/a/119501/38350)

## .def 文件

t1enc.def 之类的 <encoding>enc.def 文件定义了字符形状（glyph）与编码的对应关系，LaTeX 读入这些文件之后，才能在相应的编码下正确调用字符形状来排版。在任意时刻，都有一个*当前的字体编码*。诸如 \"{o} 的命令，在不同编码下的效果是不一样的。例如，在 OT1 编码下（或是其它不包含字符形状 ö 的编码），\"{o} 会被翻译成 \accent"7F o；在 T1 编码下，则是 \char"F6。

当加载 fontenc 宏包的时候，LaTeX 就会读入 <encoding>enc.def 文件。具体读入的文件，由 fontenc 宏包的参数确定。每次读入 <encoding>enc.def 文件就改变一次当前字体编码。和大多数宏包不同，fontenc 宏包可以加载多次，以便根据不同的字体指定不同的编码。有一些字体相关的宏包，会在内部隐式地调用 fontenc 宏包（比如 textcomp 宏包）。在 \begin{document} 处的字体编码，则是最后一次传给 fontenc 宏包的参数。

除了 <encoding>enc.def 类型的文件，还有其他一些 .def 文件。不过这些文件就和字体没关系了。

## .fd 文件

当 LaTeX 遇到 \fontfamily{<family>}\selectfont 的时候（可能隐式地调用，比如在 \ttfamily 之类的字体声明处，以及在 \textsf 之类的字体命令处），LaTeX 会在内部表中查询是否有已知的，由 \DeclareFontFamily{<encoding>}{<family>}{<tokens>} 定义的组合

```tex
<encoding>+<family>
```

这里，<encoding> 就是当前的字体编码。

假设当前的字体编码是 T1，然后希望使用 Palatino 字族（ppl），但 T1+ppl 的组合没有定义（也就是 \T1+ppl 命令未定义，对的，命令中间有个加号），那么 LaTeX 就会去寻找 t1ppl.fd 或者大写版本的 T1ppl.fd 文件。

如果二者都找不到，那么 LaTeX 就会输出警告，告诉用户「当前的字体我找不到，不过我会用另外的字体来替代」。不过，这种替代，不会改变当前的字体编码。

.fd 文件总是以 \DeclareFontFamily 声明开头，然后跟着若干个 \DeclareFontShape 命令。这些命令组合在一起，对应了 <encoding>+<family> 的组合。[fntguide.pdf](http://texdoc.net/texmf-dist/doc/latex/base/fntguide.pdf) 里有更详细的介绍。

当然，你也可以在导言区里写 \DeclareFontFamily 或者 \DeclareFontShape 这样的命令。\DeclareFontShape 必须与紧跟的 \DeclareFontFamily 对应。这些声明会对应字体四个维度的属性声明，并对应一个字体尺寸文件（font metric file）。在我们的例子中

```tex
\usefont{T1}{ppl}{b}{up}
```

会指向 pplb8t 这个字体尺寸。具体来说，字体尺寸文件又两种：.vf 文件或者 .tfm 文件。如果存在 pplb8t.vf 文件，那么 TeX 会优先加载它，否则就会加载 pplb8t.tfm 文件。二者必需有一个，否则就会报错。

在 \DeclareFontShape 命令中，你可以设定字体替换等规则；如果 LaTeX 没有找到合适的字体替换规则，那么就会使用默认字体去替换。如果 .fd 文件里，或者导言区中的，\DeclareFontShape 写错了，也会导致错误（Corrupt NFSS tables）。

接下来，假设 TeX 找到了 pplb8t.vf 或者 pplb8t.tfm 文件。

## .vf 文件

字体尺寸文件可以是*虚拟的*，pplb8t 正是这种情况。.vf 尺寸文件中有字符边界框、意大利体修正、铅空、连字等信息，还有一些关于从其它文件中（虚拟的或者实际存在的）选择实际字符形状的信息。在本例中，pplb8t.vf 选择了一个实际存在的字符形状 pplb8r

```tex
(MAPFONT D 0
   (FONTNAME pplb8r)
   (FONTCHECKSUM O 25012244013)
   (FONTAT R 1.0)
   (FONTDSIZE R 10.0)
   )
```

并按照 T1 字体编码重新对字符形状做了排序。例如，在 pplb8t.vf 的 "F7 位上 （八进制  `367），有如下声明

```tex
(CHARACTER O 367
   (CHARWD R 0.832996)
   (CHARHT R 0.485498)
   (CHARDP R 0.011493)
   (MAP
      (SETCHAR O 234)
      )
   )
```

这是说，字符形状 œ（你在 LaTeX 里可以用 \oe 输出它）实际会在 pplb8r 的以八进制计算的第  `234 个位置（十六进制："9C）中取得，不过实际的用户是不会想关心它的。这里也包含了关于字符形状的尺寸信息：宽度 8.32996pt、高度 4.85498pt、深度 0.11493pt，并且意大利体修正为 0（这是在字体大小为 10pt 时候的值，否则需要按比例做额外的换算）。

## .tfm 文件

.tfm 文件（在本例中 pplb8r.tfm 文件必须存在）中的内容格式和 .vf 文件的格式完全相同，不过，它可以指向其他字体尺寸文件。

## 打住

实际上，TeX 引擎关心的东西到这里就结束了：根据字符尺寸将字符排版并按页输出。打印或预览的驱动才会实际去关注字符形状。不过，对 pdfTeX 来说，它也需要储存所有的字符形状（译注：因为要直接输出 PDF 文件，必须知道字符形状）。

## .map 文件

粗体的字形 œ 最终从 pplb8r 里取得。因此 pdfTeX 会读取已经加载的 .map 文件（默认是 pdftex.map），在其中查找以 pplb8r 开头的条目

```tex
pplb8r URWPalladioL-Bold " TeXBase1Encoding ReEncodeFont " <8r.enc <uplb8a.pfb
```

于是，pdfTeX 会读取 Type1 字体文件 uplb8a.pfb（如果已经读取过了就不会再次读取了），然后，pdfTeX 会对字体文件*重新编码*。这是因为 .pfb 文件是以 Adobe Standard Encoding 编码保存的，并且有一些字符形状在这种情况下是隐藏起来的。 于是，驱动（译注：在 pdfTeX 的情况下，驱动就是它自己）会根据 8r 编码（与 T1 类似，但不推荐在实际文稿中使用）重新排布字符形状的顺序。此时，字符形状 œ 会被保存在 "F7 位置（而不是 Adobe Standard Encoding 中的 "FA）。此外，字符形状 ö 不在 Adobe Standard Encoding 当中，不过它在 .pfb 文件中以未编码的形式存在着；在 8r 编码中，它被保存在 "F6 位置。

我们需要的是 pplb8a，为什么最后读取的是 uplb8a 呢？这是因为，字体最终是由 URW 提供的免费版本。当然，实际用户是不会关注这个的。

## .pfb 文件

.pfb 文件包含了字符的形状，它们决定了字符在打印（或者预览）中是怎样呈现的。这些文件不会被用户直接调取，而是被引擎或者驱动程序调用。当然，也有 .pfa 文件，它和 .pfb 文件储存的信息完全相同，只不过它是用可见的 ASCII 码字符来储存信息的，因此它会比相应的 .pfb 文件要大出不少。

译注：在现代的 TeX 发行版中，有名为 tex-font-cheatsheet.pdf 的文件。你可以在系统命令行中执行 texdoc tex-font-cheatsheet 打开它。有惊喜！

对于本篇的捐助，将用于支持 TeX 在中文界的发展。