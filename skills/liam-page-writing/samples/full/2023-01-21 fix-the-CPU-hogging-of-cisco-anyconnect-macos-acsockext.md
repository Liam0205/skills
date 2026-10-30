---
title: "解决 cisco.anyconnect.macos.acsockext 大量消耗 CPU 资源的问题"
url: https://liam.page/2023/01/21/fix-the-CPU-hogging-of-cisco-anyconnect-macos-acsockext/
date: 2023-01-21
categories: ["Computer Skills"]
tags: ["CPU", "Cisco", "VPN"]
---

最近将 Cisco AnyConnect 升级到了公司提供的 4.10.00093 版本。接下来就发现 cisco.anyconnect.macos.acsockext 长期大量占用 CPU 资源，以及导致风扇转动不停。这显然是个问题。

![](/uploads/images/computer-skills/acsockext-cpu-usage.jpg)

检查发现，这是因为在 4.10 版本开始，思科的 VPN 加入了 Socket 过滤功能。从现象来看，它几乎无时无刻不在 buzy loop（哪怕把所有网络连接都断掉），这应当是个 bug。从功能来看，这种全方位的过滤功能，实在令人担忧其安全性。因此决定干掉他。以下是步骤：

- 打开系统设置 -> 网络

- 应能观察到三个以 Cisco... 开头的网络配置

- 选中它们，然后点下方的 -，删除他们

- 右下角，应用

- 应能观察到 CPU 利用率立刻下降

- 删除 /Applications/Cisco/Cisco AnyConnect Socket Filter.app 以免将来之虞