---
title: "Python 中的黑暗角落（二）：生成器协程的调度问题"
url: https://liam.page/2017/06/30/generator-coroutine-in-python-basic-topics/
date: 2017-06-30
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Yield", "Coroutine", "Generator", "Asynchronism"]
---

[前作](/2017/06/30/understanding-yield-in-python/)介绍了 Python 中的 yield 关键字。此篇介绍如何使用 yield 表达式，在 Python 中实现一个最基本的协程调度示例，避免 I/O 操作占用大量 CPU 计算时间。

## 协程及其特点

协程是一种特殊的子程序，它**可以在特定的位置暂停/恢复**（而不是像普通函数那样在逻辑上顺序执行）；并且**每当协程暂停时，调用者可以从协程中获取状态，决定调用者接下来的走向**；以及**每当协程恢复时，调用者可以传递信息给协程，影响协程的行为**。

从「可以暂停/恢复」来看，协程类似于 Python 中的迭代器。不过，迭代器仅只是将值返回给调用者，其内部的逻辑是确定的，无法与调用者做更多的交互。

因为协程可以暂停/恢复，所以，我们可以在多个协程中分别执行不同的任务；然后由调度器管理协程之间的执行，实现多任务并发。

此外，协程和调用者在同一线程中执行；考虑到[线程是操作系统进行任务调度的最小单元](/2017/01/17/layers-and-operation-system/)，**协程和调用者之间的切换，没有 CPU 上下文切换的开销**。因此，相对使用多线程、多进程实现多任务并发，协程在这方面的开销非常小。

