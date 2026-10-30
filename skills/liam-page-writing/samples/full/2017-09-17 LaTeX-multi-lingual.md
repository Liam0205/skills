---
title: "LaTeX 黑魔法（五）：在 LaTeX 中输出多国语言"
url: https://liam.page/2017/09/17/LaTeX-multi-lingual/
date: 2017-09-17
categories: ["LaTeX"]
tags: ["Multi-lingual"]
---

在 LaTeX 中输出英文之外的其他字符总是不那么自然，需要一些折腾。例如让 LaTeX 输出中文就走过了天元、CCT、CJK、xeCJK 这些路子。

以现在（2017-09）来说，在 LaTeX 中混排中英双语已经不是什么难事，只需要使用 xeCJK 宏包或者 [CTeX 宏集](/2015/05/16/ctex-20-released/)即可。但若是想要在一篇文档里排版多语言，则很多人就不知道怎么办了。

## 需要解决的问题

在 LaTeX 中输入多国语言，主要来说，现代的方案就是要解决三件事情：

- 使用一个包含文档所需所有字符的编码方案；

- 使 TeX 支持选定的编码方案；

- 选取合适的字体。

对于编码来说，使用 Unicode 字符集对应的编码方案自然是最简单的。当然，语言本国人自己使用的话，也可能会使用当地的编码（例如俄罗斯人的话可能会使用 CP1251）。若是要同时使用多国语言，则最好还是使用 UTF-8 编码。

对于 TeX 来说，支持 UTF-8 编码的文稿，又分成两类情况。对于 XeLaTeX/LuaLaTeX 来说，它们原生就支持，因此不需要做特别的处理。对于不直接支持 UTF-8 编码的排版命令来说，就需要使用 \usepackage[utf8]{inputenc} 显式地指明引擎吃进去的文稿是 UTF-8 编码的。

## 以俄语为例

使用 XeLaTeX/LuaLaTeX 实现英文、俄文混排就很简单了。我们只需要使用 fontspec 宏包提供的接口，选定同时包含英文和俄文字符的字体即可。这里我们选用 CMU Serif；它包含在 TeX Live 当中。

```tex
% !TeX encoding = UTF-8
\documentclass{article}
\usepackage{fontspec}
\setmainfont{CMU Serif}

\begin{document}

\section{Русский язык}
Русский язык

\end{document}
```

若不想使用 XeLaTeX/LuaLaTeX，也可以这样做。

```tex
% !TeX program = pdfLaTeX
% !TeX encoding = UTF-8
\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage[T2A]{fontenc}

\begin{document}

\section{Русский язык}
Русский язык

\end{document}
```

## 多国语言怎么办？

其实，对于大多数文字来说，多国语言混排和英文俄文双语混排没什么差别。无非就是老三样：

- UTF-8 编码保存文稿；

- 使 TeX 引擎支持 UTF-8 编码；

- 选择合适的字体。

例如，我们可以实现英文、希伯来文（需要字体支持）、希腊文、拉丁文、西班牙文、俄文、中文的混排。

CMU Serif 不包括希伯来文字母，因此你可能需要[下载并安装 LinLibertine 字体](http://www.linuxlibertine.org/index.php?id=91&L=1)。

```tex
\documentclass{article}
\usepackage{hyperref}
\usepackage{fontspec}
\setmainfont{CMU Serif}
% \setmainfont{LinLibertine}
\usepackage{xeCJK}

\begin{document}

\section*{The Tower of Babel, Genesis 11:7}

\subsection*{English}
Come, let us go down and confuse their language so they will not understand each other.

% \subsection*{Hebrew}
% הָ֚בָה נֵֽרְדָ֔ה וְנָבְלָ֥ה שָׁ֖ם שְׂפָתָ֑ם אֲשֶׁר֙ לֹ֣א יִשְׁמְע֔וּ אִ֖ישׁ שְׂפַ֥ת רֵעֵֽהוּ׃%

\subsection*{Greek}
δεῦτε καὶ καταβάντες συγχέωμεν ἐκεῖ αὐτῶν τὴν γλῶσσαν, ἵνα μὴ ἀκούσωσιν ἕκαστος τὴν φωνὴν τοῦ πλησίον.

\subsection*{Latin}
venite igitur descendamus et confundamus ibi linguam eorum ut non audiat unusquisque vocem proximi sui

\subsection*{Spanish}
Será mejor que bajemos a confundir su idioma, para que ya no se entiendan entre ellos mismos.

\subsection*{Russian}
сойдем же и смешаем там язык их, так чтобы один не понимал речи другого.

\subsection*{Chinese (Simplified)}
来，我们下去，在那里混乱他们的语言，使他们听不懂对方的话。%

\bigskip
\small
Texts from \url{https://www.biblegateway.com}.
Greek Septuagint text from \url{https://www.academic-bible.com/en/online-bibles/septuagint-lxx/read-the-bible-text/}.
\end{document}
```

![](/uploads/images/LaTeX/multi-language-demo.png)