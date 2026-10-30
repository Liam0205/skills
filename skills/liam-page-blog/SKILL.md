---
name: liam-page-blog
description: 在 Liam Huang 的博客源码仓库（Liam0205/blog-source，zh 与 en 两个 Hexo 站点）里新建文章、本地生成验证、发布上线。含递归子模块、被包装脚本钉死的 Node 18、中文标题的 slug 处理、frontmatter 与十六个既有分类、hexod 的九步流程、无 SSH key 时的凭证注入、GitHub Pages 的构建延迟。 Use when publishing a post to liam.page, deploying the site, or maintaining the blog-source repo.
---

# liam.page 博客发布

## 什么时候用

- 「发一篇博客」「把这篇文章发到博客上」「部署站点」「更新博客」
- 博客源码仓库的日常操作：新建文章、本地生成、发布

不适用于 WordPress、Hugo，或者不带 `./hexo`、`./hexod` 包装脚本的手写静态站。

## 仓库

- `git@github.com:Liam0205/blog-source.git`，必须递归 clone。子模块是两套 NexT 主题，主题里还嵌了一层 `source/lib/pjax`
- 本地路径约定 `~/projects/blog-source`
- `zh/` 与 `en/` 是两个独立的 Hexo 站点，各自带 `hexo`、`hexod`、`sync` 脚本
- 线上地址 `https://liam.page`（zh）与 `https://liam.page/en/`（en）
- 发布目标是 `Liam0205/liam0205.github.io` 的 master 分支，`.deploy_git` 就是那个仓库的工作目录

clone 之后用 `git submodule status` 检查，三个子模块都不该带 `-` 前缀。主题没拉下来时 `hexo g` 会直接失败。

更细的目录结构、frontmatter 样例与实测记录放在 `references/blog-source-facts.md`。

## 环境

站点脚本第一行执行 `nvm use 18`，系统自带的 Node 22 不能直接用。

```bash
export NVM_DIR="$HOME/.nvm"
. /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh
nvm install 18        # 只装一次，落在 ~/.nvm，不需要 sudo
nvm use 18
node -v               # 必须是 18.x 才算数
```

判断标准是 `node -v` 的输出，不是 `nvm use` 打印的那行成功信息。PATH 上可能还有别的 node（比如 `~/.hermes/node/bin/node`），用 `which -a node` 确认排第一位的是 `~/.nvm/versions/node/v18.*/bin/node`。

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

全站约 2354 个文件，两三秒跑完。`INFO Generated` 打出不代表页面正确，抽查四项：

```bash
F=public/2026/10/30/ai-tone-removal/index.html
ls -la $F                                     # 页面存在
grep -o "<title>[^<]*</title>" $F             # 标题渲染正确
grep -o "正文里的某个特征词" $F               # Markdown 真的转成了 HTML
grep -l "ai-tone-removal" public/index.html public/archives/index.html
```

最后一条确认文章进了首页和归档。没有出现说明日期或 draft 状态有问题。

## 发布

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

- `hexod` 里每条命令都包在 `while ! (...)` 里，认证失败不会退出，会无限重试。一定用 `timeout 420 ./hexod` 包住，否则看起来在跑，实际卡死
- `hexo d` 会先清空 `public/` 再重新生成，本地验证的结果不会带过去，每次都是全量
- 顶层还有一个 `hexod_all`，本意是两站一起发，但里面写成了 `while ! (HEXO clean)`，少一个 `$`，实际会循环失败。别用它，分别跑 zh 和 en

## 凭证

这台机器没有 SSH key，而仓库的 remote 和 deploy 目标都写成 `git@github.com:`。

不要把 token 写进 `~/.gitconfig`，也不要把 token 放进命令行参数。用一份临时 `GIT_CONFIG_GLOBAL` 把 SSH 地址重写成带 token 的 HTTPS，跑完就删：

```bash
bash scripts/publish.sh zh
bash scripts/publish.sh en    # 要发英文站时
```

脚本从 `~/.config/gh/hosts.yml` 取 `Liam0205` 的 token，生成 `~/.tmp/gitconfig`（含 user 段与 `insteadOf` 重写），导出 `GIT_CONFIG_GLOBAL`，用 `timeout 420` 跑 `hexod`，结束后删掉文件。

三条纪律：

- `GIT_CONFIG_GLOBAL` 会顶替 `~/.gitconfig`，所以提交身份要一起写进去，否则作者会变成默认账号
- 提交身份沿用仓库历史里已有的那个，`git log -1 --format='%an <%ae>'` 查出来是 `Liam <liamhuang0205@gmail.com>`
- `zh/.deploy_git` 是独立的 git 仓库，身份要单独设一遍，脚本里已经处理

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
- [ ] `node -v` 是 18.x，`which -a node` 第一位是 nvm 装的那个
- [ ] 文件名是英文 slug，与站内既有文章一致
- [ ] frontmatter 字段齐，分类在十六个既有分类里，正文没有重复的 H1
- [ ] `hexo g` 之后能打开该页，标题正确，正文有内容，首页和归档都有链接
- [ ] 发布命令用 `timeout` 包住
- [ ] 临时 gitconfig 用完删掉
- [ ] 线上返回 200 且标题正确
- [ ] 源码仓库与 deploy 仓库都已推送，`git status` 干净

## 常见坑

- 新文章的 slug 不改，URL 会是中文被百分号编码，以后引用和分享都难看
- `hexo new` 生成的文件不受 git 管理，`hexod` 的第一步 `git add ..` 会把它带进去，所以不必单独 add
- 主题是 `--remote` 更新的，发布时可能顺带拉进主题的新提交，源码仓库的 commit 里会看到主题指针变化，属于正常现象
