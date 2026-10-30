---
title: "手动安装 XCode Command Line Tools"
url: https://liam.page/2020/10/13/install-XCode-Command-Line-Tools-manually/
date: 2020-10-13
categories: ["Computer Skills"]
tags: ["Apple", "XCode", "CLT"]
---

使用 macOS 时，Apple 自家的 XCode Command Line Tools 基本上很难绕开。比如你想用 Homebrew 安装点什么东西，它都会依赖 XCode CLT。

比较不幸地是，如果你更新了 macOS，那你就得重新安装 XCode。如果你重新安装 XCode，那么匹配版本的 CLT 也得重新安装。更为不幸的是，最近使用 xcode-select --install 安装 CLT，经常失败。遂起了手动安装的念头。

摸索后步骤如下：

- Apple 家官网：[https://developer.apple.com/download/more/](https://developer.apple.com/download/more/)

- 以 Apple ID 登录

- 在搜索框搜索 Command Line Tools

- 打开你 macOS 上的 XCode，检查其版本号

- 下载对应版本的 Command Line Tools 镜像（*.dmg）

- 从镜像里手工安装