同样由于协程之间共享线程，所以使用协程实现的多任务并发，无法实现[真正的并行](/2017/05/06/cxx-concurrency-multithread-basic-problems/#%E5%B9%B6%E5%8F%91%E4%B8%8E%E5%B9%B6%E8%A1%8C)。因此，显而易见，**协程适合 I/O 密集型的任务并发，而不适合 CPU 密集型的任务并发**。

## 协程调度基础

最简单的协程的例子，我们实际上已经见过了。在「使用 send() 方法与生成器函数通信」一节中，func 就扮演了协程函数的角色。每当协程函数在 yield 表达式处暂停，调用者就收到上一步计算的结果；每当协程函数自 yield 表达式处恢复，协程函数就用接收到的数进行下一轮计算。

在见识过最简单的协程示例之后，我们试着看看在调度协程的过程中，需要怎样处理。

```python
from collections import deque               # 1.

class Dispatcher(object):                   # 2.
    def __init__(self, tasks):
        self.tasks = deque(tasks)           # 3.
    def next(self):
        return self.tasks.pop()             # 4.
    def run(self):
        while len(self.tasks):              # 5.
            task = self.next()
            try:
                next(task)                  # 6.
            except StopIteration:
                pass                        # 7.
            else:
                self.tasks.appendleft(task) # 8.

def greeting(name, times):                  # 9.
    for i in range(times):
        yield                               # 10.
        print("Hello, %s.%d!" % (name, i))

dispatcher = Dispatcher([greeting('Liam', 5), greeting('Sophia', 4),
                                            greeting('Cancan', 6)])

dispatcher.run()
```

这段代码中，有两个主要角色：调度器 (2) 和任务 (9)。

从调度器的角度来说，我们自 collections 模块引入了 deque 容器 (1)，用于在 (3) 处保存任务。而后，我们在 (4) 定义了调度器 Dispatcher 的轮询函数 next()，它返回下一个尚未终止的任务。在调度器的 run() 函数中，(5) 和 (8) 保证了循环处理所有尚未完成的任务并清理已完成的任务，(6) 和 (7) 则负责触发每个任务的下一步动作。

从任务的角度来说，greeting 是一个生成器函数，是具体的协程任务。在 (10) 处，yield 表达式标记了函数暂停/恢复的位置；它将逻辑上连续的任务，在时间上切分成了若干段。

这段代码执行起来结果大致是这样：

```plaintext
Hello, Cancan.0!
Hello, Sophia.0!
Hello, Liam.0!
Hello, Cancan.1!
Hello, Sophia.1!
Hello, Liam.1!
Hello, Cancan.2!
Hello, Sophia.2!
Hello, Liam.2!
Hello, Cancan.3!
Hello, Sophia.3!
Hello, Liam.3!
Hello, Cancan.4!
Hello, Liam.4!
Hello, Cancan.5!
```

看起来和多线程那种乱七八糟的输出顺序有点像，不是吗？当然，此处由于使用 deque.pop() 轮询任务队列，所以输出顺序大致是有迹可循的。不过，这并不影响我们将其作为协程调度的示例。

在这个例子中，尽管调用者和协程之间没有其他的通信，协程函数内也没有真正意义上的 I/O 操作，但我们仍可以进行一些总结。

首先，生成器函数充当了协程函数，实现了协程。

其次，协程任务在逻辑上是连续的，但是我们可以用 yield 表达式在时间上把协程任务分成若干部分。

再次，用 yield 分割的任务，需要有一个机制控制器暂停/恢复。这个机制此处由调度器提供。

再者，对于调度器来说，它需要知道「有哪些协程任务需要恢复」。因此，它必然直接或间接地维护一个事件队列。此处，我们用 Dispatcher.tasks 完成了这一工作。

最后，对于每个协程（任务）来说，一旦被暂停，其恢复就必须依赖主动唤起。因此，调度器必须「恰到好处」地反复唤起线程——不能多也不能少：多则浪费执行时间，甚至抛出异常；少则留下未能完成的任务。因此，调度器必须恰当地维护上述队列，确定何时从队列中移除已完成的任务。在我们的例子中，(6) 和 (7) 协同完成了这一工作。

## 异步 I/O 任务模拟

回顾一下刚才的协程任务。

```python
def greeting(name, times):
    for i in range(times):
        yield
        print("Hello, %s.%d!" % (name, i))
```

在这个任务里，yield 表达式将原本在逻辑上连续的循环，人为地在时间上切分成了若干份。然而，除了用于演示暂停/恢复的携程调度之外，这个例子实际上没有必要使用协程实现。这是因为，在协程任务中，去掉 yield 表达式之后，所有的操作都是立即完成的；不存在需要阻塞以等待 I/O 的空耗 CPU 的情况。

下列代码模拟了一个需要阻塞等待 I/O 的任务。

```python
from time import sleep
from random import random as rd

def greeting(name, times, duration = 1):    # 1.
    for i in range(times):
        sleep(2 * duration * rd())          # 2.
        print("Hello, %s.%d!" % (name, i))
```

此处，新定义的 greeting 函数 (1) 有一个新的参数：duration。而后，在每次循环打印招呼信息的之前，会现行阻塞一段时间 (2)。这一阻塞就模拟了实际情况中的 I/O 类操作：空占 CPU 资源，但不进行任何计算。阻塞的时间是 2 * duration * rd()，这是一个一 duration 为期望的随机变量，用来模拟预计阻塞 duration 秒但实际情况会有波动的 I/O 任务。

假设 duration 设置为定值 1 而 times 设置为定值 3，那么执行一次 greeting 函数，平均需要耗时 3 秒。如若顺序执行 3 个这样的函数，平均下来，一共需要耗费 9 秒的时间。而这 9 秒之中，大多数时间 CPU 都仅只在空耗，没有执行实际的计算任务。因此，我们可以考虑用协程将它们并发起来执行，降低总的空耗的时间。为此，我们有如下思路。

- 将每个 I/O 任务理解为一个事件；

- 维护一个队列，用于记录尚在进行中的事件，以便后续操作；

- 当事件生成时，向上述队列注册（即将事件添加进队列）；

- 使用轮询（polling）等方式，捕获完成的事件；

- 对已完成的事件，进行后续操作（特别地，恢复协程函数），而后从队列中删除该事件。

现在，我们开始逐步在这一思路的指导下，实现协程并发。

### 引出休眠事件（SleepEvent）

回顾一下新版的 greeting 函数。若要通过生成器实现协程，就必然要添加 yield 表达式。

```python
from time import sleep
from random import random as rd

def greeting(name, times, duration = 1):
    for i in range(times):
        yield sleep(2 * duration * rd())          # 1.
        print("Hello, %s.%d!" % (name, i))
```

简单粗暴地以 (1) 的方式加上 yield 表达式是不行的。这是因为，yield 表达式会对 sleep 函数求值，而后将该值返回给调用者并暂停。但是，对 sleep 函数求值的过程，就是模拟的 I/O 操作，会阻塞执行线程。在阻塞完毕之后，再通过 yield 暂停，这就没有意义了。

```python
def coroutine_sleep(duration):              # 1.
    return SleepEvent(duration)             # 2.

def greeting(name, times, duration = 1):
    for i in range(times):
        yield coroutine_sleep(duration)     # 3.
        print("Hello, %s.%d!" % (name, i))
```

因此，我们需要定义新的 coroutine_sleep 函数 (1)。这个函数会生成一个事件（SleepEvent），然后不阻塞地立即返回 (2)。因此，在 (3) 处，yield 表达式会将 coroutine_sleep 返回的 SleepEvent 对象传递给协程函数的调用者，并暂停当前协程函数。

### 定义事件框架

接下来，我们需要定义事件框架。在实际动手之前，我们应该先分析一下一个事件类需要有哪些功能。

- 首先，事件应该有能力让外部知道自身存在。因此事件类应该伴随一个队列；并且在生成事件对象时，将自身注册进这个队列。

- 其次，事件应该有能力让外部知道自身状态，以便检查事件状态，进而进行下一步操作。因此，事件类应该是一个闭包，保存生成事件时的一些状态；并提供一个接口，利用这些状态检查事件是否完成。

- 最后，事件应当提供一个接口，记录在事件完成之后应当做什么；并且在事件完成之后执行这些操作。

据此，我们应该有如下代码。

```python
events_list = list()                    # 1.

class Event(object):
    def __init__(self, *args, **kwargs):
        events_list.append(self)        # 2.
        self._callback = lambda:None    # 3.
    def is_ready(self):                 # 4.
        ready = self._is_ready()
        if ready:
            self._callback()            # 5.
        return ready
    def set_callback(self, callback):   # 6.
        self._callback = callback
```

这里，(1) 处我们定义了一个全局的队列，用于记录尚在进行中的事件；与此同时，每当生成事件类对象时，(2) 会将当前事件对象注册到队列中。(3) 则定义了回调函数，用于记录事件完成之后执行什么操作。

(4) 和 (6) 分别是对外的接口。(4) 让外部有能力知道自身状态，其中 _is_ready() 需要在子类中实现；而 (6) 允许外部记录在事件完成之后应当做什么。(5) 则保证了当事件完成之后，(6) 中的设置会被正确执行。

至此，我们可以定义出 SleepEvent 类。

```python
from time import time as current_time
from random import random as rd

class SleepEvent(Event):                                    # 1.
    def __init__(self, duration):
        super(SleepEvent, self).__init__(duration)
        self._duration = 2 * rd() * duration                # 2.
        self._start_time = current_time()                   # 3.
    def _is_ready(self):
        return (current_time() - self._start_time >= self._duration)# 4.
```

这里，(1) 处定义了 SleepEvent 事件类，用来模拟 I/O 事件；模拟的核心在于 (2) 处定义的睡眠时长。(3) 则记录了事件诞生时的状态，用在 (4) 处确认事件是否已完成。

至此，协程函数这一侧的代码我们已经完成了，接下来我们看看调度器一侧的代码如何实现。

### 用轮询捕捉已完成的事件

因为我们在 events_list 中保存了所有尚在执行中的事件。这是相当简单的工作，所以不作过多的解释。

```python
while len(events_list):
    for event in events_list:
        if event.is_ready():
            events_list.remove(event)
            break
```

### 唤醒逻辑

在 Event 类的定义中，is_ready() 函数会在事件完成后调用 _callback 函数。而对于协程函数来说，一个事件完成后，需要做的事情无非是：唤醒，恢复执行到下一个暂停点。因此可以有这样的唤醒逻辑。

```python
def _next(gen_task):
    try:
        yielded_event = next(gen_task)                      # 1.
        yielded_event.set_callback(lambda: _next(gen_task)) # 2.
    except StopIteration:
        pass                                                # 3.
```

这里，(1) 调用 Python 内建的 next 函数，唤醒协程函数，执行到下一个暂停点，并接受其返回值，保存在 yielded_event 当中。而后，在 (2) 处将该 Event 对象设置为 Lambda 函数 lambda: _next(gen_task)。显然，这是一个递归调用 _next 函数自身的闭包——捕获了需要继续唤醒的生成器 gen_task。若生成器执行完毕，则无需继续唤醒。因此在 (3) 处，直接 pass 即可。

### 完整实验

将上述代码整合起来，就可以做实验了。

```python
#!/usr/bin/env python3

from time import time as current_time
from random import random as rd

events_list = list()

class Event(object):
    def __init__(self, *args, **kwargs):
        events_list.append(self)
        self._callback = lambda:None
    def is_ready(self):
        ready = self._is_ready()
        if ready:
            self._callback()
        return ready
    def set_callback(self, callback):
        self._callback = callback

class SleepEvent(Event):
    def __init__(self, duration):
        super(SleepEvent, self).__init__(duration)
        self._duration = 2 * rd() * duration
        self._start_time = current_time()
    def _is_ready(self):
        return (current_time() - self._start_time >= self._duration)

class Dispatcher(object):
    def __init__(self, tasks):
        self.tasks = tasks
        self._start()
    def _next(self, gen_task):
        try:
            yielded_event = next(gen_task)
            yielded_event.set_callback(lambda: self._next(gen_task))
        except StopIteration:
            pass
    def _start(self):
        for task in self.tasks:
            self._next(task)
    def polling(self):
        while len(events_list):
            for event in events_list:
                if event.is_ready():
                    events_list.remove(event)
                    break

def coroutine_sleep(duration):
    return SleepEvent(duration)

def greeting(name, times, duration = 1):
    for i in range(times):
        yield coroutine_sleep(duration)
        print("Hello, %s.%d!" % (name, i))

if __name__ == '__main__':
    def test():
        dispatcher = Dispatcher([greeting('Liam', 3), greeting('Sophia', 3), greeting('Cancan', 3)])
        dispatcher.polling()

    import timeit
    timeit_times = 10
    avg_cost = timeit.timeit(lambda: test(), number = timeit_times) / timeit_times
    print('%.3f' % (avg_cost))

```

可能的执行结果是：

```bash
$ python coroutine_async.py
Hello, Liam.0!
Hello, Liam.1!
Hello, Liam.2!
Hello, Cancan.0!
Hello, Sophia.0!
Hello, Cancan.1!
Hello, Sophia.1!
Hello, Cancan.2!
Hello, Sophia.2!
......
Hello, Liam.0!
Hello, Sophia.0!
Hello, Sophia.1!
Hello, Cancan.0!
Hello, Liam.1!
Hello, Sophia.2!
Hello, Liam.2!
Hello, Cancan.1!
Hello, Cancan.2!
3.400
```

可以看到，平均下来，使用协程并发地执行三个 greeting 任务（times = 3, duration = 1）只需要 3.4 秒；耗时远低于顺序执行所需的 9 秒。