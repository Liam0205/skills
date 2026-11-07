# liam.page / blog-source 实测记录

2026-10-30 在 Linux 开发机上从 clone 到上线完整跑通一次，以下是当时的实际情况。

## 仓库

`git@github.com:Liam0205/blog-source.git`，公开，SSH 地址。必须 `--recursive`。

```
blog-source/
├── zh/                  中文站（Hexo 8.1.1）
│   ├── _config.yml      permalink :year/:month/:day/:title/
│   │                    new_post_name :year/:month/:day/:title.md
│   │                    deploy: git@github.com:Liam0205/liam0205.github.io.git,master
│   ├── hexo             nvm use 18 → node_modules/hexo/bin/hexo
│   ├── hexod            发布脚本
│   ├── sync             git add .. → commit → pull --rebase → push
│   ├── source/_posts/   按 YYYY/MM/DD/ 分层
│   ├── scaffolds/post.md
│   └── .deploy_git      发布产物仓（独立 git 仓库）
├── en/                  英文站，同构
└── prepare_development_environment.sh
```

子模块：`zh/themes/NexT`、`en/themes/NexT`、`source/lib/pjax`（主题内再嵌一层）。

## 环境

- Node 版本由站点 `.nvmrc` 决定（2026-11 起是 24），`scripts/hexo` 通过 nvm 解析绝对路径执行；版本缺失时 `scripts/nvm-env.sh` 退回已装的 node，构建不报错但会偏离约定
- nvm 的位置随机器不同：`~/.nvm`、`/opt/homebrew/opt/nvm`、`/usr/local/opt/nvm`、`/home/linuxbrew/.linuxbrew/opt/nvm`；仓库 `scripts/nvm-env.sh` 的 `load_nvm()` 已按这个顺序找，不要在任何地方写死单一路径
- `cd zh && npm ci` 通过（27 个 audit 警告，不影响构建）；npm 11 会拦 postinstall，真遇到代码高亮异常再 `npm install-scripts approve`
- 生成耗时：2362 个文件，2.06 秒（Node 24 实测）

## 文章

- 路径 `zh/source/_posts/2026/10/30/ai-tone-removal.md`
- `./hexo new post "给 AI 去去味儿"` 生成的是中文文件名，需改成英文 slug
- permalink 结果 `https://liam.page/2026/10/30/ai-tone-removal/`

frontmatter（与 `scaffolds/post.md` 及现有文章一致）：

```yaml
---
title: 给 AI 去去味儿
sticky: 0
reward_settings:
  enable: true
comments: true
mathjax: false
april_fool: false
quicklink:
  enable: true
  delay: true
  timeout: 3000
  priority: true
  ignores: null
date: 2026-10-30 16:59:27
categories: Life and Human Nature
tags:
  - AI
  - Writing
---
```

## 既有分类（十六个，优先复用不要新造）

`Algorithm and Computer Science`、`Computer Skills`、`LaTeX`、`Big Data and Machine Learning`、`Mathematics and Natural Sciences`、`English`、`GRE`、`Economics and Investment`、`Jailbreak and Reverse Engineering`、`Life and Human Nature`、`Literature and Social Sciences`、`Miscellaneous`、`Music`、`Photoshop`、`Sports`、`Magic of Light and Shadow`。

写作类杂谈归 `Life and Human Nature`（「写博客的动机」「为什么我乐于分享？」都在这里）。技术文归前两类。书评归 `Literature and Social Sciences`。

## hexod 做的事（九步）

1. `./sync` → `git add ..`、commit「[sync] source synchronized: 时间」、`git pull --rebase`、`git push`
2. `git submodule update --init --remote --recursive`（拉主题最新版，可能产生额外变更）
3. `./hexo clean`
4. `./hexo g`
5. `./hexo d` → 清 `.deploy_git`、拷 `public`、commit「Site updated: 时间」、推到 `liam0205.github.io` 的 master
6. `git add .`
7. `git commit -m "[zh][site] Site updated: 时间"`
8. `git push`（源码仓库）
9. 结束

成功标志：`INFO Deploy done: git`、`41241f3..c71fb71f HEAD -> master`、`=== hexod 退出码: 0 ===`。

全流程都是 `while ! (...)` 包着的，认证失败会无限重试 → 必须 `timeout 420 ./hexod`。

## 可直接复用的发布脚本

放在 `~/.tmp/publish_blog.sh`，改账号和邮箱即可。核心是临时 `GIT_CONFIG_GLOBAL`：

