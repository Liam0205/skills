---
title: "初识 Docker"
url: https://liam.page/2016/05/29/say-hi-to-docker/
date: 2016-05-29
categories: ["Algorithm and Computer Science"]
tags: ["Docker", "Operating System", "Virtualization"]
---

本文部分译自 [Benjamin Cane 的博文](http://bencane.com/2015/12/01/getting-started-with-docker-by-dockerizing-this-blog/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed:+bencane/SAUo+(Benjamin+Cane))。

Docker 是目前风靡全球的虚拟化技术。然而在两年前，Docker 还仅仅是设计者脑海中的概念而已。

本篇将介绍 Docker 的一些基本情况，以及基本操作。顺带着，我们将能见识到 Docker 一些有趣的特性。

## 容器技术与虚拟机

同样作为操作系统虚拟化的方法，容器并不如虚拟机那样出名。它们有相似之处，但也有一些差别。

由于 Hypervisor 向虚拟机提供了虚拟化的硬件，虚拟机可以包含一整个操作系统、系统软件包，以及一些应用程序。因此，在一个宿主机上，可以运行许多独立的客户机。运行在同一宿主机上的虚拟机，提供完整的操作系统环境，共享宿主机上的同一套物理资源。

与之对应，容器技术使得单一的宿主机能够运行多种操作系统环境。在这一点上，容器技术和虚拟机很相似。只不过，容器技术提供的虚拟环境，并不是完整的操作系统。一般来说，容器技术只包含了必要的系统软件包以及应用程序，而不包含整个操作系统或是虚拟化的硬件。因此，容器技术比传统的虚拟机技术占用资源少。容器技术将同一宿主机上的进程相互隔离，互不影响。事实上，与其拿来与虚拟机相较，不如说容器技术与 BSD Jails 以及 chroot 更相似。

## Docker 究竟做了什么？

Docker 其实是个很难定位的技术，我们很难说清 Docker 究竟算不算是容器技术，但它的一些特性又让人无法否认这一点。这似乎有点不可知论的意思了。

Docker 支持 [Solaris Zones](https://blog.docker.com/2015/08/docker-oracle-solaris-zones/) 和 [BSD Jails](https://wiki.freebsd.org/Docker) 这两种容器技术，提供了管理、打包以及部署容器的手段。虚拟机多多少少有类似的功能；但在过往的容器技术里，则几乎看不到——即使有，也很不好用。

容器技术本身不是 Docker 的重点。相反，管理、打包和部署容器的能力，才是 Docker 的杀手锏。

## 安装 Docker

Docker 通常没有默认安装在系统中，所以我们首先要装好它。

在 Ubuntu 里，我们可以用 apt-get install docker.io 来简单地安装它。在 yum 系的 Linux 中，也是类似。在 OS X 里，则可以用 Homebrew 来安装。这里我们以 Ubuntu 为例：

```bash
# apt-get install docker.io
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following extra packages will be installed:
  aufs-tools cgroup-lite git git-man liberror-perl
Suggested packages:
  btrfs-tools debootstrap lxc rinse git-daemon-run git-daemon-sysvinit git-doc
  git-el git-email git-gui gitk gitweb git-arch git-bzr git-cvs git-mediawiki
  git-svn
The following NEW packages will be installed:
  aufs-tools cgroup-lite docker.io git git-man liberror-perl
0 upgraded, 6 newly installed, 0 to remove and 0 not upgraded.
Need to get 7,553 kB of archives.
After this operation, 46.6 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
```

在终端里执行 docker ps 可以查看当前运行着的容器。

```bash
# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

顾名思义。docker ps 和 *nix 系统中的 ps 命令具有类似的功能。docker ps 会打印所有可用的 Docker 容器以及它们当前的状态。因为我们什么也没做，所以命令显示当前没有运行着的容器。

## 部署打包好的 nginx Docker 容器

Docker 可以像 yum 以及 apt-get 那样部署软件包，这一特性十分讨喜。这次，我们用 docker run 命令，实际部署 nginx 服务器看看。

```bash
# docker run -d nginx
Unable to find image 'nginx' locally
Pulling repository nginx
5c82215b03d1: Download complete
e2a4fb18da48: Download complete
58016a5acc80: Download complete
657abfa43d82: Download complete
dcb2fe003d16: Download complete
c79a417d7c6f: Download complete
abb90243122c: Download complete
d6137c9e2964: Download complete
85e566ddc7ef: Download complete
69f100eb42b5: Download complete
cd720b803060: Download complete
7cc81e9a118a: Download complete
```

接受 docker run 命令后，Docker 会寻找置顶的 Docker 镜像并运行。默认情况下，Docker 容器会在前台执行。也就是说，你的 shell 会与 Docker 控制台及容器中正在运行的进程绑定。加上 -d (detach) 选项，Docker 容器就会在后台执行了。

再次执行 docker ps命令，我们就能看到 nginx 容器正在了。

```bash
# docker ps
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS              PORTS               NAMES
f6d31ab01fc9        nginx:latest        nginx -g 'daemon off   4 seconds ago       Up 3 seconds        443/tcp, 80/tcp     desperate_lalande
```

不难看出，容器 desperate_lalande 正在运行，它由 nginx:latest 镜像构建而来。

### Docker 镜像

镜像是 Docker 的核心特征之一。与虚拟机镜像类似，Docker 的镜像是一个打包存档的容器。与此同时，Docker 并未就此止步——Docker 还能通过 Docker 仓库发布这些镜像。Docker 仓库扮演的角色，类似于软件包仓库，因此，Docker 可以像 yum 那样工作。让我们回顾一下 docker run 的输出。

```bash
# docker run -d nginx
Unable to find image 'nginx' locally
```

首先，Docker 表示在本地没有找到 nginx 镜像。这是因为，执行 docker run 时，我们希望 Docker 启动名为 nginx 的容器；而启动容器，需要找到对应的镜像。Docker 首先会在本地寻找相应名称的镜像；若是找不到，则会联网在远程 Docker 仓库寻找。

由于 Docker 是刚安装的，自然不存在名为 nginx 的镜像。于是，Docker 将会连接远程仓库下载它。

```plaintext
Pulling repository nginx
5c82215b03d1: Download complete
e2a4fb18da48: Download complete
58016a5acc80: Download complete
657abfa43d82: Download complete
dcb2fe003d16: Download complete
c79a417d7c6f: Download complete
abb90243122c: Download complete
d6137c9e2964: Download complete
85e566ddc7ef: Download complete
69f100eb42b5: Download complete
cd720b803060: Download complete
7cc81e9a118a: Download complete
```

接下来，Docker 打印了这些信息。默认情况下，Docker 会连接 Docker 公司维护的 [Docker Hub](https://hub.docker.com/)仓库。

与 GitHub 相同，在 Docker Hub 上创建公开仓库是免费的，创建私有仓库则是收费的。你也可以部署你自己的 Docker 仓库——只需要运行 docker run registry 就好了。不过，本文不会讨论这一块内容。

### 停止并移除容器

在我们创建自己的 Docker 容器之前，让我们先清理一下 Docker 环境。首先，我们要停止运行着的容器，然后移除它。

与 docker run 对应，docker kill <container-name> 会停止正在运行的容器。

```bash
# docker kill desperate_lalande
desperate_lalande
```

再次执行 docker ps 可以发现，容器已经不再运行了。

```bash
# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

docker kill 关闭了容器；虽然它不再运行，但仍然存在于 Docker 系统中。docker ps 默认只显示正在运行的容器，docker ps -a 则会显示所有容器（包括未运行的）。

```bash
# docker ps -a
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS                           PORTS               NAMES
f6d31ab01fc9        5c82215b03d1        nginx -g 'daemon off   4 weeks ago         Exited (-1) About a minute ago                       desperate_lalande
```

我们可以用 docker rm 来完全地移除容器。

```bash
# docker rm desperate_lalande
desperate_lalande
```

不过，虽然容器被移走了，但是 Docker 系统中仍有缓存的 nginx 镜像。因此，若然此时执行 docker run -d nginx，Docker 会直接调用本地的镜像启动容器，而无需联网下载。

docker image 会列出所有本地可用的镜像。

```bash
# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
nginx               latest              9fab4090484a        5 days ago          132.8 MB
```