---
title: "在 VIM 中切换横竖分屏"
url: https://liam.page/2017/05/24/switch-between-horizon-and-vertical-split-in-VIM/
date: 2017-05-24
categories: ["Computer Skills"]
tags: ["Vertical", "VIM", "Split", "Horizon"]
---

我们都知道，以 vimdiff 打开多个文件时，VIM 默认会以竖直分屏的方式将文件之间的差异呈现出来。而若以打开文件，我们希望对比缓冲区中的文件和磁盘上另一个文件之间的差异时，则可以在 VIM 编辑状态中，执行 VIM 命令 diffsplit <filename>。不过，正如 split 会以水平分屏的方式打开一个新的文件一样，diffsplit 也是以水平分屏的方式呈现两个文件的差异的。

diffsplit 的默认呈现方式，对大多数人来说，想必都是不友好的——不方便对比两个文件之间的差异。若是不想退出 VIM，又希望文件差异以竖直分屏呈现的话，就需要考虑如何切换横竖分屏了。

VIM 提供了两个快捷键，用于调整当前缓冲区在分屏模式下的位置。

- Ctrl + w, Shift + h: 将当前缓冲区置于终端最左侧，并占据整个终端高度；

- Ctrl + w, Shift + k: 将当前缓冲区置于终端最顶部，并占据整个终端宽度。

使用这两个快捷键，我们就能在 VIM 中切换横竖分屏了。