---
name: liam-page-blog
description: 在 Liam Huang 的博客源码仓库（Liam0205/blog-source，zh 与 en 两个 Hexo 站点）里新建文章、本地生成验证、发布上线。含递归子模块与发布前的指针对齐、被包装脚本按 .nvmrc 钉死的 Node 版本、中文标题的 slug 处理、frontmatter 与十六个既有分类、hexod 的九步流程、SSH 与 token 两种凭证方式、macOS 上标签大小写撞车导致部署失败、GitHub Pages 的构建延迟。 Use when publishing a post to liam.page, deploying the site, or maintaining the blog-source repo.
---

# liam.page 博客发布

## 什么时候用

- 「发一篇博客」「把这篇文章发到博客上」「部署站点」「更新博客」
- 博客源码仓库的日常操作：新建文章、本地生成、发布

不适用于 WordPress、Hugo，或者不带 `./hexo`、`./hexod` 包装脚本的手写静态站。

## 仓库

- `git@github.com:Liam0205/blog-source.git`，必须递归 clone。子模块是两套 NexT 主题，主题里还嵌了一层 `source/lib/pjax`
- 本地路径约定 `~/projects/blog-source`，但先看实际位置（mac 发布机上是 `/Users/Liam/BLOG/liam.page`），不要假设，`git rev-parse --show-toplevel` 确认
- `zh/` 与 `en/` 是两个独立的 Hexo 站点，各自带 `hexo`、`hexod`、`sync` 脚本
- 线上地址 `https://liam.page`（zh）与 `https://liam.page/en/`（en）
- 发布目标是 `Liam0205/liam0205.github.io` 的 master 分支，`.deploy_git` 就是那个仓库的工作目录

clone 之后用 `git submodule status` 检查，三个子模块都不该带 `-` 前缀。主题没拉下来时 `hexo g` 会直接失败。

更细的目录结构、frontmatter 样例与实测记录放在 `references/blog-source-facts.md`。

## 环境

站点不自己管 Node 版本。根目录的 `scripts/hexo` 读站点 `.nvmrc`（2026-11 起是 **24**），通过 nvm 解析成绝对路径再执行，PATH 上更靠前的 node 抢不走构建；`zh/hexo`、`zh/hexod`、`en/hexo`、`en/hexod` 只是转发壳，真逻辑在根目录 `scripts/`。

```bash
# nvm 的位置随机器不同（~/.nvm、/opt/homebrew、/usr/local、/home/linuxbrew），
# 不要写死某一条路径：复用仓库自带的 scripts/nvm-env.sh，它的 load_nvm() 已按这些前缀依次查找
. "${BLOG_REPO:-$HOME/projects/blog-source}/scripts/nvm-env.sh"
load_nvm

nvm install "$(cat "${BLOG_REPO:-$HOME/projects/blog-source}/zh/.nvmrc")"   # 只装一次，落在 ~/.nvm，不需要 sudo
```

版本没装时 `scripts/nvm-env.sh` 会退回已装的 node，构建照样跑通，所以**别用「能不能构建」判断环境对不对**，要看 `./hexo version` 里打印的 `node:` 行是不是 `.nvmrc` 要求的那个大版本。

退回到太老的 node 时不是静默降级，而是直接报错，按报错对号入座：

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `Cannot find module 'fs/promises'`（栈里是 `chokidar` / `hexo-fs`） | 退回到了 Node 12 一类老版本 | `nvm install 24`，`nvm alias default` 保持原样，别顺手改掉默认版本 |
| `Plugin load failed: hexo-generator-feed` → `Cannot find module 'hexo/lib/plugins/helper/gravatar'` | `node_modules` 过期，装的插件版本比 lock 里旧 | 用 Node 24 跑 `npm ci`（`node_modules` 不进 git） |

装依赖时用 `npm ci`，仓库带了 lock 文件。安装过程会报二十多个 audit 警告，不影响构建。

## 新建文章

```bash
cd ~/projects/blog-source/zh && ./hexo new post "给 AI 去去味儿"
```

生成位置是 `source/_posts/YYYY/MM/DD/<title>.md`，由 `new_post_name: :year/:month/:day/:title.md` 决定。

permalink 配置是 `:year/:month/:day/:title/`，其中的 `:title` 取文件名，所以**文件名就是 URL**。站点现有文章一律用英文 slug，中文标题生成的文件名要改掉：

```bash
cd source/_posts/2026/10/30 && mv 给-AI-去去味儿.md ai-tone-removal.md
```

