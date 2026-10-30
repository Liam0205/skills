---
title: "利用 markdown 宏包实现手稿的双线发布"
url: https://liam.page/2020/04/18/dual-distribution-by-the-markdown-package/
date: 2020-04-18
categories: ["Computer Skills"]
tags: ["Markdown", "PDF"]
---

[前作](/2020/03/30/writing-manuscript-in-Markdown-and-typesetting-with-LaTeX/)介绍了「你喜爱的 Markdown 写作，现更以 LaTeX 呈现」。

至此，Markdown 手稿在 markdown 宏包的帮助下，能被 LaTeX 解析，而它自身也能被很多其他的引擎解析。例如，可以被解析成 HTML 页面，而后发布成为网页。（如 [GitHub Pages](https://pages.github.com/)）那么，一个很自然的引申就来了：是否可以通过巧妙的设定，实现双线发布呢？

本文为解决这个问题提供一些思路。

## 基本思路

从抽象的角度来说，事物 A 若要在环境 I 下存在，需遵循环境 I 带给事物 A 的限制（称之为限制 I）；同样，事物 A 若要在环境 II 下存在，也需遵循环境 II 带给事物 A 的限制（称之为限制 II）。若限制 I 和限制 II 没有冲突，则 A 可同时在两个环境下存在；反之，若冲突，则不能同时存在。

对于后者的情况，要么放弃共存，要么想办法消除冲突。

对于本文的任务来说，我们需要：

- 理顺 Markdown 手稿在 LaTeX 下发布的限制条件；

- 理顺 Markdown 在 GitHub Pages 的 Jekyll 下发布的限制条件；

- 解决上述两部分限制的冲突。

### LaTeX 带来的限制条件

要使 Markdown 手稿在 LaTeX 下发布，整理后可知有以下限制条件：

- 需要 LaTeX，并且需要开启 --shell-escape。

- 允许出现 LaTeX 宏（当开启 hybrid 时）。

- 允许使用行内脚注标记（当开启 inlineFootnotes 时）。

- 插入图片时，图片路径若以 / 开始，则系统会从根目录开始搜索目标图片；不以 / 开始时，系统会从当前目录开始搜索目标图片。

这里，(1) 是使用 LaTeX 时才会出现的限制，与其它 Markdown 解析过程不会冲突；(2) 和 (3) 可视作使用 LaTeX 解析 Markdown 时对 Markdown 语法的增强，如果冲突，可以选择禁用这些增强语法；(4) 是由 LaTeX 插图时的行为决定的，最可能与其它解析方式产生冲突。

### Jekyll 带来的限制条件

要使 Markdown 手稿在 Jekyll 下发布，整理后可知有以下限制条件：

- 需要一个支持 Jekyll 的服务器，并按 Jekyll 的规则进行一些配置。

- 不允许使用行内脚注标记（取决于使用的 Markdown 解析器）。

- 插入图片时，图片路径若以 / 开始，则浏览器会从域名的根目录开始搜索目标图片；不以 / 开始时，系统会从当前 HTML 文档所在的目录开始搜索目标图片。

- 使用 Jekyll 时，需在 Markdown 文件的前部以 --- 包裹，记录一些标记。

这里，(1) 是使用 Jekyll 时才会出现的限制，与其它 Markdown 解析过程不会冲突；(2)/(3)/(4) 容易与其它解析方式产生冲突。

## 冲突事项

- 显然 LaTeX(2) 允许出现的 LaTeX 宏会与 Jekyll 冲突，因此禁用。即，在 Markdown 中我们不能时候用 LaTeX 宏。

- LaTeX(3) 与 Jekyll(2) 冲突，因此禁用行内脚注标记（类似 ^[脚注内容] 这样的写法），换用类似 LaTeX 中 \footnotemark 和 \footnotetext 的做法（[^1] 和 [^1]: 脚注内容）。

- LaTeX(4) 与 Jekyll(3) 冲突。此项冲突的根源在于图片路径以 / 开始时，搜索图片的起始位置不同。因此，需要巧妙地放置 Markdown 文件和图片文件的位置，并在 LaTeX 中利用 \graphicspath 解决相对路径的冲突。

- Jekyll(4) 带来的 --- 标记，在 LaTeX 中会被解析成奇怪的东西。因此，必须想办法绕过这一点。Jekyll 中有 include 和 include_relative 标记，可以在一个 Markdown 文件中引用其他 Markdown 文件中的内容。于是，我们可在 post.md 中使用 --- 标记，并引用 post-internal.md 的内容；而后用 LaTeX 解析 post-internal.md 的内容。

解决这些问题，即可用 LaTeX 和 Jekyll 双线发布 Markdown 手稿的内容了。若要在其他地方发布 Markdown 手稿的内容，可用类似的方法分析冲突并解决。