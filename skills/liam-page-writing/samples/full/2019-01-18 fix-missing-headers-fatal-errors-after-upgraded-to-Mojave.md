---
title: "解决升级 Mojave 后 g++ 找不到头文件的问题"
url: https://liam.page/2019/01/18/fix-missing-headers-fatal-errors-after-upgraded-to-Mojave/
date: 2019-01-18
categories: ["Computer Skills"]
tags: ["C++", "macOS", "Mojave", "XCode"]
---

Mac 升级 Mojave (10.14) 之后，尝试编译以前编译通过的 C++ 项目，g++-6 提示找不到各种头文件。例如有如下报错。

```bash
./third_party/catch.hpp:69:33: fatal error: TargetConditionals.h: No such file or directory
 # include <TargetConditionals.h>
                                 ^
compilation terminated.
```

经查，这是因为 macOS 在升级过程中，移除了过时的开发者工具。（不得不说这种无声移除的设计非常傻屄）解决的办法也很简单，重新安装 Command Line Tools 及其头文件包即可。

```bash
xcode-select --install
open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg
```

参考：[https://forums.developer.apple.com/thread/104296](https://forums.developer.apple.com/thread/104296)