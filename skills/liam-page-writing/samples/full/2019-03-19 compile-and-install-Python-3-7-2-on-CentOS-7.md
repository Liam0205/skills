---
title: "于 CentOS 7 上编译安装 Python 3.7.2"
url: https://liam.page/2019/03/19/compile-and-install-Python-3-7-2-on-CentOS-7/
date: 2019-03-19
categories: ["Computer Skills"]
tags: ["Python", "OpenSSL", "UUID", "yum"]
---

又到了愉悦地配置系统的时间……今日的任务是在 CentOS 7 上安装最新版本的 Python 3.7.2。

由于前些日子，蛤力橙表示 Anaconda 是 some what 邪恶的，所以这次不打算偷懒用 Anaconda 了，而是选择从源码编译安装。这里记录一些踩过的坑。

## 安装完成后 yum 等脚本挂掉

原因：yum 等脚本依赖 Python2 而非 Python3。这次跨大版本升级，会破坏 yum 等脚本 shebang 头部的指令。

解决办法：使 yum 等脚本显式依赖 Python2。

具体：修改 /usr/bin 下 yum 相关脚本的 shebang 头，将 python 修改为 python2。

```bash
$ cd /usr/bin
$ ls -al yum*
-rwxr-xr-x. 1 root root   801 11月 15 2016 yum
-rwxr-xr-x. 1 root root  9429 11月  6 2016 yum-builddep
-rwxr-xr-x. 1 root root  8582 11月  6 2016 yum-config-manager
-rwxr-xr-x. 1 root root  7609 11月  6 2016 yum-debug-dump
-rwxr-xr-x. 1 root root  7903 11月  6 2016 yum-debug-restore
-rwxr-xr-x. 1 root root 10999 11月  6 2016 yumdownloader
-rwxr-xr-x. 1 root root 11031 11月  6 2016 yum-groups-manager
```

## 安装过程中缺胳膊少腿

原因：Python 依赖其他第三方库，而这些库在系统内没有安装，或者安装的位置不在 Python 安装脚本默认搜索的范围内。

解决办法：使用 yum 一口气安装就好了。

具体：执行下列 yum 命令。

```bash
$ yum install -y ncurses-libs zlib-devel mysql-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel libffi-devel
```

## 安装完成后 pip 提示没有可用的 SSL，以至于无法访问 https 协议的源

原因：Python 编译时没有将 SSL 编译进去。

解决办法：安装符合要求的 OpenSSL 版本，并在 ./configure 时添加 --with-ssl 参数。

具体：执行下列命令。

```bash
$ cd /path/to/downloads
$ wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
$ tar zvxf openssl-1.1.1b.tar.gz
$ cd openssl-1.1.1b
$ ./config -fPIC --prefix=/usr/ --openssldir=/usr/openssl enable-shared shared zlib
$ make -j24
$ make install
```

注意：必须安装 1.0.2 以上版本的 OpenSSL，故而 yum 源当中的 1.0.1 版本不可用。

## 依赖 SSL 之后提示 UUID 编译失败

原因：Python 的 UUID 相关扩展的代码有 bug；无法正确载入 uuid.h 头文件或者载入了两个版本的头文件。

解决办法：修改相应头文件。

具体：在 Python 源码根目录，编辑 ./Modules/_uuidmodule.c 文件，修改头部 #include 部分的代码如下：

```c
#define PY_SSIZE_T_CLEAN

#include "Python.h"
#ifdef HAVE_UUID_UUID_H
#include <uuid/uuid.h>
#else
#include <uuid.h>
#endif
```

## 总结

总结一下编译安装 Python 3.7.2 时用到的命令。

```bash
yum install -y ncurses-libs zlib-devel mysql-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel uuid-devel libuuid-devel libffi-devel

cd /path/to/downloads
wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
tar zvxf openssl-1.1.1b.tar.gz
cd openssl-1.1.1b
./config -fPIC --prefix=/usr/ --openssldir=/usr/openssl enable-shared shared zlib
make -j24
make install

cd /path/to/downloads
wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
tar zvxf Python-3.7.2.tgz
cd Python-3.7.2
sed -i "6s/endif/else/" ./Modules/_uuidmodule.c
sed -i "7d" ./Modules/_uuidmodule.c

./configure --prefix=/usr/local/python3.7.2 --enable-optimizations --enable-shared --enable-profiling --with-ssl
make -j24
make install

cd /usr/bin
for fname in $(ls /usr/local/python3.7.2/bin/); do ln -sf /usr/local/python3.7.2/bin/${fname} ./${fname}; done
ln -sf pydoc3 pydoc
ln -sf python3 python
ln -sf python3-config python-config
ln -sf pip3 pip
```