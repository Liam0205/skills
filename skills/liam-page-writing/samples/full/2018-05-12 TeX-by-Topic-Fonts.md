---
title: "TeX 主题选讲：字体"
url: https://liam.page/2018/05/12/TeX-by-Topic-Fonts/
date: 2018-05-12
categories: ["LaTeX"]
tags: ["Fonts", "Kerning", "Ligature"]
---

此篇基本上是译文，原文是 Victor Eijkhout 所著的《TeX by Topic》的第四章。译文项目参见：[CTeX-org/tex-by-topic-cn](https://github.com/CTeX-org/tex-by-topic-cn/releases/latest)。转载请保留本段文字，尊重原作者和译者版权。由于原著使用 GFDL，故而本文也被传染地同样使用 GFDL 许可，而不是本站默认的 BY-NC-SA 4.0 许可。

在文本模式下，TeX 会从「当前字体」中取用字符。本章讨论 TeX 是如何识别不同**字体**的，以及字体都有哪些属性。

所涉命令编目：

- \font： 该命令可声明一个用于指定字体的控制序列。

- \fontname： 字体的外部名字。

- \nullfont： 在特殊情况下，TeX 会使用空字体。这是空字体的名字。

- \hyphenchar： 字体中连字符的序号。

- \defaulthyphenchar： 字体装载时 \hyphenchar 的默认值。在 plain TeX 中，默认是 `-。

- \fontdimen： 该命令可访问多种字体参数。

- \/： 倾斜校正原语。

- \noboundary： 忽略隐式边界字符。

## 字体

在 TeX 语境下，字体（font）这一术语指的是保存在外部文件中的一系列字符的集合。TeX 在运行时，会决定从哪一个字体中选取字符。而具体决策方式在文本模式和数学模式中又是不同的。

TeX 处理普通文本时会从「当前字体」中选取字符。通过字体声明，TeX 会将外部字体文件与字体选择命令联系起来。例如，下列声明会使 TeX 装载名为 myfont10.tfm 的字体文件。

```tex
\font\MyFont=myfont10
```

此后，通过下列命令，我们就可以选择使用该文件定义的字体了。

```tex
\MyFont
```

当前字体的状态是可查的：下列命令会产生当前字体对应的控制序列。

```tex
\the\font
```

数学模式下，TeX 会忽略当前字体；转而考察当前「字族」，其中有三个字体：正文字体（text style），角标字体（script style），双重角标字体（scriptscript style）。

从不同物理字体文件中分别选取部分字符，可以组成的「虚拟字体」。在 TeX 看来，这种虚拟字体就像是真实字体一样。

## 字体声明

TeX 或 IniTeX 在执行时，必然在某处会建立内部字体选择命令与外部字体文件名的联系。**font** 字体声明的语法如下：

```tex
\font<control sequence><equals><file name><at clause>
```

这里，<at clause> 指的是：

![](/uploads/images/LaTeX/at-clause.png)

注意，字体声明仅在当前分组内生效。

用户可以通过 <at clause> 指定字体的放大版本。<at clause> 有两种形式：如果指定缩放比例 scaled $f$，则 TeX 会将该字体中的所有字符尺寸倍乘 $f/1000$；如果指定目标大小 at $f$pt，而字体本身的设计大小是 $d$pt，则 TeX 会将该字体中的所有字符尺寸倍乘 $f/d$。注意，<at clause> 不会影响 TeX 从外部字体文件（.tfm 文件）中读入字体的过程；它只是在尺寸上乘了一个固定的倍数。

这样声明字体后，使用定义得到的控制序列会将当前字体设置为控制序列相应的字体。

### 字体与 tfm 文件

TeX 所需的外部字体文件是 tfm 文件（TeX 字体尺寸文件，TeX Font Metrics File），这些文件不受 \font 声明中 <at clause> 的影响。如果 tfm 事先已装载好（比如在构造格式文件时由 IniTeX 装载），则再次声明同一字体时，不依赖且无需重复载入 tfm 文件。

字体本身的设计大小由字体尺寸文件给出。例如，字体 cmr10 的设计大小是 10 点（point）。但实际上，字体中没有多少字符大小是 10 点：左右圆括号恰好是 10 点，但大写字母明显会小一点。

### 查询当前字体及字体名

前文提到过，当前字体的字体选择命令可通过 \the\font 得到。这是下列语法的一个特例。

```tex
\the<font>
```

此处，<font> 表示：

![](/uploads/images/LaTeX/font.png)

<fontdef token> 是由 \font 定义的控制序列，或是预定义的 \nullfont。至于 <family member> 的概念，则只与数学模式有关。

此外，外部字体文件名可用以下方式取得：

```tex
\fontname<font>
```

该命令以字符串的形式（其中的字符记号分类码均为 12，而空格记号的分类码为 10）给出当前字体的文件名；若有相应的 <at clause> 则也一并给出。

例如，在如下声明之后，

```tex
\font\tenroman=cmr10 \tenroman
```

\the\font 和 \the\tenroman 会给出 \tenroman；\fontname\tenroman 则给出 cmr10。

### \nullfont

TeX 将没有任何字符的字体与定义为 \nullfont。如果没有指定任何字体，或是在数学模式中某一所需的字族成员未定义，则 TeX 会从空字体中取用字符。该控制序列属于 <fontdef token>：它与其它字体选择命令的行为类似；但不与任何外部 tfm 文件相关联。

## 字体信息

TeX 执行时所需的主要字体信息包括尺寸与字符。TeX 会在字体尺寸文件中寻找这些信息，这些文件的扩展名通常是 .tfm。此类文件包含

- 全局信息：主要是 \fontdiem 参数，还有其他一些信息

- 字符的尺寸以及倾斜校正（italic corrections）

- 字符的连字（ligature）及挤压（kerning）指令

字体的设计大小也由 tfm 文件指定。

### 字体尺寸参数

文本字体至少得有 7 个 \fontdimen 参数来描述**字体尺寸**（对于未指定的参数，TeX 会以零作为默认值）；数学符号以及数学扩展字体还有更多的参数。文本字体的 7 个参数描述如下：

- 每点倾斜（slant per point）；该参数用于确定重音符号正确的水平位置。

- 词间空距（interword space）：如果用户没有显式设定 \spaceskip，则该参数会被当做词间空距的默认值。

- 词间拉伸（interword stretch）：该参数是词间距离的拉伸值部分。

- 词间收缩（interword shrink）：该参数是词间距离的收缩值部分。

- x-高度（x-height）：该参数是 TeX 内部单位（<internal unit>）ex 的值，通常是小写字母「x」的高度。

- 方块铅空宽度（quad width）：该参数是 TeX 内部单位 em 的值，它大约是大写字母「M」的宽度。

- 额外空距（extra space）：如果用户没有显式设定 \xspaceskip，则该参数是在句子末尾处加在词间空距之上的额外空距（当 \spacefactor${}\geqslant2000$）。

译注：英文单词「quad」是传统铅印术中的术语，它来自意大利语单词「quadratone」，意思是「大方块」。

第 1 个和第 5 个参数纯粹是字体的信息，因此改变它们没什么意义。其余参数则可以用来调整相关空距；后续章节有关于第 2, 3, 4, 7 个参数的相关示例。

字体尺寸参数可用字体赋值语句（<font assignment>）来修改，这种赋值语句属于全局赋值语句（<global assignment>）：

```tex
\fontdimen<number><font><equals><dimen>
```

<font> 的定义可见上文。

### 字符挤压

通常，每个字符的边界盒子（bounding box）彼此邻接。但对于部分字符组合来说，它们之间的距离应该比边界盒子邻接的情况更近一些。这种情况称为**字符挤压**（**kerning**）。对于字体来说，字符挤压的设计与字符形状的设计同等重要。

举个例子：

![](/uploads/images/LaTeX/kerning.png)

在 TeX 中，字符挤压由 tfm 文件中的字体信息控制，因此不受用户的影响。不过，tfm 文件是可以修改的。

\kern 命令与字符挤压现象没什么关系；它将在后续章节中介绍。

### 倾斜校正

TeX 原语 \/ 会向前一个字符或连字后面插入**倾斜校正**（**italic correction**）。考虑到**边界盒子**（**bounding box**）的定义，这种修正是很有必要的：边界盒子总是有竖直的边，并且 TeX 将两条竖直边之间的距离当做是字符的宽度。然而，为了在斜体或意大利体中得到恰当的空距，字符会显著突出其边界盒子。当这种向外突出的字符后边紧跟着一个非倾斜的字符时，就需要插入倾斜校正。

对比以下两例：

![](/uploads/images/LaTeX/italic_correction.png)

这里，有倾斜校正的版本的代码如下。

```tex
{\italic TeX\/} has
```

各个字符倾斜校正的具体值由字体尺寸文件中的字体信息决定；对于 Computer Modern 字体来说，该值大约是字符向外突出边界盒子距离的一半。倾斜校正与每点倾斜（\fontdimen1）是不一样的；后者仅用于放置重音符号。

倾斜校正仅在 TeX 刚处理完一个字符或者连字时才会插入其后。因此，由于在下例中，在遇到倾斜校正原语之前 TeX 刚处理完行间胶水（而不是字符或者连字），下面对罗马字族文本做的倾斜校正是不会生效的。

```tex
{\italic Some text {\/\roman not} emphasized}
```

### 连字

将字符序列替换为**连字**（*ligatures*）的过程是由字体 tfm 文件中的信息控制的。连字由字符（<character>）命令组成：在某些字体里，诸如 fi 的字符序列会替换为「fi」。

传统上，还有其它的连字，比如 ff, ffi, fl 以及 ffl；在更古老的字体里，可能还有 ft 以及 st，以及类似 fl 的连字：fk 和 fb。

在 TeX 中，连字可由显式字符记号、\char 命令以及 <chardef token> 组成。例如，如果字体里有这样的连字定义，\charf\chari 会被替换成连字「fi」。

我们有多种方式来限制不希望出现的连字。例如 halflife 中不希望出现的连字可以这样避免：

```tex
half{}life, half{l}ife, half\/life, 以及 half\hbox{}life
```

注意，使用倾斜校正原语避免不希望出现的连字的方案与其它方案的机理不完全一样。

### 边界连字（Boundary ligatures）

在 TeX3 中还有单词边界的概念：每个单词都由左右两个边界字符界定。这样的设定使 TeX 能够实现一些语言中特殊的现象，例如在希腊语中位于词尾的西格玛（$\sigma$）和位于其他位置的西格玛是不一样的。在单词的前后添加 \noboundary 命令，可以抑制相应的边界连字机制。

译注：这里指的是通过边界连字来实现一些语言中特殊的现象。

大致上，TeX 3 的连字机制比 TeX 2 要复杂得多。