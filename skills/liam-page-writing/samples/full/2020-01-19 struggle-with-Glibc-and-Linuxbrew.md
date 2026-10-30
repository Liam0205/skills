---
title: "泥潭挣扎记：Linuxbrew 里的 Glibc"
url: https://liam.page/2020/01/19/struggle-with-Glibc-and-Linuxbrew/
date: 2020-01-19
categories: ["Computer Skills"]
tags: ["Homebrew", "Linuxbrew", "brwe", "Glibc"]
---

本着 Homebrew 真香的原则，我尝试在 CentOS 上安装 Linuxbrew。至于不用 Yum 的原因，请看刚才提到的真香原则。

但随即，我就陷入到了 Glibc 的泥潭。这个泥潭是一个需要自举（bootstrap）的循环依赖；这个泥潭长这样：

- Linuxbrew 安装任何东西都依赖 curl 和 git，而且它不想用系统中自带的 curl 和 git。

- curl 和 git 都直接或间接依赖 Glibc。

- Linuxbrew 里的 Glibc 版本比较高，目前是 2.23，因此依赖高版本的 GCC（>= 4.7），以及因为 Linuxbrew 的缘故依赖 curl 和 git。

- 系统里的 GCC 版本较低，因此 Linuxbrew 安装 Glibc 失败；而通过 Linuxbrew 安装高版本的 GCC 又再次依赖 Glibc。

泥潭里有两个循环依赖：

- Glibc 和 curl 及 git 等基础工具相互依赖；

- Glibc 和 GCC 相互依赖。

## 寻找突破口，解决 Glibc 的存在性问题

两个循环都涉及到 Glibc，因此必须想办法从 Glibc 这里突破。考虑到 Glibc 基础库的地位，很多依赖它的模块，都是硬编码 Glibc 的位置。因此 Glibc 必须从源码编译安装，无法直接服用编译好的二进制文件。所以 Glibc 无论如何都得依赖 GCC。既然高版本的 Glibc 依赖高版本的 GCC，那么就只能想办法安装较低版本的 Glibc——首先解决有没有（Linuxbrew 中的）Glibc 的问题，再去解决 Glibc 版本的问题。

为了安装低版本的 Glibc，我们要用到 brew 直接从 tap 中安装的特性：

```bash
MAKEFLAGS="" \
HOMEBREW_MAKE_JOBS="1" \
brew install --verbose --ignore-dependencies https://raw.githubusercontent.com/Linuxbrew/homebrew-core/6fb5dfd50895416bea3d00628b8d3b41fa1f4f32/Formula/glibc.rb  # Glibc 2.20
```

讲一下这里的黑魔法。

MAKEFLAGS 和 HOMEBREW_MAKE_JOBS 的设定，都是为了让编译 Glibc 的过程中使用非并行编译。这是因为并行编译 Glibc 2.20 时，因为 Makefile 依赖没写好，会产生一些问题。

--verbose 参数的意义是让 brew 打印尽可能多的调试信息。--ignore-dependencies 则是无奈之举，因为 Glibc 依赖的东西反过来又会依赖 Glibc，于是 Linuxbrew 会尝试去安装高版本 Glibc，这就毁了。

执行这条命令，Linuxbrew 首先还是会去尝试安装 curl 和 git。而它们又依赖 Glibc，所以又会尝试安装高版本的 Glibc，依然会失败。这没办法，由着他们失败去。等它们失败之后，就会尝试安装 Glibc 2.20。

## 解决 GCC 的问题

接下来要解决的是 GCC 的问题。因为但凡碰到要编译的，都离不开它。于是我们有：

```bash
brew install --verbose --ignore-dependencies xz gmp mpfr libmpc isl gcc
```

这里安装 xz, gmp, mpfr, libmpc, isl 的原因是 GCC 自身就依赖他们——哪怕你不使用 Linuxbrew，手动编译 GCC 时，你也得安装它们。

## 安装 curl 和 git

有了 Glibc 和 GCC，安装 curl 和 git 就不成问题了。我们有：

```bash
brew install --verbose curl git
brew update  --verbose --force
```

## 升级 Glibc

之前我们安装的是 Glibc 2.20，现在我们来升级它。

```bash
MAKEFLAGS="" \
HOMEBREW_MAKE_JOBS="1" \
brew upgrade glibc --verbose
```

## 重新安装 GCC

因为 GCC 依赖的 Glibc 发生了变化，这导致 GCC 不可用。因此我们要做一些调整。

```bash
brew postinstall gcc
```

如此，万事 okay~