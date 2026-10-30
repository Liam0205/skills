---
title: "Python 发行版：Anaconda"
url: https://liam.page/2015/11/21/Python-distribution-Anaconda/
date: 2015-11-21
categories: ["Algorithm and Computer Science"]
tags: ["Anaconda"]
---

Python 是一款优秀的编程语言，其语法优雅简单，但更重要的是各类第三方 Python 库丰富。甚至可以说，学 Python 主要不是学它的语法，而是学习各类第三方 Python 库的用法。安装第三方 Python 库也很简单：Python 拥有 pip 这个包管理器（Package Manager），执行 pip install <package_name> 即可安装所需。

然而，在实际使用中，可能经常会遇到以下一些情况，导致我们无法轻易用 pip 安装第三方库：

- 系统 Python 安装在系统目录，需要 Root 权限才可写入，因此执行 pip 需要使用 sudo 命令。若当前用户不在 sudoer 组内，则无法使用 pip 安装第三方库。

- 系统 Python 安装在系统目录，需要 Root 权限才可写入。若当前用户不在 sudoer 组内，且未安装 pip，则用户无法安装 pip，继而无法用 pip 安装第三方库。

- 系统 Python 安装在用户 Home 目录，但因系统没有 libffi/zlib/openssl 或编译安装 Python 时没有正确配置好这些库的依赖，则也无法安装 Python 的 Setuptools 和 pip。

总而言之，pip 虽然方便，但是因为系统权限、依赖库等问题，有时难以使用。问系统管理员要权限，当然是一个解决方案，但是每次安装新的 Python 库都要麻烦别人，未免麻烦。

最近，我就遇到了这样的问题。

使用的账号没有在 sudoer 组内，因而不能用 sudo 命令获得临时的 root 权限。于是，我只能尝试自行编译安装，但又被各种第三方依赖库搞得焦头烂额。一番搜索之后，在网络上也并没有找到合适的解决方法，只好在 [Unix.sx 上提问](http://unix.stackexchange.com/questions/239691/how-to-install-python-on-centos-without-root-privileges)。

其中，[Back2Basics](http://unix.stackexchange.com/users/47709/back2basics) 提出，可以尝试 Anaconda 这个 Python 发行版。该发行版内置了许多常用的 Python 第三方库，安装之后直接就可使用。此外，Anaconda 还安装了 Setuptools 和 pip 两个 Python 包管理器。最关键的是，Anaconda 不需要自己编译，可以直接安装在用户目录。此外 Anaconda 支持 Windows/Linux/Mac OS X 全平台，更是让人心头爱得不行。

具体：

- 默认安装的第三方库列表：[http://docs.continuum.io/anaconda/pkg-docs](http://docs.continuum.io/anaconda/pkg-docs)

- 下载地址：[https://www.continuum.io/downloads](https://www.continuum.io/downloads)
Windows: 64 位 - [Python 2.7](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda2-2.4.0-Windows-x86_64.exe) - [Python 3.5](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-2.4.0-Windows-x86_64.exe) | 32 位 - [Python 2.7](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda2-2.4.0-Windows-x86.exe) - [Python 3.5](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-2.4.0-Windows-x86.exe)
OS X: 10.7 以上 - [Python 2.7](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda2-2.4.0-MacOSX-x86_64.pkg) - [Python 3.5](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-2.4.0-MacOSX-x86_64.pkg) | 10.5 以上 - [Python 2.7](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda2-2.4.0-MacOSX-x86_64.sh) - [Python 3.5](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-2.4.0-MacOSX-x86_64.sh)
Linux: 64 位 - [Python 2.7](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda2-2.4.0-Linux-x86_64.sh) - [Python 3.5](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-2.4.0-Linux-x86_64.sh) | 32 位 - [Python 2.7](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda2-2.4.0-Linux-x86.sh) - [Python 3.5](https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-2.4.0-Linux-x86.sh)

Anaconda 的安装过程十分简单，这里就不赘述了。: )