---
title: "使用 NTFS-3G 在 macOS 上激活对 NTFS 磁盘的读写功能"
url: https://liam.page/2020/04/08/enable-NTFS-writing-access-by-NTFS-3G/
date: 2020-04-08
categories: ["Computer Skills"]
tags: ["NTFS", "NTFS-3G"]
---

NTFS 是微软的 Windows NT 文件系统。在 macOS 上，默认只支持对 NTFS 磁盘的读，但不支持对 NTFS 磁盘的写。这无疑是很不方便的。

为解决这个问题，在我近几年的 macOS 使用经历中，先后试用了 [Tuxera](http://www.tuxera.com/products/tuxera-ntfs-for-mac/) 及 [Paragon](http://www.paragon-software.com/home/ntfs-mac/) 这样的付费软件，也试用了免费但需要手动挂载的 [Mounty](http://enjoygineering.com/mounty/)。但这些工具多少都有些不令我满意。

前几天检索到 NTFS-3G 这个开源工具，发现结合 FUSE for macOS 可以很方便地挂载 NTFS 磁盘并读写。所以记录下来。

## 行前准备

首先，你需要在 macOS 上安装 [Homebrew](https://brew.sh/)。按照官网的介绍，你只需要在 Terminal 中执行下列命令即可。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

## 安装 FUSE for macOS

接下来，使用 Homebrew 安装 FUSE for macOS。你需要在 Terminal 下执行下列命令。

```bash
brew install --cask macfuse
```

deprecated:

```bash
brew cask install osxfuse
```

## 安装 NTFS-3G

接下来，使用 Homebrew 安装 NTFS-3G。你需要在 Terminal 下执行下列命令。

```bash
brew tap gromgit/homebrew-fuse
brew install ntfs-3g-mac
```

deprecated

```bash
brew install ntfs-3g
```

## 切换 mount_ntfs

接下来，需要使用 NTFS-3G 提供的 mount_ntfs 来替代系统自带的 mount_ntfs。后者位于 /sbin/mount_ntfs。

由于 macOS 自 10.11 起，启用了系统完整性保护（System Integrity Protection）功能，导致在包括 /sbin 目录在内的一些目录下，即便有 root 权限，也无法修改目录下文件。你可以在 Terminal 中执行下列命令，查看 SIP 的状态。

```bash
$ csrutil status
System Integrity Protection status: enabled.
```

为此，我们需要暂时关闭 SIP，请参考下列操作步骤：

- 重启电脑；

- 按住 command + R，进入恢复模式；

- 选择你习惯的语言；

- 在顶部菜单栏，依次进入「Utilities -> Terminal」；

- 执行命令 csrutil disable，命令预期返回：「Successfully disabled System Integrity Protection. Please restart the machine for the changes to take effect.」；

- 重启电脑，正常引导进入系统；

- 启动 Terminal；

- 执行下列命令

```bash
sudo mount -uw / # 系统版本 10.15 (Catalina) 及以上需要执行此命令
cd /sbin
sudo mv mount_ntfs mount_ntfs.sys_orig # 备份系统版本的 mount_ntfs
sudo ln -sf /usr/local/sbin/mount_ntfs mount_ntfs # 将 NTFS-3G 提供的 mount_ntfs 链接到目标位置
```

- 重启电脑；

- 按住 command + R，进入恢复模式；

- 选择你习惯的语言；

- 在顶部菜单栏，依次进入「Utilities -> Terminal」；

- 执行命令 csrutil enable，命令预期返回：「Successfully enabled System Integrity Protection. Please restart the machine for the changes to take effect.」；

- 重启电脑，正常引导进入系统；

- 插入文件系统格式为 NTFS 的外部磁盘；

- 按照 FUSE for macOS 的提示，进入「System Preferences -> Security and Privacy」；

- 在「General」标签允许 FUSE for macOS 相关的权限；

- 拔出文件系统格式为 NTFS 的外部磁盘，再重新插入；

- 此后，macOS 即可正常读写文件系统格式为 NTFS 的外部磁盘。

最近 @linjie 提到说，按上述方法安装好 ntfs-3g 之后，打开 NTFS 格式的外置硬盘，看不到里面内容。这个现象在我这边没有复现，其机理也未弄明白。但 @linjie 在 GitHub 上找到了一个 [issue](https://github.com/osxfuse/osxfuse/issues/574)，提到了同样的问题。其中有人给出了一个解法，我翻译如下：

原地址：[https://github.com/osxfuse/osxfuse/issues/574#issuecomment-541309529](https://github.com/osxfuse/osxfuse/issues/574#issuecomment-541309529)
遇到此问题的同仁，可考虑附加参数 -o auto_xattr。在我这边，这个办法解决了问题。
我写了一个名为 [ezntfs](https://github.com/lezgomatt/ezntfs) 的 Python 脚本，来自动地完成这一工作。你可以通过 pip3 install ezntfs 来安装它。它仅只要求安装有 NTFS-3G，并有 Python 3.6 以上的运行环境。
依靠它，你无需手动找到磁盘 ID、推出、设置宗卷名。当下，它的文档暂缺，但只需在终端执行 ezntfs，即可看到帮助信息。
希望这对大家有所帮助。