frontmatter 照 `scaffolds/post.md` 补齐。`quicklink` 和 `reward_settings` 这两块别删，主题会读它们。写公式的稿子把 `mathjax` 改成 `true`。

**正文里不要再写一遍一级标题**，Hexo 会用 frontmatter 的 title 渲染 `<h1>`，重复写会出现两个标题。

导语之后、第一个 `##` 之前必须补一行 `<!-- more -->`，前后各留一个空行。少了它，首页会把整篇文章铺开，也不出现「阅读全文」链接。2026-11 的 gist 那篇就漏了这一行，首页直接展开全文，补上才恢复。

`categories` 从下面十六个里选一个，不要新造：

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

归类参照站内既有习惯：写作与生活类杂谈放 `Life and Human Nature`，技术长文放前两类，书评放 `Literature and Social Sciences`。

`tags` 用英文单词，写文章里实际涉及的对象或技术，三个以内。

## 生成验证

```bash
cd ~/projects/blog-source/zh && ./hexo g
```

全站约 2360 个文件，两三秒跑完（2026-11 在 Node 24 下实测 2362 个、2.06 秒）。`INFO Generated` 打出不代表页面正确，抽查四项：

```bash
F=public/2026/10/30/ai-tone-removal/index.html
ls -la $F                                     # 页面存在
grep -o "<title>[^<]*</title>" $F             # 标题渲染正确
grep -o "正文里的某个特征词" $F               # Markdown 真的转成了 HTML
grep -l "ai-tone-removal" public/index.html public/archives/index.html
grep -c "阅读全文" public/index.html                 # 首页每篇都该有一条摘要链接
```

最后两条确认文章进了首页和归档，且首页只显示摘要。没有出现说明日期、draft 状态有问题，或者正文漏了 `<!-- more -->`。

## 发布

### 发布前：先对齐子模块

`./sync` 的第一步是 `git add -A`（`git add ..`），会把根仓库里**任何**子模块指针变化一起提交。如果本机 checkout 落后于根仓库记录的指针，这一步就是一个把指针倒退的 commit，推上去等于把仓库状态弄坏。先查：

```bash
git diff --submodule=log        # 出现 "(rewind)" 或 "(commits not present)" 就是落后
git submodule status            # 前缀 "" 正常；"-" 未初始化；"+" 已检出与记录不一致
```

有 rewind 就先拉齐再发布：

```bash
git submodule update --init --remote --recursive
```

这一步会同时更新 en 和 attachment（2026-11 的 zh 发布就把 en 的两个子模块一起拉到了最新），所以别在别的子模块落后时发布 —— 一次发布只需要跑一遍。

子模块大仓库（`zh/.deploy_git` 的 pack 有 500 MB 量级）走 SSH fetch 可能长时间没有任何输出，见下面「常见坑」里的 HTTPS + 代理办法。

### 九步流程

`./hexod` 依次做九件事：

1. `./sync`：`git add ..` → commit → `git pull --rebase` → push，把源码推到 blog-source
2. `git submodule update --init --remote --recursive`，把主题拉到远端最新，可能带来额外变更
3. `hexo clean`
4. `hexo g`
5. `hexo d`：清空 `.deploy_git`、拷入 `public`、commit、推到 `liam0205.github.io` 的 master
6. `git add .`
7. `git commit -m "[zh][site] Site updated: 时间"`
8. `git push`，把 `.deploy_git` 的新提交记回源码仓库
9. 结束

成功的标志是日志里出现 `INFO Deploy done: git`、一行 `xxxxxxxx..yyyyyyyy HEAD -> master`、以及 `hexod 退出码: 0`。

三个注意点：

- 2026-11 起 `hexod` 不再无限重试：普通步骤走 `run`（失败即 `die`），只有 fetch / rebase / push 这类瞬时故障用 `retry 5`（退避 5→60 秒）。`timeout` 仍建议包一层兜底，但超时不再等于卡死在某一行 `while !` 里
- `hexo d` 会先清空 `public/` 再重新生成，本地验证的结果不会带过去，每次都是全量
- 顶层 `hexod_all` 已经修好了（旧的 `while ! (HEXO clean)` 少个 `$` 那个 bug 没了），两站一起发可以用，但它只在最后 push 一次根仓库；分别跑 zh / en 仍然更可控

## 凭证

仓库的 remote 和 deploy 目标都写成 `git@github.com:`。**先确认本机能不能 SSH，再决定要不要注入 token**，不要默认用 `publish.sh`：

