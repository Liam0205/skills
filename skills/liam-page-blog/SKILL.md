---
name: liam-page-blog
description: 在 Liam Huang 的博客源码仓库（Liam0205/blog-source，zh 与 en 两个 Hexo 站点）里新建文章、本地生成验证、发布上线。含 Node 18 环境准备、slug 与 frontmatter 约定、hexod 的四个阶段、以及本机没有 SSH key 时的凭证注入。 Use when publishing a post to liam.page or maintaining the blog-source repo.
---

# liam.page 博客发布

## 什么时候用

- 「发一篇博客」「把这篇文章发到博客上」「更新博客」
- 博客源码仓库的日常操作：新建文章、本地生成、发布

## 仓库

- `git@github.com:Liam0205/blog-source.git`，必须递归 clone，子模块包含 zh 与 en 两套 NexT 主题、`zh/.deploy_git`（发布目标仓库的工作目录）
- 本地路径约定 `~/projects/blog-source`
- `zh/` 与 `en/` 是两个独立的 Hexo 站点，各自带 `hexo`、`hexod`、`sync` 脚本
- 线上地址 `https://liam.page`（zh）与 `https://liam.page/en/`（en）
- 发布目标是 `Liam0205/liam0205.github.io` 的 master 分支

## 环境

站点脚本第一行执行 `nvm use 18`，系统自带的 Node 22 不能直接用。

```bash
export NVM_DIR="$HOME/.nvm"
. /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh
nvm install 18        # 只装一次，落在 ~/.nvm
nvm use 18
```

然后在站点目录里装依赖。仓库带了 `package-lock.json`，用 `npm ci` 比 `npm install` 稳：

```bash
cd ~/projects/blog-source/zh && npm ci
```

PATH 上可能还有别的 node（比如 `~/.hermes/node/bin/node`），用 `which -a node` 确认排第一位的是 `~/.nvm/versions/node/v18.*/bin/node`。

## 新建文章

```bash
cd ~/projects/blog-source/zh && ./hexo new post "给 AI 去去味儿"
```

生成位置是 `source/_posts/YYYY/MM/DD/<title>.md`，由 `new_post_name: :year/:month/:day/:title.md` 决定。

permalink 配置是 `:year/:month/:day/:title/`，其中的 `:title` 取文件名，所以**文件名就是 URL**。站点现有文章一律用英文 slug，中文标题要手动把文件改成英文名：

```bash
cd source/_posts/2026/10/30 && mv 给-AI-去去味儿.md ai-tone-removal.md
```

frontmatter 照 `scaffolds/post.md` 补齐，`quicklink` 和 `reward_settings` 这两块别删，主题会读。

`categories` 从下面这组里选一个：

```
Algorithm and Computer Science    Big Data and Machine Learning
Computer Skills                   Economics and Investment
English                           GRE
Jailbreak and Reverse Engineering LaTeX
Life and Human Nature             Literature and Social Sciences
Magic of Light and Shadow         Mathematics and Natural Sciences
Miscellaneous                     Music
Photoshop                         Sports
```

`tags` 用英文单词，写文章里实际涉及的对象或技术，三个以内。

## 生成验证

```bash
cd ~/projects/blog-source/zh && ./hexo g
```

全站大约 2300 个文件，两三秒跑完。验证三件事：

```bash
F=public/2026/10/30/ai-tone-removal/index.html
ls -la $F                                   # 页面存在
grep -o "<title>[^<]*</title>" $F           # 标题正确
grep -l "ai-tone-removal" public/index.html public/archives/index.html
```

第三条确认文章进了首页和归档。没有出现说明日期或 draft 状态有问题。

## 发布

`./hexod` 依次做四件事：

1. `./sync`：`git add ..` → commit → `git pull --rebase` → push，把源码推到 `blog-source`
2. `git submodule update --init --remote --recursive`，把主题拉到远端最新
3. `hexo clean` → `hexo g` → `hexo d`，推送到 `liam0205.github.io` 的 master
4. `git add .` → commit → push，把 `.deploy_git` 的新提交记回源码仓库

三个注意点：

- `hexod` 里每条命令都包在 `while ! (...)` 里，认证失败会无限重试。一定用 `timeout` 包住，否则会卡死
- `hexo d` 会先清空 `public/` 再重新生成，本地验证的结果不会带过去，每次都是全量
- 顶层还有一个 `hexod_all`，本意是两站一起发，但里面写成了 `while ! (HEXO clean)`，少一个 `$`，实际会循环失败。别用它，分别跑 zh 和 en

GitHub Pages 有构建延迟：推送成功后页面通常还要 40 秒到两分钟才从 404 变成 200。用 `curl -sL -o /dev/null -w "%{http_code}"` 循环探测，别推完立刻断言失败。

## 凭证

这台机器没有 SSH key，而仓库的 remote 和 deploy 目标都写成 `git@github.com:`。

不要把 token 写进 `~/.gitconfig`。用一份临时 `GIT_CONFIG_GLOBAL` 把 SSH 地址重写成带 token 的 HTTPS，跑完就删：

```bash
bash scripts/publish.sh zh
```

脚本做的事：从 `~/.config/gh/hosts.yml` 取 `Liam0205` 的 token，生成 `~/.tmp/gitconfig`（含 user 段与 `insteadOf` 重写），导出 `GIT_CONFIG_GLOBAL`，用 `timeout 420` 跑 `hexod`，结束后删掉文件。

需要发英文站就换成 `bash scripts/publish.sh en`。

## 常见坑

- 提交身份是 `Liam <liamhuang0205@gmail.com>`，仓库级配置。`zh/.deploy_git` 是独立的 git 仓库，身份要单独设一遍，脚本里已经处理
- 新文章的 slug 不改，URL 会是中文，被百分号编码，以后引用和分享都难看
- 文章里的 `mathjax: false` 是 scaffold 默认值，写公式的稿子要改成 `true`
- `hexo new` 不受 git 管理，新文件要先 `git add` 才会进 `sync` 的提交。`hexod` 的 `./sync` 里第一步就是 `git add ..`，所以直接跑 `hexod` 也没问题
