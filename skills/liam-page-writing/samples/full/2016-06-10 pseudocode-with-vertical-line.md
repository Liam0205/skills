---
title: "排版伪代码时打印垂直的缩进提示线"
url: https://liam.page/2016/06/10/pseudocode-with-vertical-line/
date: 2016-06-10
categories: ["LaTeX"]
tags: ["Macro", "Pseudocode", "Algorithm"]
---

和实际使用中的 Python 一样，伪代码的排版很讲究缩进。书写 Python 代码，通常会使用等宽字族（打字机字族），因此缩进一板一眼十分清晰；然而，在排版算法时，经常会遇到非等宽的字族和等宽字族混用的情况——此时，缩进有时候就不那么明确了。此时，给伪代码排版加上垂直的缩进提示线能够起到很好的提示作用。

## 排版欧几里得算法试试看

```tex
\documentclass{article}
\usepackage{algorithm}
%\PassOptionsToPackage{noend}{algpseudocode} % 不显示循环、条件的结尾
\usepackage{algpseudocode}
\begin{document}
\begin{algorithm}
  \caption{Euclid’s algorithm}\label{euclid}
  \begin{algorithmic}[1]
    \Procedure{Euclid}{$a,b$}\Comment{The g.c.d.\ of a and b}
      \State{$r\gets a\bmod b$}
      \While{$r\not=0$}\Comment{We have the answer if r is 0}
        \State{$a\gets\displaystyle\sum_{i=1}^n x_i$}\Comment{Nonsense to show that tall lines might work}
        \State{$a\gets b$}
        \State{$b\gets r$}
        \State{$r\gets a\bmod b$}
      \EndWhile\label{euclidendwhile}
      \State{\Return $b$\Comment{The gcd is b}}
    \EndProcedure
  \end{algorithmic}
\end{algorithm}
\end{document}
```

![](/uploads/images/LaTeX/pseudo_euclid.png)

干脆利落的代码，很好懂对吧。: )

这里，我们调用了 algorithm 宏包，它提供了 algorithm 环境。这是一个三线表样式的浮动体，浮动的策略和 LaTeX 标准的 figure、table 环境一致。algpseudocode 宏包则是 algorithmicx 宏包的一部分，它提供了实际用来排版伪代码的环境。

## 从一小段竖线开始改造

```tex
\newcommand*{\algrule}[1][\algorithmicindent]{\makebox[#1][l]{\hspace*{.1em}\vrule height \algrl@height depth \algrl@depth}}%
\newcommand*{\algrl@height}{.75\baselineskip}
\newcommand*{\algrl@depth}{.25\baselineskip}
```

这一小段代码相对还是很好理解的。

主要命令 \algrule 依赖两个长度：\algrl@height 和 \algrl@depth。如果你对 plainTeX 比较熟悉的话，那么显而易见，这两个长度分别是标尺 \vrule 的高度和深度。

此外，\algrule 还有一个默认参数 \algorithmicindent。这是 algorithmicx 宏包中定义的长度变量，用来保存每一个缩进块的缩进长度。这里我们将它作为默认参数传给内部的 \makebox，\makebox 制作了一个宽度为 \algorithmicindent 的水平盒子，在靠左边的地方，画了一条高度为 \algrl@height、深度为 \algrl@depth 的标尺（一小节竖线）。

值得注意的是，\algrl@height 和 \algrl@depth 加起来正好是 \baselineskip，也就是行距。这里我们将它们定义成宏，是为了方便后续调整每一节细线的具体高度。若不然，遇到超过 \baselineskip 的情形（例如插入了一个庞大的数学公式），上下两行之间的竖线就会断开。

## 逐层打印当前行的提示线

有了上面定义的竖线，我们就可以逐层打印某一行的提示线了。

在这里，我们不难总结：如果当前伪代码缩进了 $k$ 次，那么我们就需要画出 $k$ 个小竖线。为此，我们需要定义一个临时用的计数器，并构建一个以它为循环变量的 TeX 循环。

