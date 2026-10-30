---
title: "程序员的自我修养（八）：使用 JProbe 调试 Linux 内核"
url: https://liam.page/2018/04/28/debug-in-Linux-kernel-jprobe/
date: 2018-04-28
categories: ["Algorithm and Computer Science"]
tags: ["Linux", "Kernel", "JProbe", "Debug"]
---

对于我这种普通程序员来说，Linux 内核是神秘而高贵的，轻易我们不敢去说内核相关的事情。不过，有时候逼不得已，也得硬着头皮对内核进行一些调试。（比如发现一些异常现象，怀疑是某个系统调用的异常行为在作祟时）为此，学习一些内核调试技术也是有必要的。

限于个人水平，此篇以操作指南为主，不涉及过多的理论知识——其实是我不懂。

## KProbes 介绍

JProbe 是 KProbes 的一部分。因此，介绍 JProbe 大致应当从 KProbes 开始。

### 游戏的名目

The Name of the Game--- Knuth, *The TeXbook*

KProbes 的名字由字母 K 和 Probes 组合而成。此处，字母 K 表示是「Kernel」的缩写，表示 Linux 内核；英文单词 probe 则是「探测」的意思。因此 KProbes 从名字来说，即是内核探测工具的意思。

### KProbes 的背景

在内核或者内核模块的调试过程中，了解一些函数是否被调用、何时被调用、调用后的执行情况如何、传入参数和返回值分别是什么是很自然的想法。为此，最简单的方法是修改这些函数的源码，在适当的位置打印相关日志。不过，这种方案虽然听起来简单，实际操作时候却不简单：需要重新编译内核。这算是很高的代价了。

KProbes 技术大体上就是为了解决这一需求而设计的。KProbes 允许用户

- 自行定义回调函数；

- 动态地插入或者移除探测点；

- 当内核执行到相关探测点时，KProbes 会调用用户注册的回调函数，待回调函数执行完毕后再继续正常的执行流程。

显而易见，利用 KProbes 的回调函数收集和打印相关信息比上述「简单的方法」代价要小得多了。

### KProbes 的组成

KProbes 提供了三种探测手段：

- KProbe

- JProbe

- KRetProbe

这里，KProbe 最基本也最强大，是后续两种探测手段的基础。KProbe 允许在任意位置放置探测点，例如可以在函数内部某条指令处放置探测点；并且提供了探测点调用前、调用后、访存出错三种情况的回调方式。

- 调用前回调：pre_handler

- 调用后回调：post_handler

- 访存出错回调：fault_handler

JProbe 是本文的重点，它和 KRetProbe 都是在 KProbe 的基础上实现的。JProbe 的探测点在函数入口处，可用于收集函数的参数；KRetProbe 则顾名思义，其探测点在函数出口处，可用于收集函数的返回值。

### 硬件依赖

从前面的描述不难看出，KProbes 这类技术一方面需要在某些时候让内核执行流程陷入到用户注册的回调函数中，另一方面需要单步执行被探测点的指令。因此，KProbes 对硬件平台是有依赖的。前者依赖 CPU 的异常处理，而后者依赖单步调试技术。

在目前主流的 i386, x86_64, arm 等平台上，KProbes 已经能较好地工作。在其它平台上，KProbes 则可能只实现了部分功能。具体则需要查看内核相关文档：Documentation/kprobes.txt。

### KProbes 的一些限制

- KProbes 允许在同一个位置注册多个 KProbe 探测点，但是不能注册多个 JProbe 探测点。

- JProbe 不能以 JProbe 的回调函数或者 KProbe post_handler 作为探测点。

