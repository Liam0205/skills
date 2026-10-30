---
title: "用 minted 构建 example 环境"
url: https://liam.page/2020/04/29/combine-minted-and-its-layout-as-example/
date: 2020-04-29
categories: ["LaTeX"]
tags: ["minted", "example"]
---

在 LaTeX 中排版代码的环境有很多，在普通用户里最出名的当属 listings 和 minted。前者在纯粹的 LaTeX 环境中就能使用，后者则需要开启 --shell-escape 标记调用外部 Pygmentize 来美化代码。对于 listings 来说，配置一个美观的输出还是比较麻烦的，于是越来越多的人开始使用 minted。

此次要解决的问题，是构造一个 example 环境。其中包含 LaTeX 代码，然后输出分两部分。左侧是代码本身，用 minted 排版输出；右侧是代码的输出效果。

## 分析

因为我们要「一码两用」，所以就必然牵扯到将代码暂存，然后由两部分输出代码分别调用的问题。在 TeX 里暂存代码，要不然暂存到一个文件当中，要不然暂存到一个宏当中。考虑到我们之后要使用 minted 将代码原样输出，若是将代码暂存到一个宏当中，之后的展开控制会变得非常复杂。所以方案基本就确定了：我们要将代码暂存到外部文件当中。

代码既存，我们接下来就要考虑输出。对于 minted 来说，它有 \inputminted 可读入外部文件进行排版。对于输出代码效果来说，因为暂存的代码本就是 LaTeX 的代码，所以只需 \input 进来即可。我们需要做的工作，就只有将两部分输出安排的明明白白。

## 暂存代码

minted 宏包会将需要排版的代码内容交给 Pygmentize 来美化，而 Pygmentize 美化的输入当然也是文件。所以，这样推论下去，minted 宏包必然会将需要排版的代码内容临时输出到文件。因此，我们要将代码暂存到外部文件，就可以借助 minted 宏包已经实现的内部宏来实现。我们现在需要找到这段代码，然后做可能必要的修改。

首先打开 minted.sty，找到定义 minted 环境的地方。

```tex
\ifthenelse{\boolean{minted@draft}}%
  {\newenvironment{minted}[2][]
    {\VerbatimEnvironment
      \minted@configlang{#2}%
      \setkeys{minted@opt@cmd}{#1}%
      \minted@fvset
      \minted@langlinenoson
      \begin{Verbatim}}%
    {\end{Verbatim}%
      \minted@langlinenosoff}}%
  {\newenvironment{minted}[2][]
    {\VerbatimEnvironment
      \let\FVB@VerbatimOut\minted@FVB@VerbatimOut
      \let\FVE@VerbatimOut\minted@FVE@VerbatimOut
      \minted@configlang{#2}%
      \setkeys{minted@opt@cmd}{#1}%
      \minted@fvset
      \begin{VerbatimOut}[codes={\catcode`\^^I=12},firstline,lastline]{\minted@jobname.pyg}}%
    {\end{VerbatimOut}%
        \minted@langlinenoson
        \minted@pygmentize{\minted@lang}%
        \minted@langlinenosoff}}
