---
title: "listings 配置：MATLAB 语法高亮"
url: https://liam.page/2016/09/01/listings-settings-for-MATLAB/
date: 2016-09-01
categories: ["LaTeX"]
tags: ["Listings", "MATLAB"]
---

最近会用到 MATLAB，总结的时候就想要在 LaTeX 里面插入 MATLAB 的代码。minted 宏包当然是一个选项，不过它基于 Python 的 pygments 库，使用起来有一定门槛；所以最终还是决定要动手配一下 MATLAB 的高亮。

具体来说，配置如下：

```tex
\usepackage{listings}
\usepackage[usenames,dvipsnames]{color}

\definecolor{DarkGreen}{rgb}{0.0,0.4,0.0}

\lstloadlanguages{Matlab}
\lstset{language=Matlab,
        frame=single,                           % single framed
        basicstyle=\small\ttfamily,
        keywordstyle=[1]\color{Blue}\bfseries,  % primitive funs in bold blue
        keywordstyle=[2]\color{Purple},         % args of funs in purple
        keywordstyle=[3]\color{Blue}\underbar,  % user funs in blue with underbar
        stringstyle=\color{Purple},             % strings in purple
        showstringspaces=false,
        identifierstyle=,
        commentstyle=\usefont{T1}{pcr}{m}{sl}\color{DarkGreen}\small,
        tabsize=4,
        % more standard MATLAB funcs
        morekeywords={sawtooth, square},
        % args of funcs
        morekeywords=[2]{on, off, interp},
        % user funcs
        morekeywords=[3]{FindESS, homework_example},
        morecomment=[l][\color{Blue}]{...},     % line continuation (...) like blue comment
        numbers=left,
        numberstyle=\tiny\color{Blue},
        firstnumber=1,
        stepnumber=1
        }
```

每个设置的作用，在注释里都有了。具体使用起来，效果如下。

![](/uploads/images/LaTeX/lst-matlab.png)