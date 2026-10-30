---
title: "【LaTeX Tips】国内期刊 CCT 模板编译经验"
url: https://liam.page/2013/10/15/LaTeX-CCT-template/
date: 2013-10-15
categories: ["LaTeX"]
tags: ["Template", "CCT", "SYSENGI"]
---

国内有不少期刊依旧在使用过时的 CCT 方式来支持中文，这些模板非常相似，似乎系出同源。由于这些模板在现代的 TeX 发行版内无法正确编译，对不少投稿人造成困扰，所以我写下这篇文章，希望对投稿人有一些帮助。

## 模板特征

这些模板的导言区内代码大致如下：

```tex
\documentclass[twoside]{cctart}
\usepackage{headrule,vatola,amssymb}
\usepackage{graphicx,multirow,bm}
\usepackage{booktabs,dcolumn}
\newcolumntype{z}[1]{D{.}{.}{#1}}
\usepackage{tabularx}
\usepackage{slashbox}
%\usepackage{footmisc,perpage}
```

提取出以下几条特征：

- \documentclass 里载入 cctart 文档类；

- 载入了 vatola 宏包；

- 载入了 headrule 宏包；

- 载入了 slashbox 宏包。

如果你手上的模板符合这些特征，那么这篇文章将对你有帮助。

### 列表

这里给出一个列表，记录使用此类模板的期刊。如果你发现你投稿的期刊也使用了这样的模板（符合上述特征），请留言告诉我；我将会及时补充到列表当中，方便后来者。

- [系统工程理论与实践](http://www.sysengi.com/) - [LaTeX 模板](http://www.sysengi.com/UserFiles/File/model2019.tex)

- [数学的实践与认知](http://ssjs.cbpt.cnki.net/WKA2/WebPublication/index.aspx?mid=ssjs) - [LaTeX 模板](http://211.151.247.86/Editor/2013/0516/ssjs/9c56b9c5-ab32-4bcc-980a-6861cebffefd.tex)

- [计算科学](http://www.computmath.com/Jwk_jssx/CN/column/column84.shtml)

- [数学年刊](http://camath.fudan.edu.cn/camacn/ch/index.aspx) - 页面左侧，「常用下载」栏

## 问题分析

这些模板使用的文档类是 cctart，是 CCT 系统的一部分。CCT 系统是早年的一个中文支持方式，现在已经过时。虽然 CTeX 里还保留了 CCT，但是和这些编写模板时的版本已经不同；至于 TeX Live 里，根本就没有 CCT 系统。所以，编译报错也就是自然而然的事情了。

模板使用了 vatola 和 headrule 两个宏包。这两个宏包均是 LaTeX 2.09 时代的陈旧宏包；他们的功能已为其他宏包所替代。因此，现代的发行版（[TeX Live](http://www.tug.org/texlive/)、[CTeX 2.9.2.164](http://www.ctex.org/CTeXDownload)）不再包含这些宏包；于是，编译的时候会提示缺少宏包的错误。

此外，虽然 slashbox 宏包是为当前的 LaTeX 2e 设计的，但是它的许可协议与 TeX Live 的协议有冲突，因此 TeX Live 中并不包含这个宏包。于是，如果你的 TeX 发行版是 TeX Live，那么编译的时候也会提示错误。

## 解决方案

陈旧的模板与现代的 TeX 发行版之间的矛盾不可调和，因此必有一方需要妥协。

如果你坚持**不改动模板**，那么就只好使用与模板同时代的 TeX 发行版。当然，你必须使用 Windows 操作系统。

你可以到下载 [CTeX 2.4.6](ftp://159.226.92.9/pub/software/Windows/CTeX-2.4.6-Full.exe) 并安装。CTeX 2.4.6 里的 WinEdt 有一个 CCTLaTeX 按钮，点击它之后，可以正确编译得到 .dvi 和 .ps 文件，如果需要 .pdf 文件可以用 ps2pdf 工具转换。

如果你坚持**使用现代的发行版**，那么就需要对模板进行一些微调。这里提供两种方法，两种方法均适用于各个操作系统。

**使用 ctexart**

- 将 \documentclass 里载入的文档类，从 cctart 更换为 ctexart；

- 下载本站提供的 [vatola.sty](//liam.page/attachment/attachment/LaTeX-useful-tools/old_style/vatola.sty) 和 [headrule.sty](//liam.page/attachment/attachment/LaTeX-useful-tools/old_style/headrule.sty) 两个宏包文件（**2014-12-17 更新**）；

- 到 CTAN 上下载 [slashbox 宏包](http://www.ctan.org/pkg/slashbox) 并安装；

- 将上述三个宏包安装至 TEXMFLOCAL，然后执行 texhash 命令；或者直接将它们放在与模板文件相同的文件夹里面；

- 使用 pdfLaTeX 编译，可以得到与原模板几乎完全一致的结果；

- 正式投稿时，只需要将 ctexart 换回 cctart 即可。

**安装新版 CCT 系统 (2014-12-21 更新）**

- 下载 CCT 的 [TDS 安装包](//liam.page/attachment/attachment/LaTeX-useful-tools/CCT_TDS.zip)；

- 将 TDS 安装包中的内容，解压合并至 TEXMFLOCAL 的相应目录；

- 将 \documentclass 里文档类选项，从 twoside 更换为 twoside, CJK；

- 在 \documentclass 之后加载 ifpdf 宏包：\usepackage{ifpdf}；

- 下载本站提供的 [vatola.sty](//liam.page/attachment/attachment/LaTeX-useful-tools/old_style/vatola.sty) 和 [headrule.sty](//liam.page/attachment/attachment/LaTeX-useful-tools/old_style/headrule.sty) 两个宏包文件（**2014-12-17 更新**）；

- 到 CTAN 上下载 [slashbox 宏包](http://www.ctan.org/pkg/slashbox) 并安装；

- 将上述三个宏包安装至 TEXMFLOCAL，然后执行 texhash 命令；

- 分情况讨论：
如果使用 Windows 系统，则在 \begin{document} 之前添加一行命令 \AtBeginDvi{\input{zhwinfonts}}；
如果使用 Mac OS X 或 Linux 系统，则需要安装好 Windows 的中易字体，然后在 \begin{document} 之前添加一行命令 \AtBeginDvi{\input{zhwinfonts}}；
如果使用 Mac OS X 或 Linux 系统，你也可以安装下列字库，然后在 \begin{document} 之前添加一行命令 \AtBeginDvi{\input{zhfzfonts}}；
方正书宋GBK：FZSSK.TTF
方正楷体GBK：FZKTK.TTF
方正黑体GBK：FZHTK.TTF
方正仿宋GBK：FZFSK.TTF
华文隶体：STLITI.ttf
华文琥珀：STHUPO.TTF

- 使用 pdfLaTeX 编译，可以得到与原模板完全一致的结果；

- 正式投稿时，只需要将添加的 CJK 选项和 ifpdf 宏包以及 \AtBeginDvi{} 命令删除就可以了。

## 总结

总的来说 CCT 是一个过时的中文支持方式，非常希望系统工程理论与实践的编辑部能与时俱进改用新的方式支持中文，为所有作者提供方便。对于广大的 LaTeX 用户，除非特别需要，不要使用老旧的 TeX 发行，以增强文档的兼容性。

同时也希望各位作者向期刊编辑反映这个问题，尽快淘汰这些模板。