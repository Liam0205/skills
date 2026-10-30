---
title: "在 VSCode 的 LaTeXworkshop 插件中使用 LaTeXmk"
url: https://liam.page/2020/04/24/using-LaTeXmk-with-LaTeXworkshop-with-VSCode/
date: 2020-04-24
categories: ["LaTeX"]
tags: ["VSCode", "LaTeXmk", "LaTeXworkshop"]
---

之前，东升介绍了[如何将 VSCode 配置为 LaTeX 编辑器](http://ddswhu.me/posts/2018-04/vs-code-for-latex/)，我介绍了[如何在 macOS 上配置 VSCode 与 Skim 的 LaTeX 正反跳转](/2018/04/24/Working-with-VSCode-on-macOS-configuration-LaTeX-workshop-and-Skim/)。按东升的配置，为解决交叉引用，我们需要在 recipes 当中多次调用编译工具，一则稍显麻烦，二则对于源文件无变动的情况会进行不必要的编译。

LaTeXmk 是为了解决这些问题而设计的。阅读其文档之后，针对以下几条编译路径，我写好了 LaTeXworkshop 的配置，供后来人参考。

- XeLaTeX - BibTeX

- pdfLaTeX - BibTeX

- LuaLaTeX - BibTeX

- LaTeX - DVIPDFMx - BibTeX

- upLaTeX - DVIPDFMx - BibTeX

```json
{
  "latex-workshop.latex.tools": [
    {
      "name": "XeLaTeXmk",
      "command": "latexmk",
      "args": [
        "-xelatex",
        "-synctex=1",
        "-shell-escape",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
      ]
    },
    {
      "name": "pdfLaTeXmk",
      "command": "latexmk",
      "args": [
        "-pdflatex",
        "-synctex=1",
        "-shell-escape",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
      ]
    },
    {
      "name": "LuaLaTeXmk",
      "command": "latexmk",
      "args": [
        "-lualatex",
        "-synctex=1",
        "-shell-escape",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
      ]
    },
    {
      "name": "LaTeXmk-DVIPDFMx",
      "command": "latexmk",
      "args": [
        "-e",
        "$dvipdf='dvipdfmx %O -o %D %S'",
        "-latex",
        "-pdfdvi",
        "-synctex=1",
        "-shell-escape",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
      ]
    },
    {
      "name": "upLaTeXmk-DVIPDFMx",
      "command": "latexmk",
      "args": [
        "-e",
        "$dvipdf='dvipdfmx %O -o %D %S'",
        "-latex=uplatex",
        "-pdfdvi",
        "-synctex=1",
        "-shell-escape",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
      ]
    }
  ],
  "latex-workshop.latex.recipes": [
    {
      "name": "XeLaTeXmk",
      "tools": [
        "XeLaTeXmk",
      ]
    },
    {
      "name": "pdfLaTeXmk",
      "tools": [
        "pdfLaTeXmk",
      ]
    },
    {
      "name": "LuaLaTeXmk",
      "tools": [
        "LuaLaTeXmk",
      ]
    },
    {
      "name": "LaTeXmk-DVIPDFMx",
      "tools": [
        "LaTeXmk-DVIPDFMx",
      ]
    },
    {
      "name": "upLaTeXmk-DVIPDFMx",
      "tools": [
        "upLaTeXmk-DVIPDFMx",
      ]
    }
  ]
}
```

这里，针对 LaTeX 和 upLaTeX 的情形，为了使用 DVIPDFMx 覆盖 LaTeXmk 默认的 dvipdf，使用 -e 参数，将设定 dvipdf 命令的 Perl 代码作为参数传给 LaTeXmk。这样免去了修改 .latexmkrc 配置文件的麻烦。类似地，如果要使用 BibLaTeX 代替 BibTeX，则可以修改名为 $bibtex 的 Perl 变量。

此外，这里默认打开了 -shell-escape 标记。如果你不知道它意味着什么，那可以就这么保留，它会在将来给你省下一些麻烦。如果你知道它意味着什么，可以按需保留或删除。