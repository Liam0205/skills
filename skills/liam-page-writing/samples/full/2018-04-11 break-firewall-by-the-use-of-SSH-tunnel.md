---
title: "最佳搭档：利用正反 SSH 隧道穿透防火墙访问内网服务器"
url: https://liam.page/2018/04/11/break-firewall-by-the-use-of-SSH-tunnel/
date: 2018-04-11
categories: ["Computer Skills"]
tags: ["SSH", "Tunnel"]
---

SSH 最基本的用法相信你已经了解。这次我们要用 SSH 来做一些特别的事情：建立正反 SSH 隧道，穿透防火墙，访问本不可见的内网服务器。

## 管道和隧道

我们先来看最简单的 SSH 命令。

```bash
ssh [-p <onPort>] [<user>@] <connectToHost>
```

此处方括号内的内容是可以省略的，尖括号内的内容是根据实际情况可修改的参数。这条命令表示，自执行命令的本机，向 connectToHost 的 onPort 端口发起请求，尝试以 user 身份登录。在上述 SSH 命令执行成功之后，我们就建立了从本机到 connectToHost 的连接。具体来说，本机的 SSH client 与 connectToHost 的 SSH server 建立了连接。我们可以将这一连接想像成一个有方向的管道；它的起点是本机的某个端口，而终点是 connectToHost 上的 onPort 端口。

SSH 的 -L 和 -R 选项，允许用户在上述管道内部，再创建一个有向隧道。大体上，你可以将其想像为外部的大号管道套住了内部的小号隧道。隧道的两端与管道的两端相同，起点则由 -Local/-Remote 决定。使用 -L 选项时，本机的某个端口是起点；这种隧道称之为正向隧道；而使用 -R 选项时，起点是 connectToHost 上的 onPort 端口，这种隧道称之为反向隧道。

![](/uploads/images/Linux/HbSEM.png)
来自：[https://unix.stackexchange.com/a/46271/140887](https://unix.stackexchange.com/a/46271/140887)

## 隧道与转发

上述隧道可在已建立的 SSH 连接（管道）的基础上进行端口转发。我们从其语法开始说起，首先以 -L 为例。

```bash
ssh -L [<bindHost>:]<sourcePort>:<forwardToHost>:<onPort> <connectToHost>
```

这条命令表示，本机的 SSH 客户端将与 connectToHost 建立连接（管道），并在管道内建立从本机到 connectToHost 的隧道。此后，本机将把所有来自 bindHost 发往本机的 sourcePort 端口的消息，通过上述隧道转交给 connectToHost，并由 connectToHost 负责发往 forwardToHost 的 onPort 端口。此处有两点值得注意。其一，bindHost 省略时或置为 * 时，表示本机将转发所有主机发往 sourcePort 的消息。其二，forwardToHost 是站在 connectToHost 的视角看待的，因此若 forwardToHost 的值是 localhost，则在此语境下表示 connectToHost 这台主机的本地回环。

![](/uploads/images/Linux/a28N8.png)
来自：[https://unix.stackexchange.com/a/118650/140887](https://unix.stackexchange.com/a/118650/140887)

于是，-R 的版本也就容易理解了。

```bash
ssh -R [<bindHost>:]<sourcePort>:<forwardToHost>:<onPort> <connectToHost>
```

这条命令表示，本机的 SSH 客户端将与 connectToHost 建立连接（管道），并在管道内建立从 connectToHost 到本机的隧道。此后，connectToHost 将把所有来自 bindHost 发往 connectToHost 的 sourcePort 端口的消息，通过上述隧道转交给本机，并由本机负责发往 forwardToHost 的 onPort 端口。至于 bindHost 和 forwardToHost 的语义则与 -L 版本类似。

![](/uploads/images/Linux/4iK3b.png)
来自：[https://unix.stackexchange.com/a/118650/140887](https://unix.stackexchange.com/a/118650/140887)

## 相关参数

在使用隧道之前，还应了解一些参数。

- -f：使 SSH 在建立连接之后保持在后台运行。

- -N：告诉 SSH，我们只希望建立隧道，而不会在远程主机上执行任何指令。

- -T：告诉 SSH，我们只希望建立隧道，因而不需要创建虚拟终端。

- -C：允许 SSH 压缩数据。

## 穿透防火墙

我们做如下假设。

- HOST_A：目标机器；内网机器，位于防火墙之后，可以访问外网，但无法从外网访问。

- HOST_B：跳板机；外网机器，位于防火墙之前，可以访问外网，但无法访问内网机器。

- HOST_C：工作机；外网机器，网络环境与 HOST_B 类似。

我们的目的是希望 HOST_C 上能够随时随地访问 HOST_A，那么需要怎么做呢？

### 分析

由于所有位于外网的机器都不可见 HOST_A，因此最终连接到 HOST_A 的方式必然在根本上从 HOST_A 发起，而后又将流量反向交给 HOST_A。因此，不难发现，在 HOST_A 上应当向跳板机 HOST_B 发起 SSH 连接，并通过反向隧道将流量返回 HOST_A。

至此，跳板机 HOST_B 上已有一个端口可以连接到目标机器 HOST_A。现在的问题是，如何将连向跳板机的 SSH 连接转发到跳板机上的这个特殊端口。为此，我们可以在跳板机上向其自身建立一个 SSH 连接，而后通过正向隧道将流量在跳板机内部转发到上述端口。

### 实际操作看看

首先在 HOST_A 上执行：

```bash
ssh -fNTCR localhost:1556:localhost:22 HOST_B
```

这里，HOST_A 向 HOST_B 发起 SSH 连接，建立了一个管道。而后，在管道内建立了一个从 HOST_B 到 HOST_A 的反向隧道。HOST_B 会将所有来自（第一个）localhost（即 HOST_B 本机）的发往 HOST_B 1556 端口的流量，经由上述隧道转交给 HOST_A 本机，而后转发给（第二个）localhost（即 HOST_A）的 22 端口。

而后在 HOST_B 上执行：

```bash
ssh -fNTCL *:1555:localhost:1556 localhost
```

这里，HOST_B 向自身（第二个 localhost）发起 SSH 连接，建立了一个管道。而后，在管道内建立了一个从 HOST_B（本机）到 HOST_B（这里，HOST_B 向自身（第二个 localhost）的正向隧道。HOST_B（本机）会将来自任意主机的发往其 1555 端口的流量，经由上述隧道转交给 HOST_B（第二个 localhost），而后转发给（第一个）localhost（即 HOST_B）的 1556 端口。

如此一来，所有发往 HOST_B 的 1555 端口的流量，会先转发到 HOST_B 的 1556 端口，再转发到 HOST_A 的 22 端口。因此，只需要在 HOST_C 上对 HOST_B 的 1555 端口发起 SSH 连接，就相当于是对 HOST_A 的 22 端口发起连接。

```bash
ssh -p 1555 HOST_B
```

如此即可。