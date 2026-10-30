---
title: "将 Sublime Text 作为 LaTeX 前端编辑器"
url: https://liam.page/2013/11/13/Sublime-with-LaTeX/
date: 2013-11-13
categories: ["LaTeX"]
tags: ["Sublime", "LaTeXTools"]
---

## 开始

Sublime Text (ST for short)是一款优雅的编辑器，它的基本情况在[极致优雅——Sublime Text 简介/入门/技巧](/2013/11/11/Sublime-elegant/)一文中已有介绍，这里我们讨论如何在 Windows 下[^1]配置 ST 使之成为 LaTeX 前端，并具有以下特性：

- 使用 ST 内建的 build 工具编译文档；

- 若编译产生错误则列出错误列表，双击错误定位错误代码；

- 若编译不产生错误则启动阅读器；

- 支持正反向搜索（需要 SyncTeX 支持）；

- 支持快捷地插入参考文献和引用（使用 BibTeX）；

- 采用 ST 内建的 Goto Anything 跳转至 LaTeX 源文件中的任意章节；

- 命令自动补全。

## 准备工作

这里讨论 Windows 系统下，ST3 配合 LaTeXTools（ST 的插件），使用 TeX Live 2013 作为 TeX 发行，SumatraPDF 作为 PDF 预览的配置。需要以下软件：

