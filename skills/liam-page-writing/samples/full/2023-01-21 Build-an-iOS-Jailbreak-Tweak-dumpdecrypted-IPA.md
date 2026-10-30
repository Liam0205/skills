---
title: "编写 iOS 越狱插件：给 App 砸壳"
url: https://liam.page/2023/01/21/Build-an-iOS-Jailbreak-Tweak-dumpdecrypted-IPA/
date: 2023-01-21
categories: ["Jailbreak and Reverse Engineering"]
tags: ["Jailbreak", "Development", "Dumpdecrypting"]
---

在真正开始编写插件之前，我们还必须要分析我们的目标对象。只有进行了妥善的分析之后，我们才能确定要在何处进行注入、修改。

现代软件通常会加上一层加密的壳，必须经过脱壳才能分析。脱壳也常被戏称为砸壳。此篇我们介绍可用于 iOS 平台的脱壳工具。

## iOS 端：安装 frida-server

Frida 是跨平台的脱壳工具。首先我们需要在 iOS 上安装其服务端。

- 源：https://build.frida.re/

- 搜索 Frida 安装即可。

目前最新版本的 Frida (16.0.8) 存在 bug 会导致无法安装。蜗牛源（https://repo.snailovet.com/）提供了其早先版本（15.2.2）。经测试可用。

## macOS 端：安装 frida-tools

Terminal 中执行：

```bash
pip3 install frida-tools
```

为与 15.2.2 版本的 frida-server 匹配，你可能需要安装指定版本的 frida-tools。

```bash
pip3 install frida-tools==11.0.0
```

而后，我们可以下载 dump 脚本。

```bash
git clone https://github.com/AloneMonkey/frida-ios-dump
```

## Dumpdecrypting

使用 USB 线缆，连接手机和电脑。以不加载任何插件的方式启动你要砸壳的 App。（你可能需要 Choicy 这一插件来实现）

在 macOS 的 Terminal 中执行

```bash
cd /path/to/frida-ios-dump
python3 dump.py -H 192.168.1.3 -p 22 -u root -P 'alpine' "健康"
```

其中 -H 指定你手机的 IP 地址，-p 指定 ssh 的端口，-P 指定 root 账户的密码（默认是 alpine）。最后的程序名字，可以是显示在你手机上的名字，也可以是它的 Package ID。所有可用的 name/ID 可以通过下列命令查看。

```bash
python3 dump.py -H 192.168.1.3 -p 22 -u root -P 'alpine' -l
```

如此，即可在当前目录下生成 健康.ipa 可供后续分析。