---
title: "使用 Python 记录键盘事件"
url: https://liam.page/2019/12/06/record-keyboard-events-by-python/
date: 2019-12-06
categories: ["Computer Skills"]
tags: ["Python", "Keyboard"]
---

今天也不知道是想了什么，突然就想要试试看我有效击键时的手速到底有多快。为此，需要记录下来击键的记录。于是找到了 Python 的 keyboard 库。

安装非常简单，只需执行 pip install keyboard 即可。而后保存并执行如下代码：

```python
import keyboard
import time

keyboard.hook(lambda e: print(e, time.clock()))
keyboard.wait('Ctrl')
```

这里，我们利用 keyboard.hook 为每个键盘事件下钩子，并且执行其中的 lambda 函数。keyboard.wait() 的作用是阻塞进程，直到按下 Ctrl 键。

测试结果如下：

```plaintext
KeyboardEvent(g down) 4.450576466
KeyboardEvent(g up) 4.505627652
KeyboardEvent(i down) 4.510628277
KeyboardEvent(t down) 4.570555791
KeyboardEvent(i up) 4.580582066
KeyboardEvent(space down) 4.581583136
KeyboardEvent(p down) 4.630656009
KeyboardEvent(t up) 4.671189791
KeyboardEvent(space up) 4.693182730
KeyboardEvent(p up) 4.705543556
KeyboardEvent(u down) 4.705867633
KeyboardEvent(s down) 4.730623806
KeyboardEvent(u up) 4.750832241
KeyboardEvent(s up) 4.795770594
KeyboardEvent(h down) 4.810543976
KeyboardEvent(h up) 4.86056459
KeyboardEvent(enter down) 4.920739469
KeyboardEvent(enter up) 4.930514276
KeyboardEvent(ctrl down) 7.030813124
```

从中可见，在敲下 git push<enter> 这条命令的过程中，发生了多次击键交错的现象（即上一个按键还未完全弹起，下一个按键就已经触发）。这是在高速击键时很常见的现象。此外，输入到执行这条命令，总共花费了不到 0.5 s 的时间，不愧曾经单身多年 ←_←。

你的手速如何呢？