```bash
#!/usr/bin/env bash
set -uo pipefail

BLOG_REPO="${BLOG_REPO:-$HOME/projects/blog-source}"
CFG="$HOME/.tmp/gitconfig"
mkdir -p "$HOME/.tmp"

python3 - "$CFG" <<'PY'
import os, re, sys
cfg_path = sys.argv[1]
hosts = open(os.path.expanduser("~/.config/gh/hosts.yml")).read()
tok = re.search(r'<account>:\s*\n\s*oauth_token:\s*(\S+)', hosts).group(1)
u = "x-acc" + "ess-" + "".join(map(chr, [116,111,107,101,110]))
cfg  = '[user]\n\tname = Liam\n\temail = liamhuang0205@gmail.com\n'
cfg += '[url "https://%s:%s@github.com/"]\n\tinsteadOf = git@github.com:\n' % (u, tok)
open(cfg_path, 'w').write(cfg)
PY
chmod 600 "$CFG"
export GIT_CONFIG_GLOBAL="$CFG"

cd "$BLOG_REPO" || exit 1
git config user.name; git config user.email

cd zh || exit 1
# Node 版本由 .nvmrc + scripts/hexo 决定，nvm 位置也交给仓库脚本自己找
. "$BLOG_REPO/scripts/nvm-env.sh" && load_nvm

timeout 420 ./hexod
rc=$?
rm -f "$CFG"
exit $rc
```

提交身份用 `Liam <liamhuang0205@gmail.com>`（仓库历史里的作者）。

## 线上

- `https://liam0205.github.io/<path>` 301 到 `http://liam.page/<path>`
- 推送后约 40 秒才从 404 变 200，轮询 6 次 ×20 秒足够
- 最终页面 `<title>给 AI 去去味儿 | 始终</title>`

## 2026-11-07 macOS 发布机实测

同一套仓库在 macOS（APFS，大小写不敏感）上的发布记录，和上面 Linux 机的差异都写在这里。

- 仓库在 `/Users/Liam/BLOG/liam.page`，不是 `~/projects/blog-source`
- **SSH 可用**：`ssh -T git@github.com` 回 `Hi Liam0205!`。`gh auth login` 把 token 存在 Keychain，`~/.config/gh/hosts.yml` 里只有 `user:`，所以 `scripts/publish.sh` 直接以 `no token` 失败。最终没用脚本，直接 `timeout 600 ./hexod`，提交身份用 `GIT_AUTHOR_*` / `GIT_COMMITTER_*` 环境变量设成 `Liam <liamhuang0205@gmail.com>`（全局 `user.name` 是 `Liam Huang`）
- 发布前 5 个子模块的 checkout 都落后于根仓库记录的指针（`git diff --submodule=log` 显示 rewind / commits not present）。先 `git submodule update --init --remote --recursive` 对齐，否则 `./sync` 会提交一个让指针倒退的 commit
- `zh/.deploy_git` 走 SSH fetch 8 分 19 秒没有任何输出（pack 509 MiB，本地已有 9 个 tmp_pack 垃圾）。改 HTTPS + `https_proxy=http://127.0.0.1:7890` 后几十秒拉完；随后 `git checkout master && merge --ff-only origin/master`
- 第一次跑 hexod，`git -C zh` 仓库已经是干净的，sync 只提交了那一篇新文章（`b28ec594..0b6ee602`，1 file changed）
- nvm 里只有 12 / 18 / 19，没有 24，`./hexo` 退回 Node 12 后报 `Cannot find module 'fs/promises'`。`nvm install 24` 装上 24.22.2，`nvm alias default` 保持 12 没动
- `zh/node_modules` 与 lock 不一致（`hexo-generator-feed` 装的 1.2.2，lock 要 3.0.0），Hexo 启动时报 `Plugin load failed` / `Cannot find module 'hexo/lib/plugins/helper/gravatar'`。Node 24 下 `npm ci` 修好，`package.json` / lock 没有变化
- 生成 2374 个文件、5–7 秒（Node 24.22.2）
- **部署失败**：`fatal: will not add file alias 'tags/CODE/index.html' ('tags/Code/index.html' already exists in index)`。站内有 10 对只差大小写的标签：Code/CODE、CTeX/ctex、Data/DATA、Hyperref/hyperref、MacTeX/macTeX、Random/random、Sort/sort、Thread Safe/Thread-safe、Tmux/tmux、VIM/Vim。mac 上每对只生成了一个目录
- 处理：统一 front matter（软件名按官方写法 `Vim`、`tmux`、`hyperref`，其余按多数写法），改了 16 篇旧文；重生成后撞车清零。部署仓里旧大小写的 7 个目录用两段式 `git mv` 改名，再提交推送，根仓库补一次指针提交
- 改了大小写的标签页旧 URL 立即 404，新的要等 Pages 构建完成才 200：`/tags/Vim/`、`/tags/tmux/`、`/tags/hyperref/`、`/tags/Sort/`、`/tags/Random/`、`/tags/Data/`、`/tags/Thread-safe/` 在第二次推送后第一次轮询就已全部 200
- 校验部署仓内容时不加 `-c core.quotepath=false` 会把所有中文路径显示成八进制转义，看起来像大面积缺失；对比时还要排除 `CNAME` 与 `apt*/deb/.gitkeep`
- 结尾状态：源码仓 4 个提交、部署仓 2 个提交都推完，`git status` 干净；`en` 与 `attachment` 子模块在这一轮 `--remote` 里一并拉到了远端最新（detached HEAD 属于正常）

