---
title: "彻底关闭 ThinkPad 的触控板"
url: https://liam.page/2018/11/20/turn-off-touchpad-of-ThinkPad/
date: 2018-11-20
categories: ["Computer Skills"]
tags: ["ThinkPad", "TouchPad"]
---

这是一篇简单的记录。

新电脑是 ThinkPad。众所周知，TP 的小红点（TrackPoint）很好用。相应的，TP 的触控板就不怎么好用了。特别地，TP 的触控板在打字的时候，经常会误触导致光标漂移。

因此，我需要关闭触控板。

网上爬文，大多数结果都告诉要安装 UltraNav 的驱动。从联想官网上下载安装驱动后，TP 提示说找不到相关设备。看起来是驱动与硬件不匹配导致的。遂删除驱动。

最后想到，BIOS 能控制各种输入输出设备。遂在重启时进入 BIOS 设置（Enter 键），找到触控板（TouchPad）设置，将其设置为 disabled。完成！

```plaintext
Reboot
Hold 'Enter'
BIOS -> config -> keyboard/mouse -> TouchPad (disabled)
```