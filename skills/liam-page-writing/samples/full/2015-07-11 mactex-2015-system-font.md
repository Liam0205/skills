---
title: "修复 MacTeX 2015 无法按字体文件名调用系统字体的问题"
url: https://liam.page/2015/07/11/mactex-2015-system-font/
date: 2015-07-11
categories: ["LaTeX"]
tags: ["MacTeX", "Font", "XeLaTeX", "System"]
---

XeLaTeX 是 eTeX 的扩展。它直接支持 Unicode 字符，并且能够调用安装在操作系统的字体。这些特性解决了以往 TeX 切换字体不便的问题，对于中文 TeX 用户来说，更是福音。

前段时间，TeX Live 更新到了 TeX Live 2015 版本，Mac OS X 上相应的也更新到了 MacTeX 2015 版本。不过此次更新之后，XeLaTeX 却无法通过字体文件名调用系统字体。亦即，下列代码无法通过编译（提示 font-not-found）：

```tex
\documentclass{article}
\usepackage{fontspec}
\setmainfont{GillSans.ttc}
\begin{document}
GillSans Test.
\end{document}
```

XeLaTeX 通过字体文件名调用字体需要 kpathsea 库的协助。默认情况下，kpathsea 会搜索 MacTeX 自己的目录树（TEXMF）。如果希望 kpathsea 搜索系统字体目录的话，还需要配置 OSFONTDIR 这个环境变量。

在 MacTeX 2014 中，这个变量是默认配置好了的。但是在 MacTeX 2015 中，不知为何，这个变量没有预先配置。因此，需要用户自行配置。

具体的配置方法如下：

- 打开目录：/usr/local/texlive/2015

- 编辑目录下的文件：texmf.cnf

- 在文件末尾新建一行，加上：OSFONTDIR = /Library/Fonts//:~/Library/Fonts//

- 保存文件

- 重新编译上述代码即可成功