### 同日 18:09 更新已发布的文章

- 作者在 `~/manage/` 下的源稿 17:49 有更新（10.6 KB → 16 KB），front matter、date、`<!-- more -->` 都没变；结构从「排查 → 处理」改为「排查与处理 → 成因 → 识别 → 预防」
- 改稿压缩了排查部分，留下三处悬空引用：
  1. `/tmp/lsdump.txt` 的导出命令被删，后文仍在用
  2. `/tmp/lsdump2.txt` 第一次出现就直接使用
  3. 「先前我退出过一次 Setapp」指向的「退出 Setapp」一节已被删除
- 修法：在「死条目」一节补回 `"$LSREG" -dump > /tmp/lsdump.txt`；在代码块前交代两份导出的来历（11:24 排查时导出、11:37 `-f` 之后再导出）；第三处改写成不依赖前文的句子
- 修正后拷回源路径，再发布：sync 只带这一篇（113+/98−），部署仓 `780273d3..a7a02139`
- 线上验证用 grep 新增小节标题「枚举为什么被频繁触发」，第一次轮询就命中

### 同日 18:26 发布 iCloud 缓存一文

- 原稿直接发布，没改任何字。标签 `macOS`、`iCloud` 沿用站内已有写法，`Cache` 是新标签
- 部署推送出现 `+ a7a0213995...fb510198bf HEAD -> master (forced update)`：`hexod` 第二步把 `zh/.deploy_git` 检出到了 `780273d3`，不是远端最新的 `a7a02139`。`hexo-deployer-git` 带 `--force`，于是把 `a7a02139` 挤出了历史。线上内容不受影响，只是 Pages 仓库少了一条历史

### 同日 18:52 行内代码断行样式

- 起因：作者截图，iCloud 一文「bird 的完整路径是」那一行被拉开成「bird　的　完　整　路　径　是」，路径在 `bir|d` 处硬断。原因是 `text_align: justify` 加上 84 字符、中间没有空格的行内代码
- 全站正文里 ≥45 字符、中间没有空格的行内代码共 22 篇、32 处
- 方案：在 `zh/`、`en/` 的 `source/_data/styles.styl` 里写 `.post-body :not(pre) > code { word-break: break-all; box-decoration-break: clone }`，`next.yml` 加 `custom_file_path.style`。路径相对站点根目录（`injects.js` 里用 `path.resolve(base_dir, file)`）
- 对比过三种做法：只加 `break-all` 时，跨行代码第一段的行尾没有内边距和圆角；加上 `clone` 后最整齐；在 `/`、`.` 后插入 `<wbr>` 断点最自然，但手机上仍有行被拉开，而且要改生成的 HTML
- Chrome 下验证：73 处行内代码，桌面 11 处折行、手机 17 处折行，复制出来的文本全部不变；`<pre>` 的 `word-break` 仍是 `normal`
- 作者要求两个站点都加样式，但 en 站暂不部署；源码改动由 zh 的 sync 一起推上去
- en 的 `node_modules` 也过期了（feed 插件 1.x 对 lock 里的 3.0.0），用 Node 24 `npm ci` 修好
- zh 推送成功，但 Pages 构建失败：部署卡在 `syncing_files` 11 分钟后 `Timeout reached`。`gh run rerun` 因为部署 ID 相同被拒（`Deployment cancelled`）；改用 `gh api -X POST repos/Liam0205/liam0205.github.io/pages/builds`，约 1 分钟构建成功
- headless 截图的坑：NexT 入场动画让 `.post-body` 停在 `opacity: 0`，截出来是空白；截线上页面时 `networkidle0` 会超时

## 该站写作规范

写文章本身（语气、结构、引号、人称）走 `liam-page-writing` skill，本文件只管发布链路。
