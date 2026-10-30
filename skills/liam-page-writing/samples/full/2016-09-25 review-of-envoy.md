---
title: "Python envoy 模块源码剖析"
url: https://liam.page/2016/09/25/review-of-envoy/
date: 2016-09-25
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Library", "Subprocess"]
---

Kenneth Reitz 是公认的这个世界上 Python 代码写得最好的人之一。抱着学习的心态，我阅读了 Reitz 写的 envoy 模块的源码，将笔记记录如下。

## 介绍

和 requests 模块一样，envoy 也是 Reitz 的作品，连官方描述都类似——Python Subprocesses for Humans。

实际上，envoy 的核心代码非常少，总共只有不到 300 行代码，只是简单的对标准库 subprocess 的封装。但是，所谓短小精干，envoy 实现的接口简单易用，比裸用 subprocess 方便不少。

## 背景知识

在讲 envoy 的代码之前，我们先回顾一些背景知识。

### 程序和进程

在计算机科学及相关领域，经常能看到程序和进程的概念。有些人不清楚它们的差别，混为一谈。这是不好的。

- 程序：一般是一组CPU指令的集合构成的文件，静态存储在诸如硬盘之类的存储设备上。

- 进程：当一个程序要被计算机运行时，就是在内存中产生该程序的一个运行时实例，我们就把这个实例叫做进程。

简单来说，程序就是编译出来的二进制可执行文件，比如 Windows 里的 .exe 文件，*nix 里的 ELF 文件。操作系统将它们装载到内存空间并执行时的实例，就是进程。**程序和进程之间隔着一个「装载」的步骤**。

### Linux 里的进程

以下实验均在 CentOS 5.4 环境下操作。

首先，我们在终端里执行

```bash
ps -eo pid,ppid,comm,cmd | less
```

这里 ps 命令用来查询正在运行的进程，-e 表示我们想要查看所有的进程，-o 则选择我们想查看的列名称。这里我们查看 pid, ppid, comm, cmd。

![](/uploads/images/python/review_envoy_01.png)

在这个输出结果中，每一行代表一个进程（表头除外），共分为 4 列。

- PID: Process IDentity，进程在当前系统中的唯一识别码，相当于我们的身份证号。

- PPID: Parent PID，父进程的 PID。

- COMMAND: 进程的简称。

- CMD: **进程对应的程序**及其运行时所带的参数。

### 从计算机启动到进程的创建

计算机启动时，首先会从主板上的 **BIOS** (Basic Input/Output System) 中执行程序，从某个设备（比如软盘、硬盘、光盘、网络等）上启动计算机。而后，计算机会定位到所选的设备上，读取开头的 512 字节里的 **MBR** (Master Boot Record)。MBR 里记录着从存储设备启动 **Boot Loader** 的具体分区和位置。Boot Loder 里记录着操作系统名称、内核所在位置等信息，启动 Boot Loader 之后，它会帮我们**加载 Kernel**。内核负责两件事：对下负责管理硬件，对上负责提供系统调用。于是，内核首先会**预留自己运行所需的内存空间**，然后调用**驱动程序 (drivers)**检测计算机硬件，最后启动 init 进程，并将控制权交给这个进程。在 Linux 里，init 的 PID 是 1。init 进程负责设置计算机名称、时区，检测文件系统，挂载硬盘，清空临时文件，设置网络等操作。通常意义上说，当 init 完成这些工作，计算机就算启动完成了。

我们小结一下，计算机启动的流程是：

BIOS -> MBR -> Boot Loader -> Kernel -> 预留内存空间 -> drivers -> init -> settings

我们知道，运行于操作系统上的进程（包括 init）与操作系统交互，都是通过**系统调用**来完成的。然而 Linux 并没有提供创建新进程的系统调用。实际上，Linux 里创建新的进程这一动作，是通过 fork 和 exec 两个函数来实现的。

我们先来看看 fork 函数的用法。

```c
pid_t pid;
if (pid = fork()) {
    // ...
} else {
    // ...
}
```

调用 fork 函数后，新的进程（任务）和当前进程一起从代码的同一位置开始执行：从 fork 函数获得返回值。在这里，新的进程称为子进程 (Child Process)，当前进程相对应称之为父进程 (Parent Process)。不过，在子进程中，fork 函数返回 0；在父进程中，fork 函数则返回子进程的 PID。因此，在子进程中，表达式 pid = fork() 为 false，跳转到后续的 else 语句块继续执行；在父进程中，表达式 pid = fork() 为 true，继续执行语句块。

