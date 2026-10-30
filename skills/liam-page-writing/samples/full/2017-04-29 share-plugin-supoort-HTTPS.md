---
title: "支持 HTTPS 协议的分享插件"
url: https://liam.page/2017/04/29/share-plugin-supoort-HTTPS/
date: 2017-04-29
categories: ["Computer Skills"]
tags: ["Share", "HTTPS", "Plugin"]
---

常关注我博客的朋友应该已经发现，几个域名都已经换成了全站 HTTPS。我认为，使用 HTTPS 反映的是一种对读者负责的态度，时至如今没有开启全站 HTTPS 的都是没节操的。

- [https://liam0205.me](https://liam0205.me/)

- [https://cn.liam.science](https://cn.liam.science/)

- [https://blog.liam.science](https://blog.liam.science/)

但是，并不是所有的服务都有节操，正如并不是所有的人都有节操一样。因此，对这些服务就必须寻找支持 HTTPS 的替代品，以免产生 broken HTTPS 的现象。

国内几个常见的分享插件，都不支持 HTTPS。（对，说的就是你 JiaThis）为此，我们就必须自己动手，丰衣足食。

## NeedMoreShare2

经过一番简单的搜索，我找到了名为 [NeedMoreShare2](https://github.com/revir/need-more-share2) 的项目。这个项目只有简单的 CSS 和 JS，并且可以直接部署在自己的网站上，因此就不需要依赖站外的资源，可以说是相当的方便。

此外，项目采用 MIT 协议，因此可以放心地使用。

## 下载、安装

项目挂在 GitHub 上，因此你可以很简单地使用 GitHub 自带的功能得到 master 分支的代码。对于不熟悉 GitHub 的同学，你也可以直接点击[下载链接](https://github.com/revir/need-more-share2/archive/master.zip)。

使用 Hexo 等博客系统的同学，也可以为博客源代码添加一个子模块（submodule）。下面的命令，会将 GitHub 上面的仓库，克隆到 source/plugin/need-more-share2 目录，并作为主项目的一个子模块。

```bash
git submodule add git@github.com:revir/need-more-share2.git source/plugin/need-more-share2
```

将来想要更新子模块，就只需要执行下面的命令就可以了。

```bash
git submodule update --remote
```

接下来，我们需要引用 NeedMoreShare2 的样式表和脚本。

```html
<!-- Javascript file -->
<script src="/plugin/need-more-share2/dist/needsharebutton.min.js"></script>
<!-- CSS file -->
<link href="/plugin/need-more-share2/dist/needsharebutton.min.css" rel="stylesheet" />
```

之后只需要在合适的位置，启用分享按钮就可以了。

```html
<button class="btn btn-default need-share-button">Share</button>
```

## 更多的定制

NeedMoreShare2 还支持参数的传递，只需要加上以 data-share- 开头的一些属性就可以了。

NeedMoreShare2 支持的参数有以下一些

- iconStyle：分享图标的形式，取值有 default, box；

- boxForm：分享图标的排列样式，取值有 horizontal, vertical；

- position：点按按钮之后，分享图标出现的位置，默认是 bottomCenter，取值可以是以下组合 top/middle/bottom + Left/Center/Right；

- networks：希望分享到哪些社交网络，默认是 'Weibo,Wechat,Douban,QQZone,Twitter,Pinterest,Facebook,GooglePlus,Reddit,Linkedin,Tumblr,Evernote'，还可以有 RenRen；

- url：默认是 location.href；

- title：默认是document.title；

- image：默认从 meta[property="og:image"] 或 meta[name="twitter:image"] 取值；

- description：默认从 meta[property="og:description"] 或 meta[name="twitter:description"] 取值。

比如我的博客的分享按钮，对应了下列代码。

```html
<div style="text-align: center;">
<div id="i-share"
    class="btn btn-default need-share-button"
    data-share-position="topCenter"
    data-share-icon-style="default"
    data-share-networks="Wechat,Weibo,Renren,Twitter,Facebook,GooglePlus,Douban,QQZone,Evernote">
    <i class="icon-next-heart fa fa-heart"></i>
</div>
</div>
<script>
    new needShareButton(document.getElementById('i-share'));
</script>
```

注意，这里我给 div 标签记录了 id = "i-share"。而后使用 new needShareButton(document.getElementById('i-share'));，激活了按钮。这种方式可定执行高，也是官方介绍的第二种设置按钮的方式。我个人推荐使用这种方式。

好了，各位希望在 HTTPS 下使用分享按钮的朋友，愉♂悦地设置起来吧~