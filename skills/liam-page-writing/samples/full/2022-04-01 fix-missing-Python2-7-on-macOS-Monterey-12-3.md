---
title: "解决 macOS Monterey 12.3 上因缺失 Python 2.7 导致的问题"
url: https://liam.page/2022/04/01/fix-missing-Python2-7-on-macOS-Monterey-12-3/
date: 2022-04-01
categories: ["Computer Skills"]
tags: ["Python", "macOS", "Monterey"]
---

最近将手头的 MacBook Pro 的操作系统升级到了最新版本的 macOS Monterey 12.3。启动系统之后，发现部分 App 启动即崩溃。检查详细信息时，发现链接器无法找到 Python 2.7；即有类似下列报错：

```txt
Termination Reason: Namespace DYLD, Code 1 Library missing
Library not loaded: /System/Library/Frameworks/Python.framework/Versions/2.7/Python
Referenced from: /Applications/CHIRP.app/Contents/CHIRP
Reason: tried: '/System/Library/Frameworks/Python.framework/Versions/2.7/Python' (no such file), '/Library/Frameworks/Python.framework/Versions/2.7/Python' (no such file)
```

这是由于 Apple 在 macOS Monterey 12.3 开始，[移除了随系统发行的 Python 2.7](https://developer.apple.com/documentation/macos-release-notes/macos-12_3-release-notes#Python)；于是，尚在依赖 Python 2.7 的 App 在启动时的动态链接阶段就会出错而崩溃。

考虑到部分 App 尚未更新以解除对 Python 2.7 的依赖，这里我们需要手动安装 Python 2.7。为此，我们可在 Python 官网上找到历史版本（[Python 2.7.18](https://www.python.org/ftp/python/2.7.18/python-2.7.18-macosx10.9.pkg)）并下载安装。按我的经验，自主安装 Python 2.7.18 之后，问题即得到解决。