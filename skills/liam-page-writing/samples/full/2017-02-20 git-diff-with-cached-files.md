---
title: "使用 git diff 查看差异"
url: https://liam.page/2017/02/20/git-diff-with-cached-files/
date: 2017-02-20
categories: ["Computer Skills"]
tags: ["Git", "Diff", "Cached"]
---

这是一篇简单的记录。

在 git 中

- 使用 git diff 命令可以查看工作区与暂存区之间的差异。

- 使用 git diff <gitreversion> 命令可以查看工作区与指定版本之间的差异。

- 使用 git diff --cached 命令可以查看暂存区与当前 HEAD 指针指向版本之间的差异。

- 使用 git diff --cached <gitreversion> 命令可以查看暂存区与指定版本之间的差异。

- 使用 git diff -- <file> 可以查看特定文件在工作区与暂存区之间的差异。

- 使用 git diff <gitreversion> -- <file> 可以查看特定文件在工作区与指定版本之间的差异。

- 使用 git diff --cached -- <file> 可以查看特定文件在暂存区与当前 HEAD 指针指向版本之间的差异。

- 使用 git diff --cached <gitreversion> -- <file> 可以查看特定文件在暂存区与指定版本之间的差异。

![](/uploads/images/Git/git_diff.png)
图片来自：[http://365git.tumblr.com/post/3464927214/getting-a-diff-between-the-working-tree-and-other](http://365git.tumblr.com/post/3464927214/getting-a-diff-between-the-working-tree-and-other)