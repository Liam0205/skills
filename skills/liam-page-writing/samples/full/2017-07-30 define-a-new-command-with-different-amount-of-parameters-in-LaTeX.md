---
title: "LaTeX 黑魔法（三）：定义参数变长的命令"
url: https://liam.page/2017/07/30/define-a-new-command-with-different-amount-of-parameters-in-LaTeX/
date: 2017-07-30
categories: ["LaTeX"]
tags: ["Macro", "TeX", "LaTeX2e", "LaTeX3"]
---

在 C++ 中，我们可以为同一个函数赋予不同的执行内容，这种行为称之为「函数重载」。具体重载的函数，共享同一个函数名，但是接收的函数参数在数量、类型上不同。LaTeX 是宏语言，没有一般意义上的参数类型的说法。但是，有没有办法在 LaTeX 中「重载」一个宏，根据输入的参数数量不同，而产生不同的效果呢？

本文给出解决方案。

## 在 TeX 和 LaTeX2e 中定义新命令

TeX 中，定义新命令的标准方法是使用 TeX 原语 \def。它有几个变种，记录如下。

- \def：局部定义，定义时不展开；

- \edef：局部定义，定义时完全展开；

- \gdef：相当于 \global\def；

- \xdef：相当于 \global\edef。

建立在 TeX 之上的各种格式，其提供的定义新命令的方案，都是通过这四个 \def 来实现的。LaTeX2e 中定义新命令的标准方法是使用 \newcommand。它也有几个变种，记录如下。

- \newcommand：新定义一个命令，如果该命令已有定义，则报错；

- \renewcommand：重定义一个命令，如果该命令未定义，则报错；

- \providecommand：如果该命令未定义，则定义一个新的命令；否则，啥也不干。

当然，在 LaTeX2e 中，也有 \DeclareRobustCommand 一系列命令，可以用来定义新的命令。这一系列命令，是 LaTeX2e 针对「脆弱命令」问题，提供的一些保护机制。此处不表。

在标准的方法中，不论是 TeX 还是 LaTeX2e，都没有提供「参数变长」的实现方法。也就是说，如果不引入奇怪的技巧，我们在普通的 LaTeX 文稿中，是无法重载命令的。

## \@ifnextchar

\@ifnextchar 是[一个 LaTeX 内部宏](/2015/04/10/how-to-list-unnumbered-section-in-the-table-of-contents/)。它的作用，是「预读」输入列表的下一个字符，然后判断预读的字符是否与作者期待的字符一致，执行不同的分支。

例如，我们知道，LaTeX 命令的可选参数，默认是放在所有必选参数之前。那么，我们是否有可能让可选参数放在必选参数之后呢？答案当然是肯定的，利用 \@ifnextchar 就可以做到。

```tex
\documentclass{article}
\makeatletter
\newcommand{\foo@helper@i}[1]{One parameter: #1{}.}
\def\foo@helper@ii #1[#2]{Two parameters: #1{}, #2{}.}
\newcommand{\foo}[1]{%
\@ifnextchar[%
  {\foo@helper@ii{#1}}%
  {\foo@helper@i{#1}}%
}
\makeatother
\begin{document}
\foo{hello}

\foo{hello}[world]
\end{document}
```

我们来看 \foo 的定义。它接收一个标准的 LaTeX 参数。因此不管是 \foo{hello} 还是 \foo{hello}[world]，LaTeX 都会把其中的 \foo{hello} 先「吃下去」。接下来，LaTeX 会判断下一个字符是否为 [。对于 \foo{hello} 这种用法，下一个字符是换行符，因此判定失败，执行 \foo@helper@i。而对于 \foo{hello}[world] 这种用法，吃下去 \foo{hello} 之后，输入流中剩下了 [world]...，下一个字符正是 [，因此执行 \foo@helper@ii。

对于 \foo@helper@ii，它是使用 TeX 的原语 \def 定义的命令。参数列表 #1[#2] 表示该命令接受两个参数。第一个参数是标准的 TeX 参数——用分组包括起来。因此，上一步执行的 \foo@helper@ii 将第一个参数喂给了 \foo@helper@ii。接下来，\foo@helper@ii 还要吃下去第二个参数。按照定义，第二个参数被方括号 [] 所包围。因此 [world] 中的 world 被吃掉，作为第二个参数。

最终输出如图。

![](/uploads/images/LaTeX/option-brackets-later.png)

## \bgroup

上面的 \foo 命令，基本已经达成了我们的目标。只不过，第二个参数必须是用方括号表达的。当然这不是不可以，但强迫症选手们可能会希望第二个参数也能用花括号来界定。强迫症们尝试把 \@ifnextchar[ 尝试换成了 \@ifnextchar{，于是他们得到了报错

```plaintext
File ended while scanning use of...
```

这是因为，TeX 遇到 { 时，会将其解释为一个分组。因此，这种写法会造成 TeX 读入的分组不匹配。这样一来，我们就必须用 \bgroup 来代替花括号。它的定义是 \let\bgroup={。

```tex
\documentclass{article}
\makeatletter
\newcommand{\foo@helper@i}[1]{One parameter: #1{}.}
\newcommand{\foo@helper@ii}[2]{Two parameters: #1{}, #2{}.}
\newcommand{\foo}[1]{%
\@ifnextchar\bgroup%
  {\foo@helper@ii{#1}}%
  {\foo@helper@i{#1}}%
}
\makeatother
\begin{document}
\foo{hello}

\foo{hello}{world}
\end{document}
```

这样一来，我们就实现了一个 \foo 命令，在参数不同的情况下，具有不同的行为。

## xparse 宏包

基于 LaTeX3 的 xparse 宏包给了我们新的选项。它提供的 \NewDocumentCommand 命令，允许用户使用新的接口定义 LaTeX 命令。其形式为

```tex
\NewDocumentCommand{<command>}{<parameter specificers>}{<replacement text>}
```

比如，以下两个定义，效果是一致的。

```tex
\usepackage{xparse}

\newcommand{\baz}[1]{I eat #1{}.}
\NewDocumentCommand{\bar}{m}{I eat #1{}.}
```

其中，参数标识符 m 表示 \bar 接收一个标准的 LaTeX 参数。除去 m 之外，xparse 宏包还提供了许多额外的参数标识符（具体参照其手册）。其中，g 表示该参数是一个可选参数，并且以花括号界定其范围。当参数未给出时，参数值为 -NoValue-；否则是实际的参数内容。此时我们可以用 \IfNoValueTF 命令来做分支判断。

于是，上述 \foo 命令可以按如下方式实现。

```tex
\documentclass{article}
\usepackage{xparse}
\NewDocumentCommand{\foo}{mg}{%
  \IfNoValueTF{#2}%
  {One parameter: #1{}.}%
  {Two parameters: #1{}, #2{}.}%
}
\begin{document}
\foo{hello}

\foo{hello}{world}
\end{document}
```

这样的实现方式，相对在 LaTeX2e 里用 \@ifnextchar\bgroup 判断就简单清晰多了。