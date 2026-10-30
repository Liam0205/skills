---
title: "如何使用美赛模板 mcmthesis"
url: https://liam.page/2016/01/27/how-to-use-mcmthesis/
date: 2016-01-27
categories: ["LaTeX"]
tags: ["mcmthesis"]
---

最早由[王昭礼](http://www.latexstudio.net/)编写制作的 mcmthesis 模板，服务了许多届参加美国大学生数学建模竞赛（简称：美赛）的大学生。2014 年我接手了模板的开发和维护工作，将模板由宏包改为文档类，并上传至 [CTAN](http://www.ctan.org/pkg/mcmthesis)。截至今日，TeX Live (2015 及之后的版本) 和 MiKTeX 均收录了这个模板。

这篇文章将介绍一下模板的基本情况和用法。

在所有的正文内容开始之前，我认为有必要做一些简短的说明。

- 美赛**并没有**强制要求必须使用 LaTeX 排版参赛论文，使用 Microsoft Office Word 进行论文的编排也是可以的。往年也有很多使用 Word 排版出的优秀论文的获奖情况。

- LaTeX 是一个「精致的」文书准备系统，使用起来有一定的门槛。虽然 mcmthesis 已经在很大程度上减少了美赛参与者在这方面的工作了，但是我**不推荐**毫无 LaTeX 使用经验的参赛者使用。

- 如果你确实毫无使用经验，或是自我感觉对 LaTeX 的了解还有很多模糊的地方，建议你先看一下[这篇文章](/2014/09/08/latex-introduction/)。

- LaTeX 圈子流行着一句话：使用模板就不要管格式。简单来说，目前的模板已经适配了美赛官方对论文格式的全部要求，不需要用户再做任何修改。在美赛有限的参赛时间内，纠结诸如「给目录中的 \section 添加引导符」之类的审美上的需求，纯粹是**自作自受且自讨苦吃**。

下面开始正文。

## 获取模板

### 普通用户

对于普通用户来说，建议认真阅读这段文字，不要采用高级用户手工编译安装的方式安装。所谓「普通用户」指得就是你。

对于普通用户来说，建议使用所谓「即开即用」的版本。

- 安装好一个 TeX 发行版，推荐 [TeX Live](/texlive/)/MiKTeX；不推荐 CTeX 套装。

- 前往[发布页面](https://github.com/Liam0205/mcmthesis/releases/)，下载最新的稳定版本。

- 解开压缩包。

- 阅读 mcmthesis.pdf 及本文后，编辑 mcmthesis-demo.tex 文件，直接开始使用。

### 中级用户

前文已经提到，模板已经被 TeX Live 和 MiKTeX 收录。因此，使用这两个发行版的用户，可以通过相应的宏包管理器安装。如果你已经预先安装了**所有宏包**，那么可以跳过「获取模板」这一节，直接使用。**建议完全的新手安装所有宏包，避免以后缺少宏包带来的麻烦**。

至于 CTeX 套装的用户，请[卸载干净 CTeX](http://www.latexstudio.net/archives/5151)，而后[安装 TeX Live](/texlive/) 和你喜欢的编辑器；或者使用上述「即开即用」的版本。

#### TeX Live

在系统命令行下执行：

```bash
tlmgr option repository http://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet
tlmgr update --self --all --reinstall-forcibly-removed
tlmgr install mcmthesis
```

这里第一行，我们使用清华大学的镜像；如果你有更好的选择，也可以设置为你喜欢的镜像。第二行，将现有的宏包都更新到最新。第三行，安装 mcmthesis 模板。

注意，在 Linux/Mac OS X 系统中运行，你可能需要使用 sudo 前缀，以 root 权限执行。

#### MiKTeX

MiKTeX 的宏包管理器有比较好的图形化前端。从开始菜单找到 MiKTeX -> Maintenance (Admin) -> Package Manager (Admin)，打开包管理器。然后选中 mcmthesis 宏包，再点安装按钮就好了。不明白的话，这里有别人做的 Youbute 的视频：[Installing a package with MikTeX](https://www.youtube.com/watch?v=9lM9PbHUcWM)。

### 高级用户

- 模板的官方主页是：[http://www.ctan.org/pkg/mcmthesis](http://www.ctan.org/pkg/mcmthesis)

- 模板的开发主页是：[http://github.com/Liam0205/mcmthesis](http://github.com/Liam0205/mcmthesis)

- 作者王昭礼的主页是：[http://www.latexstudio.net](http://www.latexstudio.net/)

- 我的主页是：[https://liam.page](https://liam.page/)

你可以在模板的[官方主页](http://www.ctan.org/pkg/mcmthesis)下载到模板源文件。解包之后，打开系统命令行，依次执行：

```bash
cd /path/to/mcmthesis
xetex mcmthesis.dtx
xelatex mcmthesis.dtx
xelatex mcmthesis.dtx
xelatex mcmthesis-demo.tex
xelatex mcmthesis-demo.tex
mv LICENSE.tex LICENSE
mv README.tex README
rm *.log *.out *.aux *.glo *.idx
```

接下来：

```bash
mkdir TEXMF/tex/latex/mcmthesis/
mv mcmthesis.cls TEXMF/tex/latex/mcmthesis/
mkdir TEXMF/source/latex/mcmthesis/
mv mcmthesis.dtx TEXMF/source/latex/mcmthesis/
mkdir TEXMF/doc/latex/mcmthesis/
mv ./* TEXMF/doc/latex/mcmthesis/
texhash
```

如果你在执行上面任何一步遇到了问题，说明你可能不是「高级用户」，请参照普通用户的安装方法进行安装。

## 初识模板

### 阅读模板说明

我们要养成良好的习惯，在使用新的工具之前，阅读它的说明书。TeX 系统提供了 texdoc 命令，用于调取各个宏包/组件的说明书。使用方法也很简单，只需要在命令行执行 texdoc <name> 就可以了。例如：

```bash
texdoc mcmthesis
```

会打开 mcmthesis 的说明书。而：

```bash
texdoc mcmthesis-demo
```

则会打开使用 mcmthesis 模板编译的示例文档。

![文档截图](/uploads/images/LaTeX/mcmthesis-doc.png)

### Hello World

我们构建最简单的示例看看：

```tex
%!TeX program = xelatex
%!TeX builder = latexmk
\documentclass{mcmthesis}

\usepackage{blindtext}      % 提供 \blindtext 命令，演示用

\title{The Title}
\author{Liam Huang}
\date{today}

\begin{document}

\begin{abstract}
\blindtext                  % 演示用无意义文字
\begin{keywords}
keyword1; keyword2
\end{keywords}
\end{abstract}

\maketitle                  % 打印控制页等

\blindtext                  % 演示用无意义文字
\end{document}
```

使用 XeLaTeX 编译后，效果如图：

![](/uploads/images/LaTeX/mcmthesis-01.png)

![](/uploads/images/LaTeX/mcmthesis-02.png)

## 调整选项

mcmthesis 提供了 \mcmsetup 命令来调整模板的行为。具体使用方法是载入 mcmthesis.cls 之后调用，例如：

```tex
\documentclass{mcmthesis}
\mcmsetup{tcn = 12345, problem = B, titlepage = false}
```

### 队伍控制号码 / tcn

每个美赛参赛队伍，都会由赛事主办方提供一个唯一的控制号码（Team Control Number）。主办方要求该号码必须出现在摘要页上，以及之后正文的页眉中。mcmthesis 通过选项 tcn 来设定该号码，如果不进行设置，将使用默认的 0000。

```tex
\mcmsetup{tcn = 0000}
```

### 选题 / problem

每个参赛队伍能且只能选择一个题目进行作答。赛事主办方要求参赛队伍将选题的题号标注在摘要页上。mcmthesis 通过选项 problem 来设定选题，如果不进行设置，将使用默认的 A。

```tex
\mcmsetup{problem = A}
```

### 摘要页 / sheet

mcmthesis 用 LaTeX 代码实现了自己的摘要页。如果你觉得默认的摘要页效果不满意，希望使用学校提供的摘要页，或者你有自信用 LaTeX 自己实现摘要页，那么你可以将该选项设置为 false，关闭 mcmthesis 的摘要页输出。如果不进行设置，将使用默认的 true，即输出 mcmthesis 摘要页。

```tex
\mcmsetup{sheet = true}
```

### 摘要页中的标题 / titleinsheet

如果参赛者希望在摘要页中「Summary」的上方显示文章标题，那么可以将该选项设置为 true。如果不进行设置，将使用默认的 false，即不在摘要页中显示文章标题。

```tex
\mcmsetup{titleinsheet = false}
```

注意，赛事主办方没有对摘要页中是否显示文章标题做具体规定。但是，对于主办方来说，在初审（即只看摘要页中的摘要内容）时对文章标题并无兴趣。因此默认设置为 false。

### 摘要页中的关键字 / keywordsinsheet

如果参赛者希望在摘要页中「Summary」的下方显示关键字，那么可以将该选项设置为 true。如果不进行设置，将使用默认的 false，即不在摘要页中显示关键字。

```tex
\mcmsetup{keywordsinsheet = false}
```

注意，赛事主办方没有对摘要页中是否显示关键字做具体规定。但是，对于主办方来说，每篇文章的关键字其实都差不多，加上关键字对初审并没有提高多少信息量，反而显得累赘。因此默认设置为 false。

### 标题页 / titlepage

如果参赛者不希望在摘要页后显示 LaTeX 标准的标题页，那么可以将该选项设置为 false。如果不进行设置，将使用默认的 true，即 mcmthesis 会在摘要页后显示 LaTeX 标准的标题页。

```tex
\mcmsetup{titlepage = true}
```

### 标题页中的摘要 / abstract

如果参赛者认为，摘要页已经显示过一次摘要，在标题页显示摘要有些累赘，故而不希望在摘要页后的标题页中显示摘要（和关键字），那么可以将该选项设置为 false。如果不进行设置，将使用默认的 true，即 mcmthesis 会在标题页中显示摘要。

```tex
\mcmsetup{abstract = true}
```

### CTeX 套装兼容选项 / CTeX

v6.0 及之后版本有此选项

当你使用 CTeX 套装时，请将该选项设置为 true。如果不进行设置，将使用默认的 false，即关闭与 CTeX 套装的兼容。

```tex
\mcmsetup{CTeX = false}
```

[不建议使用 CTeX 套装](http://www.latexstudio.net/archives/5151)

### 定制摘要页头部内容

v6.2 及之后版本有此选项

MCM/ICM 的主办方经常变动摘要页头部的年份及赛事名称说明的格式，可谓岁岁年年各不同。因此，模板很难保证这部分的格式与当年的要求完全一致，故而给出一个易于修改的接口。例如：

```tex
\renewcommand{\headset}{{\Large\the\year}\\MCM/ICM\\Summary Sheet}
```

将输出：

![](/uploads/images/LaTeX/mcmthesis-headset.png)

## 结语

对于大多数中国的大学生来说，参加美赛可能是第一次接触 LaTeX。这是一个好机会，但时间上却显得紧迫。因此，王昭礼和我先后维护了 mcmthesis 模板，希望参加美赛的 LaTeX 用户，在格式上花费最少的时间，办最好的事（即输出效果最好的文章）。

然而，除却模板规定的格式之外，文章质量的好坏，还与用户对 LaTeX 的了解以及用户的代码书写习惯有很大关系。因此，前文才提到「不建议新手使用」的说法。

不过，年年美赛，看着一茬又一茬的学生投入美赛并使用自己写的模板，还是很有成就感的。总的来说，祝各位美赛好运！