```tex
\newcount\ALG@printvrule@tempcnta
\def\ALG@printvrule{%
    \ifnum \theALG@nested>0%
        \ifx\ALG@text\ALG@x@notext%
            % do nothing
        \else
            \unskip
            \addvspace{-1pt}%
            \ALG@printvrule@tempcnta=1%
            \loop
                \algrule[\csname ALG@ind@\the\ALG@printvrule@tempcnta\endcsname]%
                \advance \ALG@printvrule@tempcnta 1
            \ifnum \ALG@printvrule@tempcnta<\numexpr\theALG@nested+1\relax
            \repeat
        \fi
    \fi
}%
```

在这里，\ALG@printvrule@tempcnta 是我们的循环变量，用来表征「即将打印的是第几级缩进」。

此外，由于 \ALG@printvrule 会实际输出内容，因此要特别注意行末的换行符带来的额外空格。在有必要的地方，我们需要加上注释符号 % 抹掉这些空格。

\theALG@nested 是 algorithmicx 宏包的内部变量，用来保存当前行嵌套了多少层缩进。当它大于零时，我们就知道该干活了。我们主要关注循环部分。

- 首先，我们将 \ALG@printvrule@tempcnta 初始化为 1，因为我们总是从第一级缩进开始排版；

- 而后，我们进入循环，调用刚才定义的 \algrule 命令；

- 此处，\csname ALG@ind@\the\ALG@printvrule@tempcnta\endcsname 将展开为形如 \ALG@ind@1、``\ALG@ind@2这样的变量，他们在algorithmicx` 宏包里用来保存各级缩进的缩进深度；

- 调用 \algrule 命令后，我们已经完成阶段性的工作，开始维护循环变量：通过 \advance 将它自加 1；

- 最后的判断极好理解：我们必须确保循环变量不超过嵌套的层数。

## 给 \ALG@doentity 打补丁

\ALG@doentity 命令是 algorithmicx 宏包内部用来输出每条算法实体（entity）的工具。在进行一系列判断、控制后，它将根据 \theALG@nested 缩进恰当的距离，而后输出算法的具体内容。修改它需要用到 etoolbox 宏包的 \patchcmd 命令，它能够在宏的展开中查找替换指定的内容。

```tex
\patchcmd{\ALG@doentity}%
    {\noindent\hskip\ALG@tlm}{\ALG@printvrule}
    {}{\errmessage{failed to patch}}
```

\patchcmd 接收 5 个参数，分别表示：

- 你想对哪个命令打补丁

- 你想替换啥

- 你想将它替换成啥

- 如果替换成功了咋办

- 如果替换失败了咋办

因此，这个补丁将会对 \ALG@doentity 进行修改：将原本单纯的缩进输出，替换为我们自己定义的带提示线的缩进输出。

## 给 \State 命令打补丁

上面提到，在某些情况下，\algrl@height 和 \algrl@depth 定义的默认高度是不够的；而至今为止，我们还没有让它俩能够自动适应变化的行高。\State 命令是 algorithmicx 宏包中用来输出算法语句的命令，我们在它的基础上定义一个新的 \vState 命令。

```tex
\newbox\statebox
\newcommand{\vState}[1]{%
    \setbox\statebox=\vbox{#1}%
    \edef\algrl@height{\dimexpr \the\ht\statebox + 1pt\relax}%
    \edef\algrl@depth{\dimexpr \the\dp\statebox + 1pt\relax}%
    \ifdim\algrl@height < .75\baselineskip
        \def\algrl@height{\dimexpr .75\baselineskip + 1pt\relax}%
    \fi
    \ifdim\algrl@depth < .25\baselineskip
        \def\algrl@depth{\dimexpr .25\baselineskip + 1pt\relax}%
    \fi
    \State #1%
    \def\algrl@height{\dimexpr .75\baselineskip + 1pt\relax}%
    \def\algrl@depth{\dimexpr .25\baselineskip + 1pt\relax}%
}
```

这里，我们将 \vState 的参数读入一个竖直盒子中，然后将 \algrl@height 和 \algrl@depth 分别设置为盒子的高度和深度。同时，为了保险，还用 \ifdim 对它俩的值做了判断，确保二者相加不会小于 \baselineskip。在调用原始的 \State 命令输出后，我们又将二者的定义还原回去。此处用到了大量的 \dimexpr ... \relax 表达式，这是 eTeX 中用来做长度计算的语句。

## 实际运行看看

将上述补丁组合在一起，就能得到我们期待的效果了。

![](/uploads/images/LaTeX/pseudo_euclid_vline.png)