---
title: "更换 Windows 7 锁屏界面的背景"
url: https://liam.page/2018/11/21/replace-the-background-of-login-page/
date: 2018-11-21
categories: ["Computer Skills"]
tags: ["Background", "Windows 7", "Login"]
---

Windows 7 在登录时默认的背景图片是一片蓝色。作为一个程序员，我会倾向于认为，这片蓝色是一张图片资源。因此，它是可以被更换的。

这篇介绍如何更换 Windows 7 锁屏界面的背景。

## 允许自定义

经过一番搜索，我并没能找到那一片蓝的资源图。不过，爬文过程中，我发现 OEM 厂往往会将锁屏界面替换为 OME 自定义的图片。而这个开关需要在注册表中打开。具体来说：

开始菜单 -> 搜索 -> Regedit.exe -> 导航至 HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Authentication/LogonUI/Background -> 修改 OEMBackground 的值为 1。

## 设置 OEM 锁屏背景图片资源

新建目录 C:\Windows\System32\oobe\info\backgrounds，而后将资源图片保存为 .jpg 格式，并重命名为 backgroundDefault.jpg。特别地，要注意它的体积不能超过 256KiB。

## 锁屏查看效果

![](/uploads/images/computer-skills/login_photo.jpg)