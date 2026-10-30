---
title: "禁止 Kindle Paperwhite2 在连接 WiFi 的情况下静默升级"
url: https://liam.page/2014/08/17/kindle-paperwhite2-stop-slient-updating/
date: 2014-08-17
categories: ["Computer Skills"]
tags: ["Kindle", "BackDoorLock", "KUAL"]
---

又是关于 Kindle 的文章呢，不过心情和上一篇可谓截然相反。嘛，生活还要继续，不想了。

Kindle 的原生系统实在是欠调教，想要用得顺手不得不自己安装插件。若是如此也就罢了，恼人的是，Amazon 会在 Kindle 链接 WiFi 的情况下为 Kindle 推送更新，而这些不经过用户同意静默安装的升级，会使得不少插件失效。这样一来，每次升级就得重新安装优化不少插件，着实浪费时间，于是禁止静默升级变得十分有必要。

## BackDoorLock 介绍

[BackDoorLock](http://www.mobileread.com/forums/showthread.php?t=205666) 是 [mobileread 论坛](http://www.mobileread.com/) 上的 dsmid 前辈制作的插件，其作用只有一个：禁止 Amazon 在不经用户同意的情况下静默升级 Kindle 的固件。

BackDoorLock 并不会阻止 Kindle 从 Amazon 上取得升级所需的安装文件，它会在 Kindle 尝试安装升级的时候打断这个过程。这样设计是有意义的，因为如果阻止 Kindle 下载升级文件，则 Kindle 在联网的情况下会不断尝试下载，从而造成耗电量剧增，并最终影响电池寿命。

## BackDoorLock 的安装

首先保证你的 Kindle PW2 已经越狱（参考[这篇文章](http://liam0205.me/2014/05/20/koreader-on-kindle-paperwhite/)中关于越狱的部分）。dsmid 提供了两种方法安装 BackDoorLock。其一是下载 .bin 文件，放在 Kindle 根目录，使用「更新您的 Kindle」的方式安装。其二是先安装 KUAL (Kindle Unified Application Launcher) 安装，然后以查件的方式运行。这里推荐使用第二种方法。

### 安装 MKK

KUAL 需要 MKK (Mobileread Kindlet Kit) 的支持，所以先安装 MKK。

- 到[这里](http://www.mobileread.com/forums/showthread.php?t=233932)下载 MKK 的安装包。

- 使用 USB 数据线将 Kindle 与计算机连接。

- ZIP 归档中有名为 Update_mkk-20140214-k5-ALL_install.bin 的文件，将其解压到 Kindle 根目录。

- 断开 Kindle 与计算机的 USB 连接。

- 依次进行如下操作
主页按钮（[Home]）
菜单按钮（[Menu]）
设置选项（Settings）
菜单按钮（[Menu]）
更新您的 Kindle（Update Your Kindle）

### 安装 KUAL

- 到[这里](http://www.mobileread.com/forums/showthread.php?t=203326)下载 KUAL 的安装包。

- 使用 USB 数据线将 Kindle 与计算机连接。

- ZIP 归档中有名为 KUAL-KDK-2.0.azw2 的文件，将其解压到 Kindle 的 documents 目录。

### 安装 BackDoorLock

- 到[这里](http://www.mobileread.com/forums/showthread.php?t=205666)下载 MKK 的安装包。

- 使用 USB 数据线将 Kindle 与计算机连接。

- ZIP 归档中有名为 backdoorlock 的目录，将其完整地解压到 Kindle 的 extensions 目录（若不存在则新建）。

### 启用 BackDoorLock

将 Kindle 从电脑中退出后，在 Kindle 首页能看到如下图所示的图标，标有「Kindle Launcher」的就是 KUAL 启动图标了。

![安装完成后的主界面](//liam.page/attachment/attachment/images/Kindle/Home_KUAL.png)

点击 KUAL 图标，进入 KUAL 界面。

![KUAL 界面](//liam.page/attachment/attachment/images/Kindle/KUAL_BackDoorLock.png)

点击 BackDoorLock，打开 BackDoorLock。

![BackDoorLock 界面](//liam.page/attachment/attachment/images/Kindle/BackDoorLock.png)

这里

- Lock the back door 是禁用静默升级，

- Unlock the back door 是启用静默升级，

- Lock state 是查看 BackDoorLock 的工作状态，

- Delete update file(s) 是删除升级文件，以腾出空间，

- Move update file(s) 则是移动升级文件。