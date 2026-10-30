---
title: "网站改版之域名迁移的一些经验"
url: https://liam.page/2018/10/15/website-revise-domain-name/
date: 2018-10-15
categories: ["Computer Skills"]
tags: ["Search Engine", "Domain Name"]
---

今天起，始终博客的域名从 liam0205.me 正式迁移至 liam.page。希望继续能为大家贡献高质量的技术文章。

以下是综合检索到的关于网站改版之域名迁移的一些经验。

## 保证资源可用：301 重定向

虽然迁移域名，但是互联网上已经存在了很多指向老域名的外链。为了保证这些外链依旧可用，不会死链，我们需要为全站所有链接做 HTTP 301 永久重定向。

301 重定向的实现方法有很多，这里不做展开，请自行搜索。

## 保证搜索引擎收录和权重迁移

作为个人技术博客，搜索引擎的自然搜索是一大流量来源。虽然不指望靠着博客流量挣钱，但是也不会希望因为网站域名切换导致流量大幅下降。因此，做好搜索引擎的收录和权重迁移工作还是很重要的。为此，你需要首先了解到哪些搜索引擎为你贡献了较大比例的流量。

对于始终博客来说，Google、Bing、Baidu、360 So 贡献了较大的流量。因此我们首先需要在这四个搜索引擎的站长平台上注册并验证新旧两套域名的所有权。而后，进行站点改版提交。

- [Google Webmaster](https://www.google.com/webmasters/#?modal_active=none) - [站点迁移帮助](https://support.google.com/webmasters/answer/83106)

- [Bing](https://www.bing.com/webmaster/home/mysites) - 站点工具 -> 站点移动

- [Baidu](https://ziyuan.baidu.com/) - 优化与维护 -> 网站改版

- [360 So](http://zhanzhang.so.com/) - 优化与维护 -> 改版收录保护

最后，我们需要在这些站长平台上，提交新的网站地图。如此，等待搜索引擎收录及权重迁移即可。这个过程可能持续长达数月，需要耐心等待。

## 其他资源迁移

始终博客使用[不蒜子](http://busuanzi.ibruce.info/)进行网页计数。为了不使迁移后的计数只有可怜的个位数，也需要联系不蒜子的管理员进行修改。为此，需要加入不蒜子交流群（QQ 群：419260983）联系 Bruce 进行修改。

## Time Line

- 2018-10-15：全站 301 重定向

- 2018-10-15：Google、Bing、Baidu、360 So 站点迁移完成

- 2018-10-15：不蒜子计数迁移完成