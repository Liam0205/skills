---
title: "管理 macOS 系统上的启动项"
url: https://liam.page/2019/01/16/manage-daemons-and-agents-on-macOS/
date: 2019-01-16
categories: ["Computer Skills"]
tags: ["macOS", "Daemons", "Agents"]
---

最近在 Mac 上安装了一些软件。重启后发现这些软件会随开机启动。我不喜欢这样，所以想禁止这些启动项。

在中文网络搜索，大多数内容都是在系统偏好设置中，在账户和群组里管理「登录项」。但是目标软件没有出现在登录项的列表中。为此，我不得不在英文网络上搜索，找到了 Apple 关于开发者的一些文档，最终解决了问题。

这篇记录一下如何管理 macOS 系统上的启动项。

## 守护进程与用户代理

启动项的专业称呼是守护进程（Daemon）。守护进程是计算机系统中，运行在后台的程序。在 *nix 系统中，守护进程通常没有父进程（让自己成为孤儿进程，[前作](/2016/09/25/review-of-envoy/#%E8%BF%9B%E7%A8%8B%E7%9A%84%E7%BB%88%E6%AD%A2)中有相关讨论）。一般来说，守护进程完成监听而后作出响应的任务。举例来说，杀毒软件的守护进程监听到有新下载的文件，就给出响应——启动杀毒软件对新下载的文件进行安全扫描。

通常来说，守护进程是系统启动及内核运行后在系统初始化阶段启动的进程。对于 macOS 来说，还有名为用户代理（User Agent）的守护进程类似物。与守护进程相同，用户代理也能实现上述监听而后作出响应的功能。不过，与守护进程不同的是，用户代理是在用户登录系统时启动的，而不是在系统初始化阶段启动的。不过，就本文而言，守护进程与用户代理是一回事，因此除有特殊注明外，一律以守护进程指代，不做区分。

## launchd

在 macOS 上，Apple 推荐用 launchd 来启动守护进程与用户代理。具体来说，launchd 在系统启动及内和运行后，在系统初始化阶段启动守护进程，而在用户登录是启动用户代理。流程大致如下：

- 读入属性列表文件（property list files）

- 注册守护进程所需的套接字（sockets）和文件描述符（file descriptors）

- 启动要求在任何情况下持续运行的守护进程

- 对于按需启动的守护进程，在 launchd 收到相应请求时，启动对应的守护进程

- 当关机（对于守护进程）或用户登出（对于用户代理）时，launchd 对这些守护进程发出 SIGTERM 信号

其中，对于守护进程，其属性列表文件在以下目录中：

- /System/Library/LaunchDaemons/

- /Library/LaunchDaemons/

对于用户代理，其属性列表文件在以下目录中：

- /System/Library/LaunchAgents

- /Library/LaunchAgents

- ~/Library/LaunchAgents

这里，由于 launchd 提前为所有守护进程注册好了套接字及文件描述符，因而守护进程可以在任何时候按需启动。如果 launchd 监听到系统中有其他进程向某一守护进程发出请求，但该守护进程尚未启动；则发出请求的进程会被暂停，直到 luanchd 启动相应的守护进程并对请求作出响应为止。此外，若在一段时间内守护进程没有收到任何请求，则守护进程可以自行退出。launchd 会记录这种退出，并在将来有请求到来时再启动相应的守护进程。

## 属性列表文件（property list files）

上一节提到，launchd 会去相应目录读取属性列表文件，然后根据属性列表文件中的参数，注册套接字和文件描述符等资源，以及控制守护进程的运行策略。因此，接下来的关键就是这类属性列表文件。

属性列表文件的英文是 Property List files，对应的文件名后缀是 .plist。说是属性列表文件，其实本质上就是 XML 文件。以下是一个示例文件。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.hello</string>
    <key>ProgramArguments</key>
    <array>
        <string>hello</string>
        <string>world</string>
    </array>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Apple 在[文档里](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html#//apple_ref/doc/uid/10000172i-SW7-104142-BCICCCFI)给出了守护进程属性列表文件必选和推荐的字段，这里翻译如下。

关键字
说明

Label
必填；包含用于 launchd 识别守护进程的唯一字符串标识符。

ProgramArguments
必填；包含用于 launchd 启动守护进程时使用的参数。

inetdCompatibility
表示该守护进程对于每个传入的连接启用相互独立的实例。该关键字会让 launchd 像 inetd 那样运作；具体来说，launchd 会将与每个传入连接的客户端建立好的套接字传给相互独立的守护进程实例。

KeepAlive
该关键字用于指定相应的守护进程是按需启动还是要一直启动着。Apple 推荐实现按需启动的守护进程。

此外，Apple 在[技术笔记](https://developer.apple.com/library/archive/technotes/tn2083/_index.html)中还提及了其他两个关键字，这两个关键字也可能影响守护进程的运行策略（当然还有其他一些关键字可能影响，但主要还有这两个）：

- RunAtLoad：在属性列表文件加载时启动守护进程；

- SuccessfulExit：与 KeepAlive 联合使用。当 SuccessfulExit = true 时表示若进程正常退出（Exit at 0），则 launchd 应当尝试将其重启；当 SuccessfulExit = false 时表示若进程异常退出，则 launchd 应当尝试将其重启。

因此我们可以构建一些场景：

预期的行为
相应的属性配置

完全地按需启动
KeepAlive = false; RunAtLoad = false

在属性列表文件加载时启动，而后按需启动
KeepAlive = false; RunAtLoad = true

在守护进程异常退出之前，按需启动
KeepAlive = { SuccessfulExit = false }; RunAtLoad = false

在守护进程正常退出之前，按需启动
KeepAlive = { SuccessfulExit = true }; RunAtLoad = false

## 管理启动项

有了这些知识，管理 macOS 上的启动项就很容易了。你需要做的就是在上述 5 个目录下，找到相应程序的属性列表文件，而后按你的意图修改即可。当然，有些属性列表文件需要使用 root 权限来修改。有必要的话，你需要在终端（Terminal.app）当中使用 sudo vim /path/to/your.plist 来修改目标文件。

唯有一点需要注意，在做任何修改之前**做好备份**。