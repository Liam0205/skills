---
title: "为 MacTeX 配置中文支持"
url: https://liam.page/2014/11/02/latex-mactex-chinese-support/
date: 2014-11-02
categories: ["LaTeX"]
tags: ["MacTeX", "OS X", "CJK"]
---

最近有人问到如何在 MacTeX 里配置中文支持，这里一并回答。

目前来说，结合 xeCJK 宏包使用 XeLaTeX 编译，应该是最方便的方式了。

XeLaTeX 要求 .tex 文档保存为 UTF-8 编码。所以要做的事情只有两件：

- 配置一个 UTF-8 的编辑环境；

- 用 xeCJK 的语法选择合适的字体。

## 配置 UTF-8 的编辑环境

MacTeX 自带了名为 TeXshop 的编辑器，这里以它为例配置 UTF-8 的编辑环境。其他编辑器也有类似配置。

打开 TeXshop，按下 cmd + , 打开偏好设置。在「源代码」标签下找到编码设置，调整为 UTF-8。然后单击「好」保存即可。

![调整 TeXshop 的编码](//liam.page/attachment/attachment/images/MacTeX_xeCJK/01.png)

## 查找字体信息

XeTeX 在 Mac OS X 下的行为和 Windows/Linux 下不大一样。Mac 底下，XeTeX 并不使用 fontconfig 库来搜索字体，所以我们没法在终端里通过 fc-list 命令来查看可用的字体列表。不过 Mac 里提供了名为「字体册」的程序，来列出系统中所有可用的字体信息。

其实这样的设计挺讨厌的，TeX Live 自带了许多开源字体，因此没有办法很好地使用。必须用字体名而不是字族名来调用这些字体，实在是不太方便。当然，如果有需要，我们可以把 TeX 里自带的这些开源字体用硬链接的方式，添加到 Mac 的字体目录下。

打开字体册程序，找到需要的字体信息：

![在字体册中查找字体信息](//liam.page/attachment/attachment/images/MacTeX_xeCJK/02.png)

这里的 PostScript 名称就是我们需要的信息，我们记下华文宋体的名字：「STSong」。你还可以按需找到其他字体的名字，比如华文中宋、华文楷体、华文黑体等字体的名字。

## 用 xeCJK 的语法配置字体

使用下列代码，配置中文字体。

```tex
\usepackage{xeCJK}
\setCJKmainfont[BoldFont=STZhongsong, ItalicFont=STKaiti]{STSong}
\setCJKsansfont[BoldFont=STHeiti]{STXihei}
\setCJKmonofont{STFangsong}
```

这里，

- 文档中文主字体是华文宋体，对应的 bfseries 字体是华文中宋，对应的 itshape 字体是华文楷体；

- 文档的「无衬线」中文字体是华文新黑，对应的 bfseries 是华文黑体；

- 文档的「等宽」中文字体是华文仿宋。

完整代码的编译效果截图如下：

![编译效果 ](//liam.page/attachment/attachment/images/MacTeX_xeCJK/03.png)

## 使用 ctex 宏包和文档类 [2015-05-21 更新]

xeCJK 之解决了中文支持问题，以及一些关于标点的处理，并没有提供和中文版式相关的解决方案。ctex 宏包和文档类封装了 xeCJK，同时提供了中文版式的相关支持。新版的 ctex 宏包和文档类能够自动检测用户使用的操作系统，自动选择合适的字体配置，十分方便。

```tex
\documentclass[UTF8]{ctexart}
\begin{document}
中文
\end{document}
```

测试截图如下：

![编译效果 ](//liam.page/attachment/attachment/images/MacTeX_xeCJK/04.png)

如果希望 ctex 只提供中文支持的功能不对版式做任何修改，也可以这样使用：

```tex
\documentclass{article}
\usepackage[UTF8, heading = false, scheme = plain]{ctex}
\begin{document}
中文
\end{document}
```