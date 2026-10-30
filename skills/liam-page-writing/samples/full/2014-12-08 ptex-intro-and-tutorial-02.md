---
title: "日文 LaTeX 系统介绍 - 字符与编码"
url: https://liam.page/2014/12/08/ptex-intro-and-tutorial-02/
date: 2014-12-08
categories: ["LaTeX"]
tags: ["pTeX", "Encoding"]
---

本文为译文，原文载于[这里](http://www.preining.info/blog/2014/12/writing-japanese-in-latex-part-2-characters-and-encodings/)。欢迎关注本系列的文章。

[上一篇文章](http://www.preining.info/blog/2014/12/writing-japanese-in-latex-part-1-introduction/)（[译文](http://liam0205.me/2014/12/07/ptex-intro-and-tutorial-01/)）简单介绍了在 LaTeX 中排版日文的一些情况，今次我们会探讨一些关于字符和编码的技术细节。

![](/images/pTeX-intro/nihongo-latex.jpg)

这篇文章我们将讨论字符集和编码。在书写欧洲文字的时候，人们就已经需要用到非 ASCII 字符了；诸如日文这样的有成千上万个表义字符的书写系统，其字符数量更是远超 ASCII 所能涵盖的数量。同时我们也会琢磨一下为什么在日文文档里的转义字符为什么不是反斜线（\），而是日本货币标志（￥）。

首先，我并不精于此道。因此，文中讲解的内容十分简单，并且不可避免地会有谬误。如有发现请指出。

## 字符集和编码

对于 ASCII 来说，这事儿很简单。比如，在计算机中表示「A」这个字母，我们只需要用 65 这个十进制数来表示即可。并且，65 对应的二进制数，也正是字母「A」在计算机中的样子。因此，对于 ASCII 来说，它既是字符集又是编码。

对于非 ASCII 字符来说，这事儿就变得复杂起来了。

对于欧洲的字符来说可能还好。比如常用的 Latin1 字符集中，字符「Ö」的码位是 214。由于一个字节可以表示 256 个不同的值，所以勉强能装下整个 Latin1 字符集。

但是对于成千上万的日文汉字 (Kanji) 来说，这就不行了。首先需要有一个统一的方式将字形 (glyph) 编号，每个字形对应一个 ID (数字)。然后再寻找一个合适的方式去编码这些字形。

### 字符集标准

- **JIS** - 实践中有一些日本工业标准 ([Japanese Industrial Standards](http://en.wikipedia.org/wiki/Japanese_Industrial_Standard))。比如，JIS X 0201 在 ASCII 字符集的基础上，增加了 64 个半宽 (half-width) 的片假名；又比如，[JIS X 0208](http://en.wikipedia.org/wiki/JIS_X_0208) 是最常见的汉字字符集，它包含 6879 个字符，其中有 6355 个汉字，另有 524 个其他类型的字符。

- **UCS** - 通用字符集 ([Universal Character Set](http://zh.wikipedia.org/wiki/%E9%80%9A%E7%94%A8%E5%AD%97%E7%AC%A6%E9%9B%86)) 中包含了近十万个抽象字符，它试图将有史以来所有的字符都包含进来。涉及到日语的部分有一些特殊，对应的标准是统一汉码 ([Han Unification](http://en.wikipedia.org/wiki/Han_unification))，这个字符集将中日韩表意相同的形近字统一映射到一个码位上。

### 编码

有了字符集标准，接下来需要考虑如何在计算机中用二进制和字节表示这些字符。编码和字符集是两个不同的概念，但因为总是一起提及，所以经常有人混淆。

对于现代计算机和 TeX 来说，有以下一些常见的编码。其中前三个编码了 JIS 字符集；最后一个编码了 Unicode 字符集。

- SJIS ([Shift JIS](http://zh.wikipedia.org/wiki/Shift_JIS)) - SJIS 编码了 JIS X 0201 和 JIS X 0208 两个字符集。它很好地兼容了 ASCII 和 JIS X 0201，这使得它在老的计算机上工作正常；但是它也有一些奇怪的性质，并因此在一些通用解析器上工作不正常。

- JIS X 0202 - 通称 JIS 的编码标准，它编码了 JIS X 0208。这个编码在诸如电子邮件的 7-bit 信道上的传输性能良好；老的 Emacs 也将其当做内部编码。

- EUC(-JP) Extanded Unix Code - 实际上是符合 ISO 2022 标准的字符集的编码族。这种编码在日本的 Unix-affine 计算机上流行多年。

- [UTF-8](http://en.wikipedia.org/wiki/UTF-8) - 编码了 UCS 字符集，是 [Unicode 标准](http://en.wikipedia.org/wiki/Unicode)的一部分，现行于几乎所有现代计算机操作系统上。

最后我们来看一个例子。

```plaintext
Language
Ä á
日本語
ひらがな
```

注意观察他们在不同编码规则情况下对应的十六进制数据。

**UTF-8**

第一行的「Language」在 UTF-8 编码中对应的十六进制与 ASCII 完全相同，用一个字节表示一个字符；第二行的注音字母则用两个字节来编码，其中 0x20 是单字节的空格；第三行的日文汉字和第四行的平假名都用三个字符来编码。

```plaintext
4c 61 6e 67 75 61 67 65
c3 84 20 c3 a1
e6 97 a5 e6 9c ac e8 aa 9e
e3 81 b2 e3 82 89 e3 81 8c e3 81 aa
```

**SJIS**

SJIS 编码就有点意思了。首先，第一行保持相同，与 ASCII 兼容。第二行的「Ä」并不在字符集当中，于是 SJIS 把它当做是「"A」，编码成「0x22 0x41」；另一方面，「á」在字符集当中，SJIS 用三个字节将它编码成「0x81 0x4c 0x61」。注意第一行的编码，「0x4c」是字母「L」，「0x61」是字母「a」。它们连在一起与「á」的第二和第三个字节完全相同。这样「La」的编码就出现了歧义，一些解析器就无法正常工作了。

接下来的日文汉字和平假名分别用两个字节来编码。

```plaintext
4c 61 6e 67 75 61 67 65
22 41 20 81 4c 61
93 fa 96 7b 8c ea
82 d0 82 e7 82 aa 82 c8
```

**ISO2022-JP**

同样由于「Ä」不在字符集当中，ISO2022-JP 把它当做是「"A」来进行编码；但「á」却花了 9 个字节来编码。同时汉字和平假名的编码方式也是不固定的。

```plaintext
4c 61 6e 67 75 61 67 65
22 41 20 1b 24 42 21 2d 1b 28 42 61
1b 24 42 46 7c 4b 5c 38 6c 1b 28 42
1b 24 42 24 52 24 69 24 2c 24 4a 1b 28 42
```

**EUC-JP**

EUC-JP 编码对应的字符集是 JIS X 0212，比之前的 JIS X 0201 和 JIS X 0208 大得多。这次「Ä」能够正确编码了。两个变音的拉丁字符被分别编码成三个字节；汉字和假名则是两个字节。

```plaintext
4c 61 6e 67 75 61 67 65
8f aa a3 20 8f ab a1
c6 fc cb dc b8 ec
a4 d2 a4 e9 a4 ac a4 ca
```

从这里可以看到，UTF-8 编码汉字和假名需要用到三个字节。因此用 UTF-8 编码来处理文档，得到的文件体积要大上不少。同时，旧有的编码沿用多年，惯性很大。因此 UTF-8 编码在日本用了很多年才得以推广。

## 我的计算机在用什么编码？

这取决于你的计算机操作系统。

- Linux: 大多数情况下，Linux 系统使用 UTF-8 编码。在终端里执行 locale 命令，输出结果中的 LC_CTYPE 字段里可以看到系统语言和使用编码的信息。比如，en_US.utf8。

- Mac: 在 OS X 之前，Mac 使用的是苹果公司修改的 SJIS 版本，其名为 MacJapanese。从 OS X 开始，Mac 使用的是 UTF-8。

- Windows: 老版本使用 M$ 家修改的 SJIS 版本，其名为 CP932 （代码页 932，简体中文系统则是 CP936)。不过，新版本的 Windows 也有可能使用 UTF-8。

- BSD: 据我所知，用的是 UTF-8。

## 小结

在 LaTeX 里些日文文档之前，你先要确定你使用的是什么编码。不同的 TeX 引擎对编码支持的情况不同，你应该根据需要选择合适的编码和 TeX 引擎。目前被 TeX 引擎支持最好的编码（译注：原文是字符集）是 UTF-8。新版本的 pTeX 接受 UTF-8 编码；upTeX, XeTeX, LuaTeX 原生支持 UTF-8 编码；使用 BXcjkjatype 时，也应当使用 UTF-8 编码。

不过，不少老版本的文档使用 SJIS 编码。此时你应该使用 pTeX，用 pLaTeX 来编译；或者将他们转换为 UTF-8 编码后使用。

## 关于 \ 和 ￥

以下内容来自维基百科 [ShiftJIS](http://en.wikipedia.org/wiki/Shift_JIS) 词条：

The single-byte characters 0x00 to 0x7F match the ASCII encoding, except for a yen sign (U+00A5) at 0x5C and an overline (U+203E) at 0x7E in place of the ASCII character set’s backslash and tilde respectively.

也就是说，在 SJIS 中，符号「¥」的编码与 ASCII 里的反斜线「\」的编码相同，都是 0x5C；与此同时，TeX 将 0x5C 当做是转义符。于是，在使用 SJIS 编码的计算机里，TeX 控制序列就都变成了类似 ¥hfill 的样子。

下一篇文章，我们将正式开始编写 LaTeX 代码！

## 译者续

SJIS 在日本的地位和 GBK 在中国的地位差不多。在早期的 Windows 系统里，使用的 CP936 与 GBK 几乎相同。同时，中文 LaTeX 早期的支持方式也都是基于 GBK 编码的。

为了避免不必要的麻烦，我们的口号是：「**珍爱生命，远离 GBK**」。