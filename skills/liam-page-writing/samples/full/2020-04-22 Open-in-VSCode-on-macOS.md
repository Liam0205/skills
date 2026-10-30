---
title: "在 Finder 的右键菜单中添加「Open in VSCode」"
url: https://liam.page/2020/04/22/Open-in-VSCode-on-macOS/
date: 2020-04-22
categories: ["Computer Skills"]
tags: ["VSCode", "Automator"]
---

本文记录如何利用 macOS 的「自动操作」，在 Finder 右键菜单中添加「Open in VSCode」功能。

操作步骤如下：

- 打开 Automator.app（自动操作）

- 选择 Quick Action（快速操作）
![](/uploads/images/computer-skills/quick-action.jpg)

- 配置工作流
Workflow recieves current（工作流接受当前），选择 files or folders（文件或文件夹）
in（位于），选择 Finder（访达）
![](/uploads/images/computer-skills/workflow-recieves.jpg)

- 新增一个 Open Finder Items（打开访达项目）的操作
open with（打开方式），选择 Visual Studio Code.app
![](/uploads/images/computer-skills/open-finder-items.jpg)

- 保存为 Open in VSCode
![](/uploads/images/computer-skills/save-open-in-vscode.jpg)

此时，在 Finder 中选中任意目录，而后右键 -> Quick Actions（快速操作）-> Open in VSCode 即可用 VSCode 打开选中的目录。

![](/uploads/images/computer-skills/open-in-vscode.jpg)