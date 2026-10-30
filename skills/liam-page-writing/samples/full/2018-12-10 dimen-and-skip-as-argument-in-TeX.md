---
title: "LaTeX 黑魔法（七）：TeX 中作为参数的 dimen 和 skip"
url: https://liam.page/2018/12/10/dimen-and-skip-as-argument-in-TeX/
date: 2018-12-10
categories: ["LaTeX"]
tags: ["Arguments", "TeX-core"]
---

接触 TeX 稍久的用户，应该多少都接触过 \kern 和 \hskip 两个命令。那么不知你是否会好奇，TeX 是如何获取它们的参数的呢？要知道，像 I\kern37ptlike\hskip100ptcake 这种看上去奇奇怪怪的写法，能正常工作，但 \hskip 2pt minuscule chances of error 这种看起来正常的写法却会报错。

此篇介绍一下 TeX 中作为参数的 dimen 和 skip。

## 作为参数的 dimen

命令 \kern 的参数是 ⟨dimen⟩，因此我们以它为例。具体来说，TeX 在读入 \kern 这个 token 之后，会先去寻找一个十进制分数（⟨decimal number⟩），而后寻找合法的单位（⟨unit of measure⟩）。在十进制分数和单位之间的空格都会被忽略。在单位之后，则有一个可选空格。

这里，十进制分数可以是：

- 任意在 TeX 中合法的整数；

- 任意合法的十进制分数（以句点或逗号作为整数与小数部分的分隔）。

特别说明一下以逗号作为整数与小数部分的分隔的问题。在中国，大多数时候，我们都以句点作为小数点，来分隔十进制分数的整数与小数部分；例如 1.25。同时，逗号通常用于大数记录时的千分标记；例如 1, 000.25。但是，在部分国家（例如法国和德国），在表示十进制分数时，句点和逗号的用法正好颠倒。因此，1, 000.25 在法国和德国记作 1. 000,25。有趣的是，\kern , pt 是一个合法的铅空。它会产生一个宽度为 0pt 的铅空。这是因为，逗号在此被当做是小数点。而小数点前后的数字是零时，是可以省略的。

这里的单位，指得是 TeX 接受的，以两个字符表达的长度单位。包括：pt, cm, mm, in, dd, pc, cc, bp, sp, em, ex。对于 pdfTeX 来说，还包括 px。如果 TeX 在读入一个合法的十进制分数之后，没有找到合法的单位，则会报错：

```tex
! Illegal unit of measure (pt inserted).
```

因此，\kern37ptlike 是合法的。它与 \kern 37 pt like 等价。

## 作为参数的 skip

命令 \hskip 的参数是 ⟨skip⟩，因此我们以它为例。具体来说，TeX 在读入 \hskip 这个 token 之后，会先和上述步骤一样，寻找一个 ⟨dimen⟩，作为 ⟨skip⟩ 的自然长度。而后，TeX 会在展开得到的 token list 当中继续寻找 plus。如果 TeX 找到了 plus，则 TeX 又会去寻找一个 ⟨dimen⟩。不过，此时十进制分数之后，除了长度单位，还可以是 fil, fill 或者 filll。其中 fil(|l|ll) 之后的可选空格会被忽略。特别地，如果没有找到 plus，TeX 也会继续寻找 minus。找到 minus 之后的规则，就跟 plus 的情况一样了。

因此，在 \hskip 2pt minuscule chances of errors 这个例子中，TeX 读入 2pt 作为 \hskip 的自然长度。而后，尽管没有找到 plus，但找到了 minus——它藏在 minuscule 这个单词中。很不幸，此时在 minus 之后没有一个合法的 ⟨dimen⟩，于是 TeX 会报错。如果你不了解 TeX 读入 ⟨skip⟩ 的规则，那这种报错还是蛮令人挠头的。

为了避免这些问题，在 ⟨skip⟩ 之后，果断地加一个 \relax 总归是个好主意。

## bonus! 奇怪的 fil(|l|ll)

首先我们来看一个例子。你认为下面的写法是合法的吗？

```tex
\hskip 0pt plus 1 fil L l minus 2 fiLL
```

答案是合法的……

事实上，fill 和 filll 并不是 TeX 的关键字。真实情况是，fil 和 l 是 TeX 关键字。而 TeX 在读入 fil 之后，会尝试继续寻找 l 这个关键字。如果找到了，就拼在一起，作为弹力更大的弹簧。此外，TeX 的关键字是不区分大小写的。

因此，fil L l 就相当于 filll；而 fiLL 就相当于是 fill。也因此，如果你不了解这一点，下面的例子可能会让你很伤脑筋——Let's Go 当中的 L 怎么不输出了？

```tex
\hskip 0pt plus 1fil Let's go
```

通常，我们（雾）把这种情况称之为「神秘的 L」。←_←