```bash
ssh -T -o BatchMode=yes -o ConnectTimeout=8 git@github.com   # 回 "Hi <user>! You've successfully authenticated" 就算通
```

**SSH 通**：直接跑 `./hexod`，不用临时 gitconfig。提交身份靠环境变量，不改全局配置：

```bash
export GIT_AUTHOR_NAME=Liam GIT_COMMITTER_NAME=Liam
export GIT_AUTHOR_EMAIL=liamhuang0205@gmail.com GIT_COMMITTER_EMAIL=liamhuang0205@gmail.com
timeout 600 ./hexod
```

注意 `~/.gitconfig` 里 `user.name` 可能是 `Liam Huang`，仓库历史里的作者是 `Liam <liamhuang0205@gmail.com>`，两者不一致，所以要用环境变量覆盖。

**SSH 不通**：不要把 token 写进 `~/.gitconfig`，也不要把 token 放进命令行参数。用一份临时 `GIT_CONFIG_GLOBAL` 把 SSH 地址重写成带 token 的 HTTPS，跑完就删：

```bash
bash scripts/publish.sh zh
bash scripts/publish.sh en    # 要发英文站时
```

脚本从 `~/.config/gh/hosts.yml` 取 `Liam0205` 的 token，生成 `~/.tmp/gitconfig`（含 user 段与 `insteadOf` 重写），导出 `GIT_CONFIG_GLOBAL`，用 `timeout 420` 跑 `hexod`，结束后删掉文件。

`gh auth login` 在 macOS 上默认把 token 存进 Keychain，此时 `hosts.yml` 里**只有 `user:`，没有 `oauth_token:`**，脚本会以 `no token` 退出，且因为没有 `GIT_CONFIG_GLOBAL`，后面的 git 命令会退回 SSH 然后卡住。遇到 `no token` 别去改脚本绕过，先按上面测 SSH。

三条纪律：

- `GIT_CONFIG_GLOBAL` 会顶替 `~/.gitconfig`，所以提交身份要一起写进去，否则作者会变成默认账号
- 提交身份沿用仓库历史里已有的那个，`git log -1 --format='%an <%ae>'` 查出来是 `Liam <liamhuang0205@gmail.com>`
- `zh/.deploy_git` 是独立的 git 仓库，身份要单独设一遍，脚本里已经处理

## macOS 特有：标签只差大小写会让部署失败

APFS 默认不区分大小写。站内只要有一对只差大小写的标签（`Code` / `CODE`、`Vim` / `VIM`），Hexo 会为两者生成 `tags/Code/` 与 `tags/CODE/`，而磁盘上只能存在一个目录，`hexo d` 的 `git add` 就会拒绝：

```plaintext
fatal: will not add file alias 'tags/CODE/index.html' ('tags/Code/index.html' already exists in index)
FATAL Something's wrong...
hexod 退出码: 1
```

此时 `./sync` 已经跑完，文章源码已经推上去了，只是站点没上线。**不要反复重跑 hexod**，先处理标签。

1. 列出撞车的标签：

   ```bash
   cd zh && ls public/tags | tr 'A-Z' 'a-z' | sort | uniq -d
   ```

2. 找出每个写法分别被哪些文章用：逐篇看 front matter 的 `tags`（行内 `[a, b]` 与块状 `- a` 两种都要看）。逐个确认，别靠 grep 猜，`Thread Safe` 这种带空格的写法 grep 很容易漏。

3. 统一写法并重生成。软件名用官方写法（`Vim`、`tmux`、`hyperref`），其余用多数文章已经在用的那种；正文不动，只改 `tags`。统一之后 `ls public/tags | tr 'A-Z' 'a-z' | sort | uniq -d` 必须为空。

4. 改过大小写的标签页，旧 URL 会 404，新的在 Pages 构建完成后 200。要在发布后逐个 `curl` 确认。

`.deploy_git` 里可能还留着旧大小写的目录名。索引里已经有该路径时 `git add` 会报 alias 冲突，用**两段式 `git mv`** 改名（一步 `git mv tags/VIM tags/Vim` 在某些情况下不可靠）：

```bash
cd zh/.deploy_git
for p in DATA:Data Hyperref:hyperref Thread-Safe:Thread-safe VIM:Vim; do
  o=${p%%:*}; n=${p##*:}
  git mv "tags/$o" "tags/__tmp_$n" && git mv "tags/__tmp_$n" "tags/$n"
done
```

