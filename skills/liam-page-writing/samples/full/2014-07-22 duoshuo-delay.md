---
title: "异步加载多说评论框以加快页面访问速度"
url: https://liam.page/2014/07/22/duoshuo-delay/
date: 2014-07-22
categories: ["Computer Skills"]
tags: ["Blog", "Duoshuo", "Async Loading"]
---

多说评论框可以让静态博客实现评论功能，对于搭在 GitHub Pages 上的博客来说是非常好用的功能。美中不足的是，多说评论框的加载速度有些慢；默认情况下，多说评论框总是随页面一起加载，拖慢了整个页面的加载速度。

本希望用自动异步加载的方式，在页面加载完成之后，再加载多说评论框。奈何多说没有提供所需的 API。于是只能退而求其次，采用手动的方法。

多说在其[官博](http://dev.duoshuo.com/docs/50b344447f32d30066000147)提出了一种异步加载的方式。经测试，这个方法可用——只需要点击按钮，多说评论框就会弹出来。但是，官博提供的方法只能弹出，不能缩回，有些恼人。于是自己写了几行代码，解决了这个问题。

## 详细步骤

首先，我们需要加载多说的 embed.js 基础代码，并设置 duoshuoQuery。多说官博希望我们把这段代码放在网页的 head 中，我不推荐这样做。因为我们使用异步加载的原因，就是希望提高速度，而如果将多说的代码放在 head 中，又拖慢了速度。所以我们将代码放在多说评论框加载之前就可以了。

```html
<script>var duoshuoQuery = {short_name:"你的多说二级域名"};</script>
<script src="http://static.duoshuo.com/embed.js"></script>
```

多说二级域名是指你注册多说时，填写的 abc.duoshuo.com 中的 abc 部分。

紧接其后之后，我们要写入 JavaScript 函数，实现多说评论框的缩放功能。

```html
<script type="text/javascript">
function toggleDuoshuoComments(container, id, url){
  if(jQuery(container).has("div").length>0){
    jQuery(container).empty();
    return;
  }
  var el = document.createElement('div');
  el.setAttribute('data-thread-key', id);
  el.setAttribute('data-url', url);
  DUOSHUO.EmbedThread(el);
  jQuery(container).append(el);
}
</script>
```

在需要插入按钮的地方，我们建立一个 click 事件。

```html
<a href="javascript:void(0);" onclick="toggleDuoshuoComments('#comment-box', <%= item.title %>, <%- config.url %><%- config.root %><%- item.path %>);">查看评论</a>
```

其中 <%= item.title %> 和 <%- config.url %><%- config.root %><%- item.path %> 是 hexo 的语法。

最后，在需要弹出评论框的地方，插入一个 div 标签。

```html
<div id="comment-box" ></div>
```

这样就大功告成啦！