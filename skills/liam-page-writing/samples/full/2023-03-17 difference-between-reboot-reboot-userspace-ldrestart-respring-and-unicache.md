---
title: "越狱后 iDevice 的重启、重启用户空间、软重启、注销、重建图标之间的关系"
url: https://liam.page/2023/03/17/difference-between-reboot-reboot-userspace-ldrestart-respring-and-unicache/
date: 2023-03-17
categories: ["Jailbreak and Reverse Engineering"]
tags: ["Reboot", "Userspace", "LDRestart", "Respring", "UICache"]
---

越狱用户在将 iDevice 越狱后往往会接触到重启、重启用户空间、软重启、注销、重建图标这些概念。但中文互联网圈子内似乎还没有对它们做完整解释的帖子，故有此篇。

## 前置知识

### 内核空间与用户空间

内存对于程序的运行是必不可少的。程序需要将自身的可执行代码以及运行过程中处理的数据结构存放在内存当中。操作系统内核也是一种程序，因此也和普通的用户应用程序一样需要内存。

为了安全起见，防止普通的用户应用程序不小心地（当然，也防止恶意地）访问并修改内核保存在内存中的内容，现代计算机的操作系统（iDevice 等手持设备也属于广义的计算机）会将整个内存寻址空间（这里的内存指得是虚拟内存）切出一块来单独给内核使用。这块空间就是所谓的内核空间。普通用户程序的权限较低，无权访问内核空间的内容，只能通过系统调用（System Call）来与内核进行交互。

与此相对应地，内核之外的所有其他用户应用程序都运行在内核空间之外的部分，即用户空间。

### launchd

在 macOS 和 iOS (包括衍生的 iPad OS 和 TVOS) 中，进程 ID（PID）为 1 的进程即是 launchd。这是操作系统内核启动后启动的第一个程序。它负责按需启动守护进程（不运行在前台的进程）和应用程序，并负责监控守护进程。操作系统启动后，所有后续启动的进程都是它的子子孙孙（直接或间接 fork 自 launchd）。

launchd 还有一个配套的命令行应用程序 launchctl。它可以与 launchd 通讯，以便管理系统的各个守护进程。

### SpringBoard

SpringBoard 是 iDevice 上管理主屏幕界面的标准应用程序。它也负责启动 WindowServer、启动 App 等工作。因此它也成为越狱后众多 Tweak 的注入目标。

## 辨析

有了这些前置知识，我们就能对这些概念进行辨析了。

- 重启（Reboot）：和普通意义上的「重启计算机」是同样的含义。它几乎相当于给设备断电，然后从零开始启动系统和其他应用程序。因此，如果你的 iDevice 运行的越狱不是完美越狱（Untethered Jailbreak），那么重启后将会丢掉越狱状态。在 iDevice 命令行中运行 reboot 可使设备重启。

- 重启用户空间（Reboot Userspace）：保持内核持续运行，但杀死所有运行在用户空间的进程，包括 launchd，然后重启。这种情况下，因为内核未受影响，所以重启用户空间后仍处于越狱状态。在 iDevice 命令行中运行 launchctl reboot userspace 可使设备重启用户空间。

- 软重启（ldrestart）：这是 Apple 官方提供的能力。和重启用户空间类似，但 launchd 本身并不会杀死然后重启。同样，为内核未受影响，所以重启用户空间后仍处于越狱状态。在 iDevice 命令行中运行 ldrestart 可使设备软重启。

- 注销（Respring）：杀死 SpringBoard，然后重启它。我们通常会在一些影响到 SpringBoard 的设置之后执行注销指令。显然，注销不会掉出越狱状态。在 iDevice 命令行中运行 killall -9 backboardd 可使设备注销。

- 重建图标（UICache）：SpringBoard 存有一份 App 图标、状态栏、Dock 等的缓存（UICache）。若你修改了这些内容，那么可能需要重建这一缓存来使你的变更生效。显然，重建图标不会掉出越狱状态。在 iDevice 命令行中运行 uicache 可使设备重建图标。

注意，在重启用户空间和软重启的过程中，你可能有一定概率遇见内核错误（Kernel Panic），从而导致 iDevice 从重启用户空间/软重启 fallback 到直接重启。这种情况，是会丢掉越狱状态的。

## 插件

Netskao 开发的 PowerSelector 插件可在控制中心（Control Center）中添加一个插件。点按该插件的图标后会弹出一个窗口。在窗口中可以按需选择关机、重启、重启用户空间、软重启、注销、重建图标等操作。可谓十分方便，在此推荐。