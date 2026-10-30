---
title: "为网页标题添加「崩溃了」彩蛋"
url: https://liam.page/2019/07/22/crash-title-cheat/
date: 2019-07-22
categories: ["Computer Skills"]
tags: ["JavaScript"]
---

经常浏览[「始终」博客](/)的读者很容易会发现，当你在浏览器中切换 tab 页到其它网页时，始终博客的页面会有一定概率「崩溃」。具体来说，tab 页上的标题会变成 ╭(°A°`)╮ 页面崩溃啦~ 这样子，切换回来之后又会发现页面其实没问题，同时标题会变成 (ฅ>ω<*ฅ) 咦，又好了~ 这样子。因为这个彩蛋比较有趣，所以很多朋友回点回来看一看页面发生了什么。想想还是蛮有趣的。

最近有不少朋友问到这个效果是怎么实现的。这里记录一下。

因为功能十分简单，所以直接放代码出来。

```javascript
<script type="text/javascript">
var originalTitle = document.title;      // 1.
var crashSwitched = false;               // 2.
var titleTime;
document.addEventListener('visibilitychange', function () {
  if (document.hidden) {
    if (Math.random() < parseFloat({{ theme.crash_title_cheat.probability }})) {         // 3.
      crashSwitched = true;              // 2.a.
      document.title = '{{ theme.crash_title_cheat.crash_string }}' + originalTitle;     // 1.a.
      clearTimeout(titleTime);
    }
  } else {
    if (crashSwitched == true) {
      crashSwitched = false;             // 2.b.
      document.title = '{{ theme.crash_title_cheat.recover_string }}' + originalTitle;   // 1.b.
      titleTime = setTimeout(function () {
        document.title = originalTitle;  // 1.c.
      }, 2000);
    }
  }
});
</script>
```

首先解释一下以下一些 Hexo 变量：

- theme.crash_title_cheat.probability：值为 0.25。意味着当用户从博客页面切走时，有 0.25 的概率会触发「页面崩溃」的彩蛋。

- theme.crash_title_cheat.crash_string：值为 ╭(°A°`)╮ 页面崩溃啦~，这就是「页面崩溃」时你看到的字符串。

- theme.crash_title_cheat.recover_string：值为  (ฅ>ω<*ฅ) 咦，又好了~，这就是「页面恢复」时你看到的字符串。

而后我们看 (1) 处用变量 originalTitle 记录了当前页面的原始标题；(2) 处用变量 crashSwitched 记录当前页面是否有触发该彩蛋。当页面被隐藏切走时，在 (3) 处有一定概率触发页面崩溃的彩蛋。彩蛋被触发时，首先 (2.a) 修改触发标记，然后 (1.a) 修改页面标题。当页面被切回时，则会检查触发标记。若标记触发，则首先 (2.b) 抹掉触发标记，然后 (1.b) 添加「咦，又好了~」这样的字符串，最后在 2000 毫秒之后 (1.c) 恢复为真实标题。