- KProbes 可以于包括中断处理函数在内的几乎所有函数中注册探测点，但是不能在 KProbes 自身的相关函数中注册探测点（定义在 kernel/kprobes.c 以及 arch/*/kernel/kprobes.c 中的函数），以及不能在 do_page_fault 和 notifier_call_chain 中注册探测点。

- KProbes 的探测依赖函数调用，因此在内联函数或者可能被内联的函数中注册探测点可能失效。

- KProbes 的各种回调函数会关闭内核抢占，甚至依平台不同关闭终端，因此在回调函数中不应调用会放弃当前 CPU 时间片的函数（例如互斥量相关函数）。

## JProbe 使用方法

### 回调函数

首先我们要明确，我们希望利用 JProbe 做什么，也就是 JProbe 的回调函数应该如何实现。

我们假设有这样一个任务：关注某一个进程在调用 Linux 虚拟文件系统的 write 操作时，打印其进程 ID (PID)，并打印参数中的偏移量。假设这个进程的名字是 "liam_test"。考虑到我们要在 vfs_write 函数的入口处做探测，我们需要实现的回调函数其实是 vfs_write 的一个代理，因此它的参数应当与 vfs_write 完全一致。因此有如下实现。

```c
ssize_t jvfs_write(struct file *file, const char __user *buf, size_t count, loff_t *pos) {
    if (!strcmp("liam_test", current->comm)  /* we're in the program `liam_test` */  ) {
        printk(KERN_INFO "pid: %u, pos: %lld.\n", current->pid, *pos);
    }
    jprobe_return();
    return 0;
}
```

注意这里涉及了 jprobe_return() 这个 JProbe API。在回调函数执行完毕以后，必须调用该函数，如此执行流才会回到正常的执行路径中去。

### JProbe 结构体

实现好了回调函数之后，我们来看如何用 JProbe 结构体，将回调函数和被探测的函数关联起来。

```c
/*
 * Special probe type that uses setjmp-longjmp type tricks to resume
 * execution at a specified entry with a matching prototype corresponding
 * to the probed function - a trick to enable arguments to become
 * accessible seamlessly by probe handling logic.
 * Note:
 * Because of the way compilers allocate stack space for local variables
 * etc upfront, regardless of sub-scopes within a function, this mirroring
 * principle currently works only for probes placed on function entry points.
 */
struct jprobe {
    struct kprobe kp;
    void *entry;    /* probe handling code to jump to */
};
```

结构体本身非常简单，内里只有一个 struct kprobe 和一个 void* 指针。前者说明 JProbe 是基于 KProbe 实现的，后者保存回调函数的入口。为此我们还需要查看 struct kprobe 的实现，具体每个成员的含义以注释的形式给出。

```c
struct kprobe {
    /* Hash 表，索引值为被探测点的地址 */
    struct hlist_node hlist;
    /* 同一探测点上多个 kprobe 结构的链表 */
    struct list_head list;
    /* 记录当前 probe 被暂时放弃的计数器 */
    unsigned long nmissed;
    /* 被探测点的地址 */
    kprobe_opcode_t *addr;
    /* 被探测函数的名字 */
    const char *symbol_name;
    /* 被探测点相对函数入口的偏移量 */
    unsigned int offset;
    /* 被探测点即将被执行时的回调函数 */
    kprobe_pre_handler_t pre_handler;
    /* 被探测点执行完毕后的回调函数 */
    kprobe_post_handler_t post_handler;
    /* 在执行上述两个回调函数或者单步执行被探测点处指令时出现访存错误时的回调函数 */
    kprobe_fault_handler_t fault_handler;
    /* 在上述三个回调函数执行过程中，若触发断点指令，则调用该回调函数 */
    kprobe_break_handler_t break_handler;
    /* 断点处的原始指令 */
    kprobe_opcode_t opcode;
    /* 上述原始指令的拷贝，被用于单步执行 */
    struct arch_specific_insn ainsn;
    /* 该 probe 的状态标记 */
    u32 flags;
};
```

因此，对于一个典型的 JProbe 任务（探测 vfs_write 函数的传入参数），我们通常会设置这样的结构体。

```c
static struct jprobe write_stub = {
    .kp = {
        .symbol_name = "vfs_write",
    },
    .entry = jvfs_write,
};
```

这样的结构体表示我们希望在 vfs_write 这个符号（对应内核的 vfs_write() 函数）的入口处进行探测，探测时的回调函数是 jvfs_write。注意，[当函数名被用作值时，它等价于一个指针](/2017/02/05/pointer-in-C-and-Cpp/)。这样，我们就通过 write_stub 这个 struct jprobe 将回调函数和被探测函数关联起来了。

### 注册与卸载

接下来的工作，就是要向系统内核注册我们实现的 JProbe 了。为此，我们需要实现两个函数 jprobe_init 和 jprobe_exit。

```c
static int __init jprobe_init(void) {
    int ret;
    ret = register_jprobe(&write_stub);
    if (ret < 0) {
        printk(KERN_INFO "register_jprobe failed, returned %d\n", ret);
        return -1;
    }
    printk(KERN_INFO "Planted jprobe at %p, handler addr %p\n",
                       write_stub.kp.addr, write_stub.entry);
    return 0;
}

