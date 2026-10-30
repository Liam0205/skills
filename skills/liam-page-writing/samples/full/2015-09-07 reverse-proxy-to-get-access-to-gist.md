---
title: "使用 Nginx 搭建反向代理以访问 Gist"
url: https://liam.page/2015/09/07/reverse-proxy-to-get-access-to-gist/
date: 2015-09-07
categories: ["Computer Skills"]
tags: ["Reverse Proxy", "Nginx", "Gist"]
---

嗯，这么久没更新博文，是因为有一篇文章写了很久但一直没写完。真是哔了狗了。

今天想说的是一件更加哔了狗的事情。

Gist 是 GitHub 推出的代码片段分享服务，是最好用的代码片段分享服务没有之一。但是，它被天杀的围墙挡在了外面；而挡住它的理由更是无厘头——有人在白宫上发起了一个针对围墙的请愿活动，使用 Gist 提供了一份围墙制作人员的[名单](http://yangzhe1991.org/blog/2013/01/%E8%87%AA%E7%94%B1/)。

没办法，学习工作都需要用到 Gist，于是决定用 Nginx 在 EC2 上搭建一个针对 Gist 服务的反向代理服务器。

## 反向代理

想必大家对代理服务器并不陌生，但是对「反向代理」这个名词却不一定了解。

实际上，代理服务器按照起到的功能作用可以分为两种：正向代理服务器和反向代理服务器。我们用得比较多的是正向代理服务器：它横在客户端前面，代理客户端的行为，向服务器发出请求。反向代理服务器则与之相反：它横在服务器面前，代理服务器的行为，接受客户端的请求，然后向服务器请求资源后，以服务器的身份将资源内容返回给客户端。

![反向代理示意图](//liam.page/attachment/attachment/images/Network/Reverse_Proxy.png)

对于大型网站来说，反向代理可以作为 DMZ 服务器，承担屏蔽外网访问的功能。此时，外网所有的访问，都通过 DMZ 转发到内网相应的服务器上，从内网服务器获取内容后，再经由 DMZ 返回给外网的客户端。这样，外网客户端无法获知内网的网络拓扑结构，这对内网是一种保护。

现在我们希望在对于围墙可信的某计算机上搭建一个反向代理服务器，并赋予它一个特定的域名（比如 example.com）。这样，我们访问 example.com 就相当于访问了 gist.github.com。

## 编译安装 Nginx

Nginx 是俄罗斯大神 Igor Sysoev 开发的网页服务器，稳定、高效、并发能力好；最关键的是，用它来配置反向代理服务器非常方便。

首先我们来编译安装 Nginx。

### 前期准备

编译安装需要 gcc 和 g++ 之类的编译器，文章之后的内容都默认你的服务器上已经安装了这些工具。

我的 EC2 服务器用的是 Ubuntu Server，安装这些工具可以用 apt-get。

```bash
sudo apt-get install build-essential
sudo apt-get install libtool
```

接下来，我们需要安装 PCRE、zlib 以及 openssl 库。PCRE 是用 Perl 写的正则表达式库，zlib 库在 gzip 压缩的时候会用到，openssl 则是著名的 SSL 库。

我们将源码保存在 /usr/local/src，然后开始下载和编译 PCRE、zlib 和 openssl 库。

```bash
# PCRE
cd /usr/local/src
sudo wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.gz
sudo tar -zvxf pcre-8.37.tar.gz
cd pcre-8.37
sudo ./configure
sudo make
sudo make install
# zlib
cd /usr/local/src
sudo wget http://zlib.net/zlib-1.2.8.tar.gz
sudo tar -zvxf zlib-1.2.8.tar.gz
cd zlib-1.2.8
sudo ./configure
sudo make
sudo make install
# openssl
cd /usr/local/src
sudo wget http://www.openssl.org/source/openssl-1.0.0s.tar.gz
sudo tar -zvxf openssl-1.0.0s.tar.gz
```

### 安装 Nginx

Nginx 最新的版本是 1.9.4。我们下载并安装它。

```bash
cd /usr/local/src
sudo wget http://nginx.org/download/nginx-1.9.4.tar.gz
sudo tar -zvxf nginx-1.9.4.tar.gz
cd nginx-1.4.2
sudo ./configure --sbin-path=/usr/local/nginx/nginx\
--conf-path=/usr/local/nginx/nginx.conf\
--pid-path=/usr/local/nginx/nginx.pid\
--with-http_ssl_module --with-http_sub_module\
--with-http_stub_status_module\
--with-pcre=/usr/local/src/pcre-8.37\
--with-zlib=/usr/local/src/zlib-1.2.8\
--with-openssl=/usr/local/src/openssl-1.0.0s
sudo make
sudo make install
```

这里，./configure 配置的时候：

- --sbin-path 指定了二进制文件的位置

- --conf-path 指定了配置文件的位置

- --pid-path 指定了 pid 文件存放的位置

- --with-http_ssl_module 将会安装 SSL 模块

- --with-http_sub_module 将会安装替换模块，之后的 URL 替换会用到它

- --with-http_stub_status_module 将会安装性能监视模块

- --with-pcre 链接 PCRE 库

- --with-zlib 链接 zlib 库

- --with-openssl 链接 openssl 库

### 测试运行

首先确定 80 端口没有被占用：

```bash
netstat -ano | grep 80
```

然后执行命令，运行 Nginx：

```bash
sudo /usr/local/nginx/nginx
```

查看 80 端口的情况：

```bash
netstat -ano | grep 80
```

出现下列结果，则说明 Nginx 已成功运行，并且正在监听 80 端口：

```plaintext
tcp     0      0 0.0.0.0:80     0.0.0.0:*   LISTEN  off (0.00/0/0)
```

## 配置反向代理

Nginx 的配置文件是用花括号对 {} 嵌套而成的结构化配置文件。这里我们不讲 Nginx 配置文件的详细内容，关于它的详细说明可以参见[这篇博客](http://www.cnblogs.com/xiaogangqq123/archive/2011/03/02/1969006.html)。

按照安装时指定的内容，我们需要找到 /usr/local/nginx/nginx.conf 中的 http 块，在其中添加以下内容：

```plaintext
# server, gist reverse proxy
server {
    listen  80;
    server_name gist.example.com;
    access_log  off;
    resolver    8.8.8.8;
    location / {
        proxy_pass          https://gist.github.com;
        proxy_cache_valid   200 302 1h;
        proxy_cache_valid   404 1m;
        proxy_cache_use_stale error timeout invalid_header updating
            http_500 http_502 http_503 http_504;
        proxy_set_header    Accept-Encoding "";
        proxy_set_header    Accept-Language "zh-CN";
        proxy_set_header    User-Agent $http_user_agent;
        sub_filter  https://gist-assets.github.com/ http://gist.example.com;
        sub_filter  https://gist.github.com/ http://gist.example.com;
        sub_filter_once     off;
    }
}
```

这里对它做一个解释。

- 井号开头的行是注释

- server 开始了 server 块

- listen 表明 Nginx 将会在 80 端口监听

- server_name 是我们给反向代理配置的域名，访问这个域名就相当于访问 Gist

- access_log 是日志文件的配置，这里为了简化我将它关掉了

- resolver 是 DNS 服务器

- location 块具体配置反向代理的行为

- proxy_pass 说明将会将请求转发至 Gist

- proxy_cache_valid 配置缓存

- proxy_cache_valid 同上

- proxy_cache_use_stale

- 同上

- proxy_set_header 设置 HTTP 请求头，Accept-Encoding "" 表示拒绝任何压缩，这保证了服务器返回给反向代理的内容是未经压缩的，以便进行 URL 替换

- proxy_set_header 设置 HTTP 请求头，语言设置

- proxy_set_header 设置 HTTP 请求头，设置 UA

- sub_filter URL 替换

- sub_filter 同上

- sub_filter_once 被关闭，替换所有可替换的内容

这样，访问 http://gist.example.com 就相当于访问了 https://gist.github.com。最后，我们需要让 Nginx 载入新的配置文件：

```bash
sudo /usr/local/nginx/nginx -t
```