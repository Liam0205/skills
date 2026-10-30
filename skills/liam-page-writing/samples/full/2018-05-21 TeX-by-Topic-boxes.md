---
title: "TeX 主题选讲：盒子"
url: https://liam.page/2018/05/21/TeX-by-Topic-boxes/
date: 2018-05-21
categories: ["LaTeX"]
tags: ["List", "Vertical", "Box", "Mode", "Horizontal"]
---

此篇基本上是译文，原文是 Victor Eijkhout 所著的《TeX by Topic》的第五章。译文项目参见：[CTeX-org/tex-by-topic-cn](https://github.com/CTeX-org/tex-by-topic-cn/releases/latest)。转载请保留本段文字，尊重原作者和译者版权。由于原著使用 GFDL，故而本文也被传染地同样使用 GFDL 许可，而不是本站默认的 BY-NC-SA 4.0 许可。

TeX 中的水平与竖直盒子分别是水平与竖直列表内容的容器。盒子可保存在盒子寄存器当中。本章讨论盒子寄存器，以及关于盒子尺寸、盒子内容相互位置的问题。

所涉命令编目：

- \hbox： 构造一个水平盒子。

- \vbox： 构造一个竖直盒子，其参考点（reference point）是最后一个元素。

- \vtop： 构造一个竖直盒子，其参考点是第一个元素。

- \vcenter： 构造一个在竖直方向于数学轴（math axis）居中的竖直盒子；该命令仅在数学模式下使用。

- \vsplit： 将竖直盒子顶部部分分离。

- \box： 使用盒子寄存器，而后清空它。

- \setbox： 将盒子赋值给一个盒子寄存器。

- \copy： 使用盒子寄存器，但保留其中内容而不清空。

- \ifhbox \ifvbox： 判断盒子寄存器中保存的是水平盒子还是竖直盒子。

- \ifvoid： 判断盒子寄存器是否为空。

- \newbox： 分配新的盒子寄存器。

- \unhbox \unvbox： 将保存有水平盒子或竖直盒子的寄存器解包，并将其中内容追加到当前的水平列表或竖直列表中，而后清空寄存器。

- \unhcopy \unvcopy： 与 \unhbox、\unvbox 的行为相同，但不清空寄存器。

- \ht \dp \wd： 返回及设置盒子寄存器中盒子的高度、深度、宽度。

- \boxmaxdepth： 该命令表示 TeX 所允许的盒子的最大深度。在 plain TeX 中，它的默认值是 \maxdimen。

- \splitmaxdepth： 该命令表示 TeX 所允许的由 \vsplit 生成盒子的最大深度。

- \badness： 刚刚构造的盒子的劣度。

- \hfuzz \vfuzz： 该命令表示水平或竖直盒子的尺寸超出指定尺寸的阈值；当超过该阈值时，TeX 会考虑将其认定为溢出的（overfull）盒子。

- \hbadness \vbadness： 该命令表示一个阈值；当盒子的劣度超过该阈值时，TeX 会将相应盒子认定为欠满的（underfull）或者溢出的。

- \overfullrule： 当水平盒子溢出时，TeX 会打印一条标尺，以表明有溢出的水平盒子；该命令表示上述标尺的宽度。

- \hsize： 该命令表示在水平盒子内文本排版可用的行宽。

- \vsize： 该命令表示页盒子（page box）的高度。

- \lastbox： 若最后追加进当前列表的内容是一个盒子，则该寄存器会保存上述盒子。

- \raise \lower： 这两个命令用于在水平模式中调整盒子的垂直位置。

- \moveleft \moveright： 这两个命令用于在竖直模式中调整盒子的水平位置。

- \everyhbox \everyvbox： 这两个命令分别用于在每个水平盒子或竖直盒子开头处插入的记号列表。

## 盒子

本章我们讨论盒子。TeX 中的水平盒子与竖直盒子分别是盒子是水平与竖直列表内容的容器。需要多次使用的盒子可以保存在盒子寄存器当中。

当 TeX 需要接受一个盒子（<box>）时，TeX 可接受以下形式：

- \hbox <box specification> {<horizontal material>}

- \vbox <box specification> {<vertical material>}

- \vtop <box specification> {<vertical material>}

- \box <8-bit number>

- \copy <8-bit number>

- \vsplit <8-bit number> to <dimen>

- \lastbox

其中 <box specification> 的定义如下

![](/uploads/images/LaTeX/box_specification.png)

而 <8-bit number> 则是 0--255 范围内的数字。

包围盒子内容的花括号定义了一个分组；它们可以是分类码为 1 和 2 的显式字符，也可以是通过 \let 定义的控制序列（隐式字符）；见下文。

除下文提到的 \lastbox 之外，盒子通常可以用在水平、竖直和数学模式。盒子与模式之间的关系将在后续章节中讨论。

由 \vcenter 命令（仅可在数学模式下使用）产生的盒子不是通常意义的盒子（<box>）。特别地，它不能赋值给 \setbox；详见后续章节。

\vsplit 命令将在后续章节详细讨论。

## 盒子寄存器

共有 256 个盒子寄存器，它们从 0 开始编号至 255。盒子寄存器要不然是空的（void），要不然包含了一个水平盒子或一个竖直盒子。本节只讨论盒子**寄存器**；盒子的尺寸、内部内容的排列方式则在后续小节中讨论。

### 使用 \newbox 分配盒子寄存器

plain TeX 中的 \newbox 宏可用于分配一个未被使用的盒子寄存器：

```tex
\newbox\MyBox
```

此后，我们可以这样给盒子寄存器赋值：

```tex
\setbox\MyBox=...
```

或者这样使用盒子寄存器里的内容：

```tex
\box\MyBox
```

连续调用该命令会生成的盒子寄存器的编号也是连续的；这样，宏集合（macro collections）可以各自分配盒子寄存器，而无需担心与其它宏中分配的寄存器冲突。

盒子寄存器的编号是通过 \chardef 赋值的（见后续章节）。这说明，\MyBox 等价于一个数字（<number>），并且能被当做是数字使用。控制序列 \newbox 是一个外部（\outer）宏。新分配的盒子寄存器初始时是空的。

### \setbox、\box 和 \copy 的用法

我们可以将一个盒子（<box>）赋值给盒子寄存器 ：

![](/uploads/images/LaTeX/setbox.png)

此处的 <box> 可以是显式的盒子，比如

```tex
\setbox37=\hbox{...} 以及 \setbox37=\vbox{...}
```

也可以是另一个盒子寄存器:

```tex
\setbox37=\box38
```

一般来说，盒子寄存器的编号由 \newbox 命令分配。

通过 \box 和 \copy，我们可以将盒子寄存器中保存的盒子追加在 TeX 正在构建的列表当中。例如，下列命令会将编号为 38 的盒子追加到当前列表中：

```tex
\box38
```

为节省内存，盒子寄存器在使用后会被清空：TeX 假设当你使用 \box$nn$ 之后，你就不会再需要其中的内容了，于是便会清空它。如果你**确实**需要重复使用盒子寄存器的内容，你可以用 \copy$nn$ 命令。它与 \box$nn$ 的效果相同，但不会清空盒子寄存器中的内容。

通过 \unhbox 和 \unvbox 及其拷贝版本 \unhcopy 和 \unvcopy 解包盒子寄存器中的内容是可行的。不同于 \box 可以在任何模式下使用，解包盒子的操作只能用在恰当的模式下——因为解包盒子会形成一个部分的水平列表或竖直列表（参见后续章节）。后文有关于解包盒子寄存器的更多信息。

### 关于盒子的条件判断：\ifvoid、\ifhbox 及 \ifvbox

通过 \ifvoid 可以判断盒子寄存器是否为空。当 \box<number> 为空时，下式返回真：

![](/uploads/images/LaTeX/ifvoid.png)

注意，盒子寄存器为空与盒子寄存器保存了空盒子是两码事。空盒子要么是水平盒子要么是竖直盒子；空的盒子寄存器既可以作为水平盒子使用，也可以作为竖直盒子使用。

\ifhbox 和 \ifvbox 则分别用于判断一个盒子寄存器中的盒子是否为水平盒子或竖直盒子：

![](/uploads/images/LaTeX/ifhvbox.png)

注意，若寄存器为空，则两个判断都为假。

### \lastbox

当 TeX 构建完成一个部分列表（partial list）后，此列表中的最后一个盒子可通过 \lastbox 来访问。该命令的行为与盒子寄存器相似；因此，你可以将 \lastbox 赋值给其他盒子寄存器，以将其从列表中删除。如果列表中最后一个元素不是盒子，则 \lastbox 的行为与空寄存器相似。你无法通过 \lastbox 访问主竖直列表中的最后一个元素；在这种情况下，\lastbox 总是空寄存器。

举例来说，下面的语句将当前列表中的最后一个盒子赋值给编号为 0 的盒子寄存器，并将其从当前列表中删除：

```tex
{\setbox0=\lastbox}
```

由于赋值过程位于分组之内，在分组结束后，寄存器会被清空。因此，在一个自然段开始之时使用这一语句，可以删除缩进盒子（见后续章节）。后文也有关于 \lastbox 的例子。

由于 \lastbox 在外部竖直模式中总是为空，它不能访问追加到输出页上的盒子。但当页面保存在 \box255 中时，我们可以在输出阶段解包这个盒子，而后取得 \lastbox：

译注：关于这一技巧，这里有一个完整的示例：[https://gist.github.com/91fd658069b0d3dfb7dbd2cba69b856a](https://gist.github.com/91fd658069b0d3dfb7dbd2cba69b856a)

```tex
\vbox{\unvbox255{\setbox0=\lastbox}}
```

值得一提的是，如果竖直模式中的盒子被 \moveright 或 \moveleft 调整过位置，或是水平模式中的盒子被 \raise 或 \lower 调整过位置，则使用 \lastbox 访问列表中最后一个元素时，这些位置调整信息都会丢失。

## 盒子天然的尺寸

译注：这里指的是没有其他拉伸、收缩的影响下，盒子自身的尺寸。

### 已创建的水平盒子的尺寸

\hbox 内所有的元素都依次排在一行，并且它们的参考点会在齐盒子的基线（baseline）上对齐，除非显式使用 \raise 或者 \lower 调整它们竖直方向上的位置。

盒子的宽度是盒子内所有元素宽度之和。因此下面盒子的宽度为正

```tex
\hbox{\hskip1cm}
```

而下面盒子的宽度为负

```tex
\hbox{\hskip-1cm}
```

具体举例来说：

```tex
a\hbox{\kern-1em b}--
```

的输出是

![](/uploads/images/LaTeX/hbox_kern.png)

这表明，水平盒子可以有负的宽度。

\hbox 的高度和深度是盒子内所有元素在盒子基线上方和下方的最大值。水平盒子的高度和深度都是非负的。

\raise 和 \lower 命令是在 \hbox 内调整元素竖直位置的唯一方法（当然，除了在 \hbox 中嵌套一个新的 \vbox）；TeX 不允许在水平盒子中使用竖直命令（<vertical command>，例如 \vskip）；此外，虽然我们可以在水平盒子中使用 \par，但它却不会有任何作用。

### 已创建的竖直盒子的尺寸

在 \vbox 内，竖直元素的参考点与盒子的参考点在竖直方向上对齐，除非显式使用 \moveright 或者 \moveleft 调整它们水平方向上的位置。

竖直盒子的参考点总是在盒子的左边界上。竖直盒子的宽度是盒子内所有元素的右边界相对参考点向右超出距离的最大值。盒子内元素相对参考点向左超出的距离则不被计算在盒子的宽度之中。因此，与前例相对应，下列代码的结果

```tex
a\vbox{\hbox{\kern-1em b}}--
```

是

![](/uploads/images/LaTeX/vbox_kern.png)

由 \vbox 和 \vtop 生成的竖直盒子在计算高度和深度时会有所不同。基本原则是，\vbox 的参考点位于最后一个元素的基线之上，而 \vtop 的参考点位于第一个元素的基线之上。一般来说，只要最后一个（第一个）元素是盒子或者标尺（rule），则 \vbox（\vtop）的深度（高度）非零。

\vbox 的高度是除最后一个元素之外所有元素高度与深度之和，再加上最后一个元素的高度；\vbox 的深度则是最后一个元素的深度。\vtop 的高度是第一个元素的高度；\vtop 的深度则是除第一个元素之外所有元素高度与深度之和，再加上第一个元素的深度。也就是说，对于 \vtop 来说，其深度是所包含所有元素的高度与深度之和，再减去第一个元素的高度。

如果 \vtop（\vbox）的第一个元素（最后一个元素）不是盒子或标尺，那么实际规则还要更复杂一点。如果 \vbox 的最后一个元素是铅空（kern）或伸缩胶（glue），则盒子的深度为零；而若 \vtop 的第一个元素是铅空或伸缩胶，则盒子的高度为零。（注意这些定义中的不对称性；可参考后续示例）

关于竖直盒子，还有一个限制：如果 \vbox 或者 \vtop 的深度超出 \boxmaxdepth，则盒子的参考点会下移这一超出的数值。具体来说，超出限制的那一部分深度，会被加在盒子自身的高度之上。如果盒子有 to 或者 spread 声明符，则相关的伸缩胶都会被重新设置，以将追加的高度考虑在内。

通常，\boxmaxdepth 的值是 TeX 能表示的最大尺寸。但在一些情况下，例如，在 plain TeX 的输出阶段的一些计算中，它的值会被修改得小很多。详见后续章节。

### 例子

水平盒子相较而言简单直接一些。水平盒子的宽度是盒子两条竖直边界之间的距离：从开始到结束，因此，水平盒子的宽度不一定是正数。例如在下例中，\box1 的宽度为零。

```tex
\setbox0=\hbox{aa} \setbox1=\hbox{\copy0 \hskip-\wd0}
```

具体来说 /\box1/ 的结果是（打了引号）

![](/uploads/images/LaTeX/box1.png)

水平盒子的高度和深度则不能为负。例如在下例中，\box1 的深度是 0pt 而高度是 15pt。

```tex
\setbox0=\hbox{\vrule height 5pt depth 5pt}
\setbox1=\hbox{\raise 10pt \box0}
```

竖直盒子相较而言就要麻烦不少。我们首先来讨论其宽度。首先，如下定义的水平盒子的宽度是 10pt。

```tex
\setbox0=\hbox{\hskip 10pt}
```

则如下定义的竖直盒子宽度是 5pt。

```tex
\setbox1=\vbox{\moveleft 5pt \copy0}
```

这是因为，在竖直盒子中，位于参考点左边的内容不计入其宽度。同样的，如下定义的竖直盒子宽度是 15pt。

```tex
\setbox2=\vbox{\moveright 5pt \copy0}
```

如果 \vbox 的最后一个元素是盒子，则其深度是最后一个元素的深度。因此，如下定义的 \vbox 高度为 10pt 深度为 5pt。

```tex
\vbox{\vskip 5pt \hbox{\vrule height 5pt depth 5pt}}
```

如下定义的 \vbox 的高度则是 0pt 而深度为 5pt。

```tex
\vbox{\vskip -5pt \hbox{\vrule height 5pt depth 5pt}}
```

如果最后一个元素是铅空或伸缩胶，则竖直盒子的深度为零。因此，如下定义的 \vbox 高度为 15pt 深度为 0pt。

```tex
\vbox{\hbox{\vrule height 5pt depth 5pt}\vskip 5pt}
```

下列 \vbox 的高度为 5pt 深度则是 0pt。

```tex
\vbox{\hbox{\vrule height 5pt depth 5pt}\vskip -5pt}
```

与 \vbox 的深度对应，\vtop 的高度基本上就是其第一个元素的高度。重复之前的例子，则如下定义的 \vtop 高度为 0pt 深度为 15pt。

```tex
\vtop{\vskip 5pt \hbox{\vrule height 5pt depth 5pt}}
```

如下定义的 \vtop 高度为 0pt 深度为 5pt。

```tex
\vtop{\vskip -5pt \hbox{\vrule height 5pt depth 5pt}}
```

如下定义的 \vtop 高度为 5pt 深度为 10pt。

```tex
\vtop{\hbox{\vrule height 5pt depth 5pt} \vskip 5pt}
```

如下定义的 \vtop 高度为 5pt 深度为 0pt。

```tex
\vtop{\hbox{\vrule height 5pt depth 5pt} \vskip -5pt}
```

## 继续讨论盒子的尺寸

### 预先指定尺寸

盒子的尺寸可以通过尺寸说明符（<box specification>）来指定；具体语法可见上文。盒子中的伸缩胶会依需求缩放，使得盒子的尺寸达到上述设定值。预先指定盒子的尺寸的方法是：

```tex
\hbox to <dimen> \lb...\rb,
\vbox to <dimen> \lb...\rb
```

如果盒子中有可以拉伸或收缩的伸缩胶，则这些伸缩胶会被拉伸或收缩，以将盒子的尺寸调整至指定的大小。与伸缩胶伸缩相关的是所谓的劣度值（见后续章节）。如果伸缩胶能够提供的拉伸或收缩值不足所需，则得到的盒子会欠满或溢出。后文有关于欠满和溢出的报错的相关讨论。

还有一个命令可使盒子实际的尺寸异于其天然尺寸。

```tex
\hbox spread <dimen> \lb...\rb,
\vbox spread <dimen> \lb...\rb
```

这种情况下，TeX 会使盒子内的伸缩胶拉伸或收缩，以在盒子天然尺寸的基础上缩放 <dimen>。

与 \vtop 配合使用尺寸说明符相对来说比较复杂。TeX 构造 \vtop 时会先构造一个 \vbox，同时会将尺寸说明符传递给该 \vbox；而后再根据上述规则计算盒子的高度和深度。

伸缩胶相关设置将在后续章节中讨论。

### 改变盒子的尺寸

我们可以用 \ht、\dp 和 \wd 来分别获得盒子寄存器的高度、深度和宽度。举例来说，\dp18 会给出 18 号盒子的深度。盒子的尺寸不光可读，还可写。通过给盒子的尺寸赋值，我们可以在某种意义上愚弄 TeX，使得在 TeX 看来某个盒子的尺寸不同于其真实值。不过，修改盒子尺寸并不会修改其中的内容；特别地，不会修改伸缩胶设置的方式。

不少格式（format）都定义了 \smash 宏：

```tex
\def\smash#1{{\setbox0=\hbox{#1}\dp0=0pt \ht0=0pt \box0\relax}}
```

在宏定义中，\smash 命令将内容保存在盒子中，但是将盒子的高度和深度都值为零；这也就是说，最终盒子会被输出，但是后续有关盒子尺寸的计算中，TeX 都会将高度和深度认作是零。

改变盒子尺寸只能通过为其赋值来实现：这些盒子尺寸（<box dimen>s）能且只能通过盒子尺寸赋值语句（<box size assignment>）来设置，而不能用诸如 \advance 的命令来修改。

注意，**盒子尺寸赋值**总是**全局赋值**。赋值的效果会超出任意限定它的分组（参见后续章节）。因此下列代码

```tex
\setbox0=\hbox{---} {\wd0=0pt} a\box0b
```

有输出：

![](/uploads/images/LaTeX/abemdash.png)

上述有关被创建的盒子的尺寸限制并不适用于显式修改盒子尺寸的情况。例如，对水平盒子设置 \dp0=-2pt 是合法的。

### 移动盒子

在水平盒子中，所有元素的参考点与盒子自身的参考点都位于同一条水平线上。水平盒子中的盒子可用 \raise 或 \lower 来上移或下移。

相似地，在竖直盒子中，所有元素的参考点与盒子自身的参考点都位于同一条竖直线上，且各个元素从上到下依次排列。竖直盒子中的盒子可用 \moveleft 或 \moveright 来左移或右移。

注意，上述命令只能用来移动盒子，特别地，这些命令不能用于字符或标尺。

### 盒子的尺寸与盒子的摆放

在确定水平列表和竖直列表中元素的摆放位置时，TeX 需要维护两个变量：当前参考线以及在参考线上的当前位置。对于水平列表来说，参考线是包围当前内容的 \hbox 的基线；对于竖直列表来说，参考线是穿过包围当前内容的 \vbox 的参考点的竖线。

在水平模式中，TeX 放置元素的逻辑如下。初始时，参考线上的当前位置即是包围当前内容的从水平盒子的参考点。此后，TeX 会依如下步骤操作。

- 如果元素被 \raise 或 \lower 上下移动了位置，则相应地调整元素的位置。

- 如果元素是水平盒子，则对其内容递归地调用该算法；如果元素是竖直盒子，按盒子的高度向上移动当前位置，而后按照后文所述的有关竖直盒子的算法放置盒子内竖直列表中的元素。

- 按当前元素的宽度，沿着参考线向右移动当前位置。

对于竖直盒子中的竖直列表，TeX 的会将当前位置初始设置在盒子的左上角，参考线则是穿过该点的竖线——这条竖线同样也会穿过盒子的参考点。竖直盒子中的元素依照如下逻辑摆放。

- 如果元素被 \moveleft 或 \moveright 上下移动了位置，则相应地调整元素的位置。

- 将元素的左上角与当前位置对齐。

- 如果元素是竖直盒子，则对其内容递归地调用该算法；如果元素是水平盒子，按盒子的高度向下移动当前位置，而后按照前文所述的有关竖直盒子的算法放置盒子内水平列表中的元素。

- 按当前元素的高度与深度之和，沿着参考线向下移动当前位置。

注意，上文中没有描述 TeX 是如何构建盒子的。对于竖直盒子，构建盒子的过程还要包括插入行间距伸缩胶（行间胶，baselineskip glue）的过程。上文介绍的过程描述的是 TeX 会如何输出一个已经构建完成的盒子中的内容。

### 盒子与反向伸缩胶

默认情况下，盒子在一条参考线上依次摆放。但有时，让盒子互相重叠也是很有用的。让盒子互相重叠，最简单的办法是使用反向行间胶。在水平模式中，下列代码会摆放编号为 8 的盒子，但不会移动当前位置。

```tex
{\dimen0=\wd8 \box8 \kern-\dimen0}
```

更实用的是使用 \llap 和 \rlap 命令。它们的定义如下：

```tex
\def\llap#1{\hbox to 0pt{\hss #1}}
\def\rlap#1{\hbox to 0pt{#1\hss}}
```

这两个命令允许其中的内容基于当前位置向左或向右突出。这里，\hss 伸缩胶等价于 \hskip 0pt plus 1fil minus 1fil，它能吸收 \llap 或 \rlap 的参数中的任意正负宽度。

举例来说，下列代码

```tex
\llap{\hbox to 10pt{a\hfil}}
```

等价于

```tex
\hbox{\hskip-10pt \hbox to 10pt{a\hfil}}
```

它们的宽度都是 0pt。

## 盒子的欠满与溢出

如果盒子有尺寸说明符则 TeX 会拉伸或收缩其中的伸缩胶。对于仅有有限伸缩能力的伸缩胶，TeX 会计算其伸缩过程中的**劣度**（见后续章节）。在 TeX3 中，用户可通过 \badness 宏来检查刚刚构建的盒子的劣度。劣度的取值范围是 $0$--$10,000$；而如果盒子溢出了，则其劣度为~$1,000,000$。

如果 TeX 认为劣度过大，则会给出一条诊断信息。我们首先考虑对水平盒子的报错。

若 \hbadness${}\geqslant10,000$，则 TeX 不会对需要拉伸其中伸缩胶的水平盒子报错；否则，当水平盒子中的伸缩胶拉伸的劣度超过 \hbadness 时，TeX 会提示盒子欠满（underfull）。

伸缩胶的收缩可能引发盒子溢出的报错：如果盒子内伸缩胶最大的收缩量不足以使盒子的宽度满足指定的宽度，则 TeX 认为该盒子溢出了。当且仅当收缩量不足的量大于 \hfuzz 或者 \hbadness${}<100$ 时（这会使得所有可用的收缩的劣度为 $100$），TeX 才会报告盒子溢出的问题。

举例来说，如果盒子内伸缩胶的最大收缩量不足以使盒子的宽度减小到指定的尺寸，则若设置 **\hfuzz=1pt**，TeX 会忽略上述不足的部分小于 1pt 的盒子而不报错。

```tex
\hbox to 1pt{\hskip3pt minus .5pt}
\hbox to 1pt{\hskip3pt minus 1.5pt}
```

这里只有第一个盒子会报错：它比目标尺寸大了 1.5pt；但是第二个盒子不会报错，因为它只比目标尺寸大了 0.5pt，小于 **\hfuzz**。

如果一个盒子虽不至变成溢出盒子但也被收缩了，也有可能被 TeX 报告问题：如果一个盒子比较紧凑，也就是说，如果这个盒子使用了至少一半的收缩能力，则在劣度（介于 13 到 100 之间）超过 \hbadness 时，TeX 会报告这个问题。

对水平盒子与竖直盒子来说，相关警告的逻辑几乎完全相同。对于竖直盒子来说，有 \vbadness 以及 \vfuzz 来控制相关报错。区别之处在于，如果一个水平盒子溢出了，则 TeX 会在盒子右侧绘制一个高度与盒子相同宽度为 \overfullrule 的溢出标尺。此处有一个例外，在 \halign 中，如果 \tabskip 伸缩胶无法提供足够的收缩量时，TeX 不会绘制溢出标尺。

## 盒子的开始与结束

盒子的内容以花括号定界。其中，左右花括号既可以是显式字符（分类码为 1 和 2 的字符），也可以是使用命令 \let 定义的隐式字符。TeX 会将记号 \everyhbox 或者 \everyvbox 插入在左花括号之后。如果盒子位于 \setbox 赋值语句中，则记号 \afterassignment 会在「everybox」记号之前插入在左花括号之后。

举例来说，

```tex
\everyhbox{b}
\afterassignment a
\setbox0=\hbox{c}
\showbox0
```

的结果是：

```tex
> \box0=
\hbox(6.94444+0.0)x15.27782
.\tenrm a
.\tenrm b
.\kern0.27779
.\tenrm c
```

借助隐式花括号，我们可以通过宏来开始和结束盒子。比如下面的代码就用到了这一特性：

```tex
\def\openbox#1{\setbox#1=\hbox\bgroup}
\def\closebox#1{\egroup\DoSomethingWithBox#1}
\openbox0 ... \closebox0
```

利用这一机制，我们可以提取整个自然段的内容：

译注：这是一个在 plain TeX 下的示例，而非是 LaTeX 下的。因此，这里的 \parbox 不是 LaTeX 里的段落盒子。关于这一技巧，此处有一完整示例：\url{[https://gist.github.com/1d8b9bd2f401eb0ea970a47693723ab1](https://gist.github.com/1d8b9bd2f401eb0ea970a47693723ab1)

```tex
\everypar{\setbox\parbox=
   \vbox\bgroup
        \everypar{}
        \def\par{\egroup\UseBox\parbox}}
```

此处，\everypar 命令

译注：\everypar 命令的参数，会被插入在每个开启自然段的水平列表的头部，位于缩进盒子之后。

开始了一个盒子，并且将自然段的文本内容保存在盒子中。假设段落的开头是：

```tex
Begin a text ...
```

这就等价于

译注：注意这里忽略了盒子开头位置的 \everypar 以及对 \par 的重定义。

```tex
\setbox\parbox=\vbox{Begin a text ...
```

由于在盒子中，\par 被重定义了，所以，假设段落的结尾是

译注：注意这里的 \par 可以是手工插入的，也可以是输入处理器在\cstate{S

遇见行尾符自动插入的。}：

```tex
... a text ends.\par
```

等价于

```tex
... a text ends.}\Usebox\parbox
```

在这个例子中，\UseBox 命令只能将盒子作为一个整体对待；如果想要分别处理盒子中的元素，则需要使用新的技巧。在下列代码中，\HandleLines 可以访问自然段竖直列表中连续的元素：

```tex
\everypar{\setbox\parbox=
 \vbox\bgroup\everypar{}%
      \def\par{\endgraf\HandleLines
               \egroup\box\parbox}}
\def\HandleLines{ ... \lastbox ... }
```

后文还有一个相关例子。

## 将盒子解包

使用 \unhbox 和 \unvbox 可将盒子解包；\unhcopy 和 \unvcopy 是对应的拷贝版本。由于它们会构建部分的水平列表和竖直列表，它们分别是水平命令和竖直命令（见后续章节）。注意，不能用 \unhbox 去解包一个寄存了 \vbox 的盒子寄存器；反过来也一样不行。不过，空寄存器可以用 \unhbox 也可以用 \unvbox 解包。

解包操作会将盒子寄存器中盒子的内容取出，而后追加在盒子所处的列表中；所有的伸缩胶会被重新设置。因此下列代码

```tex
\setbox0=\hbox to 1cm{\hfil} \hbox to 2cm{\unhbox0}
```

与下列代码完全相同

```tex
\hbox to 2cm{\hfil}
```

且与下列代码不同

```tex
\hbox to 2cm{\kern1cm}
```

\unhbox 的这一本质特性被用来定义 \leavevmode：

```tex
\def\leavevmode{\unhbox\voidb@x}
```

该命令会使 TeX 从竖直模式切换到水平模式，而不向水平列表中添加任何额外的东西。当然，由模式切换出发的 \indent 会在水平列表中添加一个缩进盒子。在水平模式中，\leavevmode 没有任何作用。注意，此处没必要使用 \unhcopy，因为寄存器本身就是空的。

还有一个细节需要注意：在竖直模式中解包竖直盒子的操作不会在前序内容与盒子内容之间添加任何行间伸缩胶。此外，\prevdepth 的值也不会发生改变，因此，盒子内容之间的伸缩胶以及盒子内容与后续内容之间的伸缩胶仅在盒子前面有东西存在的时候才会生效；并且，行间伸缩胶的只取决于之前内容的深度。相似地，在水平模式中解包水平盒子的操作不会改变 \spacefactor。

## 盒子中的文本

水平盒子与竖直盒子里都能装文本，但它们处理文本的方式有所区别。在水平盒子中，文本被摆放在一条直线上，并且盒子的宽度在原则上是文本（及盒子内其它元素）的自然宽度。水平盒子中不允许有竖直命令（<vertical command>），此外 \par 在水平盒子里没有任何作用。

竖直盒子相对来说就要复杂得多了。在竖直盒子中，一旦遇到字符或其他任何水平命令（<horizontal command>），TeX 就会开始在非受限水平模式构建段落；也就是说，仿佛这一段落是直属于页面的一部分。而当遇到竖直命令（<vertical command>）或盒子结束时，TeX 会使用当前的参数值（例如 \hsize）将该段落分段成行。

因此，下列代码的**不会**输出宽度为 3 厘米的段落（如果 \hsize${} > {}$3cm，则水平盒子会溢出）：

```tex
\hbox to 3cm{\vbox{some reasonably long text}}
```

下列代码才会输出宽度为 3 厘米的段落：

```tex
\vbox{\hsize=3cm some reasonably long text}
```

竖直盒子中的成段文本会被分段成行，而后每行都会被打包进一个水平盒子中。这些水平盒子会堆叠在内部竖直模式当中，盒子之间有 \baselineskip 和 \lineskip 分割（见后续章节）。这也是页面当中文本内容摆放的过程；只不过水平盒子是在外部竖直模式当中堆叠起来的。

如果内部竖直列表是空的，则 TeX 不会在段落开始处插入 \parskip 伸缩胶。

由于水平盒子中的文本不会被分段成行，受限和非受限水平模式还有这样一个区别：在受限水平模式中，TeX 不会插入 discretionary nodes 和会改变当前语言值的无名项目（whatsit items）。如果文本随后被解包形成段落的一部分，则这可能引发一些问题。

后续章节有关于这些内容的解释。

## 杂记

### 忘掉 \box

在 \newcount\foo 之后，我们就可以单独用 \foo 来访问这个计数器了。但是，对于盒子来说则必须使用 \box\foo 来访问相应的盒子。其原因在于，TeX 中不存在单独的 \boxdef 命令，而是用 \chardef 命令来代替（详见后续章节）。

举例来说，假设 \newbox\foo 命令分配了编号为 25 的寄存器，则 \textup{\foo} 与 \char25 等价。

### 特殊用途的盒子

有些盒子寄存器有特殊用途。

- 编号为 255 的盒子 \box255 在 TeX 内部参与页面输出的例程。

- \voidb@x 是一个数字，对应的盒子寄存器在 plain.tex 中分配；我们可以总是假设它是一个空寄存器。它被用于定义诸如 \leavevmode 等宏。

- 使用 plain TeX 宏 \newinsert 创建新的 \insert 之后，TeX 会预留编号相同的若干寄存器，且编号从 254 开始向前倒数。这些寄存器是：\count、\dimen、\skip 以及 \box。

### 水平模式中竖直盒子的高度

在水平模式中，竖直盒子的参考点与包围它的水平盒子的参考点在竖直方向上对齐。TeX 会从竖直盒子的左上角，即竖直盒子参考点上方与参考点距离等于竖直盒子高度的点，开始遍历竖直盒子中的内容。改变盒子的高度会改变盒子中内容摆放的高度。

考虑以下代码

```tex
\hbox{a\setbox0=\vbox{\hbox{b}}\box0 c}
```

其效果是

![](/uploads/images/LaTeX/abc.png)

再考虑以下代码

```tex
\hbox{a\setbox0=\vbox{\hbox{b}}\ht0=0cm \box0 c}
```

其效果是

![](/uploads/images/LaTeX/alowbc.png)

相对的，在竖直模式中改变水平盒子的宽度不会影响水平盒子摆放的位置。

### 竖直盒子的更多细节

有两种竖直盒子：\vbox 和 \vtop。嵌套使用两种盒子的结果可能会令人困惑。例如

```tex
\vtop{\vbox{...}}
```

完全等价于

```tex
\vbox{...}
```

如前所述，若 \vbox 的最后一个元素是铅空或伸缩胶，则其深度为零；若 \vtop 的第一个元素是铅空或伸缩胶，则其高度为零。前面的几个例子已经通过用铅空作为第一个元素或者最后一个元素演示了这一点，但是，如果 \vtop 的第一个元素不是铅空或伸缩胶，人们有可能忽视其对 \vtop 的影响。举例来说，尽管下列代码中，第一个元素不是铅空或伸缩胶，但其高度为零。这是因为在 \write 指令中包含了一个无名项目，它会被放在竖直列表当中。

```tex
\vtop{\write16{...}...}
```

修正的办法是通过 \leavevmode 离开竖直模式，切换到水平模式并开启新的自然段，而后将无名项目放在自然段的起始处，而非是自然段的上方。

```tex
\vtop{\leavevmode\write16{...}...}
```

摆放数值列表中的元素有时会比较棘手。例如，竖直列表中的水平盒子与竖直盒子的处理方式是不一样的。考虑以下例子，在 \offinterlineskip 之后

译注：\offinterlineskip 会禁止 TeX 在行与行之间自动地插入行间伸缩胶；因此，在 \offinterlineskip 之后，每行的 \hbox 会没有缝隙地堆叠在一起。

第一个例子

```tex
\vbox{\hbox{a}
     \setbox0=\vbox{\hbox{(}}
     \ht0=0pt \dp0=0pt \box0
     \hbox{ b}}
```

结果是

![](/uploads/images/LaTeX/ab.png)

稍稍修改之后

```tex
\vbox{\hbox{a}
     \setbox0=\hbox{(}
     \ht0=0pt \dp0=0pt \box0
     \hbox{ b}}
```

结果变成了

![](/uploads/images/LaTeX/abprime.png)

造成这一区别的原因在于，水平盒子的摆放位置由其参考点确定，而竖直盒子的摆放位置由其左上角确定。

### 将 \lastbox 还回列表

通过 \lastbox 你可以将（内部）竖直列表中最后一个盒子取出。但是，如果你想把取出的盒子换回去，则竖直间距可能会出问题。比如说，如果你这样将它换回去，则行间伸缩胶会有两份。

```tex
\setbox\tmpbox=\lastbox
\usethetmpbox \box\tmpbox
```

而如果你在换回去之前使用 \unskip 命令，看上去解决了问题，但实际上错得更加微妙：

```tex
\setbox\tmpbox=\lastbox
\unskip \usethetmpbox \box\tmpbox
```

此时，内部距离（<internal dimen>）\prevdepth（控制行间伸缩胶；见后续章节）的值会因最后一个盒子而改变，但正确的行间伸缩胶应该由上一个盒子来决定。正确的方法不是使用 \unskip，而是使用 \nointerlineskip：

```tex
\setbox\tmpbox=\lastbox
\usethetmpbox \nointerlineskip \box\tmpbox
```

### 使用 \lastbox 切分自然段

反复调用 \last... 和 \un... 可以将自然段切分开。这里给出一个例子。

![](/uploads/images/LaTeX/eatlines.png)

```tex
\newbox\linebox \newbox\snapbox
\def\eatlines{
   \setbox\linebox\lastbox    % check the last line
   \ifvoid\linebox
   \else                      % if it's not empty
   \unskip\unpenalty          % take whatever is
   {\eatlines}                % above it;
                              % collapse the line
   \setbox\snapbox\hbox{\unhcopy\linebox}
                      % depending on the difference
   \ifdim\wd\snapbox<.98\wd\linebox
         \box\snapbox % take the one or the other,
   \else \box\linebox \fi
   \fi}
```

它的使用方式是

```tex
\vbox{ ... some text ... \par\eatlines}
```

或者也可以用 \everypar 自动插入。

宏 \eatlines 会从竖直列表取得 \lastbox。如果列表为空，则 \ifvoid 将返回真。这些盒子都是水平盒子，每个盒子包含了段落中的一行：如果使用 \ifhbox 来判断盒子分类的话，将返回真。