---
name: liam-page-blog
description: 在 Liam Huang 的博客源码仓库（Liam0205/blog-source，zh 与 en 两个 Hexo 站点）里新建文章、本地生成验证、发布上线，以及从源路径更新已发布的文章（看差异、修悬空引用、同步回源稿）。含递归子模块与发布前的指针对齐、被包装脚本按 .nvmrc 钉死的 Node 版本、中文标题的 slug 处理、frontmatter 与十六个既有分类、hexod 的九步流程、SSH 与 token 两种凭证方式、macOS 上标签大小写撞车导致部署失败、GitHub Pages 的构建延迟。 Use when publishing or updating a post on liam.page, deploying the site, or maintaining the blog-source repo.
---

# liam.page 博客发布

## 什么时候用

- 「发一篇博客」「把这篇文章发到博客上」「部署站点」「更新博客」
- 「源路径的文章有更新」「看看改了什么」「更新吧」：更新已发布的文章，见「更新已发布的文章」一节
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

### 排版：过长的行内代码

正文是两端对齐（NexT 默认 `text_align: justify`）。很长、中间没有空格的行内代码（典型是 `/System/Library/...` 这类绝对路径）放不进当前行时，会整段被挤到下一行，前一行只剩几个字，被拉开到整行宽，字距大得很难看；代码本身也只能在最后一个字符硬断（`bir|d`）。

2026-11 起两个站点在站点层加了 `source/_data/styles.styl`（经 `next.yml` 的 `custom_file_path.style` 引入），让正文里的行内代码可以在任意字符处断行，并且每段折行都保留内边距与圆角：

```styl
.post-body :not(pre) > code {
  word-break: break-all;
  -webkit-box-decoration-break: clone;
  box-decoration-break: clone;
}
```

所以写稿时不必为了排版把长路径改成代码块。是否改成独立代码块由作者决定，不要自作主张。验证过的性质：复制出来的文本与原文一致、不含换行；`<pre>` 代码块不受影响；只在 Chrome 上截图验证过。

`styles.styl` 和 `next.yml` 在 `zh/`、`en/` 各有一份，改样式时两边要一起改。样式改动要用浏览器渲染确认，不要只看 CSS 有没有生成，见下文「用浏览器截图验证排版」。

### 用浏览器截图验证排版

看排版问题要实际渲染，不要凭经验判断。本机有 Google Chrome，用 `puppeteer-core` 驱动它即可，不用下载浏览器：

```bash
mkdir -p /tmp/shot && cd /tmp/shot && npm init -y >/dev/null
PUPPETEER_SKIP_DOWNLOAD=1 npm i puppeteer-core@23 --silent
cd zh && ./hexo server -p 9227 &        # 或者直接截线上页面
```

两个坑：

- NexT 有入场动画，headless 下 `.post-block` / `.post-body` 会一直停在 `opacity: 0`，截出来是空白。截图前注入一段样式强制显示：`page.addStyleTag({content: '.post-block,.post-body,.post-header{opacity:1 !important;transform:none !important}'})`
- 截线上页面别用 `waitUntil: 'networkidle0'`，第三方脚本会让它超时，用 `'load'` 加 60 秒超时

宽度至少截两档：桌面 1280、手机 375。除了截图，再用 `getComputedStyle` 确认规则真的生效，用 `getClientRects()` 数折行，用 `Selection` 校验复制出来的文本不变。

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

### Pages 构建失败

`hexod` 退出码 0 只说明推送成功，Pages 可能在之后构建失败，线上就一直停在旧版本。等不到新内容时先查构建状态：

```bash
gh api repos/Liam0205/liam0205.github.io/pages/builds --jq '.[0:3][] | "\(.created_at) \(.status) \(.commit[0:10]) \(.error.message // "")"'
gh run list -R Liam0205/liam0205.github.io -L 3
gh run view <run-id> -R Liam0205/liam0205.github.io --log-failed | tail
```

en 站把仓库名换成 `Liam0205/en`。

2026-11-07 遇到过一次：部署步骤卡在 `Current status: syncing_files` 约 11 分钟，然后 `Timeout reached, aborting!`，是 GitHub 侧的问题，跟站点内容无关。

