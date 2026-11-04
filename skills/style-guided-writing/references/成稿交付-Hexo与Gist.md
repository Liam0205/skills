# 成稿交付：Hexo 与 Gist

长文写完只是第一步。这一页记的是把成稿送出去那一段的具体做法，以及踩过的坑。

## Hexo 侧（liam.page）

### 公式

frontmatter 里 `mathjax: false` 是 scaffold 默认值，写公式的稿子必须改成 `mathjax: true`，否则全文只能拿 unicode 上下标凑，排出来难看。作者对此明确表过不满。

两条硬约束：

- `$$ ... $$` 必须写在同一行。跨行写，markdown 渲染器会在中间插 `<br>`，MathJax 认不出来。
- 行内公式里不要用裸下划线。`n_kv` 会被当成斜体配对吃掉。改用不带下标的字母记号，比如 $L$ 层数、$H$ 是 KV 头数、$h$ 是 head_dim、$D$ 是隐层宽度。

验证办法：`hexo g` 之后看产物里有没有 `tex-mml-chtml.js` 和 `has-jax` 类名，再确认 `$$` 之间干净。

### 插图

图片放 `zh/source/uploads/images/<子目录>/`，子目录按内容分类（algorithms、LaTeX、computer-skills 等）。文件名带语义，先想清楚这张图要证明什么再起名。

matplotlib 出中文图时把 `font.sans-serif` 设成 `WenQuanYi Zen Hei`，`axes.unicode_minus` 设 False。渲染完必须自己看一遍——小写 `l` 和数字 `1` 在这些字体下容易混，`ℓ` 也是因为这个才换上去的。

### 撤稿

源文件删掉，`hexo clean` 之后重新 `hexo g` 与部署，页面会变成 404，首页、归档、`search.xml` 同步消失。部署仓库的提交历史里仍然留着那一版，但不可访问。删之前把源文件备份到 `~/.tmp/retired/`。

## Gist 草稿渠道

正式发布之前把稿子发给别人看，用 Liam0205 账号建 **secret gist**：不进公开列表、不进搜索，拿到链接即可读。

- 调 `POST https://api.github.com/gists`，`public` 设 false 就是 secret。
- 文件名要带 `.md` 后缀，GitHub 才按 markdown 渲染，`$...$` 与 `$$...$$` 会正常出公式。
- 更新同一个 gist 用 `PATCH /gists/{id}`，只传要改的文件即可。
- token 从 `~/.config/gh/hosts.yml` 里 Liam0205 那一段取，不要把 token 写进命令行参数——写成脚本从文件读，输出里替换成 `<TOKEN>` 再打印。

写完 `curl -sL` 验一次：页面 200、标题能抓到、raw 链接的字节数和本地文件对得上。