改完拿 `public/` 和部署仓索引做一次全量对比，确认没有残留的错大小写（`git ls-files` 默认会把非 ASCII 路径转义，要加 `-c core.quotepath=false`）：

```bash
diff <(cd zh/public && find . -type f | LC_ALL=C sort) \
     <(git -C zh/.deploy_git -c core.quotepath=false ls-files | LC_ALL=C sort)
```

输出里只允许出现 `CNAME`（`.deploy_git` 里的仓库文件）与 `apt*/deb/.gitkeep` 这类部署仓自带的文件。然后单独提交并推送 `.deploy_git`，再把根仓库的指针提交一次：

```bash
git -C zh/.deploy_git commit -m "Site updated: fix tag directory case ..."
git -C zh/.deploy_git push origin HEAD:master
git add zh/.deploy_git && git commit -m "[zh][site] Site updated: ..." && git push
```

## 线上生效有延迟

推送成功不等于页面可见，GitHub Pages 要重新构建，通常四十秒到两分钟。自定义域名下 `*.github.io` 会 301 到域名，所以直接测最终地址：

```bash
for i in 1 2 3 4 5 6; do
  code=$(curl -sL -o /dev/null -w "%{http_code}" https://liam.page/YYYY/MM/DD/<slug>/)
  echo "第 $i 次：$code"; [ "$code" = "200" ] && break; sleep 20
done
```

轮询六次、每次间隔二十秒足够。等不到就去查 Pages 的构建状态，不要急着改文章内容。

## 检查清单

- [ ] clone 带 `--recursive`，`git submodule status` 三个子模块都非空
- [ ] 发布前 `git diff --submodule=log` 没有 `(rewind)` / `(commits not present)`，子模块不落后于记录的指针
- [ ] `./hexo version` 打印的 `node:` 大版本等于站点 `.nvmrc`（2026-11 起是 24）
- [ ] 文件名是英文 slug，与站内既有文章一致
- [ ] frontmatter 字段齐，分类在十六个既有分类里，正文没有重复的 H1
- [ ] 新文章的标签与既有标签大小写完全一致，`ls public/tags | tr 'A-Z' 'a-z' | sort | uniq -d` 为空
- [ ] 导语与第一个 `##` 之间有 `<!-- more -->`，首页只显示摘要、「阅读全文」在
- [ ] `hexo g` 之后能打开该页，标题正确，正文有内容，首页和归档都有链接
- [ ] 本机 SSH 是否可用已确认（通则不注入 token），发布命令用 `timeout` 包住
- [ ] 临时 gitconfig 用完删掉
- [ ] 线上返回 200 且标题正确；改动过的标签页 URL 也逐个 200
- [ ] 源码仓库与 deploy 仓库都已推送，`git status` 干净

## 常见坑

- 新文章的 slug 不改，URL 会是中文被百分号编码，以后引用和分享都难看
- `hexo new` 生成的文件不受 git 管理，`hexod` 的第一步 `git add ..` 会把它带进去，所以不必单独 add
- 主题是 `--remote` 更新的，发布时可能顺带拉进主题的新提交，源码仓库的 commit 里会看到主题指针变化，属于正常现象
- 子模块指针落后时直接发布，`git add -A` 会提交一个让指针倒退的 commit；发布前必查 `git diff --submodule=log`
- `zh/.deploy_git` 的 pack 有 500 MB 量级，SSH fetch 可能七八分钟一点输出都没有（看上去像卡死）。改走 HTTPS 加显式代理，几十秒就完：

  ```bash
  cd zh/.deploy_git
  https_proxy=http://127.0.0.1:7890 git fetch --progress \
    https://github.com/Liam0205/liam0205.github.io.git +master:refs/remotes/origin/master
  git checkout master && git merge --ff-only origin/master
  ```

  代理端口取自 `scripts/sh-util.sh` 的 `use_proxy`（`LOCAL_PROXY`，默认 `127.0.0.1:7890`）；先 `nc -z 127.0.0.1 7890` 确认端口在听。
- `.deploy_git` 这类子模块通常停在 detached HEAD，`git push origin HEAD:master` 比先 checkout 更省事
- nvm 里没装 `.nvmrc` 要求的版本时，`./hexo` 会静默退回一个更老的 node 然后报各种模块找不到，先看 `./hexo version` 的 `node:` 行
- 标签只差大小写会让 macOS 上的 `hexo deploy` 直接失败，见上文专节
