---
title: "跳过冗余 revisions 以加速 git svn fetch"
url: https://liam.page/2020/01/09/speed-up-git-svn-fetch-by-skipping-reduntant-revisions/
date: 2020-01-09
categories: ["Computer Skills"]
tags: ["Git", "SVN"]
---

众所周知，Git 相较 SVN 的一个优势在于它会将版本库的所有历史信息下载到本地，但它的背面则是：如果版本库很大，则 git clone 会消耗很长时间。使用 git svn 桥接 SVN 仓库时，如果 SVN 仓库很大（例如有超过 100,000 次修订），则 git svn fetch 会花费很长时间（可能超过 24 hours）。

如果你觉得，git svn fetch 这么多修订只是一次性的工作，因此勉强能够忍受。那我只能说，能有这种想法，还是「太年轻」。

SVN 相较 Git 的一个优势在于它可以针对仓库里的各个子路径进行权限设置。于是，我们可以假设这样一种场景：

- SVN 仓库中，有例如 100,000 次修订。

- 你使用 git svn clone -s <uri of svn repository> 将这 10 万次修订都下载到本地，行程了一个 Git 本地仓库。

- 在开发的过程中，你发现你缺少某些子路径的权限，于是你找到 SVN 管理员，为你授权了这些子路径。

- 而后，你会使用 git svn fetch 来更新你的本地仓库。这时，你会发现报错 <file> was not found in commit <hash>。其原因在于，由于之前你的权限缺失，导致前次 git svn clone 以及历次 git svn fetch 的过程中，这些路径在 git-svn 看来是「空的」；但在这次 git svn fetch 时，这些路径突然有了东西，但是缺少相应的历史。

- 为了修正这个问题，有以下一些解决办法：
干掉整个本地仓库，从头再 git svn clone -s <uri of svn repository> 一次。这相当于从 r1 开始重新 git svn fetch 一次。
使用 git svn reset -p <revision> 将本地仓库回退到一个早先的版本，然后从该版本 git svn fetch。需要注意的是，涉及到权限缺失的路径，必须在该 <revision> 之后创建。定位这个 <revision> 本身就很困难，更不用说若是这些路径有过移动的话，又会有一系列的问题。因此，虽然该方案相当于从 <revision> 开始重新 git svn fetch；能省下 r1 -- <revision> 之间的修订，但仍然十分麻烦。

在这种情况下，从头再来，似乎是唯一的选择了。而后，你终于不得不承认曾经的自己「太年轻」。

为了解决这个困局，我们不得不做一次 trade-off。既然问题的根源在于 Git 会将所有历史信息下载到本地，若是我们能舍弃一些过早的历史信息，只下载较近的历史，就能够绕过这个问题。为此，我们需要：

- rm -rf <local repo>：删掉已经「失真」的本地仓库。

- mkdir <local repo>：建立一个空的目录。

- cd <local repo>：进入刚创立的目录。

- git svn init -s <uri of svn repository>：以 git svn 初始化该仓库，但不立即 clone。

- git svn fetch -r <revision>：从 <revision> 开始，拉取仓库版本信息；即舍弃从 r1 开始到 <revision> 结束的所有历史信息。

唯独需要注意的是，如果涉及到分支操作，你必须保证你会用到的分支，都在上述 <revision> 之后创建。

如此一来，只要 <revision> 选得好，代码开始写的早。