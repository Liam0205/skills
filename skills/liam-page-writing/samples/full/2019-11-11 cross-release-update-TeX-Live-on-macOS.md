---
title: "在 macOS 上跨版本更新 TeX Live"
url: https://liam.page/2019/11/11/cross-release-update-TeX-Live-on-macOS/
date: 2019-11-11
categories: ["LaTeX"]
tags: ["TeX Live"]
---

很久没写 LaTeX 了。嗯……原因是因为我很久没用 LaTeX 了。

因为很久没用 LaTeX，所以 Mac 上的 macTeX 也很久没更新。这不，目前版本还是 macTeX 2018，而 macTeX 2019 都出来很久了。另一方面，因为系统版本有升级，导致与 macTeX 2018 有些不兼容。于是，升级到 2019 版本变得势在必行。

## 升级 macTeX 还是升级 TeX Live

本质上 macTeX 是对 TeX Live 的打包封装。里面当中实际执行的，还是 TeX Live。因此，升级 TeX Live 而不升级 macTeX 可以避免下载巨大的 macTeX.pkg。

## update-tlmgr-latest

一般升级，用到的命令是

```shell
tlmgr update --self --all --reinstall-forcibly-removed
```

但是，跨版本升级时，它会报错。不过，它会有提示，让你下载 update-tlmgr-latest 来将 tlmgr 更新到最新版本，从而可以跨版本更新。于是我们有

```shell
wget http://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh
bash update-tlmgr-latest.sh
tlmgr update --self --all --reinstall-forcibly-removed
```

## 更新语言配置

上述 tlmgr update 在执行到最后，构建 fmt 文件时会报错。例如：

```plaintext
I can't find file `dehypht-x-2018-03-31.tex`!
```

检查发现，构建 fmt 文件时，会读取 /usr/local/texlive/2018/texmf-var/tex/generic/config/language.def 文件，它提到了：\addlanguage{german-x-latest}{dehypht-x-2018-03-30.tex}{}{2}{2}。

上网检查发现，可以用 tlmgr generate language 更新语言定义文件。遂执行

```shell
tlmgr generate language
fmtutil -sys --all
```

至此，万事 OK~