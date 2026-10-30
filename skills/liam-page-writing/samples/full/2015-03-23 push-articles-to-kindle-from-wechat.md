---
title: "将微信上的文章推送到 Kindle 上"
url: https://liam.page/2015/03/23/push-articles-to-kindle-from-wechat/
date: 2015-03-23
categories: ["Computer Skills"]
tags: ["WeChat", "Kindle"]
---

微信是近几年发展起来的社交网络。微信公众号和微信朋友圈的出现，让微信变成了一个优秀的信息发布和传播平台。有甄别能力的同好，往往能在微信上找到不少好的文章。但是，一来用手机查看文章伤眼，二来微信上的文章不变保存，三来用手机看文章需要网络支持。总之，是有诸多不便。

昨天思考到这个问题之后，我有做一些搜索，而后就有了欣喜的发现：可以将微信里的文章、好友发来的文字消息免费推送到 Kindle 设备上。

## 原理

激活 Kindle 之后，亚马逊都会为每一台 Kindle 设备分配一个电邮地址。向这个电邮地址里发送包含电子书的邮件，就可以将电子书推送到 Kindle 上了。当然，如此的话，可能会造成垃圾信息泛滥。因为如果不加限制，任何人都能往用户的 Kindle 上推送文件，结果会是一团糟。基于这些考虑，在亚马逊官网的后台里，提供了「认可的电邮地址」的设置。亚马逊在收到邮件之后，会检查这个认可的电邮列表。只有来信电邮在列表当中，亚马逊才会将电子书推送到 Kindle 上。

简单来说，亚马逊将 Kindle 和一个特定的电邮地址关联在一起，通过可信邮箱往上述电邮地址发送邮件，就能把附件中的电子书推送到 Kindle 上。

有了这样的基础知识，就不难理解微信推送的原理了。

亚马逊官方在微信上设立了一个公众平台，平台的后端就是一个电子邮箱。我们将微信上的文章保存在公众平台里，后端邮箱就会把文章发送到 Kindle 邮箱中，最后再推送到 Kindle 设备上。

![推送流程图](//liam.page/attachment/attachment/images/Kindle/wechat_flowchat.png)

明确原理之后，我们来进行设置。

## 亚马逊官网

这里以中国亚马逊为例，如果你的 Kindle 使用的是美国亚马逊账号，请登录美国亚马逊网站进行相应操作。

登录中亚之后，点击下面的链接，进入 Kindle 管理页面。

[https://www.amazon.cn/mn/dcw/myx.html](https://www.amazon.cn/mn/dcw/myx.html)

进入「我的设备」一栏，找到你的 Kindle 设备对应的图标。页面下方会显示出该设备对应的 Kindle 邮箱，请记下来。

![记录 Kindle 邮箱地址](//liam.page/attachment/attachment/images/Kindle/amazon01.png)

进入「设置」一栏，在页面底部，点击「添加认可的电子邮箱」，将 kindle@eub-inc.com 添加到列表当中。

![将 `kindle@eub-inc.com` 添加到认可的电子邮箱列表当中](//liam.page/attachment/attachment/images/Kindle/amazon02.png)

## 微信

首先我们要关注亚马逊的微信公众平台。搜索公众号 cn_Kindle 并关注「亚马逊 Kindle 服务号」。

![亚马逊 Kindle 服务号](//liam.page/attachment/attachment/images/Kindle/wechat01.jpg)

接下来，进入服务号界面，向服务号发送消息 绑定+你的 Kindle 邮箱地址。比如 绑定+myemail@kindle.cn。

![绑定 Kindle 邮箱地址](//liam.page/attachment/attachment/images/Kindle/wechat02.jpg)

## 实际使用看看

周筠老师今天分享了一篇文章，我们把它推送到 Kindle 上看看。

打开这篇文章后，点击右上角的 ···，选择「亚马逊 Kindle 服务号」。

![一键推送到 Kindle](//liam.page/attachment/attachment/images/Kindle/wechat03.jpg)

将你的 Kindle 设备连上网络，过一会儿，就能收到推送了。

![Kindle 截图](//liam.page/attachment/attachment/images/Kindle/kindle01.png)