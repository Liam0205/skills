---
title: "解决 beamer 中列表环境无法两端切齐的问题"
url: https://liam.page/2017/04/11/justifying-in-beamer-s-lists/
date: 2017-04-11
categories: ["LaTeX"]
tags: ["Beamer", "Justifying"]
---

众所周知，beamer 作为一个幻灯片文档类，大多数情况是不做两端对齐的。但是，有些强（chu）迫（nv）症（zuo）宝宝总喜欢让列表环境有两端对齐的效果。

这篇文章来治一治这样的强迫症。

## 原因分析

为了支持幻灯片的效果，beamer 重定义了 LaTeX 中常见的列表环境。对列表环境的重定义放在 beamerbaselocalstructure.sty 当中。我们截取一段对 itemize 环境的重定义看看。

```tex
\renewcommand{\itemize}[1][]{%
  \beamer@ifempty{#1}{}{\def\beamer@defaultospec{#1}}%
  \ifnum \@itemdepth >2\relax\@toodeep\else
    \advance\@itemdepth\@ne
    \beamer@computepref\@itemdepth% sets \beameritemnestingprefix
    \usebeamerfont{itemize/enumerate \beameritemnestingprefix body}%
    \usebeamercolor[fg]{itemize/enumerate \beameritemnestingprefix body}%
    \usebeamertemplate{itemize/enumerate \beameritemnestingprefix body begin}%
    \list
      {\usebeamertemplate{itemize \beameritemnestingprefix item}}
      {\def\makelabel##1{%
          {%
            \hss\llap{{%
                \usebeamerfont*{itemize \beameritemnestingprefix item}%
                \usebeamercolor[fg]{itemize \beameritemnestingprefix item}##1}}%
          }%
        }%
      }
  \fi%
  \beamer@cramped%
  \raggedright%
  \beamer@firstlineitemizeunskip%
}
```

不难发现，在重定义的 \itemize 也就是 itemize 环境的前半段命令中，显式地使用了 \raggedright 命令。这个命令的作用，是在不在右侧尝试对齐文字。于是我们会看到这样的效果。

```tex
\documentclass{beamer}
\usepackage{mwe}
\begin{document}
\begin{frame}
  \begin{itemize}
    \item \blindtext
  \end{itemize}
\end{frame}
\end{document}
```

![](/uploads/images/LaTeX/beamer_itemize_raggedright.png)

因此，修正这个问题，我们只需要修正 \raggedright 的效果就好了。

## patchcmd

我们在[排版伪代码时打印垂直的缩进提示线](/2016/06/10/pseudocode-with-vertical-line/)一文中，介绍了来自 etoolbox 宏包的 \patchcmd 命令。这个命令可以在 TeX 宏中搜索特定的内容，然后替换成想要的东西。

不过，来自 etoolbox 的 \patchcmd 在对付「带有可选参数的命令」就会失效。为了解决这个问题，我们可以引入来自 xpatch 的 \xpatchcmd 命令。这个命令的用法和 \patchcmd 完全一样；并且它支持对带可选参数的命令进行补丁。

值得一提的是，xpatch 宏包里定义的命令，都有非常明确的用法，整个宏包的代码量也不多。因此，是学习 LaTeX3 的一个很好的实例。

于是，我们只需要给 \itemize 命令打个补丁就可以了。

```tex
\usepackage{ragged2e}
\usepackage{xpatch}
\xpatchcmd{\itemize}{\raggedright}{\justifying}{}{}
```

这里，我们使用 \xpatchcmd 命令，将 \itemize 命令中的 \raggedright 替换成来自 ragged2e 宏包的 \justifying 命令。这个命令，会使 TeX 尝试将文字做两端切齐。我们可以看一下效果。

```tex
\documentclass{beamer}
\usepackage{mwe}
\usepackage{ragged2e}
\usepackage{xpatch}
\xpatchcmd{\itemize}{\raggedright}{\justifying}{}{}
\begin{document}
\begin{frame}
  \begin{itemize}
    \item \blindtext
  \end{itemize}
\end{frame}
\end{document}
```

![](/uploads/images/LaTeX/beamer_itemize_justifying.png)

如果想要修正 enumerate 或者 description 环境的两端切齐问题，也可以用类似的操作。