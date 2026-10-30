---
title: "解决 Windows 7 上的图标异常"
url: https://liam.page/2018/12/28/fixing-icon-missing-on-Windows-7/
date: 2018-12-28
categories: ["Computer Skills"]
tags: ["Windows", "Windows 7", "BAT"]
---

话说 Windows 的小毛病是真的多。配置电脑一段时间之后，Micorsoft Word 的图标就变成了白板（如下图）。这篇文章解释这个现象是哪里出了问题，以及要如何解决。

![](/uploads/images/computer-skills/bad_icon.png)

上图即是又遇见的奇怪的图标——咦，为什么要说又。看见它就很不爽对吧？

Windows 对不同文件类型/文件的图标是有一个图标缓存的。这个缓存的文件名叫做 IconCache.db。如果缓存中存在这个文件类型/文件的图标，就会以缓存中的图标来标示文件类型/文件；如果缓存中不存在，则从原始路径去读取图标资源。

问题就处在这个 IconCache.db 上。它可能被各种奇怪的操作修改、破坏。如果它被修改破坏了，那么我们看到的图标就会有异常。

解决问题的办法也很简单——删掉缓存，让 Windows 重建缓存即可。以下是解决这一问题的批处理文件内容。你可以将它保存为 refresh_thumbnail_cache.bat 或者直接从[这里下载](/uploads/codes/bat/refresh_thumbnail_cache.bat)，而后双击执行。执行时，Windows 资源管理器会被杀死，而后重启。因此，你可能会观察到计算机会「闪」几下。这是正常现象，无需担心。

```plaintext
@echo off
taskkill /f /im explorer.exe
cd /d %userprofile%\AppData\Local
del IconCache.db /a
start explorer.exe
echo done.
```