---
title: "极致优雅——Sublime Text 简介/入门/技巧"
url: https://liam.page/2013/11/11/Sublime-elegant/
date: 2013-11-11
categories: ["LaTeX"]
tags: ["Sublime", "Tricks", "Tips"]
---

Sublime Text 是一个顶尖的代码、标记语言、随笔编辑器。你会爱上它华丽的界面、超凡的功能和令人惊叹的表现。---[http://www.sublimetext.com/](http://www.sublimetext.com/)

## 简介与初步

在折腾过无数 IDE 和被无数编辑器折磨过之后，我毅然投入了 Sublime Text (ST for Short)的怀抱。如剑客渴望名剑一样，ST 就是我渴望的[誓约胜利之剑](http://zh.wikipedia.org/zh/%E7%8E%8B%E8%80%85%E4%B9%8B%E5%8A%8D)，尽管它的售价高达 70 USD[^1](%E5%AE%9E%E9%99%85%E4%B8%8A%E4%BD%9C%E8%80%85%E5%BE%88%E8%B4%B4%E5%BF%83%E5%9C%B0%E6%8F%90%E4%BE%9B%E4%BA%86%E6%B0%B8%E4%B9%85%E8%AF%95%E7%94%A8%E7%9A%84%E5%8A%9F%E8%83%BD%EF%BC%8C%E4%BB%85%E4%BB%85%E4%BC%9A%E4%BB%A5%E4%B8%80%E4%B8%AA%E5%BE%88%E4%BD%8E%E7%9A%84%E9%A2%91%E7%8E%87%E6%8F%90%E7%A4%BA%E8%B4%AD%E4%B9%B0%E3%80%82%E8%B4%AD%E4%B9%B0%E7%BD%91%E5%9D%80%EF%BC%9A%5Bhttp://www.sublimetext.com/buy%5D(http://www.sublimetext.com/buy)).

### 下载与安装

你可以在[ST 官网](http://www.sublimetext.com/)找到醒目的下载链接，对于 Windows 系统，当前正式版为 [2.02](http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%202.0.2%20Setup.exe), 最新测试版为 [ST 3 build 3047](http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%20Build%203047%20Setup.exe). 对于 ST 3 build 3047, 这里提供一个便携版的本站[下载](//liam.page/attachment/attachment/Sublime/Sublime Text Build 3047.zip), 这一版本来自[官方](http://www.sublimetext.com/3)，这里仅仅是提供另一个下载点。

ST 的安装不必多说，对于可执行文件按照步骤来即可，对于便携版本只需解压到希望的目录下即可。

这里我们讨论在 Windows 系统下的操作，我们假定 ST 根目录为

```plaintext
C:\ST\
```

### 中文化

对于希望将编辑器界面汉化的，可以下载[汉化包 for 3047](//liam.page/attachment/attachment/Sublime/Default.sublime-package)并置于 C:\ST\Data\Installed Packages\ 目录下即可。

#### 选择一个合适的字体

在 Windows 系统下，Sublime 默认会使用 Consola 这个字体。作为英文字体来说，它是一个等宽字体，并且设计得十分适合写代码。但很可惜，因为一些原因，尽管英文字体优秀，中文字体默认却使用宋体。尽管这也是一个优秀的字体，但是看久了会很累，并不适合编程使用。

基于这个理由，我将 Consola 和微软雅黑字体合二为一，制作了一个名为 Adina 的字体。可以在这里[下载](http://pan.baidu.com/s/1nujj8vv). [^2](%E5%A6%82%E6%9E%9C%E8%AF%A5%E5%AD%97%E4%BD%93%E4%BE%B5%E7%8A%AF%E4%BA%86%E6%82%A8%E7%9A%84%E6%9D%83%E7%9B%8A%EF%BC%8C%E8%AF%B7%E8%81%94%E7%B3%BB%E6%88%91%E3%80%82%E6%88%91%E4%BC%9A%E5%9C%A8%E6%94%B6%E5%88%B0%E6%B6%88%E6%81%AF%E4%B9%8B%E5%90%8E%E7%9A%84%E7%AC%AC%E4%B8%80%E6%97%B6%E9%97%B4%E5%9B%9E%E5%A4%8D%E6%82%A8%E5%B9%B6%E5%88%A0%E9%99%A4%E7%9B%B8%E5%85%B3%E8%B5%84%E6%BA%90%E3%80%82)

安装好字体之后，你可以在 Sublime Text 的窗口中，在菜单栏上找到 Preferences - 'Settings - User'. 在打开的文件之中增加：

```plaintext
"font_face": "Adina",
"line_padding_bottom": -1,
"line_padding_top": 0,
```

这样，Sublime Text 就能使用 Adina 字体了。

### 安装 Package Control

Package Control 是一个用来管理插件的插件。它能够按照所需启用/停用插件，安装/卸载插件，并支持自动更新插件，十分强大。因此，它几乎是使用 ST 必备的插件。

[](//liam.page/attachment/attachment/images/Sublime/sublime_text_package_control.png)
[Package Control 在 ST 控制面板中的示例](https://sublime.wbond.net/).

安装方法如下：

- 点击 Preference/Browse Packages;

- 跳转到上一级目录，并进入 Installed Packages/;

- 下载 [Control.sublime-package](https://sublime.wbond.net/Package%20Control.sublime-package) 并置于 Installed Packages/;

- 重启 ST.

至此，在 Preferences 下就能看到 Package Control 的按钮了，使用 Ctrl + Shift + p (C-S-p for Sort) 调出命令面板，输入 Package Control: 即可看到它的全部功能。这一命令面板在你今后的使用中会不断给你带来惊喜。

一个使用 Package Control 安装插件包的例子在[这里](/Sublime-with-LaTeX/#latextools).

### 激活码

对于 ST 这样一柄神剑来说，使用盗版并不是一件值得提倡的事情，70 USD 的价格也确实值得上它的价值，何况作者提供了永久试用的功能。所以最好还是[买吧](http://www.sublimetext.com/buy)！

当然，[朽木博客](http://www.xiumu.org/note/sublime-text-3.shtml)提供了一份可用的激活码。

## 入门

这一节的大部分内容，来自[官网首页](http://www.sublimetext.com/)和 [Nettuts+ 对 Sublime Text 2 的介绍](http://net.tutsplus.com/tutorials/tools-and-tips/sublime-text-2-tips-and-tricks/)。

### 记号约定

从这里开始，我们将会遇到许多的快捷键。考虑到 ST 是跨平台的，为了统一符号，作如下约定

记号
Windows
Mac OS

C-
Ctrl
Command

S-
Shift
Shift

A-
Alt
Option

----

C-c
Ctrl + c
Command + c

C-S-p
Ctrl + Shift + p
Command + Shift + p

----

C-kk
Ctrl + k, Ctrl + k
Command + k, Command + k

C-l, v
Ctrl + l, v
Command + l, v

### 最具特色的

#### Goto Anything

Goto Anything 使你可以通过敲击少量按键打开任意文件，并跳转至某一符号、行或单词。

按下 C-p, 然后

- 输入文件名的某一部分以打开文件；

- 输入 @ 跳转至某一符号，# 搜索文件，: 跳转至行。[^3]

也可以组合使用，比如 tp@tf 会把你带到 *text_parser.py* 这个文件的 *read_file* 函数位置。类似，tp:100 会把你带到这一文件的第 100 行。

#### Multiple Selections

你可以通过 Multiple Selections 功能同时更改十个位置，而非是在十个位置分别做十次同样的操作。这允许你交互地对很多行进行更改，比如修改变量名，操作一系列文件。

C-S-l 能将选中的部分分离成行，C-d 会选中下一个重现词。你也可以参考[这里](http://www.sublimetext.com/docs/2/column_selection.html)，学习如何使用鼠标进行 Multiple Selections.

#### Command Palette

Command Palette 整合了并不常用的功能，比如排序、改变语法规则、改变缩进设置。只需要简单敲击键盘，你就能找到你想要的功能；在导航栏上寻找功能或是记忆晦涩的快捷键将成为历史。

你可以通过 C-S-p 来打开 Command Palette.

#### Distraction Free Mode

当你需要集中精力的时候，Distraction Free Mode 正是你所需的。Distraction Free Mode 将打开全屏模式，除了你的文档之外屏幕上一无所有。你可以根据所需，增加 UI 中的元素。

你可以点击 View - Distraction Free Mode 进入 Distraction Free Mode.[^4]

#### Split Editing

尽最大可能利用你的宽屏。你可以将屏幕分成任意多的栏或行，编辑不同的文件或者相同文件的不同部分。

对于具有多显示器的机器，你可以在各个屏幕上分别使用 Split Editing, 或者将每一个屏幕当做是 Split Editing 的一个窗口。

在 View - Layout 菜单中可以找到 Split Editing 的选项。

#### Instant Project Switch

ST 中的 projects 能捕捉工作空间中的所有内容，包括修改且尚未保存的文件。你可以以类似 Goto Anything 的方式瞬间切换 projects. 这种时候不会出现「未保存」的提示——所有的修改，在下一次打开 project 的时候都会被复原。

#### Plugin API

ST 有一个基于 Python 的强大插件 [API](http://www.sublimetext.com/docs/2/api_reference.html). 同时，ST 还有一个内建的 Python 控制台，以供随时进行交互测试。

#### Customize Anything

ST 中的任何东西——包括按键绑定、菜单、代码片段、宏、自动补全——都是通过 JSON 文件来控制的。这种机制使得你能够灵活地为每一文件类型和项目来进行不同的配置。

#### Cross Platform

ST 在 OS X, Windows 和 Linux 上都能工作。你可以使用同一许可证在任意系统上使用 ST.

### 更加详细的介绍

参考 [Nettuts+ 对 Sublime Text 2 的介绍](http://net.tutsplus.com/tutorials/tools-and-tips/sublime-text-2-tips-and-tricks/)的[译文](http://lucifr.com/2011/08/31/sublime-text-2-tricks-and-tips/)，由 [Lucifr](http://lucifr.com/about) 翻译。

## 快捷键

### 文件操作/跳转

按键
作用

C-p
跳转

C-g
按行跳转

C-r
按标记跳转[^5]

C-;
按搜索关键词跳转

C-S-p
打开命令面板

C-o
打开文件

C-s
保存

C-S-s
另存为

C-w
关闭当前文件

C-S-w
关闭所有打开文件

C-`[^6]
打开/关闭 Python 命令行

### 界面切换

按键
作用

<F11>
切换全屏

S-<F11>
切换免打扰模式

C-kb
开关侧边栏

A-S+<NUM>
分为 <NUM> 栏

A-<NUM>
切换至打开的第 <NUM> 个文件

C-<Tab>
切换 Tab

C-S-<Tab>
向前切换 Tab

C-i
显示底部面板

### 文本编辑

按键
作用

C-a
全选

C-c
选中后复制

C-x
选中后剪切

C-v
粘贴

C-z
撤销

C-y
恢复撤销

C-u
软撤销（可以撤销光标移动）

C-S-u
恢复软撤销

C-f
查找

C-S-f
在所有打开文件中查找

C-h
替换

C-S-F
查找并替换

<F3>
查找下一个

S-<F3>
查找前一个

C-t
光标所在位置的左右字符或单词互换

C-<Backspace>
删除一个单词

C-ku
改为大写

C-kl
改为小写

C-d
选中光标位单词，继续按键复选下一重复单词

C-l
选中当前行，继续按键继续选定下一行

A-<F3>
复选所有重复单词

S-<右键拖拽>
多行光标/多行复选

C-<左键拖拽>
复选

C-S-<Space>
选定光标所在范围

C-A-<↑>
向上多行光标

C-A-<↓>
向下多行光标

<Tab>
选中部分缩进

S-<Tab>
选中部分取消缩进

C-]
选中部分缩进

C-[
选中部分取消缩进

### 代码编辑

按键
作用

C-m
光标移动至匹配括号位置

C-S-m
选择括号包含的内容，继续按键选定上一级括号内的内容

C-S-[
折叠

C-S-]
展开折叠

C-A-]
选中部分代码自动对齐

C-/
注释/取消注释行 或 注释/取消注释选定部分

C-S-/
注释/取消注释选定部分

### 整行编辑

按键
作用

C-kk
从光标位置开始，删除到行尾

C-k<Backspace>
从光标位置开始，删除到行首

C-S-k
删除整行

C-S-<Backspace>
删除整行

C-S-<↑>
光标所在行与上行互换

C-S-<↓>
光标所在行与下行互换

C-S-d
复制光标所在行，并插入在当前行之前

C-<Enter>
在光标所在行的后面插入新行，并移动光标

C-S-<Enter>
在光标所在行的前面插入新行，并移动光标

### 标记

按键
作用

C-<F2>
设置/去除标记

<F2>
跳转至下一个标记位置

S-<F2>
跳转至上一个标记位置

C-S-<F2>
清除所有标记

[^3]: 你可以按下 C-r 来跳转到符号，或是按下 C-g 跳转到行。[^4]: 按下 S-F11 可以进入/退出 Distraction Free Mode, 按下 F11 可以进入/退出普通的全屏模式。[^5]: 根据当前设定的语法规则有不同，例如，在 Markdown 模式下，会按照标题跳转；在 Python 等程序语言下，会按照函数名称定义来跳转；在 LaTeX 下，会按照章节标题/标签来跳转。[^6]: 这个键在数字 1 的左边，是英文的「反引号」。