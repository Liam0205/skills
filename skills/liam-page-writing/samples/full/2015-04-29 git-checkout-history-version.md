---
title: "在 Git 中 Checkout 历史版本"
url: https://liam.page/2015/04/29/git-checkout-history-version/
date: 2015-04-29
categories: ["Algorithm and Computer Science"]
tags: ["Git"]
---

昨天写代码的时候，误删了一个文件。今天发现的时候，commit 已经 push 到版本库了。本想用 git reset 回退版本，找回文件后重新提交。但是想起 Git 是一个版本控制系统哎，直接从版本库里 checkout 出某个文件的历史版本不就好了？

想法挺好，但是很久没用这个功能，自己已经不记得具体的命令了。于是查了下手册，把和 checkout 历史版本有关的几个命令都记录一下。

### 从某个历史版本创建新的分支

在 Git 中从当前分支创建并检出新分支的命令是

```bash
git checkout -b name-of-new-branch
```

这个命令实际上是

```bash
git checkout -b name-of-new-branch current-branch
```

的简写形式。也就是说，当我们不指定 checkout 起点时，Git 默认从当前活动分支开始创建新的分支。

Git 的每个提交都有一个 SHA1 散列值（Hash 值）作为 ID。我们可以在 checkout 命令中使用这些 ID 作为起点。比如：

```bash
git checkout -b name-of-new-branch 169d2dc
```

这样，Git 的活动分支会切换到 name-of-new-branch 这个分支上，而它的内容与 169d2dc 这个分支一致。

注意：SHA1 的散列值有 40 个字母，相当长。所以 Git 允许我们在不引起歧义的情况下，使用散列值的前几位作为缩写。

提示：你也可以用 git branch name-of-new-branch 169d2dc 来创建一个历史分支，而不切换到该分支。

### 将某个历史版本 checkout 到工作区

首先说明，这样做会产生一个分离的 HEAD 指针，所以个人不推荐这么做。

如果我们工作在 master 分支上，希望 checkout 到 dev 分支上，我们会这么做：

```bash
git checkout dev
```

这里 dev 实际上是一个指针的别名，其本质也是一个 SHA1 散列值。所以，我们很自然地可以用

```bash
git checkout <sha1-of-a-commit>
```

将某个历史版本 checkout 到工作区。

### 将某个文件的历史版本 checkout 到工作区

大多数时候，我们可能只需要对某一个文件做细小的修补，因此只 checkout 该文件就行了，并不需要操作整个 commit 或分支。

上一节我们介绍了如何将某个历史版本完整地 checkout 到工作区。实际上，我们只需要在上一节的命令之后加上需要 checkout 的文件即可。

```bash
git checkout <sha1-of-a-commit> </path/to/your/file>
```

当然，有时候你需要将某个文件的历史版本 checkout 出来，并以一个新的名字保存。这时候可以这么做：

```bash
git show <sha1-of-a-commit>:</path/to/your/file> > </new/name/of/the/file>
```