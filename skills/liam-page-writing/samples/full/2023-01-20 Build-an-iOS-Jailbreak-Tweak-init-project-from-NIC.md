---
title: "编写 iOS 越狱插件：从 NIC 中创建项目"
url: https://liam.page/2023/01/20/Build-an-iOS-Jailbreak-Tweak-init-project-from-NIC/
date: 2023-01-20
categories: ["Jailbreak and Reverse Engineering"]
tags: ["Jailbreak", "Development", "Tweak", "Theos"]
---

安装好 Theos 之后，我们便可以开始编写插件了。第一步，我们可以利用 Theos 提供的 New Instance Creator（NIC）来创建一个项目模板。这样一来，很多基本信息的文件，我们就不用手工编辑了。

## 执行 NIC

在安装好 Theos 的基础上，可以执行下列命令启动 NIC 程序。

```bash
$THEOS/bin/nic.pl
```

之后，NIC 会在终端上打印出一个列表，询问你想要创建何种类型的项目。

```bash
$ $THEOS/bin/nic.pl
NIC 2.0 - New Instance Creator
------------------------------
  [1.] iphone/activator_event
  [2.] iphone/activator_listener
  [3.] iphone/application
  [4.] iphone/application_swift
  [5.] iphone/control_center_module-11up
  [6.] iphone/cydget
  [7.] iphone/flipswitch_switch
  [8.] iphone/framework
  [9.] iphone/library
  [10.] iphone/notification_center_widget
  [11.] iphone/notification_center_widget-7up
  [12.] iphone/preference_bundle
  [13.] iphone/preference_bundle_swift
  [14.] iphone/theme
  [15.] iphone/tool
  [16.] iphone/tool_swift
  [17.] iphone/tweak
  [18.] iphone/tweak_with_simple_preferences
  [19.] iphone/xpc_service
  [20.] iphone/xpc_service_modern
Choose a Template (required):
```

我们主要关注的是其中的 iphone/tweak 和 iphone/tweak_with_simple_preferences。后者会构造一个 Preferences.plist 文件，以便我们能在 iOS 的系统设置中配置该插件的行为。

这里我们选择 18。接下来，NIC 会交互式地要求我们键入一些插件的信息。

```bash
Choose a Template (required): 18
Project Name (required): PhantomSteps
Package Name [com.yourcompany.phantomsteps]: page.liam.phantom_steps
Author/Maintainer Name [Liam Huang]:
[iphone/tweak_with_simple_preferences] MobileSubstrate Bundle filter [com.apple.springboard]: com.apple.Health
[iphone/tweak_with_simple_preferences] List of applications to terminate upon installation (space-separated, '-' for none) [SpringBoard]: com.apple.Health
Instantiating iphone/tweak_with_simple_preferences in phantomsteps/...
Done.
```

这里，我们给项目起名为 PhantomSteps，其包名称为 page.liam.phantom_steps。你可以按需修改。MobileSubstrate Bundle filter 这一项是说，你可能影响的 App 的名字。List of applications to terminate upon installation 这一项则是说，在安装你的插件时，需要杀死的程序的名字。

## 目录结构

创建成功后，目录结构应该类似

```bash
$ tree .
.
├── Makefile
├── PhantomSteps.plist
├── Tweak.x
├── control
└── layout
    └── Library
        └── PreferenceLoader
            └── Preferences
                └── PhantomSteps
                    └── Preferences.plist

5 directories, 5 files
```

这里

- PhantomSteps.plist 记录了需要杀死的包的名称。

- control 包含了先前在 NIC 交互式环境中填写的信息。

- Makefile 是对应 GNU make 的文件。

- Tweak.x 是插件自身的代码。Theos 会从模板中创建一个带有各种注释的文件供参考。

通过 NIC 模板创建的项目可见：[GitHub](https://github.com/Liam0205/PhantomSteps/tree/c48a76ae16ea761b24bfa94524331a1b7523d0b0)