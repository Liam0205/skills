---
title: "【LaTeX Tips】如何确定某个宏定义的位置"
url: https://liam.page/2013/11/20/LaTeX-How-to-find-out-where-a-macro-is-defined/
date: 2013-11-20
categories: ["LaTeX"]
tags: ["Macro", "Package"]
---

我们在排错的时候，经常希望知道出错的宏是在哪里定义的，然后通过比对定义和现有情况判断错误原因。

LeoLiu 在 [TeX.SX](http://tex.stackexchange.com/a/8523/38350) 给出了一个利用 filehook 宏包实现的方法，效果拔群！当然，方法有些讨巧。

代码：

```tex
\documentclass{article}
\usepackage{filehook,currfile}
\newwrite\finder
\immediate\openout\finder=\jobname.fnd

\def\searchmacro#1{
  \AtBeginOfFiles{\ifdefined#1
      \expandafter\def\csname \currfilename:found\endcsname{}%
    \fi}
  \AtEndOfFiles{\ifdefined#1
      \unless\ifcsname \currfilename:found\endcsname
        \immediate\write\finder{found in '\currfilename'}%
    \fi\fi}}

\searchmacro\url

\usepackage{hyperref}
\begin{document}
dummy
\end{document}
```

编译后，在 \jobname.fnd 里我们能找到

```plaintext
found in 'url.sty'
found in 'hyperref.sty'
```

也就是说，\url 是在 url.sty 里定义的，而 url.sty 被 hyperref.sty 调用。

We would be glad to know where a certain macro is defined, when we are debugging. LeoLiu provided a method by using the package filehook, on the website [TeX.SX](http://tex.stackexchange.com/a/8523/38350). It's really great!

The code is somewhat tricky:

```tex
\documentclass{article}
\usepackage{filehook,currfile}
\newwrite\finder
\immediate\openout\finder=\jobname.fnd

\def\searchmacro#1{
  \AtBeginOfFiles{\ifdefined#1
      \expandafter\def\csname \currfilename:found\endcsname{}%
    \fi}
  \AtEndOfFiles{\ifdefined#1
      \unless\ifcsname \currfilename:found\endcsname
        \immediate\write\finder{found in '\currfilename'}%
    \fi\fi}}

\searchmacro\url

\usepackage{hyperref}
\begin{document}
dummy
\end{document}
```

After compiling, we will get

```plaintext
found in 'url.sty'
found in 'hyperref.sty'
```

in \jobname.fnd. That is to say, \url is defined in url.sty, which is inputed by hyperref.sty.