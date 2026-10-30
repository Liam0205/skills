---
title: "升级 Ubuntu，解决登录时提示有软件包可以更新的问题"
url: https://liam.page/2015/06/27/ubuntu-server-packages-can-be-updated/
date: 2015-06-27
categories: ["Computer Skills"]
tags: ["Update", "Ubuntu", "Server", "apt-get", "Upgrade"]
---

Ubuntu 系统在用户登录时会显示欢迎信息。有时用户会看到「有 xx 个软件包可以更新，其中有 xx 个安全更新」。

```plaintext
Welcome to Ubuntu 14.04.2 LTS (GNU/Linux 3.13.0-48-generic x86_64)

    * Documentation:  https://help.ubuntu.com/

    System information as of Sat Jun 27 01:12:04 UTC 2015

    System load:  0.0               Processes:           98
    Usage of /:   10.6% of 9.71GB   Users logged in:     0
    Memory usage: 10%               IP address for eth0: 192.168.12.233
    Swap usage:   0%

    Graph this data and manage this system at:
    https://landscape.canonical.com/

    Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

91 packages can be updated.
39 updates are security updates.
```

对于一般的更新，如果不影响使用，一般也就罢了。但是通常，如果系统提示有安全更新，大多数用户（特别是服务器管理员）还是会去更新的。不过，面对 Ubuntu 的这些提示，很多用户经常遇到「不管怎么 apt-get updage && apt-get upgrade 也不见好」的问题。

## 升级命令

虽然 apt-get 经常被人诟病，但实际上它还是个挺好用的软件包管理器。在 Ubuntu 14.04 以后的系统中，apt-get 相关的升级更新命令有四个：

```bash
apt-get update
apt-get upgrade
apt-get full-upgrade
apt-get dist-upgrade
```

那么，这四个升级命令都有什么差别呢？

根据 apt-get 的官方手册：

- update - 从服务器更新可用的软件包列表。

- upgrade - 根据列表，更新已安装的软件包。upgrade 不会删除在列表中已经没有的软件包，也不会安装有依赖需求但尚未安装的软件包。

- full-upgrade - 根据列表，更新已安装的软件包。full-upgrade 可能会为了解决软件包冲突而删除一些已安装的软件包。

- dist-upgrade - 根据列表，更新已安装的软件包。dist-upgrade 可能会为了解决软件包冲突而删除一些已安装的软件包，也可能会为了解决软件包依赖问题安装新的软件包。

## 我们应该怎么做？

依次执行如下命令即可：

```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
sudo reboot
```