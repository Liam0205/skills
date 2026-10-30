---
title: "使用合适的字体回退机制（Fallback）改善网页在 Windows 平台的字体显示效果"
url: https://liam.page/2015/04/30/using-font-fallback-to-enhance-the-appreance-on-windows/
date: 2015-04-30
categories: ["Computer Skills"]
tags: ["Hexo", "Font", "Fallback"]
---

昨天在群里提起 Windows 平台下坑爹的中易宋体之屏显效果，今日忽而想起自己的博客在 Windows 平台下显示的也是宋体。当然，这不是我的错。原本的字体机制，博客会按照顺序选择一款无衬线字体，直到无可选择时采用系统默认的无衬线字体。但是坑死人不偿命的云都死系统，把 SimSun （中易宋体）这个带有衬线（好吧，严格来说中文没有这个概念，我们跟着西文勉强这么称呼它）的字体也放进了系统 sans serif 字族里面去。其结果就是，不能丑陋更多。

作为一个强迫症患者，我们来看看如何修复这个问题。

## 字体选择

配置字体回退机制，两个主要的原则就是：

- 屏显效果好的字体放前面

- 适用范围小的字体放前面

两条原则共同的作用就是：在尽可能多的平台下，获得相对更好的字体屏显效果。

对于中文来说，安装在作业系统中的主流黑体，屏显效果有大致如下的排序：

- Hiragino Sans GB - 冬青黑体

- Source Han Sans CN - 思源黑体

- Microsoft YaHei - 微软雅黑 (On Windows)

- STXihei - 华文细黑

- WenQuanYi Micro Hei - 文泉驿米黑

- SimHei - 中易黑体

其中冬青黑体和华文细黑，默认安装在 OS X 作业系统上；微软雅黑和中易黑体则主要安装在 Windows 作业系统上；思源黑体和文泉驿米黑则是 Linux 系统的主流中文黑体。

参考这一屏显效果排序，再结合一些实际情况（比如，在 OS X 作业系统中可能会因为安装 MS Office 而获得微软雅黑和中易宋体），我们给出了这样一个字体回退机制：

- Hiragino Sans GB

- STXihei

- Source Han Sans CN

- Microsoft YaHei

- WenQuanYi Micro Hei

- SimHei

这样，再加上西文的字体和系统默认的 sans serif，我们就得到了完整的字体回退列表：

```plaintext
font-sans = "Helvetica Neue", "Helvetica", "Hiragino Sans GB", "Source Han Sans CN", "STXihei", "Microsoft YaHei", "WenQuanYi Micro Hei", "SimHei", "Arial", sans-serif
```

## 修改 modernist 主题的字体回退配置

网页的字体回退机制一般写在样式表（CSS）文件中。hexo 的样式表文件是从一些 styl 文件中产生的，每一个主题的 styl 文件结构都不大一样，所以这篇文章以我使用的 modernist 为准讲述。

modernist 的作者很有心，将一些可能需要个性化配置的变量专门储存在名为 variable.styl 的文件里。这个文件位于 ./theme/modernist/source/css/_base/variable.styl，我们打开它，然后将 font-default 和 font-title 的值改为：

```plaintext
"Helvetica Neue", "Helvetica", "Hiragino Sans GB", "Source Han Sans CN", "STXihei", "Microsoft YaHei", "WenQuanYi Micro Hei", "SimHei", "Arial", sans-serif
```

之后，我们在命令行运行

```bash
hexo clean && hexo d -g
```

就能将修复好的 CSS 文件推送到仓库了。

之后在 Windows 中打开，就会依照上述字体顺序去检索字体。对于新版的 Windows 系统，一般会以微软雅黑打开；对于旧版的 Windows 字体，一般会以中易黑体打开。