- **不要** `gh run rerun`：重跑会沿用同一个部署 ID，被 GitHub 直接以 `Deployment cancelled` 拒掉
- 改为针对当前 master 重新请求一次构建，一两分钟就好：

  ```bash
  gh api -X POST repos/Liam0205/liam0205.github.io/pages/builds
  ```

### 验证样式改动

CSS 改动通过轮询 `main.css` 确认。`next.yml` 的 `minify: true` 并没有压缩 `main.css`，规则在线上仍是多行格式，所以 grep `box-decoration-break: clone`（带空格），不要 grep 压缩后的写法。`main.css` 的 `cache-control: max-age=600`，加 `?v=` 绕开 CDN 缓存。

更新已发布的文章时，状态码一直是 200，测不出新版是否生效。改成 grep 一个**只在新版里出现**的词（新加的小节标题最合适），URL 加 `?v=$i` 绕开缓存：

```bash
for i in 1 2 3 4 5 6; do
  n=$(curl -sL "https://liam.page/YYYY/MM/DD/<slug>/?v=$i" | grep -c '新版才有的小节标题')
  echo "第 $i 次：$n"; [ "$n" -gt 0 ] && break; sleep 20
done
```

## 更新已发布的文章

作者常在站外的源路径（如 `~/manage/<slug>.md`）改稿，然后说「源路径的文章有更新」。流程分三步：先看差异，再修正，最后发布。

### 先看改了什么

```bash
P=zh/source/_posts/YYYY/MM/DD/<slug>.md
S=<源路径>/<slug>.md
ls -la "$S" "$P"          # 对比修改时间，确认源稿确实更新了
diff -u "$P" "$S"
```

向作者汇报时按节归纳，不要把 diff 原样贴回去。要说清楚四件事：

- front matter、`date`、`<!-- more -->` 是否变化。date 变了，permalink 就变了，URL 会跟着变
- 结构变化：哪些节新增、合并、删除
- 删掉了哪些内容：作者删得多的时候，最容易出现悬空引用
- 前后数字是否还对得上：同一组数据换了时间窗口（10 秒、1 分钟）重新表述时，换算要一致

### 悬空引用：大幅改稿后最常见的问题

作者压缩或重组正文时，常会删掉某段命令或某一节，后文却仍在引用它。2026-11 lsd 那篇改稿就有三处：

| 症状 | 例子 | 修法 |
| --- | --- | --- |
| 后文用到的文件，生成它的命令被删了 | 「成因」用 `/tmp/lsdump.txt`，但 `-dump > /tmp/lsdump.txt` 那行随「排查」一起删了 | 在第一次用到的位置之前补回命令 |
| 文件或概念第一次出现就直接使用 | `/tmp/lsdump2.txt` 前文从未出现 | 在代码块前用一句话交代它的来历（何时、在哪一步之后导出） |
| 「先前」「上文」指向一个已删除的段落 | 「先前我退出过一次 Setapp」，可「退出 Setapp」一节已经删掉 | 改写成不依赖前文的句子，并顺手补出这句话真正想说的结论 |

逐项核对的办法：先把新稿里的文件名、变量（`$LSREG`）、「先前 / 上文 / 前面 / 后文 / 下一节」这类指代词都 grep 出来，再逐个确认前文有定义、指向的节确实存在。

```bash
grep -nE '/tmp/|\$[A-Z_]+|先前|上文|前面|后文|上一节|下一节|前一节' "$S"
```

### 修正的边界

- 只修**确实不成立**的地方：悬空引用、前后矛盾、数字对不上。措辞、结构、取舍属于作者，不动
- 写作风格的问题不在这里处理，交给 `liam-page-writing`；修正时只补最少的字，口吻跟着原文走
- 哪怕作者说了「把你认为不合理的也修正了」，也要在汇报里逐条列出改了哪里、为什么改。没改的地方也要说明核对过、没问题，例如「`$LSREG` 有定义，337 与 339 的差异文中已解释」

### 同步回源路径

修正写在 `zh/source/_posts/` 里的副本上。发布之前，**把改好的版本拷回源路径**，否则作者下次从源路径更新时，这次的修正会被冲掉。拷回之前先 `ls -l "$S"`，确认源稿在这期间没有再被改过。如果改过，就先 diff，不要直接覆盖。

