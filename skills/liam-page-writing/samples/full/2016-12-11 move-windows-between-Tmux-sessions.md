---
title: "在 Tmux 的 session 之间移动窗口"
url: https://liam.page/2016/12/11/move-windows-between-Tmux-sessions/
date: 2016-12-11
categories: ["Computer Skills"]
tags: ["Tmux", "Session", "Window"]
---

继续记录一下 Tmux 的技巧。

实际使用中，我会在同一个宿主机上开多个 Tmux session。通常来说，每个 Session 内的不同 Windows 共同完成一件事情。这就意味着，同一个 Session 可能用 SSH 连着不同的机器。

某时刻，在 Session 1 中的 Window 1 已经完成任务；恰好，它连着机器 A，而 Session 2 正需要一个连着机器 A 的终端。此时就会考虑把 A 的终端从 Session 1 中移到 Session 2。

这可以用 Tmux 命令 move-window 来实现。

## 命令的使用

命令的语法是

```plaintext
move-window [-d] [-s src-window] [-t dst-window]
           (alias: movew)
```

首先你需要用 leader + : 来激活 Tmux 的命令模式（leader 的默认值是 Ctrl + B）。

然后，你可以用 -s session:window 和 -t session 来指定从哪里（-s）移动到哪里（-t）。比如

```plaintext
movew -s dev-29:1 -t dev-33
```

这样，就能把 dev-29 这个 session 中的窗口 1 移植 dev-33 了。如果你已经在 dev-29:1 里面，那么直接用

```plaintext
movew -t dev-33
```

就可以了。同样，如果你已经在 dev-33 里，那么就可以借助 -d 参数

```plaintext
movew -d dev-29:1
```

来省略目标 session 的名字。

如果你没有给 session 起名字，就只能使用 session-id 代替名字了。你可以用 leader + s 查看所有 session 的 id。

## 参考

- [http://stackoverflow.com/a/3123600/3419508](http://stackoverflow.com/a/3123600/3419508)