---
title: "订制 Sublime Text 下 LaTeXTools 插件的编译脚本"
url: https://liam.page/2014/12/14/advanced-builder-latextools/
date: 2014-12-14
categories: ["LaTeX"]
tags: ["Python", "LaTeXTools", "Compile"]
---

[LaTeXTools](https://github.com/SublimeText/LaTeXTools) 是 [Sublime Text](http://www.sublimetext.com/) 上的一个插件，用以增强在 Sublime Text 上编辑和编译 LaTeX 文档的体验。但是其自带的编译脚本比较难用，缺点如下：

- 调用 LaTeXmk 或者 TeXify，多次编译，速度缓慢，难以切换。

- 无法在编译时方便地添加命令行参数，导致依赖 \write18 命令的宏包（比如 minted）无法使用。

为了解决这个问题，我自己写了一个编译脚本，命名为 advancedBuilder.py。

## 安装方法

- 在[这里](//liam.page/attachment/attachment/LaTeX-useful-tools/advancedBuilder.py)下载编译脚本；

- 打开 Sublime Text 目录；

- 将脚本拷贝至 ./Packages/LaTeXTools/builders/；

- 编辑 ./Packages/User/LaTeXTools.sublime-settings，将 "builder" 值从原来的 traditional 改为 advanced，即："builder": "advanced"；

- 重启 Sublime Text。

## 使用方法

基本的使用方法和原本的 traditionalBuilder.py 相同，即使用快捷键 Ctrl + B 编译（Mac OS X 是 CMD + B）。但在文档开头的注释中，增加了更多的用法。

### 改变编译流程

可以在主文档开头的注释中，使用下列语法改变编译流程。

```tex
%!TEX builder = BUILDER
```

其中 BUILDER 的可选值有：

- SIMPLE

- LATEXMK

- TEXIFY

大小写不论，默认是 SIMPLE，即只编译一遍。

### 选择编译引擎

此功能继承自默认编译脚本，有增强。

可以在主文档开头的注释中，使用下列语法改变编译引擎。

```tex
%!TEX program = PROGRAM
```

其中 PROGRAM 的可选值有：

- pdflatex

- xelatex

- lualatex

- platex-ng

- pdftex

- xetex

- luatex

- ptex-ng

大小写敏感，默认值是 pdflatex。

### 选择编译参数

可以在主文档开头的注释中，使用下列语法添加编译参数。

```tex
%!TEX option = OPTION
```

其中 OPTION 的可选值为对 PROGRAM 合法的任意参数。大小写敏感，默认为空。

另外，强制启动 -interaction=nonstopmode 和 -synctex=1 两个参数，不允许更改。

### 指定主文档

此功能完整继承自默认编译脚本。

可以在子文档的开头注释中，使用下列语法指定主文档。

```tex
%!TEX root = ROOT
```

其中 ROOT 为主文档相对当前子文档的路径。指定主文档之后，可以在子文档中直接使用快捷键编译主文档，而不用将 Sublime Text 标签页切换到主文档再进行编译。

## 示例

```tex
\documentclass{article}
\begin{document}
Hello world!
\end{document}
```

对应的命令行为：

```bash
pdflatex -interaction=nonstopmode -synctex=1  foo.tex
```

```tex
%!TEX builder = latexmk
\documentclass{article}
\begin{document}
Hello world!
\end{document}
```

对应的命令行为：

```bash
latexmk -cd -e $pdflatex = 'pdflatex -interaction=nonstopmode -synctex=1  %S %O' -f -pdf foo.tex
```

```tex
%!TEX builder = latexmk
%!TEX program = xelatex
%!TEX option = -shell-escape
\documentclass{article}
\begin{document}
Hello world!
\end{document}
```

对应的命令行为：

```bash
latexmk -cd -e $pdflatex = 'xelatex -interaction=nonstopmode -synctex=1 -shell-escape %S %O' -f -pdf
```

```tex
%!TEX builder = latexmk
%!TEX program = xelatex
%!TEX option = -shell-escape
\documentclass{article}
\begin{document}
\input{bar.tex}
\end{document}
```

```tex
%!TEX root = foo.tex
Hello world!
```

在 bar.tex 的窗口编译，命令行为：

```bash
latexmk -cd -e $pdflatex = 'xelatex -interaction=nonstopmode -synctex=1 -shell-escape %S %O' -f -pdf
```