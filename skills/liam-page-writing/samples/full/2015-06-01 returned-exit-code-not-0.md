---
title: "驱动选项错误导致「returned exit code (1)」的错误"
url: https://liam.page/2015/06/01/returned-exit-code-not-0/
date: 2015-06-01
categories: ["LaTeX"]
tags: ["Driver", "Exit Code"]
---

TeX 是一个相当庞大的系统，其中的程序、格式、宏包和工具繁多。新手比较容易接受直观的现象，对于 TeX 系统中繁琐抽象的概念则了解甚少。

比如说，新手听闻「LaTeX」之名，于是在编译的时候看见 pdfLaTeX 或 XeLaTeX 的时候就会犹豫：「这是不是我听说的那个 LaTeX 呢」。于是，新手可能会倾向于使用 LaTeX 去编译。编译完成之后，又面临着将 DVI 文件转化为 PDF 文件的问题，这时候新手又会面临两个选择：

- 使用 dvips 先转换为 PS 文件，再使用 ps2pdf 转换为 PDF 文件

- 使用 DVIPDFMx 直接转换为 PDF 文件

两种方式在新手眼中的差异直观而明显：「前一种方式多了 PS 文件这个中间步骤」。诚然，这是对的，但是却忽略了一些细节但关键的东西。这样不经意的忽略往往为后来的错误埋下了根源，比如新手经常会遇到下列一些错误：

- 使用 WinEdt 时，弹出对话框提示「returned exit code (1)」

- 编译完成后不报错，但是插入的图片显示异常

- 编译完成后不报错，但是纸张尺寸或超链接异常

这些错误往往是驱动选项错误导致的，准确地说，是驱动选项和实际使用的驱动不一致导致的。而所谓驱动，就是 dvips 和 DVIPDFMx 这些转换工具。

不同的生成 PDF 文件的路径，会用到不同的工具（我们称之为「驱动」）。这里给一个简单的列表：

- DVI - PS - PDF：LaTeX -> dvips -> ps2pdf，要用到 dvips 这个驱动

- DVI - PDF: LaTeX -> DVIPDFMx，要用到 DVIPDFMx 这个驱动

- PDF (Directly): pdfLaTeX，驱动就是它自己（pdfTeX）

- xDV - PDF: XeLaTeX -> xDVIPDFMx，驱动是 xDVIPDFMx（默认自动调用）

常见的编译方式，至少涉及到 dvips、DVIPDFMx、pdfTeX、xDVIPDFMx 四种驱动。这四种驱动对插图、PDF 书签、页面纸张大小等内容进行处理的时候，语法有细微的差别。为了让驱动正常工作，在 (pdf/Xe)LaTeX 编译的时候，就必须让相应的宏包按照驱动的要求工作。

现在的问题是，宏包怎么知道应当怎么工作？

如果你有注意到，就会发现，对于 pdfLaTeX 和 XeLaTeX 来说，能使用的驱动就只有一种情况；但是对于 LaTeX 来说，可以选择 dvips 和 DVIPDFMx 两种驱动。因此，如果用户选择 pdfLaTeX 或者 XeLaTeX 编译，那么宏包是可以自己检测到的，此时不需要进行特别的设置。但是，如果用户选择 LaTeX 编译，那么宏包就不知道应该怎么工作了。为了简化代码（也由于历史原因），这些宏包在用户使用 LaTeX 编译的时候，「默认使用」dvips 这个驱动；而如果希望使用 DVIPDFMx 的话，就需要在加载宏包的时候以宏包选项的方式给出说明。

那么什么时候会出错呢？

其实很简单：当实际使用的驱动和宏包的工作模式（取决于驱动选项）不一致的时候，就会出错。

比如，如果使用 \usepackage[pdftex]{graphicx} 载入 graphicx 宏包，那么就只能使用 pdfLaTeX 编译。此时使用 LaTeX 或者 XeLaTeX 都会报错。又比如，如果使用 \usepackage[dvipdfmx]{hyperref} 载入 hyperref 宏包，那么就只能使用 LaTeX - DVIPDFMx 的方式编译。此时使用 pdfLaTeX、XeLaTeX 或者 LaTeX - dvips 的话就会报错。

更有甚者，如果是这样子：

```tex
\usepackage[pdftex]{graphicx}
\usepackage[dvipdfmx]{hyperref}
```

两个宏包使用的驱动选项不一致，那么不管怎么编译，都会报错。喜欢「抄代码」的新手，经常遇到这样的问题：东抄抄西抄抄，结果两个作者没商量好，写出来的代码一个需要 pdfLaTeX 编译，另一个需要 LaTeX - DVIPDFMx 编译，于是就坑死了新手。所以：代码自己写，不要抄代码。

总结一下，要想得到正确的结果，就必须根据使用的驱动来填写正确的宏包驱动选项。常见的情况记录如下：

- LaTeX - dvips：默认情况，可以不给驱动选项，也可以给驱动选项 dvips

- LaTeX - DVIPDFMx：无法自动检测，必须手工给出驱动选项 dvipdfm 或者 dvipdfmx （详情查阅相应宏包文档）

- pdfLaTeX：可以自动检测，因此可以不给驱动选项，也可以给驱动选项 pdftex

- XeLaTeX：可以自动检测，因此可以不给驱动选项，也可以给驱动选项 xetex