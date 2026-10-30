---
title: "【LaTeX Tips】listings 中高亮定界符内的文本而不高亮定界符本身"
url: https://liam.page/2013/12/05/LaTeX-Emphasize-color-contents-between-two-delimiters-in-listings-but-not-the-delimiters-themselves/
date: 2013-12-05
categories: ["LaTeX"]
tags: ["Listings", "Highlight", "Delimiter"]
---

背景图里的代码高亮十分漂亮，用 listings 宏包实现的难点在于如何高亮某种定界符内的内容，而定界符本身保留 basicstyle 设定的样式。

```tex
\documentclass{article}
\usepackage{listings}
\usepackage{xcolor}
\lstset{
    delim = [s][\ttfamily\color{orange}]{$}{$}
}
\begin{document}
\begin{lstlisting}
\documentclass{article}
\usepackage{amsmath}
\begin{document}
$E = mc^2$
\end{document}
\end{lstlisting}
\end{document}
```

效果：

![](http://i.stack.imgur.com/VFq3G.png)

$ 之间的公式随着 $ 本身都变成了橘色。

解决问题的方法，可以参照 [David Carlisle](http://dpcarlisle.blogspot.com/) 在 TeX.SX 上对[这个问题的回答](http://tex.stackexchange.com/a/145661/38350)。

我们可以定义这样一个 listings 样式：

```tex
\def\beginlstdelim#1#2#3{
    \def\endlstdelim{#2\egroup}%
    \ttfamily#1\bgroup\color{#3}\aftergroup\endlstdelim%
}
```

它有三个参数，第一个参数是定界符的左边，第二个是定界符的右边，第三个是高亮的颜色。我们可以这样使用：

```tex
\documentclass{article}

\usepackage[usenames,dvipsnames]{xcolor}
\usepackage{listings}

\def\beginlstdelim#1#2#3{
    \def\endlstdelim{#2\egroup}%
    \ttfamily#1\bgroup\color{#3}\aftergroup\endlstdelim%
}
\lstset
{
    moredelim = **[is][\beginlstdelim{\$}{\$}{orange}]{\$}{\$},
    moredelim = **[is][\beginlstdelim{\{}{\}}{ForestGreen}]{\{}{\}},
    moredelim = **[is][\beginlstdelim{[}{]}{red}]{[}{]},
}

\begin{document}
\begin{lstlisting}
\documentclass{article}
\usepackage{amsmath}
\begin{document}
$E = mc^2$
{E = mc^2}
[E = mc^2]
\end{document}
\end{lstlisting}
\end{document}
```

效果是这样的：

[](http://i.stack.imgur.com/7nSib.png)
[输出效果](http://i.stack.imgur.com/7nSib.png)

The code in the background figure is very pretty. In terms of using listings to reproduce this beautiful style, nodus turns out to be how to color contents between two delimiters but not the delimiters themselves (remain basicstyle).

If we have the code following:

```tex
\documentclass{article}
\usepackage{listings}
\usepackage{xcolor}
\lstset{
    delim = [s][\ttfamily\color{orange}]{$}{$}
}
\begin{document}
\begin{lstlisting}
\documentclass{article}
\usepackage{amsmath}
\begin{document}
$E = mc^2$
\end{document}
\end{lstlisting}
\end{document}
```

we will get:

![](http://i.stack.imgur.com/VFq3G.png)

The equation between $s was colored by orange, so did $s themselves.

Inspired by [David Carlisle](http://dpcarlisle.blogspot.com/)'s [answer to this question](http://tex.stackexchange.com/a/145661/38350), TeX.SX, Jubobs defined a new listings style:

```tex
\def\beginlstdelim#1#2#3{
    \def\endlstdelim{#2\egroup}%
    \ttfamily#1\bgroup\color{#3}\aftergroup\endlstdelim%
}
```

It has three arguments: the first one should be the left delimiter, the second one should be the right one, and the third one specifying the color. Let's take a example:

```tex
\documentclass{article}

\usepackage[usenames,dvipsnames]{xcolor}
\usepackage{listings}

\def\beginlstdelim#1#2#3{
    \def\endlstdelim{#2\egroup}%
    \ttfamily#1\bgroup\color{#3}\aftergroup\endlstdelim%
}
\lstset
{
    moredelim = **[is][\beginlstdelim{\$}{\$}{orange}]{\$}{\$},
    moredelim = **[is][\beginlstdelim{\{}{\}}{ForestGreen}]{\{}{\}},
    moredelim = **[is][\beginlstdelim{[}{]}{red}]{[}{]},
}

\begin{document}
\begin{lstlisting}
\documentclass{article}
\usepackage{amsmath}
\begin{document}
$E = mc^2$
{E = mc^2}
[E = mc^2]
\end{document}
\end{lstlisting}
\end{document}
```

It's output:

[](http://i.stack.imgur.com/7nSib.png)
[The Output.](http://i.stack.imgur.com/7nSib.png)