---
title: "CTeX 2.4.14：macOS 字体配置升级"
url: https://liam.page/2018/05/03/ctex-2-4-14-update-for-the-fontset-for-macOS/
date: 2018-05-03
categories: ["LaTeX"]
tags: ["macOS", "Yosemite", "El Capitan", "PingFang"]
---

近日，CTeX 宏集已更新到 2.4.14 版本，本次更新主要是 macOS 字体配置的升级。在此为本次更新做一个注解。

## 起因

近来陆续有用户提出 CTeX 宏集在 macOS 上罗马字族的加粗会变为黑体（见[这里](https://github.com/CTeX-org/ctex-kit/issues/335)和[这里](https://github.com/CTeX-org/ctex-kit/issues/351)），但在较新版的 macOS 中，宋体、黑体、楷书已有多个字重的字体配置，因此 macOS 上，CTeX 宏集的字体配置无需像 Windows 上那样以黑体作为粗宋体的妥协。

此即本次更新的起因。

## 经过

参考知乎[孫志貴](https://www.zhihu.com/people/ShikiSuen/activities)的建议，结合[刘海洋](https://github.com/leo-liu)指出无衬线字体在 beamer 内的实际使用情况，我们认为：对于默认的无衬线字体，应当更多地照顾屏显效果，而非是打印效果。因此，我们决定将默认的无衬线字体配置为 PingFang SC，并提供新的字体选择命令 \pingfang；而对于过去的华文黑体，则在字体选择命令 \heiti 中予以保留。此外，考虑到与 Windows 上字体命令的兼容性，我们还决定：在引入苹方黑体后，将字体选择命令 \yahei 作为 macOS 平台上苹方黑体的别名。

考虑到苹方黑体在 El Capitan 才被引入系统，在 Yosemite 及之前的系统中则默认没有该字体，同时考虑到过去旧文档的兼容性，我们决定：对于 macOS/OS X，将字体配置区分为 macold 及 macnew。如此，一方面 CTeX 宏集可以根据苹方黑体是否存在于系统内自动在新旧两个版本的字体配置中选择，另一方面用户可自行指定 macold 字库，以保留和旧文档的兼容性。

据此，对于 macnew 有如下字体配置。

```tex
%<*macnew>
\sys_if_engine_pdftex:TF
  { \ctex_fontset_error:n { mac } }
  {
    \sys_if_engine_uptex:TF
      { \ctex_fontset_error:n { mac } }
      {
        \setCJKmainfont
          [
               UprightFont = *~Light,
                  BoldFont = *~Bold
                ItalicFont = Kaiti~SC,
            BoldItalicFont = Kaiti~SC~Bold
          ] { Songti~SC }
        \setCJKsansfont { PingFang~SC }
        \setCJKmonofont { STFangsong }
        \setCJKfamilyfont { zhsong }
          [
               UprightFont = *~Light,
                  BoldFont = *~Bold,
          ] { Songti~SC }
        \setCJKfamilyfont { zhhei }  { Heiti~SC }
        \setCJKfamilyfont { zhpf }   { PingFang~SC }
        \setCJKfamilyfont { zhfs }   { STFangsong }
        \setCJKfamilyfont { zhkai }  { Kaiti~SC }
      }
  }
%</macnew>
%<macnew>\NewDocumentCommand \yahei    { } { \CJKfamily { zhpf } }
%<macnew>\NewDocumentCommand \pingfang { } { \CJKfamily { zhpf } }
```

## 结果

经过编码后，CTeX 宏集升级到 2.4.14 (2018/05/01) 版本，新增功能如下：

- 将 macOS/OS X 上的字库配置区分 macold 及 macnew；

- 默认情况下若检测到操作系统为 macOS/OS X，或经用户设置 fontset = mac，则 CTeX 宏集将根据 /System/Library/Fonts/PingFang.ttc 的存在性载入 macold 或 macnew 的字库配置；

- macold 的字库配置和旧版本中 mac 的字库配置完全相同；

- macnew 的字库配置中
默认罗马字族（\rmfamily）
以 Songti~SC~Light 为 \mdseries 字重；
以 Songti~SC~Bold 为 \bfseries 字重；
以 Kaiti~SC 为 \itshape 字形；
以 Kaiti~SC~Bold 为 \itshape\bfseries 字形字重之组合。

默认无衬线字族（\sffamily）以 PingFang~SC 取代过去的 STXihei/STHeiti 组合
CJK 字族 zhsong 以 Songti~SC 取代过去的 STSong
CJK 字族 zhhei 以 Heiti~SC 取代过去的 STHeiti
CJK 字族 zhkai 以 Kaiti~SC 取代过去的 STKaiti
新增 CJK 字族 zhpf，作为字体命令 \yahei 和 \pingfang 选择的字族

新版本的 CTeX 宏集[已发布到 CTAN](https://www.ctan.org/pkg/ctex)，预计将于 2018/05/04 前后可经由 tlmgr/mpm 更新。