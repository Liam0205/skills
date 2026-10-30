---
title: "使用 TikZ 给版面着色"
url: https://liam.page/2017/05/14/make-text-area-colored-by-TikZ/
date: 2017-05-14
categories: ["LaTeX"]
tags: ["TikZ", "Color"]
---

有时候，我们需要给 LaTeX 添上一些背景颜色。讲道理，大多数情况，我们只需要给整个 paper 都染色就好了。此时，我们可以用[前文](/2014/04/22/LaTeX-watermark/)提到的方法来实现。

```tex
\watermark{0}{1}{\tikz\fill[cyan] (0,0) rectangle (\paperwidth, \paperheight);}
```

但是，若希望只针对特定的区域着色——比如只给版芯着色，就需要额外的讨论了。

## TeX 的版面尺寸

为了确定所需着色的区域，我们首先需要了解一下 TeX 的版面尺寸。在 LaTeX 中，我们可以使用 layout 宏包，打印当前的版面尺寸。

```tex
\documentclass{book}
\usepackage{layout}
\begin{document}
  \layout
\end{document}
```

输出可见：

- [奇数页](/uploads/images/LaTeX/book-layout-odd.png)

- [偶数页](/uploads/images/LaTeX/book-layout-even.png)

仔细观察不难发现，LaTeX 中四个基本的版面区域，都是由矩形框定的。而确定对角两点，就能确定一个矩形。我们以整个纸张的左下角为原点，试着来确定一下这四个区域的位置。

首先，LaTeX 区分奇数页和偶数页。对于奇偶页来说，它们的边距是不一样的。因此，我们有必要区分 \oddsidemargin 和 \evensidemargin。

```tex
% RequirePackage ifoddpage
\def\currentsidemargin{%
    \ifoddpageoroneside
        \oddsidemargin
    \else
        \evensidemargin
    \fi
}
```

同理，对于奇偶页来说，边注放置的位置也是不一样的。因此，我们有必要确定边注区域左边线相对版芯左边线的位置。

```tex
% RequirePackage ifoddpage
\def\currentmarginoffset{%
    \ifoddpageoroneside
        \textwidth + \marginsep
    \else
        -\marginsep - \marginparwidth
    \fi
}
```

这样一来，我们就统一了奇偶页的边距和边注的相对位置。

### 纸面

- 左下角：(0, 0)

- 右上角：(\paperwidth, \paperheight)

### 版芯

- 左下角：(1in + \hoffset + \currentsidemargin, \paperheight - 1in - \voffset - \topmargin - \headheight - \headsep - \textheight)

- 右上角：(1in + \hoffset + \currentsidemargin + \textwidth, \paperheight - 1in - \voffset - \topmargin - \headheight - \headsep)

### 页眉

- 左下角：(1in + \hoffset + \currentsidemargin, \paperheight - 1in - \voffset - \topmargin - \headheight)

- 右上角：(1in + \hoffset + \currentsidemargin + \textwidth, \paperheight - 1in - \voffset - \topmargin)

### 页脚

- 左下角：(1in + \hoffset + \currentsidemargin, \paperheight - 1in - \voffset - \topmargin - \headheight - \headsep - \textheight - \footskip)

- 右上角：(1in + \hoffset + \currentsidemargin + \textwidth, \paperheight - 1in - \voffset - \topmargin - \headheight - \headsep - \textheight - \footskip + \headheight)

### 边注区域

- 左下角：(1in + \hoffset + \currentsidemargin + \currentmarginoffset, \paperheight - 1in - \voffset - \topmargin - \headheight - \headsep - \textheight)

- 右上角：(1in + \hoffset + \currentsidemargin + \currentmarginoffset + \marginparwidth, \paperheight - 1in - \voffset - \topmargin - \headheight - \headsep)

## 在指定区域填充底色

有了四个区域的具体位置，我们就可以着手对相关区域进行填色了。比如你想要使用 TikZ 对它们进行填色，就需要就相关区域定义具体的 node。索性，tikzpagenodes 宏包已经为我们妥善定义好了相关的区域。

- current page: 整个纸张区域

- current page text area: 整个版芯区域

- current page header area: 整个页眉区域

- current page footer area: 整个页脚区域

- current page marginpar area: 整个边注区域

于是，如果你想要从版芯区域的左上角开始，一直用青色填充到版芯区域右下角至纸张右边的区域，就可以这样做了。

```tex
\documentclass{book}
\usepackage{tikz}
\usepackage{tikzpagenodes}
\usepackage{xcolor}
\newcommand*{\ColorRectangle}[3]{%
  \tikz[overlay, remember picture]
    \fill[#1] (#2) rectangle (#3);%
}

\usepackage{blindtext}
\begin{document}
  \ColorRectangle{cyan}
  % left top anchor point
  {current page text area.north west}
  % right bottom anchor point
  {current page text area.south east -| current page.south east}
  \blindtext
\end{document}
```

![](/uploads/images/LaTeX/book-layout-fill.png)