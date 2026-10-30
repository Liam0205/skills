---
title: "最佳搭档：利用 SSH 反向隧道和本地转发工具加速内网服务器的外网访问"
url: https://liam.page/2020/07/10/Making-Network-Faster-by-SSH-Reverse-Tunel/
date: 2020-07-10
categories: ["Computer Skills"]
tags: ["SSH", "Socks5"]
---

公司内网服务器（称作 hostA）访问外网速度特别慢，以至于使用 Linuxbrew 安装工具特别费事。经测试，下载同样的内容，处于办公网络的本机（称作 hostB）下载很快。遂起了代理加速的心思。

以下是解法。

## 本机本地转发

首先，我们需要在 hostB 上起一个进程，搭建一个本地的 socks5 代理。它将某个端口（记为 portB）收到的请求，全部转发到外网。

类似的工具有很多，这里不做展开。

## 反向隧道

[前作](/2018/04/11/break-firewall-by-the-use-of-SSH-tunnel/)中，我们介绍了 SSH 隧道功能。此处，我们可以从 hostB 向 hostA 建立一个反向隧道，并在 hostA 上绑定端口 portA。于是，发往 hostA:portA 的请求，都会经由 SSH 反向隧道转发到 hostB:portB，再发到外网。我们需要在 hostB 上执行：

```bash
ssh -fTCNR localhost:portA:localhost:portB hostA
```

至此，大功告成~