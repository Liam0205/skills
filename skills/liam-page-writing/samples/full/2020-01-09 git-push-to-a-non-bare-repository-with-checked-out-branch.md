---
title: "向 non-bare 仓库的检出分支推送提交"
url: https://liam.page/2020/01/09/git-push-to-a-non-bare-repository-with-checked-out-branch/
date: 2020-01-09
categories: ["Computer Skills"]
tags: ["Git", "SVN"]
---

假设有本地 Git 仓库 A，而后在本地自 A 克隆仓库 B（即，在 B 的视角，A 是远程仓库，只不过物理位置在本机）。若从 B 向 A 推送提交，则 Git 可能会报错。这是因为，A 默认是 non-bare 的仓库，粗略理解即是工作区不为空；此时，从 B 向 A 推送的话，A 仓库中的内容可能和 A 工作区内容不一致。

解决该问题的办法之一，是将 A 设置为 bare 仓库。

```bash
cd repo
mv .git ../repo.git # renaming just for clarity
cd ..
rm -fr repo
cd repo.git
git config --bool core.bare true
```

但若 A 是 git svn 桥接的仓库，则 Git 不允许我们将其设置为 bare 仓库。此时，应在仓库 A 执行下列代码，告知 Git 在仓库 A 接受检出分支推送时，同步修改工作区的内容。不过这样的话，我们要保证仓库 A 的工作区没有未提交的修改。

```bash
git config receive.denyCurrentBranch updateInstead
```