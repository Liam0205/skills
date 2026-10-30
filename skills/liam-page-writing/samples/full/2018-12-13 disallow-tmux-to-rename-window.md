---
title: "禁止 Tmux 自动修改 window 的名字"
url: https://liam.page/2018/12/13/disallow-tmux-to-rename-window/
date: 2018-12-13
categories: ["Computer Skills"]
tags: ["Tmux"]
---

使用 Tmux 也有很长时间了，基础配置一直没动，用起来也很顺手。今天在新的服务器上编译安装 Tmux 之后，使用了一段时间发现 Tmux 的 window 名字一直随着执行命令而不断变化。哪怕是强行设置了 window name 也不管用。经过一番搜索，[找到解决方案](https://stackoverflow.com/questions/6041178/keep-the-windows-name-fixed-in-tmux#comment26641702_6041178)。

只需将如下代码，贴进 ~/.tmux.conf 即可。

```plaintext
set-option -g allow-rename off
```