- ST3, 官方[下载](http://www.sublimetext.com/3)，本站 [Protable 版本下载](//liam.page/attachment/attachment/Sublime/Sublime Text Build 3047.zip)；

- Package Control, [参考](/Sublime-elegant/#package-control)；

- LaTeXTools, 官方[下载](https://github.com/SublimeText/LaTeXTools/archive/master.zip)，或使用 Package Control 下载安装（后详）；

- TeX Live, 官方[下载](http://mirror.ctan.org/systems/texlive/Images/), [Protable 安装](http://bbs.ctex.org/forum.php?mod=viewthread&tid=76538)；

- SumatraPDF, 官方[下载](https://kjkpub.s3.amazonaws.com/sumatrapdf/rel/SumatraPDF-2.4.zip), 本站[下载](//liam.page/attachment/attachment/LaTeX-useful-tools/SumatraPDF.exe)。

## 安装 LaTeXTools

ST3/TeX Live 2013/SumatraPDF 的安装乏善可陈，Package Control 插件的安装在参考的文章中讲述得很明白了，这里只说一下 LaTeXTools 的安装。[官方说明](https://github.com/SublimeText/LaTeXTools/blob/master/README.markdown)[^2]中推荐的安装方法有两种，事实上这也是 ST 插件安装的两种标准方法。

### 通过 Package Control 安装

Package Control 是 ST 上优秀的插件管理器，如无意外，推荐使用这种方式安装。

按下 C-S-p, 键入 *install* 如下图所示。

[](//liam.page/attachment/attachment/images/Sublime/Package_Install.png)
[在 ST 命令面板中启动 Package Control 的 Install 功能](https://sublime.wbond.net/)

回车后，在 ST 的下方状态栏中看到：

[](//liam.page/attachment/attachment/images/Sublime/Loading_Repo.png)
[载入插件包仓库](https://sublime.wbond.net/)

载入仓库成功，会出现命令面板，你可以在其中搜索需要安装的插件包。这里我们输入 LaTeXTools, 如图：

[](//liam.page/attachment/attachment/images/Sublime/LaTeXTools_Setup.png)
[搜索 LaTeXTools](https://sublime.wbond.net/)

回车安装，待安装好会弹出 LaTeXTools 的 Package Control Messages.

### 下载插件文件手动安装

在第一节中找到下载，将文件释放到 C:\SublimeText\Data\Packages\. 这里我们假设将 ST 安装在 C:\SublimeText\, 若你安装在其他位置，请相应调整路径。

这一路径可以通过在 ST 窗口菜单栏中，点选 Preferences - Browse Packages 打开。

### 两种安装方式的简单比较

通过 Package Control 安装，完全在 ST 窗口中操作，方便快捷。但是另一方面，通过 Package Control 安装，并没有走 SSL 的加密线路[^3]，因此对安全性需求高的用户只能采取手动安装的方式了。

## 配置 LaTeXTools

LaTeXTools 在 Windows 系统下，对 TeX Live 支持的比 MikTeX 支持的更好，但是在 Windows 的默认情况下，却采用 MikTeX 进行编译。[^4]

这真是一个奇怪而忧伤的故事。

因此我们必须对 LaTeXTools 进行简单的配置才能正确编译。所幸，这个过程并不十分复杂，步骤如下：

- ST 菜单栏上点选 Preferences - Browse Packages, 进入 .\LaTeXTools\ 目录。

- 打开 LaTeX.sublime-build 这个文件（当然推荐你使用 ST 打开）。

- 你会在大约 52 行的位置找到 *windows* 字样，在 73 行附近找到 *BEGIN MikTeX 2009* 的字样，在 90 行附近找到 *BEGIN TeXLive 2011* 字样。

- 将 *BEGIN MikTeX 2009* 和 *END MikTeX 2009* 中间夹着的部分注释掉——在每行前面加上两个斜杠，在 ST 里你可以选中这些行，然后按下 C-/ 键[^5]。

- 将 *BEGIN TeXLive 2011* 和 *END TeXLive 2011* 中间夹着的部分取消注释——将每行前面的两个斜杠去掉，在 ST 里你可以选中这些行，然后按下 C-/ 键。

如此即可。

你可能会奇怪，为什么这里写着 TeXLive 2011, 继而担心是否适用于当前版本的 TeX Live 2013. 答案是肯定的，这里写着 2011 的原因，只是开发 LaTeXTools 的时候适值 TeX Live 2011, 仅此而已。

你可能会注意到，在 TeX Live 模式下，使用的是 LaTeXmk 这个脚本。它是一个使用 Perl 创建的脚本，能帮助你快速编译你的文档——根据所需要的次数和顺序。同样的，在 MikTeX 模式下，使用的是 texify. 这和 TeX Live 下的 LaTeXmk 是类似的，在用户看来，唯一的差别大约是 texify 选择使用编译引擎的时候必须要通过修改参数来实现——而不能只是修改源文件。

## 配置 SumatraPDF

在 Windows 下，与 LaTeXTools 配合的默认预览器是 SumatraPDF. 为了让他们结合起来工作，需要进行下面两步配置。

- 将 SumatraPDF.exe 所在目录添加进[环境变量](http://zh.wikipedia.org/zh/%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F) PATH。

- 在 SumatraPDF 的设置中，设置反向搜索命令行为 "C:\SublimeText\sublime_text.exe" "%f:%l".

如果你不知道如何修改环境变量，请自行 Google.

在配置第二步的时候，你可能会遇到困难。因为「设置反向搜索命令行」默认是隐藏的，只有在打开一个具有 Sync 信息的 PDF 文件时——具有重名的 .synctex.gz 文件，这个选项才会出现。为此你可能在做完第一步的时候，需要参考下一节，编译一个文档，然后在弹出的 SumatraPDF 中进行第二步配置。

## 一个简单的例子

```tex
%!TEX program = xelatex
% 使用 Windows 六套字体（缺省的 winfonts 选项），UTF-8 编码
\documentclass[UTF8]{ctexart}
\begin{document}
文章内容。
\end{document}
```

将这个例子[^6]放入 ST, 可以看到如下图所示的代码编辑界面，保存。

[](//liam.page/attachment/attachment/images/Sublime/LaTeX_UI.png)
[代码编辑界面](https://sublime.wbond.net/)

有时（大多数情况下，如果正确保存了 .tex 扩展名，ST 会自动识别），你可能需要按下 C-S-p 然后键入 LaTeX 来选择代码高亮模式，如下图

[](//liam.page/attachment/attachment/images/Sublime/Set_Syntax_LaTeX.png)
[选择代码高亮模式](https://sublime.wbond.net/)

此时按下 C-b 即可编译，如下图

[](//liam.page/attachment/attachment/images/Sublime/Compile_info.png)
[编译信息](https://sublime.wbond.net/)

编译成功（比如本例）会自动弹出 SumatraPDF 预览；若是不成功，则会列出 Errors 信息，双击 Errors 信息会自动跳转到出错位置，十分方便。

## 更多

更多关于 LaTeXTools 的信息，请参阅 [LaTeXTools 官方文档](https://github.com/SublimeText/LaTeXTools/blob/master/README.markdown)，或阅读我的[翻译稿](http://liam0205.me/Sublime-LaTeXTools)[^7]。

[^1]: 在 OS X 和 Linux 下的配置大同小异，只是在路径、PDF 预览等方面有所不同。[^2]: [这里](http://liam0205.me/Sublime-LaTeXTools)有一份尚不完全的翻译稿。[^3]: [https://sublime.wbond.net/installation](https://sublime.wbond.net/installation)[^4]: [https://github.com/SublimeText/LaTeXTools/blob/master/README.markdown](https://github.com/SublimeText/LaTeXTools/blob/master/README.markdown)[^5]: [http://liam0205.me/Sublime-elegant/#section-12](http://liam0205.me/Sublime-elegant/#section-12)[^6]: 摘自 [CTeX 论坛](http://bbs.ctex.org/forum.php?mod=redirect&goto=findpost&ptid=48244&pid=337082&fromuid=109739), 稍有修改。[^7]: 截至 2013 年 11 月 13 日，尚未翻译完全。