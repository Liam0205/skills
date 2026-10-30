---
title: "通过 Apple Configurator 安装 TrollStore"
url: https://liam.page/2023/04/04/Install-TrollStore-by-Apple-Configurator/
date: 2023-04-04
categories: ["Computer Skills"]
tags: ["Apple", "TrollStore", "Configurator"]
---

近日有朋友问到，当无法通过[标准的网页安装](https://github.com/opa334/TrollStore)的方式安装 TrollStore 时，应当怎么办。

这里提供一个利用 Apple Configurator 安装的办法。

## 需求

- 一台 Mac（此处测试的是 macOS 12.6.1）

- 一台可安装 TrollStore 的 iDevice（此处测试的是 iPhone Xʀ, iOS 15.1）

- 一根可以连接 Mac 和 TrollStore 的线缆

## 操作步骤

- 打开 Mac，并打开 App Store.app

- 搜索并安装：Apple Configurator

- 打开 Apple Configurator，将手机和 Mac 连接

- 在 Apple Configurator 中，选中你的手机，然后在上方点 + 号，选择 App

- 左下角，选择「从我的 Mac 选取」，找到 GTA Car Tracker.ipa，等待安装

- 等待手机上安装好 GTA Car Tracker 后，打开它，选择 Install TrollStore

- 打开 TrollStore，install ldid

- 在 TrollStore 的设置页选择 Install Presistence Helper，选一个你不会用到的系统 App（我选的是 Home/家庭）

- 如常使用

这种方法因为 GTA Car Tracker 的权限不够，所以不能被选为 Presistence Helper，只能选择一个平常不用的系统 App。之后，如果 TrollStore 及其安装的 App 闪退/无法打开，则可以打开 Home/家庭 App，刷新 App。