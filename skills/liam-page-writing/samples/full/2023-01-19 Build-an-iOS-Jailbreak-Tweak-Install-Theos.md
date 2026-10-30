---
title: "编写 iOS 越狱插件：安装 Theos"
url: https://liam.page/2023/01/19/Build-an-iOS-Jailbreak-Tweak-Install-Theos/
date: 2023-01-19
categories: ["Jailbreak and Reverse Engineering"]
tags: ["Jailbreak", "Development", "Tweak", "Theos"]
---

Theos 是一个使用 Perl 开发的跨平台构建系统。由于它最开始就是为了 iOS 越狱插件而开发的，所以非常适合用来做越狱插件的开发。我们也不标新利益，从 Theos 开始。

你也可以直接参考官方英文文档：[https://theos.dev/docs/installation-macos](https://theos.dev/docs/installation-macos)

## 前置依赖

### 安装 XCode

打开 MAS，搜索 XCode，安装/更新到最新。

### 安装 Homebrew

打开 Terminal，执行下列命令（来自[Homebrew 官网](https://brew.sh/)）。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 通过 brew 安装依赖库

在 Terminal 中执行下列命令。

```bash
brew install ldid xz
```

## 下载和安装 Theos

### 设置环境变量

```bash
echo "export THEOS=~/theos" >> ~/.zprofile
# 早期的系统应该加至 ~/.profile
```

### 下载 Theos

```bash
git clone --recursive https://github.com/theos/theos.git $THEOS
```

当然，你也可以将 $THEOS/bin/ 加到环境变量 $PATH 中去。

## 安装 SDK

新版的 XCode 不提供插件可能使用到的私有框架，因此我们需要安装 Theos 维护的补丁版本。

```bash
curl -LO https://github.com/theos/sdks/archive/master.zip
TTT=$(mktemp -d)
unzip master.zip -d $TTT
mv $TTT/sdks-master/*.sdk $THEOS/sdks
rm -r master.zip $TTT
unset $TTT
```

## 更新 Theos

将来需要更新 Theos 时，可以这样：

```bash
$THEOS/bin/update-theos
```