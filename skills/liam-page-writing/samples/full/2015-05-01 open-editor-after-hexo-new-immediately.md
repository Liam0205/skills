---
title: "在 hexo new 之后立即打开新建的 Markdown 文稿"
url: https://liam.page/2015/05/01/open-editor-after-hexo-new-immediately/
date: 2015-05-01
categories: ["Computer Skills"]
tags: ["Hexo", "Markdown"]
---

自己的博客是用 Hexo 搭建的。Hexo 是其时尚为大学生的台湾人 [Tommy](https://github.com/tommy351) 开发的轻量级静态博客生成器，具有简洁、快速、扩展性好等特点。

在 Hexo 中新建一篇博文非常简单，只需要在命令行中执行

```bash
hexo new "the title of your blog"
```

即可。Hexo 会在后台自动帮你创建名为 yyyy-mm-dd-the-title-of-your-blog.md 的文件，供你撰写博文。不过，也有不方便的地方。通常你需要依次打开 hexo-home/source/_post 目录，然后在成堆的 Markdown 文件中找到刚才创建的文档。

简单搜索之后，我发现在 Hexo 的 GitHub 项目里，有人提出了类似的需求：

[https://github.com/hexojs/hexo/issues/1007](https://github.com/hexojs/hexo/issues/1007)

Tommy 指出，可以在 Hexo 目录下的 scripts 目录（若没有，则新建一个）中创建一个 JavaScript 脚本，监听 hexo new 这个动作。并在检测到 hexo new 之后，执行编辑器打开的命令。

Tommy 给出的代码如下：

```javascript
var spawn = require('child_process').spawn;

// Hexo 2.x
hexo.on('new', function(path){
  spawn('vi', [path]);
});

// Hexo 3
hexo.on('new', function(data){
  spawn('vi', [data.path]);
});
```

我使用的 Hexo 是 2.5.4 版本，然而，测试过 Tommy 给出的代码之后并没有顺利地打开编辑器。不过精髓已经理解，需要的就只是细节的改变了。

简单翻阅了一下 JavaScript 的语法规则，我尝试了下列 JavaScript 代码：

```javascript
var exec = require('child_process').exec;

// Hexo 2.x
hexo.on('new', function(path){
    exec('open -a "/Applications/Sublime Text.app" ' + path);
});
```

注意，我这里执行的系统命令，是 OS X 下的 open。换到 Windows 中，可能需要改为 start。

在命令行中敲下

```bash
hexo new "open editor after hexo new immediately"
```

之后，Sublime Text 顺利打开了相应的 Markdown 文稿。接下来的事情，就是愉快地写作啦！