fork 函数的产生子进程的速度非常快。这是因为，通过 fork 产生的子进程，只是简单地分配了内存空间，并与父进程共享**写时复制 (Copy on Write, COW)**内存空间。这意味着，通过 fork 产生子进程的过程中，并没有内存中内容的复制，因此速度非常快。

fork 产生的子进程，只是父进程的镜像。通过 fork 的返回值，我们可以在代码里判断是否是子进程。如果是子进程，就可以调用 exec 函数，使用新的程序（可执行映像文件）覆盖当前的映像，从而执行新的任务。

不难发现，Linux 中所有的进程，不断追溯其父进程，都会最终追溯到 init 进程。

### 进程的终止

当一个进程执行 exit 函数之后，内核会释放它所打开的文件、占用的内存等资源，然后在操作系统内核中保留一些退出信息

- PID

- Exit Code

- CPU time taken by the process

简而言之，进程退出后，会释放资源，然后在内核里留下一些诊断信息，成为**僵尸进程 (Zombie Process)**。进程退出后，将 PID 留在了操作系统内核中尚未释放。因此，该 PID 是不可以被后续的新进程使用的。因此，在 Linux 的设计中，父进程需要调用 wait 或者 waitpid 函数从内核中获取并处理子进程的诊断信息，并释放 PID（清扫僵尸进程）。

