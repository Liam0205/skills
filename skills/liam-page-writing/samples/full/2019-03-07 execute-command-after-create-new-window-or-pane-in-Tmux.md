---
title: "在 Tmux 创建 window 或 pane 之后执行命令"
url: https://liam.page/2019/03/07/execute-command-after-create-new-window-or-pane-in-Tmux/
date: 2019-03-07
categories: ["Computer Skills"]
tags: ["Tmux"]
---

这是一篇简单的记录。

最近在服务器上安装 Tmux，但每次新建 window 或 pane 之后，不会加载 .bashrc 中的内容。这大概与机器上默认的 login shell 的配置有关。一瞬间，脑海里想到的有两种解法。

- 修改 Tmux 默认启动的 shell；

- 在 Tmux 创建 window 或 pane 之后执行命令，source ~/.bashrc。

前一种解法不难，但只有这单一的用处。修改 ~/.tmux.conf：

```bash
set-option -g default-shell "/bin/bash"
```

后一种解法就灵活多了。具体就是在 split-window 或者 new-window 之后向 shell 发送命令。修改 ~/.tmux.conf：

```bash
bind c new-window \; send-keys "source ~/.bashrc; clear" Enter
bind - splitw -v \; send-keys "source ~/.bashrc; clear" Enter
bind | splitw -h \; send-keys "source ~/.bashrc; clear" Enter
```

此处我将 prefix + c 绑定为产生新 window 的快捷键，而后向 shell 发送 source ~/.bashrc; clear 的命令并回车。prefix + - 和 prefox + | 则分别被设置为纵向和横向分割 window 产生新的 pane，同样会发送相关命令到 shell。如此一来，前述问题就解决了。