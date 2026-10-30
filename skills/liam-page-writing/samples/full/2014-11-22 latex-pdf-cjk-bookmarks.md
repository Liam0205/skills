---
title: "在 LaTeX 中使用含有中文的 PDF 书签避免乱码的正确姿势"
url: https://liam.page/2014/11/22/latex-pdf-cjk-bookmarks/
date: 2014-11-22
categories: ["LaTeX"]
tags: ["PDF", "CJK", "Bookmarks", "Error Codes"]
---

LaTeX 的 hyperref 宏包能够在 PDF 文件里生成 PDF 书签，然而「书签乱码」是困扰很多 LaTeX 使用者的麻烦问题。

早年李树钧和张林波老师共同开发了名为 [gbk2uni](http://www.hooklee.com/tex/gbk2uni.zip) 的小工具，用以将 filename.out 中的 GBK 编码的字符转换成八进制数据；刘海洋和李清在 [ctex](https://code.google.com/p/ctex-kit/) 宏包/文档类对此做了处理，使得 ctex 宏包/文档类能够正确处理大部分的情况；后来李清编写了 [xCJK2uni](http://www.ctan.org/pkg/xcjk2uni) 宏包，使得在 pdfLaTeX 编译方式下用 CJK 的 GBK 编码模式也能正确输出 PDF 书签，而不必借用额外的工具。

这里对全部正确的方式做一个总结。

## 推荐的方式

最好的办法是将中文支持和版式处理都交给 ctex 宏包/文档类，只需要开启 hyperref 选项即可。

适用情况

- UTF-8 + XeLaTeX（目前**最最最最最最最最**推荐的方式，看到它请星星眼）

- UTF-8 + pdfLaTeX

- UTF-8 + LaTeX - DVIPDFMx

```tex
\documentclass[hyperref, UTF8]{ctexart}
\begin{document}
\section{中文书签不会乱码}
UTF-8 编码，Xe\LaTeX{}/pdf\LaTeX{}/\LaTeX{} - DVIPDFMx 编译。
\end{document}
```

```tex
\documentclass{article}
\usepackage[hyperref, UTF8]{ctex}
\begin{document}
\section{中文书签不会乱码}
UTF-8 编码，Xe\LaTeX{}/pdf\LaTeX{}/\LaTeX{} - DVIPDFMx 编译。
\end{document}
```

适用情况（除非必要，不要使用 GBK 编码）

- GBK + LaTeX - DVIPDFMx

- GBK + pdfLaTeX （CTeX 宏集 2.x 版本支持，旧版本不支持）

```tex
\documentclass[hyperref, GBK]{ctexart}
\begin{document}
\section{中文书签不会乱码}
GBK 编码，pdf\LaTeX{}/\LaTeX{} - DVIPDFMx 编译。
\end{document}
```

```tex
\documentclass{article}
\usepackage[hyperref, GBK]{ctex}
\begin{document}
\section{中文书签不会乱码}
GBK 编码，pdf\LaTeX{}/\LaTeX{} - DVIPDFMx 编译。
\end{document}
```

## 折腾星人的方式

如果不想使用 ctex 宏包/文档类，也可以选择自己写代码进行中文支持。这时候需要做额外的代码配置，保证 PDF 书签不会乱码。

适用情况

- UTF-8 + XeLaTeX

```tex
\documentclass{article}
\usepackage{xeCJK}
\usepackage{hyperref}
\setCJKmainfont{SimSun}
\begin{document}
\section{中文书签不会乱码}
UTF-8 编码，Xe\LaTeX{} 编译。
\end{document}
```

适用情况

- UTF-8 + pdfLaTeX

```tex
\documentclass{article}
\usepackage{CJKutf8}
\usepackage{hyperref}
\hypersetup{unicode}
\AtBeginShipoutFirst{\input{zhwinfonts.tex}}
\begin{document}
\begin{CJK*}{UTF8}{song}
\section{中文书签不会乱码}
UTF-8~编码，pdf\LaTeX{}~编译。
\clearpage
\end{CJK*}
\end{document}
```

适用情况

- UTF-8 + LaTeX - DVIPDFMx

```tex
\documentclass{article}
\usepackage{CJKutf8}
\usepackage[dvipdfmx]{hyperref}
\hypersetup{unicode}
\AtBeginShipoutFirst{\input{zhwinfonts.tex}}
\begin{document}
\begin{CJK*}{UTF8}{song}
\section{中文书签不会乱码}
UTF-8~编码，\LaTeX{} - DVIPDFMx~编译。
\clearpage
\end{CJK*}
\end{document}
```

适用情况

- GBK + pdfLaTeX （谁特么还在用 GBK 啊！摔！）

请大家将感谢信发送至 [李清](http://www.zhihu.com/people/qinglee) 的邮箱~

```tex
\documentclass{article}
\usepackage{CJK}
\usepackage{xCJK2uni} % 请大家将感谢信发送至 李清 的邮箱~ : )
\usepackage{hyperref}
\AtBeginShipoutFirst{\input{zhwinfonts.tex}}
\begin{document}
\begin{CJK*}{GBK}{song}
\section{中文书签不会乱码}
GBK~编码，pdf\LaTeX{}~编译。
\clearpage
\end{CJK*}
\end{document}
```

适用情况

- GBK + LaTeX - DVIPDFMx（谁特么还在用 GBK 啊！摔！）

```tex
\documentclass{article}
\usepackage{CJK}
\usepackage[dvipdfmx]{hyperref}
\hypersetup{CJKbookmarks}
\AtBeginShipoutFirst{\input{zhwinfonts.tex}}
\AtBeginShipoutFirst{\special{pdf:tounicode GBK-EUC-UCS2}}
\begin{document}
\begin{CJK*}{GBK}{song}
\section{中文书签不会乱码}
GBK~编码，\LaTeX{} - DVIPDFMx~编译。
\clearpage
\end{CJK*}
\end{document}
```