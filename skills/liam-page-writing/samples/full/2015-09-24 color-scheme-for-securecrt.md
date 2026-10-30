---
title: "SecureCRT 配色方案（仿 Solarized）"
url: https://liam.page/2015/09/24/color-scheme-for-securecrt/
date: 2015-09-24
categories: ["Computer Skills"]
tags: ["Color Scheme", "Solarized", "SecureCRT"]
---

工作中需要用到 SecureCRT，但是 SecureCRT 默认的配色方案实在是丑得不能用，写代码看久了还伤眼。「刚需」驱动下，自己仿照 Solarized 方案做了一个配色，顺眼多了。

## 设置 Emulation

按照以下顺序进入 Emulation 的设置：

- 菜单栏 Options

- 选择 Global Options

- 左侧 Category

- General

- Default Session

- 右侧 Edit default settings

- Edit Default Settings 按钮

- 左侧 Category

- Terminal

- Emulation

按照图示，将 Terminal 模式选择 Linux，同时勾选 ANSI Color。

![](//liam.page/attachment/attachment/images/SecureCRT/step01.png)

按 OK 键保存，之后选择 Change ALL Sessionts (no undo)，将更改应用到所有会话。

## 设置 ANSI Color

在同一个窗口，设置 ANSI Color；即，按照以下顺序进入 ANSI Color 的设置：

- 菜单栏 Options

- 选择 Global Options

- 左侧 Category

- General

- Default Session

- 右侧 Edit default settings

- Edit Default Settings 按钮

- 左侧 Category

- Terminal

- Appearance

- ANSI Color

按照下列图示，分别设置：

背景颜色 RGB：0:50:50。

![背景颜色](//liam.page/attachment/attachment/images/SecureCRT/step02.png)

字体颜色 RGB：130:150:150。

![字体颜色](//liam.page/attachment/attachment/images/SecureCRT/step03.png)

Vim 注释颜色 RGB：255:128:128。

![Vim 注释颜色](//liam.page/attachment/attachment/images/SecureCRT/step04.png)

目录颜色 RGB：128:128:255。

![目录颜色](//liam.page/attachment/attachment/images/SecureCRT/step05.png)

压缩文件颜色 RGB：128:128:0。

![压缩文件颜色](//liam.page/attachment/attachment/images/SecureCRT/step06.png)

按 OK 键保存，之后选择 Change ALL Sessionts (no undo)，将更改应用到所有会话。

## 设置光标

在同一个窗口，设置 Appearance；即，按照以下顺序进入光标的设置：

- 菜单栏 Options

- 选择 Global Options

- 左侧 Category

- General

- Default Session

- 右侧 Edit default settings

- Edit Default Settings 按钮

- 左侧 Category

- Terminal

- Appearance

按照图示，设置光标颜色，并将 Cursor style 设置为 Wide Vertical Bar。

![](//liam.page/attachment/attachment/images/SecureCRT/step08.png)

按 OK 键保存，之后选择 Change ALL Sessionts (no undo)，将更改应用到所有会话。

## 设置字体和字符集

在同一个窗口，设置 Appearance；即，按照以下顺序进入字体和字符集的设置：

- 菜单栏 Options

- 选择 Global Options

- 左侧 Category

- General

- Default Session

- 右侧 Edit default settings

- Edit Default Settings 按钮

- 左侧 Category

- Terminal

- Appearance

按照图示，设置字体（Font），并将 Character Encoding 设置为 UTF-8。

![](//liam.page/attachment/attachment/images/SecureCRT/step07.png)

这里 YaHei Consolas Hybrid 是一款合成字体，集合了微软雅黑与 Consolas，非常适合编程使用；建议你自行从网络上下载，安装在你的计算机上。

按 OK 键保存，之后选择 Change ALL Sessionts (no undo)，将更改应用到所有会话。

## 最终效果

至此就设置完毕了，我们来看一下最终效果：

![](//liam.page/attachment/attachment/images/SecureCRT/final_result.png)