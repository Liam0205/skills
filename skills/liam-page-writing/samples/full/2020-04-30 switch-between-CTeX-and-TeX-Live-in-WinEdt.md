---
title: "在 CTeX 套装附带的 WinEdt 中自由切换发行版"
url: https://liam.page/2020/04/30/switch-between-CTeX-and-TeX-Live-in-WinEdt/
date: 2020-04-30
categories: ["LaTeX"]
tags: ["CTeX", "TeX Live", "MiKTeX", "WinEdt"]
---

虽然站在如今（2020-04-30），CTeX 套装已经应该被扫进历史的垃圾桶。但是，CTeX 套装曾经的贡献不应该被一并扫进垃圾桶。

CTeX 套装是很多人用的第一个 TeX 发行版。其中的 WinEdt 编辑器，也是非常优秀的 TeX 编辑器，很多人更是用顺手了不乐意换。于是，如何方便地切换到 TeX Live 2020，并允许用户在需要的时候切回 CTeX 套装就是个问题了。

本文来解决它。

## 问题拆分

问题需要拆分成两个部分。

- 如何在 CTeX 套装和 TeX Live 当中自由切换；

- 如何让 WinEdt 的编码在 GBK（CTeX 套装的默认设定）和 UTF-8（使用现代 TeX 时推荐的编码）之间切换。

## 发行版的切换

我们假定用户首先安装了 CTeX，此时想要用 TeX Live，但又有保留 CTeX 套装的需求。此时，用户无需卸载 CTeX 套装，可以直接[安装 TeX Live](/texlive/)。

安装好 TeX Live 之后，当需要使用 TeX Live 时，用户可以打开 WinEdt，遵循如下操作路径：

- 菜单栏 Options

- 菜单 Configurations

- 二级菜单 TeX Live

如此就完成了，可谓是超简单。若要切换回 CTeX 套装，则只需按照相同的操作步骤，选择 MiKTeX 即可。

![](/uploads/images/LaTeX/WinEdt-switch.png)

若要确定当前使用哪一个发行版，只需抬头看看 WinEdt 标题栏上的提示即可。

![](/uploads/images/LaTeX/WinEdt-status-bar.png)

## 切换编码

切换编码稍显复杂，但也不困难。具体设置在以下位置：

- 菜单栏 Options

- 菜单 Preferences

- 标签 Unicode

- 区域 Unicode Preferences

我们将「Enable UTF-8 Format for Modes:」下面的输入框的内容修改为：

```text
TeX;UTF-8|ACP;EDT;INI
```

而后，

- 当你需要使用 UTF-8 编码时，勾选「Enable UTF-8 Format for Modes:」前的复选框，而不勾选本页其他三个复选框。（如图）
![](/uploads/images/LaTeX/WinEdt-encoding.png)

- 当你需要使用 GBK 编码时，取消勾选「Enable UTF-8 Format for Modes:」前的复选框，而勾选本页其他三个复选框。

至此，老树焕新春，CTeX 套装可以愉快地和最新的 TeX Live 共存了！