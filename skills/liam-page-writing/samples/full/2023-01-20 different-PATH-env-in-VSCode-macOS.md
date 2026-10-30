---
title: "解决 macOS 上 VSCode 当中终端环境变量重复问题"
url: https://liam.page/2023/01/20/different-PATH-env-in-VSCode-macOS/
date: 2023-01-20
categories: ["Computer Skills"]
tags: ["Shell", "VSCode", "Terminal"]
---

最近在 VSCode 当中调试代码时，意外发现 VSCode 嵌入的终端内，PATH 变量很长。仔细一看，发现其中有重复部分。但同期在系统 Terminal 当中，PATH 变量则是正常的。

举例来说，VSCode 里的终端有：

```bash
$ echo $PATH
/usr/local/opt/node@12/bin:/Users/Liam/local/opt/bin:/Users/Liam/local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/opt/X11/bin:/Library/Apple/usr/bin:/usr/local/opt/node@12/bin:/Users/Liam/local/opt/bin:/Users/Liam/local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/opt/X11/bin:/Library/Apple/usr/bin
```

同期 Terminal 里的终端有：

```bash
$ echo $PATH
/usr/local/opt/node@12/bin:/Users/Liam/local/opt/bin:/Users/Liam/local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/opt/X11/bin:/Library/Apple/usr/bin
```

检查各种 profile/bashrc 文件，均未发现异常。后查明是在 VSCode 当中启动嵌入的终端时，默认会继承 VSCode 启动时的环境变量。这导致后续在使用 PATH = "/path/to/foo/bar:$PATH" 这样的语法时，会将 PATH 复制一份。只需将 VSCode 中的下列设置改为 false 即可。

```json
"terminal.integrated.inheritEnv": false
```