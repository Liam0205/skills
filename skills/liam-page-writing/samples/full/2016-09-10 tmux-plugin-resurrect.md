---
title: "保存和恢复 Tmux 会话"
url: https://liam.page/2016/09/10/tmux-plugin-resurrect/
date: 2016-09-10
categories: ["Computer Skills"]
tags: ["Tmux", "Resurrect"]
---

Tmux 是一个强大的终端复用软件，我们可以轻易地为它列举出一堆好处。

- 支持多标签；

- 支持窗口内部进行面板的划分；

- 支持多个终端同时 attach 同一个 Tmux 会话。

如果要为 Tmux 说一个缺点，那可能就是 Tmux 会话无法在系统重启之后比较容易地恢复。这个问题在常年开机的服务器上，可能问题不明显，但是在我们自己的计算机上，或者服务器因为某些原因需要重启，那之前的 Tmux 会话就都丢失了。

为了解决这个问题，我们需要用到 Tmux 的插件系统，并安装名为 tmux-resurrect 的插件。

## Tmux Plugin Manager

和大多数支持插件的软件（系统）一样，Tmux 也有一个插件管理系统，名字就叫做 Tmux Plugin Manager。首先，我们需要安装并学习如何使用这个管理器。

### 下载和安装

Tmux Plugin Manager 的程式码托管在 GitHub 上，它的专案地址是：[https://github.com/tmux-plugins/tpm](https://github.com/tmux-plugins/tpm)。首先，我们需要将 Tmux Plugin Manager 的程式码克隆到本地。

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

而后，我们需要在 Tmux 的配置文件底部加上这么几行：

```plaintext
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Other examples:
# set -g @plugin 'github_username/plugin_name'
# set -g @plugin 'git@github.com/user/plugin'
# set -g @plugin 'git@bitbucket.com/user/plugin'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

注意，最后的 run '~/.tmux/plugins/tpm/tpm' 一定要放在整个 ~/.tmux.conf 的最后一行。

如果你尚未启动 Tmux，那么现在就可以执行 tmux new -s foobar 打开一个新的窗口了。如果你已经启动了 Tmux，那么需要在 Tmux 环境里重新加载配置文件：

```bash
tmux source ~/.tmux.conf
```

### 初始化

注意到，在默认的配置中，我们已经添加了两个插件：tpm 和 tmux-sensible。这里 tpm 是 Tmux Plugin Manager 本身，自不必说；tmux-sensible 则是插件管理器官方推荐的必装插件——当然你可以选择不装，不过我们这里就不标新立异了。

然而，tpm 本身是已经通过 git clone 命令下载到本地了，tmux-sensible 却没有。所以，我们这里需要通过 prefix shift-i 来安装它。prefix shift-i 中，i 是 install 的缩写。执行它会根据配置文件中的插件列表，安装所有插件。

如果你的环境里命令执行正常，那么 Tmux 会提示：

```plaintext
Already installed "tpm"
Installing "tmux-sensible"
  "tmux-sensible" download success

TMUX environment reloaded.

Done, press ESCAPE to continue.
```

这样，插件管理器就算是初始化成功了。

### 安装、升级和反安装插件

在 Tmux Plugin Manager 中安装、升级和反安装插件都很简单，他们的 Tmux 快捷键分别是：

```plaintext
prefix shift-i      # install
prefix shift-u      # update
prefix alt-u        # uninstall plugins not on the plugin list
```

## tmux-resurrect

和 Tmux Plugin Manager 一样，tmux-resurrect 的程式码也托管在 GitHub 上，专案地址是：[https://github.com/tmux-plugins/tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)。

### 安装

有了插件管理器，安装插件就变得很简单了。

首先，我们需要修改 ~/.tmux.conf 文件，在插件列表中加上：

```plaintext
set -g @plugin 'tmux-plugins/tmux-resurrect'
```

这样，在执行 prefix shift-i 的时候，Tmux Plugin Manager 就会到 GitHub 上的相应位置寻找相应专案并下载安装。

### 配置

同样是打开配置文件，插件配置中加上：

```bash
# tmux-resurrect
set -g @resurrect-save-bash-history 'on'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
# set -g @resurrect-save 'S'
# set -g @resurrect-restore 'R'
```

这样，tmux-resurrect 就会保存键入的命令历史、Tmux 的面板布局还有 Vim 的状态了。

### 保存和加载

至此，tmux-resurrect 已经配置好，可以保存和加载 Tmux 会话的状态了，快捷键是：

```plaintext
prefix Ctrl-s       # save tmux session to local file
prefix Ctrl-r       # reload tmux session from local file
```

这样，只要养成定期 prefix Ctrl-s 的好习惯，我们就不怕 Tmux 会话状态丢失了！