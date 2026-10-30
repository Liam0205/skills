---
title: "LaTeX 黑魔法（四）：插入动画（animate 宏包教程）"
url: https://liam.page/2017/08/10/importing-animate-in-LaTeX/
date: 2017-08-10
categories: ["LaTeX"]
tags: ["GIF", "Animate"]
---

在最初学习 LaTeX 插图的时候，我就发现，基本的 LaTeX 手段不支持 GIF 格式的动图。虽然一直保持对此的好奇，但是因为没有实际需要，再加上「论文等文稿不适合插入动画」的论调，所以一直没有去探究可行性和解决办法。

前段时间，因为制作一个幻灯片（[离散卷积和卷积神经网络](//liam.page/attachment/attachment/slides/convolutions.pdf)）的需要，不得不插入动画以演示「卷积」的过程和效果。于是就借此机会，摸索了如何在 LaTeX 中插入动画。此文是对上述过程的归纳总结。

本文主要介绍两部分内容

- 如何在 LaTeX 中插入 GIF 格式的动图；

- 如何在 LaTeX 中插入 Ti*k*Z 代码绘制的动画。

以及介绍一些运用动画效果实现的黑科技效果。

## 主角登场——animate 宏包

要在 LaTeX 中插入动画，首先要考虑输出文件类型是否支持这样的需求。否则，插入动画就变成了无根之木、无源之水。

目前来说，主流的 LaTeX 输出格式是 PDF。PDF 的全称是 Portable Document Format。它是最早由 Adobe 公司提出的文档格式标准；因其优良的特性，现已逐渐发展成为固定格式文本交换的事实标准。

自 2000 年始，1.3 版本的 PDF 开始支持 JavaScript。而后，相关特性在后续版本中不断完善。因此，若是 PDF 浏览器支持相关 [API](//www.adobe.com/content/dam/Adobe/en/devnet/acrobat/pdfs/js_api_reference.pdf)，则可以利用 JavaScript 在 PDF 文稿中做到很多事情——当然，包括了动画。因此，在 PDF 中插入动画是可能的。

Alexander Grahn 根据上述 API，开发了 animate 宏包。该宏包利用 JavaScript，允许用户在 LaTeX 文稿中插入动画，并在支持 JavaScript 的 PDF 阅读器中查看。特别喜人的是，animate 宏包支持目前最流行的几种编译方式；因此，你无须像使用 media9 之类的宏包那样，被编译方式绊住脚。目前 animate 支持的编译方式有

- pdfLaTeX / LuaLaTeX

- LaTeX -> dvips -> ps2pdf / LaTeX -> dvipdfmx

- XeLaTeX -> xdvipdfmx

当然，支持这些特性的 PDF 阅读器则比较少。目前已知的有

- Adobe Acrobat / Reader

- PDF-XChange

- Foxit Reader

## 使用 animate 宏包

此处不表如何安装 animate 宏包，我们来看如何使用 animate 宏包。

和其它宏包一样，在 LaTeX 中使用 \usepackage[<options>]{animate} 即可引入 animate 宏包。唯独需要注意的有三点

- 必须在引入 animate 宏包之前，显式地引入 graphicx 宏包；

- 若希望使用 LaTeX -> dvipdfmx 这一工具链，则需要给 graphicx 和 animate 宏包都加上 dvipdfmx 选项（[原因](/2015/06/01/returned-exit-code-not-0/)）；

- 和交叉引用中遇到的问题一样，使用 animate 宏包创建动画，也需要两次编译（第一次创建 JavaScript 内容，第二次在具体位置插入内容）。

animate 宏包支持不少参数。不过，仅有 dvipdfmx 和 xetex 两个驱动选项只能在载入宏包时使用——而其中仅有 dvipdfmx 是必须的。宏包支持的其他参数，具体的命令、环境也都支持。若是在载入宏包是提供这些参数，相当于给命令、环境设置了「默认值」。因此，这部分参数放在之后具体介绍。

## 使用 animate 宏包插入 GIF 动图——\animategraphics

animate 提供了 \animategraphics 命令，用于插入「一系列」的图片，而后将他们组成动画——相当于插入了动图。

具体来说，其命令是

```tex
\animategraphics[<options>]{<frame rate>}{<file basename>}{<first>}{<last>}
```

此处 options 是命令的参数，主要用于控制动画的各种效果，具体参数将在下一节中介绍。先前我们讲过这部分参数大都也可用于宏包选项。frame rate 的单位是 Hz，表示 1 秒钟内，「放映」多少帧。

前面说该命令用于插入一系列图片，animate 宏包要求这一系列图片有共同的文件名前缀，而后以数字编号表述其顺序。file basename 选项用于记录该前缀；first 和 last 则是这一系列图片编号的起止。

关于文件名后缀，animate 也做了具体要求。首先，animate 要求插入的图片，**后缀名必须是小写**。其次，animate 对文件搜索顺序做了规定（实际上是 graphicx 的规定）：

- pdfLaTeX / LuaLaTeX：pdf, mps, png, jpg, jpeg, jbig2, jb2, jp2, j2k, jpx

- XeLaTeX / LaTeX -> dvipdfmx：pdf, mps, eps, ps, png, jpg, jpeg, bmp

- LaTeX -> dvips -> ps2pdf：eps, mps, ps

注意到两件事情：一，上述后缀名中没有 gif，这意味着不能直接插入 GIF 格式的动图；二，前面提到，使用 animate 宏包插入动图实际是插入一系列的图片，这意味着我们需要将 GIF 格式的动图，预先转换成一系列符合要求的格式之图片。

转换格式需要用到 [ImageMagick](//www.imagemagick.org/script/index.php) 这一开源的工具。安装它，Mac 用户可以使用 brew install ImageMagick，Linux 用户可以使用各自的包管理器，Windows 用户则需要[下载](//www.imagemagick.org/script/download.php#windows)安装。

安装好 ImageMagick 之后，我们就可以用它提供的 convert 命令将 GIF 格式的动图逐帧地切分成一系列图片了。假设你的目标图片是 foo.gif，那么使用如下命令可以得到一系列图片：foo-0.png, foo-1.png, foo-2.png, ...

```bash
convert foo.gif -coalesce foo.png
```

而后，我们就可以用 animate 提供的 \animategraphics 命令插入动图了。

```tex
\documentclass{article}
\usepackage{graphicx}
\usepackage{animate}
\begin{document}
\animategraphics{24}{foo-}{0}{300}
\end{document}
```

![](/uploads/images/LaTeX/Convolution_of_spiky_function_with_box2.gif)

图片引用自 [Wikipedia](//zh.wikipedia.org/wiki/%E5%8D%B7%E7%A7%AF)。

## animate 选项

animate 宏包提供的选项，按照适用范围可以分为三类：只能用于宏包的选项、只能用于接口的选项（命令和环境）、二者皆适用的选项。现分别介绍。

这里仅介绍其中重要的部分，未尽之详细，请参考 animate 的宏包文档。

### 只能用于宏包的选项

- dvipdfmx：驱动选项，表示用户希望使用 LaTeX -> dvipdfmx 进行编译。

- xetex：驱动选项，表示用户希望使用 XeLaTeX -> xdvipdfmx 进行编译。

### 只能用于接口的选项

这里的接口指的是 animate 宏包提供的用户接口。例如我们已经见过的 \animategraphics 命令，以及下一节会介绍的 animateinline 环境。

- label=<label text>：为 animate 对象指定唯一的标签，可用于之后的 JavaScript 控制。

- every=<num>：只为每个第 <num> 帧构建动画，而忽略剩余的帧。

### 二者皆适用的选项

- type=<type name>：使用指定的图片类型（而不按照前面提到的顺序搜索）。

- poster[= first | <num> | last | none]：指定用于打印和默认展示的动画帧，默认是第一帧。

- autopause：当动画所在页不再呈现时，自动暂停动画。

- autoresume：当被暂停的动画重新呈现时，自动恢复播放。

- autoplay：当动画所在页在 PDF 阅读器中呈现时，自动播放动画。

- loop：播放到最后一帧时，从第一帧开始继续播放；如此往复。

- palindrome：播放到最后一帧时，逐帧倒退；如此往复。

- step：忽略 frame rate，只在每次点击鼠标时播放一帧。

- width=<h-size>, height=<v-size>, totalheight=<v-size>, keepaspectratio：按绝对长度缩放动画的大小。

- scale=<factor>：按比例缩放动画的大小。

- controls：展示用于控制动画的按钮。

- begin=<begin content>, end=<end content>：仅用于 animateinline 环境，在每一帧的内容前后添加相应内容。

## 使用 animate 插入用户绘制的动画——animateinline 环境

之前我们介绍了如何使用 ImageMagick 拆分 GIF 动图，而后用 \animategraphics 将拆分得到的一系列图片在 LaTeX 中插入 PDF 文档，变成动画。然而，这可能存在几个问题

- 从它处获取的 GIF 动图可能侵犯他人版权；

- 自行制作 GIF 动图成本较高——不如直接用 Ti*k*Z 等工具绘制。

因此，这就引出了更高级的主题：使用 animate 宏包，插入用户自行绘制的动画。这需要引入一个新的用户接口——animateinline 环境。它的语法是这样的：

```tex
\begin{animateinline}[<options>]{<frame rate>}
... typeset material ...
\newframe[<frame rate>]
... typeset material ...
\newframe*[<frame rate>]
... typeset material ...
\newframe
\multiframe{<number of frames>}{[<variables>]}{
... repeated (parameterized) material ... }
\end{animateinline}
```

显而易见，animateinline 环境的语法比 \animategraphics 要复杂得多。不过，仔细看的话，其实是有相通之处的。

首先，和 \animategraphics 命令一样，animateinline 环境允许用户通过 options 和 frame rate 控制动画的基本行为。不同之处在于，\animategraphics 的动画内容是固定死的——由图片提供，而 animateinline 的动画内容则需要用户在 LaTeX 代码中逐帧绘制。因此，animateinline 环境提供了三个命令来辅助和控制这些内容。

\newframe 和 \newframe* 的作用正如其名：结束上一帧并开始下一帧。唯一的不同在于，\newframe 会立即开始下一帧，而 \newframe* 则会暂停并等待用户的点击再开始下一帧。它们接受一个可选参数，以便在动画的中途改变 frame rate。

\multiframe 则更为强大，它能提供类似循环的功能，并将「循环变量」传递到 \multiframe 内部供内部绘图命令使用。具体来说，首先我们需要给出循环的次数 number of frames，而后指定循环变量 variables。循环变量的书写格式如下

```tex
<variable name>=<initial value>+<increment>
```

这里，variable name 由若干个字母组成，不含 LaTeX 命令的反斜线。需要注意的是，variable name 的首字母是有意义的，它决定了变量的类型。

- 整数：i, I

- 浮点数：n, N, r, R

- 长度：d, D

initial value 表示循环变量的初始值，而 increment 表示循环变量在每次循环末尾自增的值。

因此，我们可以写出如下代码

```tex
\multiframe{10}{iAngle=0+10, dLineWidth=3pt+-0.1pt}{
... repeated (parameterized) material ... }
```

这样，循环会执行 10 次，同时带有两个循环变量：整型变量 iAngle 和 dLineWidth。前者从 0 开始，每次增加 10；后者从 3pt 开始，每次减少 0.1pt。而后，在循环体中（\multiframe 命令的内部），我们就可以使用 \iAngle 和 \dLineWidth 获得循环变量的值了。

```tex
\documentclass{article}
\usepackage{graphicx}
\usepackage{animate}
\usepackage{tikz}
\usetikzlibrary{positioning}
\tikzset{global scale/.style={
    scale=#1,
    every node/.append style={scale=#1}
  }
}
\tikzset{global xscale/.style={
    xscale=#1,
    every node/.append style={xscale=#1}
  }
}
\tikzset{global yslant/.style={
    yslant=#1,
    every node/.append style={yslant=#1}
  }
}
\newcommand{\twodimdrawcontent}[2]{%
\useasboundingbox (0, -6) rectangle (16.1, 3);
\begin{scope}[global yslant = -0.6, xshift = 1cm, yshift = -1cm]
  \node (A) at (0, 0) {};
  \node (B) at (3, 0) {};
  \node (C) at (3, 3) {};
  \node (D) at (0, 3) {};
  \draw (0,0) grid (3,3);
\end{scope}
\node[anchor = north, xscale = 2] at (2, -5) {Kernel};

\begin{scope}[xshift = 6cm, global yslant = -0.6, yshift = -2cm]
  \node (E) at (0cm + #1cm, 2cm - #2cm) {};
  \node (F) at (3cm + #1cm, 2cm - #2cm) {};
  \node (G) at (3cm + #1cm, 5cm - #2cm) {};
  \node (H) at (0cm + #1cm, 5cm - #2cm) {};
  \draw[fill, blue!20] (0cm + #1cm, 2cm - #2cm) rectangle (3cm + #1cm, 5cm - #2cm);
  \draw[fill, blue!50] (1cm + #1cm, 3cm - #2cm) rectangle (2cm + #1cm, 4cm - #2cm);
  \draw (0,0) grid (5,5);
\end{scope}
\node[anchor = north, xshift = 6cm, xscale = 2] at (2, -5) {Input};

\begin{scope}[xshift = 12cm, global yslant = -0.6, xshift = 1cm, yshift = -1cm]
  \node (I) at (0.5cm + #1cm, 2.5cm - #2cm) {};
  \draw[fill, red!20] (0cm + #1cm, 2cm - #2cm) rectangle (1cm + #1cm, 3cm - #2cm);
  \draw (0,0) grid (3, 3);
\end{scope}
\node[anchor = north, xshift = 12cm, xscale = 2] at (2, -5) {Output};

\draw[dashed, blue] (A.center) -- (E.center);
\draw[dashed, blue] (B.center) -- (F.center);
\draw[dashed, blue] (C.center) -- (G.center);
\draw[dashed, blue] (D.center) -- (H.center);

\draw[dashed, red] (E.center) -- (I.center);
\draw[dashed, red] (F.center) -- (I.center);
\draw[dashed, red] (G.center) -- (I.center);
\draw[dashed, red] (H.center) -- (I.center);
}
\begin{document}
\begin{animateinline}[
    loop,autopause,controls,
    buttonsize=1.2em,
    buttonbg=0.6:0.6:1,buttonfg=0.2:0.2:1,
    begin={\begin{tikzpicture}[global scale = 0.7, global xscale = 0.5, on grid]},
    end={\end{tikzpicture}}]{1.8}
    \multiframe{3}{icol=0+1}{%
      \xdef\icol{\icol}
      \xdef\irow{0}
      \whiledo{\lengthtest{\irow sp < 2sp}}{
        \twodimdrawcontent{\irow}{\icol}
        \newframe
        \pgfmathsetmacro{\irow}{\irow + 1}
        \xdef\irow{\irow}
      }
      \twodimdrawcontent{\irow}{\icol}
    }
\end{animateinline}
\end{document}
```

绘图的核心代码定义在 \twodimdrawcontent 这一命令当中。该命令的内容完全是 Ti*k*Z 的语法，不在此篇的涵盖范畴中。因此不表。唯一需要注意的是，我们使用了 \useasboundingbox (0, -6) rectangle (16.1, 3); 限定每一个动画帧的大小。这是因为 animateinline 会根据第一帧的大小来确定动画的大小；若是每一帧大小不同，则可能出现某些帧显示不全的现象。

我们仔细看 animateinline 环境中的参数。loop, autopause, controls 我们很熟悉了；buttomsize, buttonbg, buttonfg 顾名思义，是用来调整按钮的样式的；begin 和 end 则在每一帧的内容前后加上了 tikzpicture 环境。这样，我们可以直接使用 \twodimdrawcontent 来绘制动画帧。

animateinline 环境的帧率（frame rate）是 1.8，这意味着每秒会播放 1.8 个动画帧（每 5 秒播放 9 帧）。具体的动画帧内容，则由 \multiframe 给出。

\multiframe 循环 3 次，对应循环变量为 icol。这是一个整型变量，从 0 开始每次自增 1。在循环体内，我们首先定义 \xdef\icol{\icol}；这是因为，\multiframe 给出的循环变量，若直接传给 \twodimdrawcontent 则无法正确展开。随后我们将 \irow 定义为 0。接下来，我们使用 \whiledo 的循环。此处不使用 \multiframe 的原因是它无法嵌套。这一循环的变量是 \irow。它从 0 开始，每次循环末尾由 \pgfmathsetmacro{\irow}{\irow + 1}, \xdef\irow{\irow} 自增 1。\whiledo 循环两次，内部用 \twodimdrawcontent{\irow}{\icol}, \newframe 制作出一帧动画。最后在 \whiledo 循环的外部，画出第三帧。

如此，就能得到我们在[前文](/2017/07/27/convolutions-and-convolution-neural-network/)中的动画效果了。

![](/uploads/images/MachineLearning/convolutions_on_images.gif)

偏好使用 PSTricks 的用户，可以参考 animate 宏包文档里的示例。

## 一点彩蛋

```tex
\documentclass{article}
\usepackage{graphicx}
\usepackage{animate}
\newcommand{\myemph}[1]{%
  \begin{animateinline}[autoplay, loop]{.5}
  \emph{#1}
  \newframe[1.5]
  \relax
  \end{animateinline}}
\begin{document}
This is \myemph{important}!
\end{document}
```