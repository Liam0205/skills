---
title: "为 Hexo 博客创建本地搜索引擎"
url: https://liam.page/2017/09/21/local-search-engine-in-Hexo-site/
date: 2017-09-21
categories: ["Computer Skills"]
tags: ["Hexo", "Search Engine", "JavaScript", "jQuery", "CSS"]
---

自 2014 年，始终博客就开始使用 [Hexo](https://hexo.io/zh-cn/index.html) 这个静态站点生成工具了；犹记得当时参考的文章，是 Bruce 的 [Hexo 你的博客](http://ibruce.info/2013/11/22/hexo-your-blog/)。

始终博客采用的主题，是 [iissan](https://github.com/iissnan/) 创建的 [NexT](https://github.com/iissnan/hexo-theme-next)。NexT 主题默认提供了两个站内搜索解决方案：swiftype 和 tinysou。早年时候，始终博客采用了 swiftype 作为站内搜索方案；但后来因为 swiftype 改版而失效，就放弃了。

近期，随着始终博客的文章数量不断增加，陆续有友人建议应该为博客加上搜索功能。然而，出于几方面的考虑，我一直没有加上搜索功能：

- 不愿意受限于第三方服务，第三方服务可能说变就变——曾经的各种博客网站，以及 swiftype 就是如此；

- 不喜欢第三方服务的样式，与博客样式脱节；

- 使用第三方服务，需要应用第三方的 JavaScript 脚本等内容，可能存在安全风险。

经过检索之后，我发现 Hexo 已有可以接受的解决方案了。本文来介绍如何在 Hexo 博客中建立自己的本地搜索引擎。

## 思路分析

对于大型搜索引擎来说，在抓取并处理好网页之后，就要建立所谓的「倒排索引」了。所谓倒排索引，指的是以检索词的 term 为键，以包含该 term 的文档列表为值。如此一来，我们就可以根据检索词中的各个 term，获取若干列表。而后，对这些列表求交集，就能得到「包含检索词中所有 term」的文档了。

在个人网站上，特别是 Hexo 生成的静态站点，做类似的工作是不太容易的。这里原因有几点，分列如下

- Hexo 生成的是静态站点，因此无法利用服务器做数据库的存储和相关计算；

- 这就制约了倒排索引的存储和求交；

- 另外一方面，制作倒排索引的过程，需要应用完善的 NLP 分词，这一工程量相对巨大。

考虑到我们无法在服务器上做数据库存储，我们就必须以文件的形式保存索引，让用户以浏览器下载该文件。此外，考虑到我们无法在服务器上做计算，我们就必须依赖可在浏览器上执行的代码，处理用户的检索任务。因此，我们说，仿照大型搜索引擎制作站内搜索，对于静态站点来说，是不现实的。

那么，我们可以怎样做呢？既然标准的方案无法达成，那我们就只能退而求其次。

首先，不管怎样「求其次」，都必须要有一个索引文件。这是因为，在索引文件当中进行各种操作，总是要比直接对网页页面进行操作来得要方便和快捷的。因此，首先我们需要一个能够嵌入 Hexo 的工具，方便地生成这样的索引文件。其次，有了索引，我们需要一个有效的算法：根据用户输入的检索词，返回包含检索词的文章列表。考虑到这样的算法需要在用户的浏览器上执行，我们选择使用 JavaScript 和 jQuery 来实现。接下来，为了与用户交互：接受检索词和返回结果；我们需要在页面的合适位置展示搜索框和输出结果。最后，还有一些细节问题需要处理。例如说，搜索框和输出结果的样式要如何设计；例如说，索引文件通常比较大，随页面一起下载会导致页面加载缓慢，要如何解决这个问题。

我们依次来解决这些问题。

## 用 hexo-generator-search 生成索引

HaHack 参考 Christian Fei 的 [Simple Jekyll Search](https://github.com/christian-fei/Simple-Jekyll-Search) 实现了名为 hexo-generator-search 的生成器。安装该生成器之后，在执行 hexo generate 的过程中，会按照配置生成一个 XML 文件，用于保存全站的文档数据。这个 XML 文件只是简单地做了数据的结构化存储，而完全没有考虑分词、倒排等问题。

安装 hexo-generator-search 非常简单，只需要在 Hexo 项目目录下执行下列命令即可。

```bash
npm install --save hexo-generator-search
```

如此一来，我们只需在站点配置文件 _config.yml 当中写入如下配置，即可为全站的文档生成索引文件了。

```plaintext
search:
  path: search.xml
  field: post
```

具体来说，hexo-generator-search 会为全站所有 post 类型的页面生成结构化的数据，并保存在本站的 /search.xml 当中。若想让 page 类型的页面也纳入索引，则可以将 field 的值修改为 all。

## 用 JavaScript 和 jQuery 实现检索算法

另外一方面，HaHack 建议以 jQuery 的文本匹配为基础，在前端界面上运行站内搜索。主要的处理流程是：

- 载入 search.xml；

- 解析 search.xml；

- 解析检索词；

- 在索引中进行字符串匹配；

- 展现结果。

我对官方的版本进行了少许的修改（后详），并加入了注释。这样应该相对比较好理解了。你可以在 [GitHub](https://github.com/Liam0205/hexo-search-plugin-snippets/blob/master/snippets/search.js) 上看到我修改的版本。

需要注意的是，search.js 依赖 jQuery。因此，你需要在引入 search.js 之前，引入 jQuery 的脚本。比如，你可以在 head 部分这样做：<script src="//cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>。

## 在合适的位置展示搜索框

接下来，我们需要在合适的位置，呈现一个搜索框。

```html
<form class="site-search-form">
    <input type="text" id="local-search-input" class="st-search-input" />
</form>
<div id="local-search-result" class="local-search-result-cls"></div>
```

此处，local-search-input 是一个输入框，用于接收用户输入的检索词；local-search-result 是用于展现搜索结果的 div 标签。这部分代码，我也已上传到 [GitHub](https://github.com/Liam0205/hexo-search-plugin-snippets/blob/master/snippets/search.swig)。

## 其他一些细节

### 调用函数

现在，我们已经有了索引文件、搜索算法和搜索框。但是，现在而言，搜索框是孤立的：用户在搜索框中输入内容，并不会触发搜索算法。换而言之，搜索函数并没有调用。因此，我们需要调用定义在 search.js 当中定义的 searchFunc。

```javascript
var path = "/search.xml";
searchFunc(path, 'local-search-input', 'local-search-result');
```

### 在何时的时候触发搜索函数

像上面这样调用搜索函数，有一个潜在的问题。调用搜索函数时，首先会尝试载入并解析 search.xml 文件。这个文件包含了站点里所有博文的所有内容；因此，通常来说它的体积非常大。这样一来，如果不做任何限制，函数将在网页加载时被调用；因而，体积庞大的索引文件也将在网页加载的时候引入。这会导致网页整体加载的速度非常缓慢，对用户体验是一种伤害。

因此，我们会考虑，在激活搜索框时，我们才去调用搜索函数。

```javascript
var inputArea       = document.querySelector("#local-search-input");
inputArea.onclick   = function(){ getSearchFile() }
```

此处，我们通过 inputArea 这个变量，监控搜索框的状态。只有当用户用鼠标点击搜索框时，才会触发 getSearchFile 函数，载入索引文件并执行 searchFunc。

getSearchFile 函数定义在 search.js 脚本当中了。

不过，这还不够。因为，如此一来，每次用户点击搜索框时，都会触发一次 searchFunc 函数，并加载一次 search.xml 索引文件。我们期待的是，只有当用户第一次点击搜索框之后，才去下载索引文件；之后的搜索行为，直接复用上一次加载的文件即可。

为此，我们需要在执行好 getSearchFile 函数之后，禁用 onclick 时间的 handler。

```javascript
var inputArea       = document.querySelector("#local-search-input");
inputArea.onclick   = function(){ getSearchFile(); this.onclick = null }
```

### 在搜索框中屏蔽回车

由于我们在搜索框中使用了 input 标签。这是一个表单，但我们不希望它具有一些表单的行为。例如说，我们的搜索结果是实时呈现的；我们不希望用户在输入检索词之后，误按回车键，导致页面刷新。

为此，我们可以这样做。

```javascript
inputArea.onkeydown = function(){ if(event.keyCode == 13) return false }
```

### 在加载索引文件时，给用户一个提示

我们为了保护页面加载的速度，将加载索引文件的过程，后移到用户点击搜索框时进行。然而，如前所述，索引文件通常是比较大的；加载并解析索引文件通常会耗费不少时间。在这个过程中，用户可能已经输入了一些检索词；这些检索词，会因为尚未加载完毕索引文件，而得不到任何的检索结果。这当然是不合适的。

因此，我们需要在加载和解析索引文件的过程中，给用户一个清晰的提示。为此，我们需要修改 search.js 脚本。

```javascript
var $resultContent = document.getElementById('local-search-result');
$resultContent.innerHTML = BTN + "<ul><span class='local-search-empty'>首次搜索，正在载入索引文件，请稍后……<span></ul>";
```

将这段代码放在加载和解析索引文件之前，就能在 local-search-result 中提示「正在载入索引文件」了。

### 样式表

最后，我们可以通过样式表来控制这一系列内容的呈现形式。始终博客使用的样式表可以在 [GitHub](https://github.com/Liam0205/hexo-search-plugin-snippets/blob/master/snippets/search.stylus) 上找到。

做完了这些工作，就可以查看效果啦。始终博客的搜索框位于页面的右上角。

参考资料：

- [http://hahack.com/codes/local-search-engine-for-hexo/](http://hahack.com/codes/local-search-engine-for-hexo/)

- [http://moxfive.xyz/2016/05/31/hexo-local-search/](http://moxfive.xyz/2016/05/31/hexo-local-search/)

- [http://www.barretlee.com/blog/2017/06/04/hexo-search-insite/](http://www.barretlee.com/blog/2017/06/04/hexo-search-insite/)

- [https://github.com/barretlee/hexo-search-plugin-snippets](https://github.com/barretlee/hexo-search-plugin-snippets)

- [https://github.com/Liam0205/hexo-search-plugin-snippets](https://github.com/Liam0205/hexo-search-plugin-snippets)