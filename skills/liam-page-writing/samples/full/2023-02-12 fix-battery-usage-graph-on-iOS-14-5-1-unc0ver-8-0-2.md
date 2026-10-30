---
title: "在 iOS 14.5.1/unc0ver 8.0.2 上解决电池用量信息无法载入的问题"
url: https://liam.page/2023/02/12/fix-battery-usage-graph-on-iOS-14-5-1-unc0ver-8-0-2/
date: 2023-02-12
categories: ["Jailbreak and Reverse Engineering"]
tags: ["Fixing"]
---

手头的 iOS 14.5.1 自使用 unc0ver 8.0.2 越狱起就一直困扰于无法正确载入电池用量信息。今日终于无法忍受这一问题，遂解决它。

## 原因

经过一番检索，在 [@SongXiaoXi](https://github.com/SongXiaoXi) 的[这篇帖子](https://github.com/LinusHenze/Fugu14/pull/242#issue-1242075829)中找到了问题的原因。具体来说，Fugu14 在越狱过程中，将用户名 _analyticsd 改为了 _nanalyticsd，但其 ID 和 $HOME 则保持不变。但随后其他的某个守护进程将 /private/var/db/analyticsd 及其子目录的所有者改为了 _analyticsd（ID 变更为 264）。这造成 _analyticsd.back 以 263 启动时无法读取 /private/var/db/analyticsd 下的数据库信息，导致电池用量信息无法渲染。

## 解决

解决起来也很简单。我写了一个插件来完成所有需要的工作。你需要添加以下两个源，然后搜索安装 FixBetteryUsageFugu14：

- https://liam.page/apt/

- https://liam.page/apt-beta/

插件会在每次 SpringBoard 启动时执行一些 Shell 命令。

你也可以手工执行这些命令观察其效果。但请确认你知道每一步在做什么之后再操作。
首先，你需要在 Cydia/Zebra 等包管理器中安装 file-cmds 这一软件包。它提供了 chflags 命令。（或者，对于高级用户，也可以考虑安装 [binpack64](http://newosxbook.com/tools/iOSBinaries.html)）。
而后，你需要在 iOS 命令行（或者 SSH 过去）中执行下列命令。

```bash
#!/usr/bin/env bash

cd /var/mobile/Containers/Data/Fugu14Untether/Library/Caches/com.apple.dyld/
ls -l
sudo chflags -v noschg,nouchg *.closure
sudo chown 263:263 *.closure
sudo chflags -v schg,uchg *.closure
ls -l

cd /var/mobile/Containers/Data/Fugu14Untether
ls -l
sudo chown -h 263:263 /var/mobile/Containers/Data/Fugu14Untether/Library # 只修改 Library 这一 symlink 的所有者
ls -l

cd /var/db
ls -l
sudo chown -R 263:263 /var/db/analyticsd/
ls -l

sudo launchctl stop com.apple.analyticsd
sleep 3
sudo launchctl start com.apple.analyticsd
```