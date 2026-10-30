---
title: "macOS 上 Bash 中的主机名"
url: https://liam.page/2020/04/27/hostname-on-BASH-in-macOS/
date: 2020-04-27
categories: ["Computer Skills"]
tags: ["macOS", "Bash"]
---

今天被问到我的 macOS 中 Terminal.app 里的主机名为什么是一颗红心「❤️」。因为设置这个主机名的时间太过久远我也忘记了。于是顺手查了查，得到 [superuser 上的回答](https://superuser.com/a/346722)。于是这篇文章做一个翻译、记录和扩展。

如果你没有覆盖默认设置的话，Bash 里的环境变量 HOSTNAME 保存的是 BSD 主机名的第一个标签（第一个句点前的内容）。于是，若你主机名是 foo.bar.baz，那么 Bash 里的环境变量 HOSTNAME 的值就会被预设为 foo。

那么，BSD 主机名来自哪呢？macOS 会按如下顺序寻找：

- /etc/hostconfig 当中

- /Library/Preferences/SystemConfiguration/preferences.plist 当中的 System ▸ System ▸ HostName

- 通过 DNS 反查你的 IP 得到的主机名

- /Library/Preferences/SystemConfiguration/preferences.plist 当中的 System ▸ Network ▸ HostNames ▸ LocalHostName

- 如果上述所有方案都没有取得主机名，那就简单地设置为 localhost

这里：

- 上述 (1) 不建议修改。

- 上述 (2) 需要通过命令行工具 sudo scutil --set HostName FooBar 来设置。

- 上述 (3) 由不得普通用户设置。

- 上述 (4) 可在 System Preferences ▸ Sharing 当中设置。