---
title: "在 SumatraPDF 反向搜索时复用 VSCode 窗口"
url: https://liam.page/2019/03/27/reuse-active-window-for-inverse-search-SumatraPDF-and-LaTeXworkshop-on-VSCode/
date: 2019-03-27
categories: ["LaTeX"]
tags: ["VSCode", "SumatraPDF", "Inverse Search"]
---

这是一篇简单的记录。

最近升级 VSCode 之后发现 SumatraPDF 的反向搜索出了些问题。具体来说，反向搜索能够定位到 VSCode 里的代码位置，但是每次反向搜索都会打开新的 VSCode 窗口。烦不胜烦。

遂上网检索，找到 [VSCode 的命令行参数文档](https://code.visualstudio.com/docs/editor/command-line)。原来，默认情况下，使用命令行打开 VSCode 会打开新的窗口。为了重用上一个活动窗口，需要在命令行参数上加上 -r 或者完整版本 --reuse-window。

于是，LaTeXworkshop 的配置变成了这样：

```json

"latex-workshop.view.pdf.external.synctex": {
  "command": "C:\\Program Files (x86)\\SumatraPDF\\SumatraPDF.exe",
  "args": [
    "-forward-search",
    "%TEX%",
    "%LINE%",
    "-reuse-instance",
    "-inverse-search",
    "\"C:\\Users\\UserName\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe\" \"C:\\Users\\UserName\\AppData\\Local\\Programs\\Microsoft VS Code\\resources\\app\\out\\cli.js\" -r -g \"%f:%l\"",
    "%PDF%"
  ]
},
```

注意，其中的「UserName」需要改为你自己的用户名。（感谢 GoneKuei）