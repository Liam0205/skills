---
title: "踩坑：value to great for base"
url: https://liam.page/2019/11/11/value-too-great-for-base-in-shell/
date: 2019-11-11
categories: ["Computer Skills"]
tags: ["Shell", "Integer"]
---

前几天启动的定时任务，有几个实例挂掉了。报错提示：

```shell
value too great for base (error token is "08")
```

出错的相关代码如下：

```shell
if [ $((${hour_s} + ${hour_diff})) -gt 23 ]; then
  # foo bar
fi
```

这里 ${hour_s} 是当前标定时间的小时数。形如 00, 01, 02, ..., 08, 09, ..., 23。${hour_diff} 是需要向后处理的小时数。这段代码的意图，是判断二者相加是否大于 23。若大于 23，则需要在日期上 +1，否则只需要操作小时即可限定数据范围。

关键就在于 08 和 09 的意思。这里 08 是上午八点的意思，为了保持格式一致，在 8 的前面填充了 0。但 Shell 把它当成是八进制（base is 8）。这样一来，怪不得 Shell 认为 08 是不合法的八进制数。为解决这个问题，我们需要告知 Shell 这是个前面填充了 0 的十进制数。于是我们需要改成这样：

```shell
if [ $((10#${hour_s} + ${hour_diff})) -gt 23 ]; then
  # foo bar
fi
```