static void __exit jprobe_exit(void) {
    unregister_jprobe(&write_stub);
    printk(KERN_INFO "jprobe at %p unregistered\n", write_stub.kp.addr);
}
```

此处 jprobe_init 和 jprobe_exit 两个函数的名字可以自由更改，重点是其中调用的 register_jprobe 和 unregister_jprobe 两个 JProbe API。JProbe 中，注册与卸载相关的 API 有如下一些。

```c
/* 向内核注册 JProbe 探测点 */
int register_jprobe(struct jprobe *jp)
/* 卸载 JProbe 探测点 */
void unregister_jprobe(struct jprobe *jp)
/* 向内核注册多个 JProbe 探测点 */
int register_jprobes(struct jprobe **jps, int num)
/* 卸载多个 JProbe 探测点 */
void unregister_jprobes(struct jprobe **jps, int num)
/* 暂停指定探测点 */
int disable_jprobe(struct jprobe *jp)
/* 恢复指定探测点 */
int enable_jprobe(struct jprobe *jp)
```

### 实现为内核模块

为了将我们的代码插入内核，我们需要将 JProbe 探测点实现为内核模块。为此我们需要调用一些内核宏。

```c
module_init(jprobe_init)
module_exit(jprobe_exit)
MODULE_AUTHOR("Liam Huang");
MODULE_DESCRIPTION("Print information of \"vfs_write\", when current process command name is \"liam_test\"");
MODULE_LICENSE("GPL");
```

### 编译内核模块

完整的 write_stub.c 文件应当如下。

```c
#include <linux/module.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kprobes.h>

ssize_t jvfs_write(struct file *file, const char __user *buf, size_t count, loff_t *pos) {
    if (!strcmp("liam_test", current->comm)  /* we're in the program `liam_test` */  ) {
        printk(KERN_INFO "pid: %u, pos: %lld.\n", current->pid, *pos);
    }
    jprobe_return();
    return 0;
}

static struct jprobe write_stub = {
    .kp = {
        .symbol_name = "vfs_write",
    },
    .entry = jvfs_write,
};

static int __init jprobe_init(void) {
    int ret;
    ret = register_jprobe(&write_stub);
    if (ret < 0) {
        printk(KERN_INFO "register_jprobe failed, returned %d\n", ret);
        return -1;
    }
    printk(KERN_INFO "Planted jprobe at %p, handler addr %p\n",
                       write_stub.kp.addr, write_stub.entry);
    return 0;
}

static void __exit jprobe_exit(void) {
    unregister_jprobe(&write_stub);
    printk(KERN_INFO "jprobe at %p unregistered\n", write_stub.kp.addr);
}

module_init(jprobe_init)
module_exit(jprobe_exit)
MODULE_AUTHOR("Liam Huang");
MODULE_DESCRIPTION("Print information of \"vfs_write\", when current process command name is \"liam_test\"");
MODULE_LICENSE("GPL");
```

我们编写如下 Makefile，以便调用 make 来将源码编译为内核模块。

```plaintext
obj-m +=write_stub.o
KDIR= /lib/modules/$(shell uname -r)/build
all:
        $(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules
clean:
           rm -rf *.o *.ko *.mod.* .c* .t*
```

此时调用 make 即可编译得到内核模块 write_stub.ko。

```bash
$ make
make -C /lib/modules/2.6.32-2.0.0.8-6/build SUBDIRS=/home/Yuuki/test/c modules
'make[1]: Entering directory `/usr/src/kernels/2.6.32-220.7.1.el6.2.0.0.8.x86_64'
  Building modules, stage 2.
  MODPOST 1 modules
make[1]: Leaving directory `/usr/src/kernels/2.6.32-220.7.1.el6.2.0.0.8.x86_64'
$ ls
delay_stub.c  delay_stub.ko  delay_stub.ko.unsigned  delay_stub.mod.c  delay_stub.mod.o  delay_stub.o  Makefile
```

### 热插拔内核模块

Linux 提供了 insmod 和 rmmod 两个命令来热插拔内核模块。因此，在 insmod write_stub.ko 之后，名为 "liam_test" 的程序调用 vfs_write 就会在内核信息中打印 PID 和相关参数了；而在 rmmod write_stub.ko 之后，则可以将该模块从内核中卸载。

```bash
$ lsmod
Module                  Size  Used by
tcp_diag                1041  0
inet_diag               8703  1 tcp_diag
fuse                   66726  2
# ...
$ sudo insmod write_stub.ko
$ lsmod
Module                  Size  Used by
delay_stub              1346  0
tcp_diag                1041  0
inet_diag               8703  1 tcp_diag
fuse                   66726  2
# ...
```

需要注意的是，这种做法需要内核支持。具体来说，内核必须打开如下编译选项

- CONFIG_KPROBES: 以便支持 KProbes；

- CONFIG_MODULES：以便支持模块动态加载；

- CONFIG_MODULE_UNLOAD：以便支持模块动态卸载。

你可以在 /boot/config-XXX 中找到内核编译选项的记录，以检查你的内核是否打开了上述选项。