```

我们显然应该看非 draft 的版本。注意到环境定义前半截的最后有：

```tex
\begin{VerbatimOut}[codes={\catcode`\^^I=12},firstline,lastline]{\minted@jobname.pyg}}
```

\minted@jobname.pyg 这显然是一个外部文件，而且，看文件扩展名这应该是一个已经经由 Pygmentize 美化好的结果了。因此，将代码暂存外部的实现一定在这之前。从命名来看，下列两行代码就变得非常可疑：

```tex
\let\FVB@VerbatimOut\minted@FVB@VerbatimOut
\let\FVE@VerbatimOut\minted@FVE@VerbatimOut
```

我们来看看这两个命令是怎么定义的。

```tex
\newcommand{\minted@FVB@VerbatimOut}[1]{%
  \setcounter{minted@FancyVerbLineTemp}{\value{FancyVerbLine}}%
  \@bsphack
  \begingroup
    \FV@UseKeyValues
    \FV@DefineWhiteSpace
    \def\FV@Space{\space}%
    \FV@DefineTabOut
    \let\FV@ProcessLine\minted@write@detok
    \immediate\openout\FV@OutFile #1\relax
    \let\FV@FontScanPrep\relax
    \let\@noligs\relax
    \FV@Scan}
\newcommand{\minted@FVE@VerbatimOut}{%
  \immediate\closeout\FV@OutFile\endgroup\@esphack
  \setcounter{FancyVerbLine}{\value{minted@FancyVerbLineTemp}}}%
```

我们先不出去处理那一堆 \FV@ 开头的宏，把目光集中在以下几行：

```tex
\immediate\openout\FV@OutFile #1\relax
\immediate\closeout\FV@OutFile
```

这是 TeX 中与文件交互的经典命令。其中

- \immediate 表示立即执行。这是因为大多数 TeX 和文件相关的命令都会延后执行，等到命令所在位置被真正排版完成后再执行。

- \openout 和 \closeout 相当于 C 语言当中的 fopen 和 fclose。

- \FV@OutFile 则相当于 C 语言当中的 FILE 指针，对应一个实际的外部文件。

- 这里的 #1 就是外部文件的文件名，它是 \minted@FVB@VerbatimOut 的参数。

由此可见，我们确实已经找到了 minted 宏包暂存代码的位置。接下来，我们逐行来看这两个宏都干了啥。

- \setcounter{minted@FancyVerbLineTemp}{\value{FancyVerbLine}}/\setcounter{FancyVerbLine}{\value{minted@FancyVerbLineTemp}} 这是在设置行号相关的计数器。我们用不着。

- \@bsphack/\@esphack 这是 LaTeX 定义的内部宏，作用是使他们界定的范围内的代码，当被用在一串文字中间时，不出现额外的空格。这个我们照旧保留。

- \FV@DefineWhiteSpace 定义在 fancyvrb 宏包（为 minted 宏包所调用）内的宏，它将空格和制表符定义为活动字符，并将他们分别定义为 \FV@Space 和 \FV@Tab。其定义是：
```tex
\begingroup
\catcode`\ =\active
\catcode`\^^I=\active
\gdef\FV@DefineWhiteSpace{\def {\FV@Space}\def^^I{\FV@Tab}}%
\endgroup
```

我们照旧保留。

- \def\FV@Space{\space} 和上面的 \FV@DefineWhiteSpace 的定义相对应可知其意。我们照旧保留。

- \FV@DefineTabOut 也是定义在 fancyvrb 宏包内的宏，它将制表符定义为连续多个空格。其定义是：
```tex
\def\FV@DefineTabOut{%
  \def\FV@Tab{}%
  \@tempcnta=\FancyVerbTabSize\relax
  \loop\ifnum\@tempcnta>\z@
    \edef\FV@Tab{\FV@Tab\space}%
    \advance\@tempcnta\m@ne
  \repeat}
```

我们照旧保留。

- \let\FV@ProcessLine\minted@write@detok 看名字是用来处理一行代码的宏，后者的定义是：
```tex
\newcommand{\minted@write@detok}[1]{%
  \immediate\write\FV@OutFile{\detokenize{#1}}}
```

显然，它就是将一行内容去记号化之后写入文件。这正是我们要的东西，照旧保留。

- \FV@Scan 也是定义在 fancyvrb 宏包内的宏，其定义是：
```tex
\def\FV@Scan{%
  \FV@CatCodes
  \VerbatimEnvironment
  \FV@DefineCheckEnd
  \FV@BeginScanning}
```

可知其意是开始逐行扫描内容。照旧保留。

既然已知 \minted@FVB@VerbatimOut 和 \minted@FVE@VerbatimOut 都做了什么，自然就知道应如何重定义他们了。我们有：

```tex
\documentclass{article}
\usepackage{minted}
\makeatletter
\edef\example@name{\jobname-example.aux}
\newenvironment{example}{%
  \renewcommand{\minted@FVB@VerbatimOut}[1]{%
    \@bsphack
    \begingroup
      \FV@DefineWhiteSpace
      \def\FV@Space{\space}%
      \FV@DefineTabOut
      \let\FV@ProcessLine\minted@write@detok
      \immediate\openout\FV@OutFile ##1\relax
      \let\FV@FontScanPrep\relax
      \let\@noligs\relax
      \FV@Scan}
  \minted@FVB@VerbatimOut{\example@name}%
}{%
  \renewcommand{\minted@FVE@VerbatimOut}{%
    \immediate\closeout\FV@OutFile\endgroup\@esphack}%
  \minted@FVE@VerbatimOut
}
\makeatother
\begin{document}
Hello \LaTeX{}.

\begin{example}
\[ E = mc^2. \]
\end{example}
\end{document}
```

至此，我们的 example 环境会将环境内容原样输出到 \jobname-example.aux 这个文件里面了。若文件保存为 foo.tex，则我们在 foo-example.aux 当中能看到质能方程的内容。

```tex
\[ E = mc^2. \]

```

## 输出

解决了代码暂存的问题，接下来就是排版了。这里我们实现一个最简单的排版效果：左代码，右效果，上下加两条横线以示区分。读者有兴趣可以扩充其效果。

```tex
\documentclass{article}
\usepackage{minted}
\makeatletter
\edef\example@name{\jobname-example.aux}
\newenvironment{example}{%
  \renewcommand{\minted@FVB@VerbatimOut}[1]{%
    \@bsphack
    \begingroup
      \FV@DefineWhiteSpace
      \def\FV@Space{\space}%
      \FV@DefineTabOut
      \let\FV@ProcessLine\minted@write@detok
      \immediate\openout\FV@OutFile ##1\relax
      \let\FV@FontScanPrep\relax
      \let\@noligs\relax
      \FV@Scan}
  \minted@FVB@VerbatimOut{\example@name}%
}{%
  \renewcommand{\minted@FVE@VerbatimOut}{%
    \immediate\closeout\FV@OutFile\endgroup\@esphack}%
  \minted@FVE@VerbatimOut
  \setlength{\parindent}{0pt}
  \hrulefill\par\vspace{1em}
  \begin{minipage}[c]{0.45\linewidth}
    \inputminted{latex}{\example@name}
  \end{minipage}\hfill
  \begin{minipage}[c]{0.45\linewidth}
    \input{\example@name}
  \end{minipage}\par\vspace{1em}
  \hrulefill
}
\makeatother
\begin{document}
Hello \LaTeX{}.

\begin{example}
\[ E = mc^2. \]
\end{example}
\end{document}
```

![](/uploads/images/LaTeX/example-demo.jpg)