---
title: "在 LaTeX 里定义一个类似 proof 的环境"
url: https://liam.page/2014/12/03/how-to-define-a-proof-like-environment/
date: 2014-12-03
categories: ["LaTeX"]
tags: ["Proof", "Environment", "Macros", "AMS"]
---

美国数学协会（AMS）是 TeX 发展中的一支重要的力量。AMS 定义的 proof 环境非常好用，能在证明结束的末尾，自动添加一个「证毕」的符号。

有时我们需要类似的环境，比如[这里](http://bbs.ctex.org/forum.php?mod=viewthread&tid=79516)的题主希望用两个环境区分「证明」和「解答」，并且都需要自动添加结束符号。这时我们可以仿照 amsthm 宏包的做法，自己定义一套环境。

proof 环境的原始定义是这样的：

```tex
\newenvironment{proof}[1][\proofname]{\par
  \pushQED{\qed}%
  \normalfont \topsep6\p@\@plus6\p@\relax
  \trivlist
  \item[\hskip\labelsep
        \itshape
    #1\@addpunct{.}]\ignorespaces
}{\popQED\endtrivlist\@endpefalse}
```

这里 \pushQED{\qed} 把 \qed 压入了 QED 这个堆栈，然后在环境结束的地方，通过 \popQED 把压入堆栈的最后一个元素弹出来。这样的设计是非常合理的。比如，如果在证明的过程中，需要分别证明两个小的情形，这样就能按照次序依次给出证明的结束符号。此外，证明开始的标题通过 \proofname 来控制。

通过这些分析，我们知道定义一个新的环境，我们需要从两个方面入手。其一是 \proofname 的位置需要改变，其二是压入堆栈的内容需要更改。

下面的代码我们定义了一个名为 \fooname 的宏，来替代 \proofname。

```tex
\providecommand{\fooname}{Foo}
```

下面的代码我们定义了名为 \bxz 的宏，来替换原本压入堆栈的 \qed。其中 \bxz 具体的符号内容用 \bxzsymbol 这个宏来控制。

```tex
\DeclareRobustCommand{\bxz}{\ifmmode \mathbxz
  \else
    \leavevmode\unskip\penalty9999 \hbox{}\nobreak\hfill
    \quad\hbox{\bxzsymbol}%
  \fi
}
\newcommand{\mathbxz}{\quad\hbox{\bxzsymbol}}
\providecommand{\bxzsymbol}{\fbox{\footnotesize B.X.Z}}
```

最后，重新定义一个名为 foo 的环境。

```tex
\newenvironment{foo}[1][\fooname]{\par
  \pushQED{\bxz}%
  \normalfont \topsep6\p@\@plus6\p@\relax
  \trivlist
  \item[\hskip\labelsep
        \itshape
    #1\@addpunct{.}]\ignorespaces
}{\popQED\endtrivlist\@endpefalse}
```

完整的测试代码如下：

```tex
\documentclass{article}
\usepackage{amsthm}
\makeatletter
\DeclareRobustCommand{\bxz}{\ifmmode \mathbxz
  \else
    \leavevmode\unskip\penalty9999 \hbox{}\nobreak\hfill
    \quad\hbox{\bxzsymbol}%
  \fi
}
\newcommand{\mathbxz}{\quad\hbox{\bxzsymbol}}
\newenvironment{foo}[1][\fooname]{\par
  \pushQED{\bxz}%
  \normalfont \topsep6\p@\@plus6\p@\relax
  \trivlist
  \item[\hskip\labelsep
        \itshape
    #1\@addpunct{.}]\ignorespaces
}{\popQED\endtrivlist\@endpefalse}
\providecommand{\bxzsymbol}{\fbox{\footnotesize B.X.Z}}
\providecommand{\fooname}{Foo}
\makeatother
\begin{document}
\begin{proof}
\begin{foo}
  The foo goes here.
\end{foo}
\begin{foo}
  \[
    E = mc^{2}.\qedhere
  \]
\end{foo}
This is the conclusion that we need.
\end{proof}
\end{document}
```

![测试代码截图](/images/LaTeX/redefine-proof.png)