```bash
cp "$P" "$S"
```

之后照常 `./hexo g` 抽查，再跑 `./hexod`。sync 提交里应当只有这一篇文章的改动。

## 检查清单

- [ ] clone 带 `--recursive`，`git submodule status` 三个子模块都非空
- [ ] 发布前 `git diff --submodule=log` 没有 `(rewind)` / `(commits not present)`，子模块不落后于记录的指针
- [ ] 两个 `.deploy_git` 的 `HEAD`、远端 `master`、根仓库记录的指针三者一致，避免部署时强推覆盖远端提交
- [ ] `./hexo version` 打印的 `node:` 大版本等于站点 `.nvmrc`（2026-11 起是 24）
- [ ] 文件名是英文 slug，与站内既有文章一致
- [ ] frontmatter 字段齐，分类在十六个既有分类里，正文没有重复的 H1
- [ ] 新文章的标签与既有标签大小写完全一致，`ls public/tags | tr 'A-Z' 'a-z' | sort | uniq -d` 为空
- [ ] 导语与第一个 `##` 之间有 `<!-- more -->`，首页只显示摘要、「阅读全文」在
- [ ] `hexo g` 之后能打开该页，标题正确，正文有内容，首页和归档都有链接
- [ ] 本机 SSH 是否可用已确认（通则不注入 token），发布命令用 `timeout` 包住
- [ ] 临时 gitconfig 用完删掉
- [ ] 线上返回 200 且标题正确；改动过的标签页 URL 也逐个 200；等不到新内容时先查 Pages 构建状态
- [ ] 改了样式：zh / en 两份 `styles.styl` 一致，桌面与手机两档截图确认过
- [ ] 更新已发布的文章时：没有悬空引用；修正逐条汇报；改好的版本已拷回源路径；线上能 grep 到只在新版里出现的词
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
- **部署仓库落后会被强推覆盖**：`hexo-deployer-git` 每次都用 `git push --force`。如果 `hexod` 第二步把 `.deploy_git` 检出到的提交比远端旧（本地记录的远端位置过期时会这样），部署就会把远端最新的那次提交挤掉，日志里出现 `(forced update)`。线上内容不受影响（每次都是全站重新生成），但 Pages 仓库会丢一条历史，根仓库里记录的那个指针也就不在任何分支上了。发布前用 HTTPS + 代理 fetch 一下两个 `.deploy_git`，确认 `HEAD`、`origin/master`、根仓库记录的指针三者一致：

  ```bash
  for s in zh en; do r=$([ $s = zh ] && echo liam0205.github.io || echo en)
    git -C $s/.deploy_git fetch -q https://github.com/Liam0205/$r.git +master:refs/remotes/origin/master
    echo "$s remote=$(git -C $s/.deploy_git rev-parse --short origin/master) HEAD=$(git -C $s/.deploy_git rev-parse --short HEAD) root=$(git ls-tree HEAD $s/.deploy_git | awk '{print substr($3,1,9)}')"
  done
  ```
- **en 站的 `node_modules` 也可能过期**：和 zh 一样，feed 插件加载失败（`hexo/lib/plugins/helper/gravatar`）时 `hexo g` 不会退出，只是少生成 `atom.xml`（实测 165 vs 166 个文件）。要看日志里有没有 `ERROR Plugin load failed`，不能只看最后的文件数
- **en 站部署要作者点名**：作者说「zh 和 en 都加上」指的是改源码；只要作者没明确说发布 en，就只跑 zh 的 `hexod`。zh 的 `./sync` 会把 en 的源码改动一起提交推送，en 的线上站点则保持不动
- 更新文章后只拿状态码验证线上，200 测不出新旧版本，要 grep 新版独有的内容
- 修正只改了 `_posts` 里的副本、没拷回源路径，作者下次从源路径更新时，修正会被悄悄覆盖掉
- 改 skill 本身：`~/.claude/skills/<name>` 只是指向 `~/.cc-switch/skills/<name>` 的符号链接，不是 git 仓库。在固定工作副本 `~/projects/skills`（`gh repo clone Liam0205/skills`）里改、提交、推送，再同步回 `~/.cc-switch/skills/<name>`。cc-switch 的仓库模式只拉不推
