---
title: "教程：如何在越狱设备上映射目录？"
url: https://liam.page/2023/04/21/Toturial-how-to-bind-and-mount-folders-on-a-jailbroken-device/
date: 2023-04-21
categories: ["Computer Skills"]
tags: ["iPhone", "Jailbreak", "iOS"]
---

字体替换、生效替换、动画效果资源替换……这些都是越狱圈经久不衰的美化需求。

在 iOS 15 以前，因为没有 SSV，所以用户可以在越狱后的设备上直接替换系统目录下的文件达成效果。实际上，当年的很多「字体插件」就是干的这么个事情。但从 iOS 15 开始，事情发生了变化。Apple 向 iOS 引入了在 macOS 上已经成熟的技术：SSV。用普通人能理解的话说，SSV 是一个在系统启动阶段的密码学校验机制。它会校验整个系统目录是否完整无修改，而如果校验失败则会拒绝启动（表现为反复白苹果）。因此，我们需要新的方案。

## 目录映射是什么？

对于普通用户，目录映射理解为是一种可以达到「指鹿为马」效果的机制。即是说，当系统或者某个软件想要访问某个路径 A 时，通过建立 A 与 B 的映射关系，让系统或者软件实际访问到的是 B 而不自知。

以字体为例。iOS 系统所用的字体存放于 /System/Library/Fonts 这个目录下。显然，我们无法修改其中的内容，否则 SSV 校验失败，机器就变砖了。但是，我们可以做目录映射，比如将其映射到 /var/jb/System/Library/Fonts 这个目录下。其中 /var/jb 是越狱后我们有权限修改而无需担心破坏 SSV 的路径。这样一来，我们只需要修改 /var/jb/System/Library/Fonts 下的文件内容，就能让系统和软件读取到替换后的字体了。

但要注意，/var/jb/System/Library/Fonts 这个路径下原本是没有内容的。因此，建立这种映射关系的前提是要将原始目录（source）当中的内容拷贝一份到目标目录（target）中去，然后再建立这一映射关系。这是有代价的。尽管 iOS 使用的文件系统 APFS 有 Copy-on-Write 的能力，但它对跨 Volumn 的拷贝并不生效（而 /System 和 /var/jb 就是在不同 Volumn 中的）。因此，这种拷贝会占用系统的存储空间，尽管可用，但不是没有代价。

## Fugu15 Max 怎样开启目录映射？

很遗憾，Fugu15 Max 的官方版本并不支持用户自定义的目录映射，而且大概率在将来也不会添加这一功能。因此，想要自定义目录映射的用户只能选择第三方修改的越狱包。这其中也存着风险——你并不知道第三方有没有往里面「加料」。

目前，已知支持用户自定义目录映射功能的有

- [我维护的 Fugu15 Max（可以与官方版本共存）](https://github.com/Liam0205/Dopamine/releases/tag/auto_1681979446)，以及

- 真皮维护的 Fugu15 Max。

普通用户只需安装上述越狱包即可开启自定义的目录映射。默认已开启映射的目录有：

- /System/Library/Fonts

- /System/Library/PrivateFrameworks/CoverSheet.framework/zh_CN.lproj

- /System/Library/PrivateFrameworks/SpringBoardUIServices.framework/zh_CN.lproj

- /System/Library/PrivateFrameworks/UserNotificationsUIKit.framework/zh_CN.lproj

这两个版本都已开源。并且，真皮的开源修改版我已完整检查过代码，确认没有加料。我自己的改版当然也是开源不加料的。这里要特别感谢真皮：我维护的版本里目录映射的功能代码最初就是来自真皮的开源改版。（俗称：抄代码）

## 怎样进行替换？

以 AppleSymbols.ttf 这个字体为例。它是 Apple 官方提供的字体，包含了各种特殊符号；其默认路径位于 /System/Library/Fonts/Core/AppleSymbols.ttf。

假使我们获得了一个改版的 AppleSymbols.ttf 文件（例如，网上广泛流传的所谓盲文修改版），就可以利用 Filza（可通过 TrollStore 安装）将它复制并粘贴到 /var/jb/System/Library/Fonts/Core/AppleSymbols.ttf，然后注销（Restart SpringBoard）即可使其生效。

有时，你也可能获得一组字体。此时，若你想要替换，则需要逐个目录地对字体文件进行替换（可以多选文件，但是不要替换目录本身）。

## 想要映射更多目录怎么办？

我的修改版和真皮的修改版都支持用户自己添加更多映射目录。但这需要用户通过 Filza 自己修改相应的 plist 配置文件。

- 我的版本，配置文件位于 /var/mobile/prefixers.plist，在 Root/source 下添加你想要映射的目录，然后重启再越狱即可。

- 真皮的版本，配置文件位于 /var/mobile/newFakePath.plist，在 Root/path 下添加你想要映射的目录，然后重启再越狱即可。

进阶用户（需要会使用命令行）也可以做到无需重启越狱即可实现新增映射目录。

- 我的版本，复制配置文件至 /var/mobile/update.prefixers.plist，在 Root/source 下添加你想要映射的目录，然后在命令行执行 /var/jb/basebin/jbctl update_bindmount 即可。

- 我的版本，复制配置文件至 /var/mobile/otaFakePath.plist，删除 Root/path 下的已有目录，再添加你想要映射的目录，然后在命令行执行 /var/jb/basebin/jbctl OTAFake 即可。

## 迁移到 Dopamine 之后呢？

我也将修改并维护中文版的 Dopamine（多巴胺）。迁移到多巴胺后，用户需要在设置中打开「启用目录映射」再进行越狱。

若想要增加自定义的目录映射，则可按照同样的方法修改 /var/mobile/Library/Preferences/page.liam.prefixers.plist（再次越狱生效），或是在越狱状态下修改 /var/mobile/Library/Preferences/update.page.liam.prefixers.plist 后执行命令 /var/jb/basebin/jbctl update_bindmount 以立即生效。