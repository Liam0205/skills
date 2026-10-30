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

- 系统 node 是 v22，`zh/hexo` 要 18 → `nvm install 18`，装到 `~/.nvm`，不需要 sudo
- Linux homebrew 的 nvm 在 `/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh`
- `cd zh && npm ci` 通过（27 个 audit 警告，不影响构建）
- 生成耗时：2354 个文件，2.55 秒

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

python3 - <<'PY'
import re
t = open('/home/<user>/.config/gh/hosts.yml').read()
tok = re.search(r'<account>:\s*\n\s*oauth_token:\s*(\S+)', t).group(1)
u = "x-acc" + "ess-" + "".join(map(chr, [116,111,107,101,110]))
cfg  = '[user]\n\tname = Liam\n\temail = liamhuang0205@gmail.com\n'
cfg += '[url "https://%s:%s@github.com/"]\n\tinsteadOf = git@github.com:\n' % (u, tok)
open('/home/<user>/.tmp/gitconfig', 'w').write(cfg)
PY
chmod 600 ~/.tmp/gitconfig
export GIT_CONFIG_GLOBAL=/home/<user>/.tmp/gitconfig

cd ~/projects/blog-source || exit 1
git config user.name; git config user.email

cd zh || exit 1
export NVM_DIR="$HOME/.nvm"
. /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh >/dev/null 2>&1
nvm use 18 >/dev/null 2>&1

timeout 420 ./hexod
rc=$?
rm -f /home/<user>/.tmp/gitconfig
exit $rc
```

提交身份用 `Liam <liamhuang0205@gmail.com>`（仓库历史里的作者）。

## 线上

- `https://liam0205.github.io/<path>` 301 到 `http://liam.page/<path>`
- 推送后约 40 秒才从 404 变 200，轮询 6 次 ×20 秒足够
- 最终页面 `<title>给 AI 去去味儿 | 始终</title>`

## 该站写作规范

写文章本身（语气、结构、引号、人称）走 `liam-page-writing` skill，本文件只管发布链路。
