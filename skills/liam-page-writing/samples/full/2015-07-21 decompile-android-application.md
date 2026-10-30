---
title: "反编译 Android 程序小记"
url: https://liam.page/2015/07/21/decompile-android-application/
date: 2015-07-21
categories: ["Algorithm and Computer Science"]
tags: ["Android", "Decompile"]
---

使用 QQ 这么多年，管理的群越来越多。现在每天被入群申请搞得烦不胜烦，于是萌生了写一个 QQ 机器人的想法。

要想实现一个 QQ 机器人，首先是要在程序里模拟登录。经过整理，可用的思路有两个：

- 使用 WebQQ 的方式登录，模拟浏览器的行为；

- 使用 Android QQ 的方式登录，模拟 Android 客户端的行为。

二者各有利弊。使用 WebQQ 方式登录协议相对简单，网络上也有[相关分析](http://hfutfei.iteye.com/blog/800866)；但是 WebQQ 不能与电脑上的 QQ 共存：登录 WebQQ 就会将电脑上的登录踢下线。使用 Android QQ 的方式登录，由于没有现成的资料可供查询，实现起来十分复杂；但是 Android QQ 是手机端 QQ，可以与电脑端 QQ 共存。

「要做就做好」。思前想后，我还是决定使用 Android QQ 的方式登录。于是问题来了，怎样去抓取 Android QQ 的行为呢？

- 在 Android QQ 外围进行抓包分析，然后让程序伪装成 Android QQ 向腾讯的服务器发包；

- 直接读 Android QQ 的源代码，然后仿照着相关内容重新实现。

方案 1 是常规方法，若能顺利实施，无非是不断重复抓包 - 分析 - 伪造的步骤。不过 QQ 的通信信息是加密处理过的，抓包分析比较费劲。因此，我决定尝试反编译 Android 程序，直接阅读源代码。

这里我介绍反编译安卓程序，得到 Java 代码的详细方法。

**请尊重他人劳动成果，勿将此方法用于恶意活动。**

## 解包 .apk

[APK](https://zh.wikipedia.org/wiki/APK) 是 Application Package File 的缩写。.apk 文件的实质是一个 .zip 压缩包，包含 Android 运行 APP 所需以下内容：

- 编译好的代码文件 .dex

- assets 目录

- 证书

- 文件资源（resources.arsc）

- 文件清单（AndroidManifest.xml）

想要得到源码，首先需要解包 .apk 文件。**我们只需要将后缀名从 .apk 改为 .zip，然后按照常规方式解压即可**。

## 处理 AndroidManifest.xml

AndroidManifest.xml 是一个传统的Android清单文件，用于描述该应用程序的名字、版本号、所需权限、注册的服务、链接的其他应用程序。为了搞清楚程序到底做了什么，我们有必要知道这个文件的具体内容。

如果用文本编辑器打开 AndroidManifest.xml，我们会发现其中是一堆乱码。

![AndroidManifest.xml 乱码](//liam.page/attachment/attachment/images/Android/AndroidManifest-Mojibake.png)

实际上，AndroidManifest.xml 已经被处理成二进制格式，我们用文本模式打开它乱码是理所应当的。为了正确读取其中内容，我们需要用 [AXMLPrinter2](https://code.google.com/p/android4me/downloads/list) 这个工具对它进行处理，将它还原成文本格式。

- [AXMLPrinter2 官方下载](https://code.google.com/p/android4me/downloads/detail?name=AXMLPrinter2.jar&can=2&q=)

- [预防 Google Code 关闭准备的备用链接](//liam.page/attachment/attachment/Android/AXMLPrinter2.jar)

之后我们需要运行

```bash
java -jar AXMLPrinter2.jar AndroidManifest.xml > AndroidManifest.txt
```

将二进制格式的 AndroidManifest.xml 转换为文本格式，并保存在 AndroidManifest.txt 之中。这样我们就能阅读其中信息了。

## 处理 .dex 文件

.dex 文件是 Java 标准的 classes 文件通过 DEX 编译后的文件格式，是用于在 [Dalvik 虚拟机](https://zh.wikipedia.org/wiki/Dalvik%E8%99%9A%E6%8B%9F%E6%9C%BA)上运行的主要代码部分。显而易见，这是我们需要处理的重头戏。

处理 .dex 文件就是要将其还原为 Java 标准的 .jar 文件。为此我们需要用到 [dex2jar](https://github.com/pxb1988/dex2jar) 这个工具。

- [dex2jar 官方下载](https://github.com/pxb1988/dex2jar/releases)

- [预防 GitHub 不能用的备用链接](//liam.page/attachment/attachment/Android/dex-tools-2.0.zip)（版本 2.0，[a9126a9](https://github.com/pxb1988/dex2jar/commit/a9126a95ad613c4021cb37930823b1281ec5414a)）

解压后，我们在命令行中运行

```bash
/path/to/dex-tools/d2j-dex2jar.sh *.dex
```

Windows 用户运行

```bash
\path\to\dex-tools\d2j-dex2jar.bat *.dex
```

就能得到 classes.dex 相应的 classes-dex2jar.jar 文件。

## 处理 .jar 文件，得到 Java 源码

.jar 文件是 .class 文件的封装。[jd-gui](http://jd.benow.ca/) 这个小工具可以以图形化的界面查看 .jar 当中 .class 文件对应的 Java 源码。所得结果可读性非常高。

下载地址：

- [Windows 版 - 官方](https://github.com/java-decompiler/jd-gui/releases/download/v1.3.0/jd-gui-windows-1.3.0.zip) - [备用](//liam.page/attachment/attachment/Android/jd-gui-windows-1.3.0.zip)

- [Mac 版 - 官方](https://github.com/java-decompiler/jd-gui/releases/download/v1.3.0/jd-gui-osx-1.3.0.tar) - [备用](//liam.page/attachment/attachment/Android/jd-gui-osx-1.3.0.tar)

使用 jd-gui 打开上一步得到的 .jar 文件，就能看到 .class 对应的 Java 源码了。

![使用 jd-gui 查看 Java 源码](//liam.page/attachment/attachment/images/Android/jd-gui-view.png)

按下快捷键 Command + Option + S 保存源码就好啦。