如果子进程退出时，父进程尚在，但父进程始终不处理子进程退出后留下的僵尸进程，而不断因为业务逻辑产生新的子进程，那么僵尸进程就会不断积累，最终占满所有可用的 PID（没有进程槽了）。这样一来，在操作系统中就无法产生新的子进程了。（参见 [fork 炸弹](https://zh.wikipedia.org/wiki/Fork%E7%82%B8%E5%BC%B9)）因此，通过 fork 函数创建子进程之后，一定要注意 wait 子进程。

如果父进程退出时，子进程尚在。这时候，没爹没娘的孤儿进程（Orphand Process）就会被 init 进程收养，直到它退出后被 init 处理。

## envoy 源码剖析

Reitz 的 envoy 项目地址是 [https://github.com/kennethreitz/envoy](https://github.com/kennethreitz/envoy)。为了保证本文的长期有效性，我将它 fork 到了这里 [https://github.com/reviewlib/envoy](https://github.com/reviewlib/envoy)。

envoy 的核心代码保存在 ./envoy/core.py 当中。我们先就这份代码的语法点做分析，然后讨论它的结构。

### 库

```python
import os
import sys
import shlex
import signal
import subprocess
import threading
import traceback
```

最头上的两个 os 和 sys 是常用的标准库，不必多说。

shlex 的名字可以分为两部分：sh 代表 shell；lex 是一个著名的词法分析器的生成器（lexical analyzer）。运用这个标准库，我们可以很容易地解析出用户需要在子进程中执行的命令。

signal 是 Python 里处理 Linux 内核信号的标准库。我们这里主要用它内部定义的信号的值，不涉及它的具体用法。

subprocess 是 Python 中实现子进程的标准库，是 envoy 封装的实际内容。

threading 是 Python 中实现多线程的一个标准库。在 envoy 里，我们实际用它来执行 subprocess.Popen() 创建子进程并执行任务。

traceback 是 Python 中用来追溯异常的标准库。

### Command 类

我们来看 Command 类。这是一个模块内部使用的类，Command 类的每个实例都能执行 run() 方法，在一个子进程里执行 Shell 命令。

初始化函数 __init__() 直截了当，只是简单地对各个数据成员赋值。

整个类的主要部分是 run() 函数，我们仔细深入进去观察一下。

第一个值得注意的地方，是对环境变量的处理。

```python
environ = dict(os.environ)
environ.update(env or {})
```

首先，作者将 os.environ 转换成一个 Python 内建字典，保存在 environ 中。而后，用字典的 update() 方法，将用户传入的环境变量补充到 environ 中。这里，update() 方法有两个特点

- 输入必须是一个非空的字典，因此作者**利用短路求值 env or {} 的方式确保「非空」**；

- 输入的 env 如果有与 os.environ 同名的环境变量，则会以 env 中的值为准，否则直接在 environ 中添加键值对。

利用这两个特点，作者巧妙地实现了程序逻辑。

第二个值得注意的地方，是在 run() 函数的内部，嵌套定义了 target() 函数。

```python
def target():

    try:
        self.process = subprocess.Popen(self.cmd,
            universal_newlines=True,
            shell=False,
            env=environ,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=0,
            cwd=cwd,
        )

        if sys.version_info[0] >= 3:
            self.out, self.err = self.process.communicate(
                input = bytes(self.data, "UTF-8") if self.data else None
            )
        else:
            self.out, self.err = self.process.communicate(self.data)
    except Exception as exc:
        self.exc = exc
```

在 Python 中，函数定义是允许嵌套的，不过

- 各个函数有自己的作用域；

- 内层函数优先访问内层作用域的变量，如果内层没有所需变量，则逐层向外寻找所需变量；

- 外层函数不能访问内层函数的变量（对外层函数来说，这是局部变量）；除非内层函数声明变量时加上了 global 关键字修饰，并且在访问它时已经调用过内层函数。

这里的 target() 函数定义了我们接到一个执行 Shell 命令的需求时，我们要做哪些事情。依其定义，我们要首先使用 subprocess.Popen() 创建一个子进程，并在相应的条件下执行 self.cmd。然后调用 self.process.communicate() 方法，将 self.data 通过管道传给正在 Shell 中执行的程序，并获取程序的标准输出和标准错误。在整个过程中，但凡出现任何问题，都保存在 self.exc 当中。这里作者使用了所有异常的基类 Exception，这是因为对于作者来说 **self.cmd 是不可控的，在执行 self.cmd 的过程中可能出现任何形式的异常**。为了能够处理所有异常，作者必须使用 Exception 来处理。

第三个值得注意的地方，是作者在工作线程中去实际执行 target() 完成的任务。

```python
thread = threading.Thread(target=target)
thread.start()
thread.join(timeout)
```

首先，作者创建了一个线程，将 target() 函数作为参数传入构造。也就是说，thread.start() 实际会执行 target() 函数的代码。而后，作者用 thread.join(timeout) 的方式，来处理上层传下来的超时限制。这样，主进程将会阻塞住，直到

- 线程中的任务完成（也就是 target() 中创建的子进程的任务完成）；或者

- 达到超时时间限制。

第四个值得注意的地方，是作者回收和处理在线程中运行的子进程任务的执行状态信息。

```python
if self.exc:
    raise self.exc
if _is_alive(thread) :
    _terminate_process(self.process)
    thread.join(kill_timeout)
    if _is_alive(thread):
        _kill_process(self.process)
        thread.join()
self.returncode = self.process.returncode
return self.out, self.err
```

首先，子进程可能抛出异常，因此需要捕获和继续向上抛出异常。

其次，线程 thread 可能因为超时而执行到当前代码，因此通过预定义的 _is_alive() 函数来判断线程是正常退出还是扔在超时运行。如果确实超时，那么首先应该终止子进程，然后尝试等待线程超时终止。如果线程仍然还活着，说明线程内的子进程没有被正确终止，那么首先杀死子进程，然后阻塞线程直到它完成。这样的设计，是**确保子进程和线程都完全停止，防止僵尸进程的出现**。

最后，函数返回标准输出和标准错误的内容。

### Response 类

我们来看 Response 类。这是一个模块内部使用的类，Response 类的每个实例都是 Command 类的实例调用 run() 方法后的执行结果信息。

```python
class Response(object):
    """A command's response"""

    def __init__(self, process=None):
        super(Response, self).__init__()

        self._process = process
        self.command = None
        self.std_err = None
        self.std_out = None
        self.status_code = None
        self.history = []

    def __repr__(self):
        if len(self.command):
            return '<Response [{0}]>'.format(self.command[0])
        else:
            return '<Response>'
```

从只有一个 __repr__() 方法可以看出，Response 类几乎只是一个简单的数据结构，提供了可供打印的功能，仅此而已。那么作者为什么要设计这样一个类呢？这里我们留给读者思考。

### expand_args 函数

expand_args(command) 函数接收一个字符串作为参数，并将之解析为一个个的命令。

```python
def expand_args(command):
    """Parses command strings and returns a Popen-ready list."""

    # Prepare arguments.
    if isinstance(command, (str, unicode)):
        splitter = shlex.shlex(command.encode('utf-8'))
        splitter.whitespace = '|'
        splitter.whitespace_split = True
        command = []

        while True:
            token = splitter.get_token()
            if token:
                command.append(token)
            else:
                break

        command = list(map(shlex.split, command))

    return command
```

我们以 'cat inFile | sort | uniq' 为引数，传入 expand_args 函数，分析一下会发生什么。

首先，作者用 shlex.shlex() 构造了一个词法分析器，并设置以管道符号 | 为标志，分割传入的字符串（或者 unicode 类型的实例，后不再重复）。加上之后的 while 循环，这基本相当于执行了 command = command.split('|') 的效果。

而后，执行 command = list(map(shlex.split, command))，调用 shlex.split 函数，作用在 command 的每一个元素上，并返回一个列表，保存在 command 当中。最后以 return 将 command 返回给调用函数。

这里的 map() 函数接收两个参数

- 一个函数

- 一个可迭代的列表

然后将函数作用在列表的每一个元素上，并返回一个列表。类似的函数还有 reduce() 函数（参考 Google 的 MapReduce 架构）。这里给出两个示例，供体会它们的作用

```python
#!/usr/bin/env python
inIter = ['adam', 'LISA', 'barT']
regNames = lambda iter: map ((lambda inStr: inStr.capitalize()), iter)
print regNames (inIter)
```

```python
#!/usr/bin/env python
inIter = [1, 2, 3, 4, 5]
prod = lambda iter: reduce ((lambda x, y: x * y), iter)
print prod (inIter)
```

最后，输入 'cat inFile | sort | uniq' 有输出 [['cat', 'inFile'], ['sort'], ['uniq']]。

### run 函数

run(command, data=None, timeout=None, kill_timeout=None, env=None, cwd=None) 函数是 envoy 模块的主要接口，用来在子进程里执行 Shell 命令。

首先解释一下 run() 函数的各个参数的含义

- command 需要执行的 Shell 命令（可以包含管道，但是不允许包含 && 或者 ; 之类的符号）；

- data 通过管道传入 Shell 命令的内容；

- timeout 子进程执行超时时间；

- kill_timeout 终止子进程失败的超时时间，超过这个时间将直接杀死子进程；

- env 环境变量；

- cwd Current Working Directory，工作目录。

run 函数的实现相对来说是平铺直叙的，这里用注释简单说明一下各个部分都做了什么即可。

```python
def run(command, data=None, timeout=None, kill_timeout=None, env=None, cwd=None):
    """Executes a given commmand and returns Response.
    Blocks until process is complete, or timeout is reached.
    """

    '''对 `command` 做词法分析，拆分命令'''
    command = expand_args(command)

    history = []
    for c in command:

        '''模拟管道的作用，传入上一程序的标准输出'''
        if len(history):
            # due to broken pipe problems pass only first 10 KiB
            data = history[-1].std_out[0:10*1024]

        '''实际在子进程里执行命令'''
        cmd = Command(c)
        try:
            out, err = cmd.run(data, timeout, kill_timeout, env, cwd)
            status_code = cmd.returncode
        except OSError as e:
            out, err = '', u"\n".join([e.strerror, traceback.format_exc()])
            status_code = 127

        '''将执行结果保存在 `history` 当中'''
        r = Response(process=cmd)

        r.command = c
        r.std_out = out
        r.std_err = err
        r.status_code = status_code

        history.append(r)

    '''函数返回最后一个管道（如果有）之后命令的输出和详细情况'''
    r = history.pop()
    r.history = history

    return r
```

### 模块设计分析

Kenneth Reitz **不愧**是公认的这个世界上 Python 代码写得最好的人之一——虽然 envoy 是对 subprocess 的简单封装，功能有限，但是代码结构非常优雅，内部实现的逐层封装十分完善。

对于模块的用户（程序员）来说，envoy 几乎只有 run 这一个入口。而它的作用也很明确：开一个子进程，执行一条 Shell 命令，然后在规定时间内取得执行结果——中间的脏活累活（处理异常、超时、主进程阻塞等待、保存历史等等），envoy 都帮你做好了。

对于 run() 函数来说，它只需要知道执行 out, err = cmd.run() 就能在子进程里执行用户需要的命令，然后将结果存在 Response 里就可以了。

对于 Command.run() 函数来说，它只需要处理好环境变量，执行 target() 最后处理超时、异常、收集结果信息就可以了。

对于 target() 来说，这是一个嵌套定义的函数，它才是真正 fork 子进程并执行 Shell 命令的函数。

不难发现，每个层次完成的任务，几乎都可以用简单一句话解释清楚

- envoy.run() - 将 Shell 命令交给它，就会在子进程里执行这些命令并处理好返回结果；

- Command.run() - 将一个具体的 Shell 命令（不包含管道）交给它，就会在子进程里执行这些命令并处理好返回结果；

- target() - fork 一个子进程，然后在子进程里开心地执行命令。

这种符合 *nix 哲学的设计，造就了优雅好用的 envoy 库。对于程序员来说，将命令交给它，然后坐等结果就可以了。无愧于 Python Subprocesses for Humans 的豪言壮语。