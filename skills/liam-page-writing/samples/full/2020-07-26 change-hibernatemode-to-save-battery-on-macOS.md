---
title: "修改休眠模式以节省 macOS 睡眠时的电池电量"
url: https://liam.page/2020/07/26/change-hibernatemode-to-save-battery-on-macOS/
date: 2020-07-26
categories: ["Computer Skills"]
tags: ["macOS", "Hibernate"]
---

切换到 Mac 已经有六年了；一直以来，就发现 MacBook Pro 在扣上盖子睡眠时，会有明显的掉电现象。我觉着这么多年，我一直没去处理它，也是挺能忍的。

然而今天忍不了了哇。

## GUI 设置

一般用户自然是会从 GUI 设置当中找寻相关线索。

于是我们打开「系统偏好设置」-「节能」-「电池」标签。

![](/uploads/images/macOS/energy-saving.jpg)

可见，除了关闭显示器的时间，我的设置已经尽可能节能了；而我们讨论的是合盖睡眠的场景，所以关闭显示器的时间在这里不影响。

## macOS 睡眠机制

既然 GUI 设置不解决问题，我们就要考虑深入了解 macOS 的睡眠机制了。

在 Google 上检索 *macOS hibernate*，比较可惜的是未能找到 Apple 官方的文档。不过，在 Stack Exchange 上我找到了[这篇回答](https://apple.stackexchange.com/questions/51725/do-macbooks-have-a-true-hibernate-option)。

按照这篇回答的说法，macOS 默认的睡眠，会关闭屏幕，但会维持用于内存（RAM）的供电。这样一来，一旦打开盖子，macOS 就能立即恢复。若是电池电量低于某个预设阈值，则会将内存中的数据转储到硬盘，而后彻底断电。

这样一来，macOS 睡眠时掉电就解释得通了。

原作者还提供了一个 [Apple 官方的链接](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/pmset.1.html)，但无法打开。根据链接内容，看起来是 pmset 这个命令的 man 内容。于是在终端中执行 man pmset 查看相关信息。

经查，

- macOS 的睡眠有两种状态
不断电，数据存储在内存中，可以快速恢复。我们称这种状态为睡眠（Sleep）
断电，数据存储在硬盘中，恢复得较慢。我们称这种状态为休眠（Hibernate/Stand-by）

- 睡眠和休眠可以组合出三种模式，由 hibernatemode 控制
hibernatemode = 0，这是桌面设备的默认值。系统只睡眠，不休眠，不将数据存储在硬盘中。
hibernatemode = 3，这是移动设备的默认值。系统默认睡眠，在一定时间后或电量低于阈值将数据存储在硬盘中，而后休眠。这是所谓的安全睡眠（Safe-Sleep）。
hibernatemode = 25。只休眠，不睡眠。

- 无论是安全睡眠模式还是休眠模式，从磁盘上恢复时，都会需要一定的时间（经测试，大约 3 秒钟）屏幕才会被点亮。

对于 hibernatemode = 3，即安全睡眠模式，又有几个参数来控制细节。

- 当剩余电量大于 highstandbythreshold（默认 50%）时，在 standbydelayhigh 秒（默认 86,400，即一整天）后进入休眠。

- 当剩余电量小于 highstandbythreshold 时，在 standbydelaylow 秒（默认 10,800，即三小时）后进入休眠。

## 实际操作看看

搞清楚具体机制之后，我们就可以做更多细节设置了。

如果你不在乎每次开盖后需要等待 3 -- 5 秒屏幕才电量，那么你可以直接禁用安全睡眠模式，盒盖休眠。

```bash
sudo pmset -b hibernatemode 25
```

如果你仍然希望使用安全睡眠模式，但希望不要掉电得太厉害，则可以适当修改 highstandbythreshold 和 standbydelayhigh/standbydelaylow 的值。比如我是这样设置的。

```bash
# When Using Battery
sudo pmset -b hibernatemode 3
sudo pmset -b highstandbythreshold 95
sudo pmset -b standbydelayhigh 3600  # 1 hour
sudo pmset -b standbydelaylow  1800  # half an hour
# When Using AC Power
sudo pmset -c hibernatemode 3
sudo pmset -c highstandbythreshold 80
sudo pmset -c standbydelayhigh 86400  # 24 hours
sudo pmset -c standbydelaylow  10800  # 3 hours
```

如此一来，我的节能设置如下：

```bash
$ pmset -g custom
Battery Power:
 lidwake              1
 standbydelayhigh     3600
 standbydelaylow      1800
 standby              1
 proximitywake        0
 ttyskeepawake        1
 highstandbythreshold 95
 powernap             0
 gpuswitch            2
 hibernatefile        /var/vm/sleepimage
 hibernatemode        3
 displaysleep         64
 sleep                1
 tcpkeepalive         1
 halfdim              1
 acwake               0
 lessbright           1
 disksleep            5
AC Power:
 lidwake              1
 standbydelayhigh     86400
 standbydelaylow      10800
 standby              1
 proximitywake        1
 ttyskeepawake        1
 hibernatemode        3
 powernap             1
 gpuswitch            2
 hibernatefile        /var/vm/sleepimage
 highstandbythreshold 80
 womp                 1
 displaysleep         180
 networkoversleep     0
 sleep                1
 tcpkeepalive         1
 halfdim              1
 acwake               0
 disksleep            10
```