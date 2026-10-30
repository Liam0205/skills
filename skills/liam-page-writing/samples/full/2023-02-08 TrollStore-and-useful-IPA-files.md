---
title: "TrollStore 及常用 IPA 官方下载"
url: https://liam.page/2023/02/08/TrollStore-and-useful-IPA-files/
date: 2023-02-08
categories: ["Jailbreak and Reverse Engineering"]
tags: ["TrollStore"]
---

TrollStore 是一个永久签名的非越狱 App。通过它，我们可以安装任意未签名的 IPA 文件。它基于一个存在于 iOS 14.0 -- iOS 15.4.1 当中的 AMFI/CoreTrust 漏洞：iOS 不验证用于签署二进制文件的根证书是否合法。因此，如果你的 i-设备的系统版本在这个范围内，则可以安装 TrollStore，而不论是否越狱。

## TrollStore

TrollStore 由社区著名开发者 opa334 开发，安装方法及完整的支持列表可见其[官方 GitHub 页面](https://github.com/opa334/TrollStore#installation-guides)。

## 常用 IPA 官方下载

- [ModMyIPA](https://github.com/powenn/ModMyIPA/releases/)：它可以修改 IPA 文件的 Package 名字等信息。于是你可以利用它做 App 多开。

- [DebToIPA](https://github.com/sourcelocation/DebToIPA)：它可以将 .deb 格式的 App 转成 .ipa 格式。

- [Filza](https://www.tigisoftware.com/default/?p=439)：iOS 平台上著名的文件管理器。特别地，它可以访问系统根目录下的文件。（当然，最好不要在不熟悉的情况下对其中文件进行修改）

- [CocoaTop](https://github.com/D0m0/CocoaTop/releases/)：iOS 平台上著名的进程管理器。

- [AppStore++](https://github.com/CokePokes/AppStorePlus-TrollStore)：允许你自由降级从 AppStore 安装的 App。

- [IPA 提取器](https://github.com/SmileZXLee/IpaDownloadTool)：允许你捕获网页安装的 IPA。