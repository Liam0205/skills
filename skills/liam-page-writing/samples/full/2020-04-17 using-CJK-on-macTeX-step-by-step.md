---
title: "手把手教你在 MacTeX 上使用 CJK"
url: https://liam.page/2020/04/17/using-CJK-on-macTeX-step-by-step/
date: 2020-04-17
categories: ["LaTeX"]
tags: ["CJK", "step-by-step", "macTeX"]
---

时至今日，劝说用户不使用 CJK 已磨破了无数张嘴皮。然而，因为各种各样的历史原因，仍然有很多用户因各种理由需要继续使用 CJK。当然，这些理由大多数是不充分的（在我看来），但仍有一些站在普通用户的角度是充分的。因此，如果你因为如下原因使用 CJK，我表示愿意提供一定的协助：

- 需要投稿某些中文期刊，但这些期刊的模板使用了 CJK 作为中文支持方式的；

- 与他人协作时，群体意志决定使用 CJK 而你无法反抗的。

对于 Windows 用户，出于上述原因需要使用 CJK 时，可在 TeX Live 中搭配王越、吴凌云等人提供的 zhwinfonts.tex，借助 zhmetrics 技术使用 CJK。但对于 macOS 用户，zhwinfonts.tex 则不好用。因为 zhwinfonts.tex 是为 Windows 上的中易字体编写的。

我曾经写过一篇文章[在 MacTeX 中使用中文模板](/2015/04/14/using-chinese-templates-in-mactex/)详细阐述这一系列问题。但其中关于 CJK 的部分，仍有用户反馈无法使用。于是有这篇文章——不介绍详细原理，只说详细步骤。

## 安装字体

因为技术上的原因，macOS 自带的字体无法搭配 zhmetrics 技术。因此，你需要下载支持该技术的字体。

- 下载下列字体（因涉及到版权，请自行搜索下载）
方正书宋 GBK：FZSSK.TTF
方正楷体 GBK：FZKTK.TTF
方正黑体 GBK：FZHTK.TTF
方正仿宋 GBK：FZFSK.TTF
华文隶体：STLITI.ttf（安装 Office 之后自带）
华文琥珀：STHUPO.TTF（安装 Office 之后自带）

- 安装字体（以 FZSSK.TTF 为例）
![](/uploads/images/LaTeX/installing_fzssk.jpg)

- 安装成功后，在 Font Book.app 当中应当可见相应字体（以 FZSSK.TTF 为例）安装在 ~/Library/Fonts/FZSSK.TTF
![](/uploads/images/LaTeX/installed_fzssk.jpg)

## 修改 TeX Live 配置文件

- 打开 Finder.app

- 按下快捷键 Command + Shift + G，输入 /usr/local/texlive 而后点击「Go」（如果目录不存在，说明你没有将 macTeX 安装在默认位置，请自行调整）
![](/uploads/images/LaTeX/modifying_texmf.cnf.jpg)

- 进入相应的年份目录（我这里是 2020），而后用 TextEdit.app 打开 texmf.cnf

- 检查文件中是否有 OSFONTDIR 变量

- 若无，则在文件最后新增一行，内容为：OSFONTDIR = ~/Library/Fonts//:/Library/Fonts//:/System/Library/Fonts//

- 若有，则确保其中包含 ~/Library/Fonts 这个目录
![](/uploads/images/LaTeX/modified_texmf.cnf.jpg)

## 安装 zhfzfonts.tex

打开 Terminal.app，依次执行下列命令：

```bash
ls -l /usr/local/texlive/texmf-local # 确认目录存在（如果不存在，说明你没有将 macTeX 安装在默认位置，请自行调整）
mkdir -p /usr/local/texlive/texmf-local/tex/generic/zhmetrics/ # 新建目录
cd /usr/local/texlive/texmf-local/tex/generic/zhmetrics/ # 进入刚才新建的目录
wget https://liam.page/attachment/attachment/LaTeX-useful-tools/zhfzfonts.tex # 下载 `zhfzfonts.tex`
texhash # 刷新 ls-R 数据库，可能需要 `root` 权限
```

![](/uploads/images/LaTeX/installing_zhfzfonts.jpg)

## 试用 CJK

至此，你可以如常使用 CJK 宏包支持中文，只需要在导言区额外新增一行即可：\AtBeginDvi{\input{zhfzfonts}}。

```tex
\documentclass{article}
\usepackage{CJK}  % CJKutf8
\AtBeginDvi{\input{zhfzfonts}}
\begin{document}
\begin{CJK*}{UTF8}{song}
中文。
\clearpage
\end{CJK*}
\end{document}
```

你可以使用 PDFLaTeX 编译，也可以使用 LaTeX - DVIPDFMx 编译。得到结果如下图所示。

![](/uploads/images/LaTeX/CJK_macOS.jpg)

注意，CJK 支持 GBK，也支持 UTF-8。因此，你需要将文档编码保存为与 CJK 环境相同的编码格式。