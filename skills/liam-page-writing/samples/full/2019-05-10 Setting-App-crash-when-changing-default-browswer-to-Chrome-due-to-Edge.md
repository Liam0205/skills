---
title: "修复 Win10 变更默认浏览器时设置 App 崩溃的问题"
url: https://liam.page/2019/05/10/Setting-App-crash-when-changing-default-browswer-to-Chrome-due-to-Edge/
date: 2019-05-10
categories: ["Computer Skills"]
tags: ["Edge", "Chrome", "Windows 10"]
---

单位配发的电脑问题比较多。昨天提交 IT 修复电脑时，出现了更多问题，不得不重装系统并升级为 Windows 10。初次接触 Windows 10 的我，又遇到了不少问题。所幸，大多数问题都经由 Google 帮助解决。但仍有一个问题始终无法解决：

- Microsoft Edge 闪退；

- 退而求其次使用 Google Chrome，但尝试将 Chrome 设置为默认浏览器时，设置 App 崩溃，设置失败。

显而易见，本质上是 Edge 有问题，连累了设置 App。Google 搜索的结果千篇一律，无非是删除当前用户 AppData 目录下 Edge 的相关文件后在 Powershell 中重新注册 Edge。但反复试验之后都无法解决问题。

最后在英文版 Microsoft Community 上找到了解决办法：

- 设置 -> 应用 -> 应用和功能

- 搜索 Edge -> 单击 -> 高级选项

- 重置 -> 修复 -> 重置

这样一路操作会把 Edge 整个重置掉。此后再去设置当中修改默认浏览器就能绕过 Edge 崩溃的问题了。