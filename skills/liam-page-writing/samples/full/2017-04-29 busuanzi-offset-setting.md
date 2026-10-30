---
title: "不蒜子计数器初始化的非官方办法"
url: https://liam.page/2017/04/29/busuanzi-offset-setting/
date: 2017-04-29
categories: ["Computer Skills"]
tags: ["Busuanzi"]
---

[不蒜子](http://busuanzi.ibruce.info/)是 Bruce 开发的一款轻量级的网页计数器，它的口号是（非官方）

轻量级，但好用。

如果你想尝试不蒜子计数器，可以查阅[不蒜子计数器的介绍文档](http://ibruce.info/2015/04/04/busuanzi/)。

不蒜子虽好，但也有一些问题。Bruce 在文档中提到

我的网站已经运行一段时间了，想初始化访问次数怎么办？请先注册登录，自行修改阅读次数。

但因为各(qi)种(shi)原(shi)因(lan)，注册登录的功能一直没有上线。所以现在，如果用户希望修改初始值，则必须联系 Bruce，让他手工升级。这无疑违背了 geek 的原则。于是这篇文章提出一个非官方的办法，解决这个问题。我们的口号是

非官方，但好用。

## 分析问题

不蒜子之所以被成为「geek 的计数器」，就是因为它的安装使用非常简单——只需要加载计数器 js 脚本，以及使用 span 标签显示计数器结果就可以了。其余所有的事情，都交给用户的 css 去控制。因此，自然，这个「所有的事情」也包括了最终显示的值是多少。因此，我们可以在最终显示的数字上做一些手脚。

不蒜子的站点 PV 对应的标签是这样的

```html
<span id="busuanzi_value_site_pv"></span>
```

既然如此，我们只需要在页面上用 js 取得这个标签中的值，而后加上一个偏移量作为初始值就可以了。如果使用 jQuery，可以这样做

```html
<script src="//cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
<script>
    $(document).ready(
        var busuanziSiteOffset = parseInt(100000);
        function fixCount() {
            if ($("#busuanzi_container_site_pv").css("display") != "none") {
                $("#busuanzi_value_site_pv").html(parseInt($("#busuanzi_value_site_pv").html()) + busuanziSiteOffset);
            }
        }
    );
</script>
```

余下唯一的问题，就是不蒜子的 js 代码，是通过异步的方式加载的。而在其加载完成之前，上述 span 标签会整个被隐藏起来，不可见。于是，这样的朴素的修复就会失效了。

对付「异步」，一个朴素的处理方式是定期轮询。比如这样

```html
<script src="//cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
<script>
    $(document).ready(function() {
        var int = setInterval(fixCount, 100);
        var busuanziSiteOffset = parseInt(10000);
        function fixCount() {
            if ($("#busuanzi_container_site_pv").css("display") != "none") {
                clearInterval(int);
                $("#busuanzi_value_site_pv").html(parseInt($("#busuanzi_value_site_pv").html()) + busuanziSiteOffset);
            }
        }
    });
</script>
```

## Hexo 的解法

在上面的分析中，我们实际上已经有了完整的解法。不过，这样的解法可定制性非常差。试想，在需要修改初始值的时候，都需要深入到代码中去，而后修改 var busuanziSiteOffset = parseInt(10000); 的值。这种事情，想想就令人崩溃。

对于 Hexo 来说，在站点或主题配置中的变量，可以在主题模版中引用得到。于是，我们可以这样做。

```armasm
# busuanzi
busuanzi: true
busuanzi_site_offset: 100000
```

以及这样做。

```html
{% if theme.busuanzi %}
<!-- 不蒜子 -->
<script async src="//cdn.busuanzi.ibruce.info/cdn/busuanzi/2.3/busuanzi.pure.mini.js"></script>
<!-- 不蒜子计数初始值纠正 -->
<script src="//cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
<script>
    $(document).ready(function() {
        var int = setInterval(fixCount, 100);
        var busuanziSiteOffset = parseInt({{ theme.busuanzi_site_offset }});
        function fixCount() {
            if ($("#busuanzi_container_site_pv").css("display") != "none") {
                clearInterval(int);
                $("#busuanzi_value_site_pv").html(parseInt($("#busuanzi_value_site_pv").html()) + busuanziSiteOffset);
            }
        }
    });
</script>
{% endif %}
```