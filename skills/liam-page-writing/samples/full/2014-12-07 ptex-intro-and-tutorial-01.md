---
title: "日文 LaTeX 系统介绍 - 简介"
url: https://liam.page/2014/12/07/ptex-intro-and-tutorial-01/
date: 2014-12-07
categories: ["LaTeX"]
tags: ["pTeX"]
---

本文为译文，原文载于[这里](http://www.preining.info/blog/2014/12/writing-japanese-in-latex-part-1-introduction/)。尽请关注本系列的文章。

对于日本人来说，在 LaTeX 里面写日文很简单。但是由于文档的缺乏，外国人（相对日本）想要这样做就不容易了。更何况日语里面会混合罗马字母、假名、汉字。

这里我想总结一下我自己写日文 LaTeX 文档的经验。这些经验一方面来自我自己的实践，另一方面来自我的日本朋友的各种帮助。系列文章的第一部分简介了日文排版的一些情况，特别是关于 TeX 的介绍。在这里，我会对用于排版日文的 TeX 引擎和宏包做一个简单的比较。

## 日文书写系统

日文中至少有四种书写系统：

- 罗马字母

- 平假名：平假名共有 45 个，一般来说用于连接汉字。

- 片假名：片假名和平假名一一对应，一般用来音译外文。

- 日文汉字：来自中文的表意文字，书面语里有很多汉字。

通常来说，日文文章里这四种书写系统会混杂在一起。下面的截图来自日文[维基百科](http://ja.wikipedia.org/wiki/%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8)的「[日本](http://ja.wikipedia.org/wiki/%E6%97%A5%E6%9C%AC)」词条。

![截图：日文维基百科的「日本」词条](/images/pTeX-intro/Japanese-Text-Example.png)

日文书写系统的的规则繁复。Haruhiko Okumura (奥村 晴彦) 先生对此有过一个不错的[介绍](http://ajt.ktug.org/2008/0201okumura.pdf)；如果你想了解详细的规则，可以看[这里](http://www.w3.org/TR/jlreq/)。TeX 本身并没有支持这些规则，于是 1987 年 NTT 的 Yasuki Saito (斉藤 康己) 先生编写了 NTT jTeX 这个引擎；1990 年，[ASCII 公司](http://asciimw.jp/) 的 Shunji Ohno (大野 俊治) 先生和 Ryoichi Kurasawa (倉沢 良一) 先生修改了 NTT jTeX，增加了出版业所必须的竖排功能，命名为 pTeX (publishing TeX)。对此，Okumura 先生的文章里有详细的叙述。

## 日文排版

日本自己开发了 pTeX，但这些年也有其他的一些 TeX 引擎可以用来排版日文。据我所知，有以下一些。

- e(p)(la)tex: 从原始的 pTeX 而来，增加了 e-TeX 的补丁以适应现代 LaTeX 的需要

- up(la)tex: 同样从原始的 pTeX 发展而来，增加了 e-TeX 的补丁并增加了 UTF-8 编码支持

- xe(la)tex: 另一个系统，同样支持 UTF-8 编码以及其他一些先进的技术

- pdf(la)tex with CJK package: 支持中日韩文字，但已过时

- pdf(la)tex with bxcjkjatype package: 一个易用的新宏包，有一些功能上的限制

- lua(la)tex with luatex-ja package: 最新的日文支持方式，提供了不少优秀的特性

## 需求

在 LaTeX 里书写日文有以下需求。

- e-TeX 原语：e-TeX 是原始 TeX 的扩展，后逐渐成为主流，现在它的原语成为 LaTeX 强制要求的一部分

- 日文排版禁则：如前所述

- 竖排：许多非技术文本都会用到竖排

- UTF-8 支持：pTeX 使用的编码不大好，有不少问题，现代计算机大都使用 UTF-8 编码

- 能够使用商业字体：在文章里能够自由切换字体

- 插图支持

在这里，pTeX 不支持 e-TeX、UTF-8 编码，插图功能孱弱；e-pTeX 完善了 e-TeX 支持，但仍不支持 UTF-8 编码且插图功能依旧孱弱；upTeX 又克服了 UTF-8 编码支持的问题；XeTeX 对竖排的支持能力有限；pdfTeX + CJK 对日文禁则处理不好，也不支持竖排；pdfTeX + bxcjkjatype 对日文禁则处理不好，不支持竖排，也无法比较好地处理商业字体；LuaTeX + LuaTeX-ja 对竖排的支持不甚良好。

## （至今为止的）结论

最近我都在使用 LuaTeX-ja，以下是**我**对此的一些总结。

- (u)ptex: 如果你想要竖排功能，这是唯一的选择；此外，由于 pTeX 系源自日本，它对日文排版禁则的支持最好

- xe(la)tex: 目前功能相对完善的宏包是 xeCJK，但其实只是对中文支持良好；日本有同好对此做了扩展，效果一般

- pdf(la)tex + CJK: 过时了，不推荐

- pdf(la)tex + bxcjkjatype: 很好用，但是有一个很重要缺点：所有非 ASCII 字符都被当做汉字对待

- luatexja: 最打动我的宏包，强烈推荐。

下一篇文章里我会介绍一下各种方式底下的最简日文示例。

谢谢！

## 译者续

马起园 (Clerk Ma) 的 pTeX-ng 是下一代的 pTeX。pTeX-ng 从 Y&Y TeX 发展而来，是纯 C 编写的 TeX 引擎。它带有 e-TeX, pTeX 的补丁，并原生支持 Unicode 编码，对字体支持良好，并且能够直接输出 PDF 文档。pTeX-ng 的前景十分喜人。