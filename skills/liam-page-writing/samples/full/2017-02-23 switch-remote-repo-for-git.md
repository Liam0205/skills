---
title: "为 Git 仓库切换远程仓库"
url: https://liam.page/2017/02/23/switch-remote-repo-for-git/
date: 2017-02-23
categories: ["Computer Skills"]
tags: ["Git", "GitHub", "CodingNet"]
---

![](/uploads/images/captures/GitHub_ban.jpeg)
悲剧！

如题图，GitHub 在北京时间 2017 年 2 月 23 日晚在中国大陆地区大部无法正常访问。那么，你挂在 GitHub 上的仓库们还好吗？

此篇介绍如何为 Git 仓库重新设置远程仓库。

## 分布式版本控制

Git 是一个分布式的版本控制系统。也就是说，它没有一个所谓的中心，事实上每一个副本都是地位等同的。比如说，你在 GitHub 上保存了一个仓库，同时你本机也有一个仓库的副本。那么你本机的仓库所存储的内容，和 GitHub 上的内容是完全一致的。这也就是说，你可以很轻易地在另一个地方部署你的仓库。

## 远程仓库设置

Git 的远程仓库设置，需要用到 git remote 命令。

```bash
$ git remote
origin
$ git remote -v
origin  git@github.com:<username>/<repository> (fetch)
origin  git@github.com:<username>/<repository> (push)
```

以上命令，展示了一个挂靠在 GitHub 上的仓库的一般状态。git remote 命令在终端上打印当前本地仓库关联的远程仓库的列表；git remote -v 中的参数 -v 表示 verbose，将详细的信息也打印出来了。

我们可以使用 git remote add 命令来增加一个远程仓库，或者用 git remote rm 来删除一个远程仓库。

```bash
$ git remote add test git@coding.net:<username>/<repository>
$ git remote -v
origin  git@github.com:<username>/<repository> (fetch)
origin  git@github.com:<username>/<repository> (push)
test git@coding.net:<username>/<repository> (fetch)
test git@coding.net:<username>/<repository> (push)
$ git remote rm test
$ git remote -v
origin  git@github.com:<username>/<repository> (fetch)
origin  git@github.com:<username>/<repository> (push)
```

## 迁移到 Coding.Net

[Coding.Net](https://coding.net/) 和 GitHub 一样，也提供基于 Git 的代码托管服务。你可以注册一个账号（获取 <username>），并建立一个仓库（获取 <repository>），然后在本地仓库执行下列代码，完成迁移

```bash
$ git remote rm origin
$ git remote add origin git@coding.net:<username>/<repository>
$ git push origin master:master
```