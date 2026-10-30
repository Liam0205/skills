---
title: "解决 Git 2.24.1 与 OpenSSL 1.1.1b 的冲突"
url: https://liam.page/2020/01/07/fix-incompatiblities-between-git-2-24-1-and-openssl-1-1-1b/
date: 2020-01-07
categories: ["Computer Skills"]
tags: ["Git", "OpenSSL", "Imcompatibilities", "Symbol"]
---

最近因为工作需要处理一些 SVN 仓库，但我还是偏好 Git。早些年就知道 Git 提供了 git svn 可以桥接 SVN。但今天发现公司开发机上的 Git 没有把 git svn 编译进来，也就是会报错：

```bash
$ git svn
git: 'svn' is not a git command. See 'git --help'.

Did you mean one of these?
        fsck
        mv
        show
        spop
        st
```

又因为开发机上我没有 root 权限，所以不得已只能自己从源码编译安装 Git。

## 基本操作

首先是下载、解包、configure、make 一波流。

```bash
$ wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.24.1.tar.gz
$ tar zvxf git-2.24.1.tar.gz
$ cd git-2.24.1
$ ./configure --prefix=~/.local --with-libpcre1 --with-curl --with-openssl=~/.local/include
$ make -j32
```

但在链接阶段报错，提示 SSLv23_method, SSL_library_init, SSL_load_error_strings, sk_num, sk_value, sk_pop_free 等符号不存在。

```plaintext
imap-send.o: In function `verify_hostname':
~/downloads/git-2.24.1/imap-send.c:252: undefined reference to `sk_num'
~/downloads/git-2.24.1/imap-send.c:254: undefined reference to `sk_value'
~/downloads/git-2.24.1/imap-send.c:260: undefined reference to `sk_pop_free'
~/downloads/git-2.24.1/imap-send.c:260: undefined reference to `sk_pop_free'
imap-send.o: In function `ssl_socket_connect':
~/downloads/git-2.24.1/imap-send.c:287: undefined reference to `SSL_library_init'
~/downloads/git-2.24.1/imap-send.c:288: undefined reference to `SSL_load_error_strings'
~/downloads/git-2.24.1/imap-send.c:290: undefined reference to `SSLv23_method'
collect2: ld returned 1 exit status
make: *** [git-imap-send] Error 1
```

我第一反应是 OpenSSL 没安装，或是没有正确配置。但随即发现，早先在安装别的工具的时候，已经安装了 OpenSSL 1.1.1b；并且已经修改了 LD_PATH 和 LD_LIBRARY_PATH 两个环境变量，确保链接器能够正确找到相应的共享对象（动态链接库）。

## 排查问题

在确定 OpenSSL 已安装且能够被编译器、链接器正确找到之后，就只能去检查一下相应符号在共享对象中是否存在了。

SSLv23_method, SSL_library_init 和 SSL_load_error_strings 显然属于 OpenSSL 当中的 libssl.so。于是执行命令

```bash
$ nm libssl.so | grep SSL_library_init
$ nm libssl.so | grep SSL_load_error_strings
$ nm libssl.so | grep SSLv23_method
```

返现返回均为空。这说明在 libssl.so 当中确实不存在这三个符号。sk_num, sk_value 和 sk_pop_free 应当位于 libcrypto.so 当中，检查也有同样结果。

这就令人「满头大汉」了。难道是我下载 OpenSSL 的姿势不对？经过一番检索，在一个与 Git 无关的版本库的 commit log 中，发现了这么一段话：

```plaintext
# https://cbi-dev.igbmc.fr/niveale/tap-formatter/commit/b67a118e7a438009e5d44d0701c21d030c92aa94
Fix: OpenSSL 1.1.0 renamed some symbols

- sk_free => OPENSSL_sk_free
- sk_num => OPENSSL_sk_num
- sk_pop_free => OPENSSL_sk_pop_free
- sk_value => OPENSSL_sk_value
- evp_md_ctx_create => evp_md_ctx_new
- evp_md_ctx_destroy => evp_md_ctx_free
```

原来，OpenSSL 自 1.1.0 开始，修改了部分 API 的名称，导致部分符号名发生了变化。此时，大胆猜想：SSL_* 等三个未定义的符号也是因为类似原因导致的。小心求证如下：

- 首先，在 libssl.so 当中检索含有 init 的符号，发现有名为 OPENSSL_init_ssl 的符号。看名字，其作用应该与 SSL_library_init 相近。

- 而后，在 Google 上检索 SSL_library_init OPENSSL_init_ssl，发现果然，也是在 1.1.0 版本中，该 API 发生了修改；并且 OPENSSL_init_ssl 包括了原先 SSL_library_init 和 SSL_load_error_strings 二者的功能。

- 最后，需要确定 SSLv23_method 的对应是什么。在 Google 上检索 SSLv23_method deprecated，发现在 [OpenSSL 官方文档](https://www.openssl.org/docs/man1.1.0/man3/SSLv23_method.html)有提到，它已为 TLS_method 所代替。

## 解决

于是检索 Git 代码中所有用到这些过时符号的代码，将他们分别修改为对应的新版本。之后编译、链接正常。最后，再顺手提交[一个 patch](https://github.com/gitgitgadget/git/pull/516)。