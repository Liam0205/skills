---
title: "在 TeX Live 测试期间跨版本更新宏包"
url: https://liam.page/2015/06/02/fake-tlpretest-to-update-packages/
date: 2015-06-02
categories: ["LaTeX"]
tags: ["Fake", "tlpretest", "TeX Live", "Update", "Packages"]
---

TeX Live 是由国际 TeX 用户组（TUG）维护的 TeX 发行版，一般被认为是 TeX 发行版的「正统」，具有稳定、更新快、维护足的特点。

不过，使用 TeX Live 也有麻烦的地方——TeX Live 每年都更新，而更新版本之后旧版本就无法再从 CTAN 上自动更新宏包。这样一来，TeX Live 用户就不得不每年都重新安装一次，相当麻烦。而且，在新版测试期间更新的宏包，旧版本的用户就无法通过 tlmgr 来更新了。对于中国的用户而言，TeX Live 2014 向 TeX Live 2015 的过渡期尤为难熬，因为 [CTeX 宏集的新版本](/2015/05/16/ctex-20-released/) 发布了。

这篇文章中，我将介绍如何在旧版本的 TeX Live 中跨版本更新宏包。

## 原理

虽然听上去麻烦，但实际上还是还是很简单的。

默认情况下，TeX Live 通过新建一个以年份数字为名的目录来区分当前的 TeX Live 版本。比如，对于安装了 TeX Live 2014 的用户，会有这样的目录结构：

```plaintext
- texlive
|- 2014
|- texmf-local
```

按照 TUG 的意图，如果用户在此基础上安装 TeX Live 2015，那么目录结构会变成：

```plaintext
- texlive
|- 2014
|- 2015
|- texmf-local
```

这样做的好处是，用户可以自由地在不同版本之间切换，同时多个版本共用一个 texmf-local 目录（用户配置目录）。只是，对于大多数人的大多数情况来说，这是没有必要的。

因此，为了将 TeX Live 2014 伪装成正在参与测试的 TeX Live 2015，我们首先要将目录名字修改成 2015。修改过目录之后，我们还需要正确处理 TeX 系统的二进制文件和系统 PATH 变量。在这之后，我们只需要将 tlmgr 的远程仓库设置为 tlpretest 仓库就好了。

## 实际操作看看

这里我们以 TeX Live 2014 升级到 TeX Live 2015 pretest 为例，未来版本的升级步骤与此类似。

对于 MacTeX 2014 用户，可以在终端下进行如此操作：

```bash
cd /usr/local/texlive/
sudo mv ./2014 ./2015
cd ./2015/bin/x86_64-darwin
sudo ./tlmgr option sys_bin /usr/texbin/
sudo ./tlmgr path add
sudo tlmgr option repository http://ctan.ijs.si/mirror/tlpretest/
sudo tlmgr update --self --all
```

在这里：

- 将工作目录切换到 texlive 目录

- 修改年份目录的名字，从 2014 修改为 2015

- 由于修改目录名字破坏了 TeX 系统的二进制文件和系统 PATH 之间的关联，在进行下一步操作之后，我们需要切换到二进制文件目录

- 运行当前目录下的 tlmgr 工具，配置系统二进制文件的目录为 /usr/texbin/

- 同样是运行当前目录下的 tlmgr 工具，将 TeX 系统的二进制文件和系统 PATH 重新关联起来

- 将 tlmgr 的远程仓库设置为 tlpretest 仓库，因为已经配置好上述关联，所以不需要用 ./ 来指明当前目录

- 使用 tlmgr 更新宏包和其他相关组件

2020-03-29 更新：

- 你可能无需执行上述 4) 和 5) 两步，转而使用 [update-tlmgr-latest.sh 的 tlpretest 版本](https://mirrors.tuna.tsinghua.edu.cn/tlpretest/update-tlmgr-latest.sh)。

- 清华大学 TUNA 镜像现已支持 tlpretest，因此无需再使用国外的源：[https://mirrors.tuna.tsinghua.edu.cn/tlpretest/](https://mirrors.tuna.tsinghua.edu.cn/tlpretest/)。

Linux 系统的操作和 Mac OS X 下的操作基本相同，不再赘述。

Windows 用户的操作基本可以在图形界面下操作：

- 首先进入 TeX Live 的安装目录

- 然后修改文件夹的名字

- 在系统设置中，修改 PATH 变量的值

- 然后打开命令提示符窗口（cmd）

- 执行命令 tlmgr option repository http://ctan.ijs.si/mirror/tlpretest/

- 执行命令 tlmgr update --self --all