---
title: "在 Windows 7 的锁屏界面上执行命令/程序"
url: https://liam.page/2018/11/22/execute-command-or-executables-on-Windows-login-page/
date: 2018-11-22
categories: ["Computer Skills"]
tags: ["Screenshot", "PsExec"]
---

[前作](/2018/11/21/replace-the-background-of-login-page/)提到了如何在 Windows 7 上更换锁屏界面的背景图片。这就给我创造了一个新的需求——如何为锁屏界面截图？

此篇以此为例，讲讲如何在锁屏界面上执行命令/程序。

## 实现思路

在锁屏界面截图需要解决的主要问题是：

- 如何在用户没有登录的情况下，执行命令；

- 有什么可用的截图工具能够在锁屏界面进行截图？

## 在锁屏界面执行命令

### PsExec

[PsExec](https://docs.microsoft.com/zh-cn/sysinternals/downloads/psexec) 是 M$ 提供的一款在远程机器上执行命令的小工具。正如 Linux 上常用的 SSH 可以将本机作为「远程机器」登录一样，PsExec 也能完成这个任务。此外，PsExec 的 -x 选项，能够在 Windows 登录页面显示 UI。这样一来，我们就能利用 PsExec 在锁屏界面执行命令了。

具体操作路径如下：

- 下载：[https://download.sysinternals.com/files/PSTools.zip](https://download.sysinternals.com/files/PSTools.zip)

- 安装：打开 .zip 包，将 PsExec.exe 复制到 C:\Windows\System32 当中

- 在开始菜单中搜索 cmd，右键「以管理员身份运行」

- 执行命令 psexec -sx cmd.exe；其中 -s 表示以系统权限运行，-x 表示在锁屏界面显示 UR

- 按 Win + L 锁屏

- 按 Alt + Tab 切换到 cmd.exe 的 UI

![](/uploads/images/computer-skills/cmd_on_login.jpg)

### 轻松访问

事实上，Windows 的轻松访问有各种 bug。利用它可以实现很多 hacky 的功能。此次我们也来利用这一小漏洞。

#### 直接替换可执行文件

默认的轻松访问可执行文件位于 C:\Windows\System32\Utilman.exe。我们可以备份它，然后将其替换为其它可执行文件。如此一来，在锁屏界面点击轻松访问按钮，就能执行被替换的可执行文件了。

#### 修改注册表

我们也可以通过修改注册表，将轻松访问的可执行文件路径，指向其它可执行文件。

- 在开始菜单中搜索 regedit，回车执行

- 导航路径
HKEY_LOCAL_MACHINE
SOFTWARE
Micorsoft
Windows NT
CurrentVersion
Image File Execution Options

- 右键，新建名为 Utilman.exe 的项

- 在右侧新建名为 Debugger 的字符串值

- 右键双击 Debugger 字符串值，将其值设置为目标可执行文件的完整路径

## 实际截图试试看

这里，我使用 [Win 7 Logon Screen Capture](http://sourceforge.net/projects/login7/) 这个小工具来截图。我将其下载解压到了 E:\Tools\Login Screen Capture.exe 位置。而后，我们只需要通过上述两种方式之任一，在锁屏界面执行截图工具即可。

以下即是我截图的结果。

![](/uploads/images/computer-skills/login_photo.jpg)