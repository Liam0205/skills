---
title: "gperftools 中 CPU Profiler 不工作问题的解法"
url: https://liam.page/2020/06/22/CPU-Profiler-in-gperftools-not-working/
date: 2020-06-22
categories: ["Algorithm and Computer Science"]
tags: ["gperftools", "CPU Profiler"]
---

为了分析服务性能瓶颈，今次我们计划用 gperftools 当中的 CPU Profiler 来打印服务当中的性能热点。按[官网介绍](https://gperftools.github.io/gperftools/cpuprofile.html)，以下三种方式之一，可开启 CPU Profiler。

- 运行时，用 LD_PRELOAD 环境变量加载 CPU Profiler 的共享对象（动态库）。例如 env LD_PRELOAD="/usr/lib/libprofiler.so" /path/to/elf_bin。

- 链接时，加上 -lprofiler（或者 -ltcmalloc_and_profiler，如果还需要 TCMalloc 的话），而后在运行时通过 env CPUPROFILE=foo.prof /path/to/elf_bin 将性能分析文件写入 foo.prof。

- 在加上链接参数 -lprofiler 的基础上，在代码内引入头文件 #include <gperftools/profiler.h>，而后在需要分析性能的代码块前后加上 ProfilerStart("/path/to/foo.prof") 及 ProfilerStop()。

这里 (1) 不需要重新编译，但是一看就很山寨；(3) 在分析特定代码片块的性能时很有效，但在意图分析整个程序的性能时就很鸡肋。目光集中在 (2) 上面。

尝试 (2) 时，遇到一个问题。不管如何设置 CPUPROFILE，程序都不会将性能分析文件转储出来。

经过分析，原因水落石出。链接器在链接 libprofiler 时，会根据程序中的符号引用情况，将未被引用的符号都删掉。由于我们的代码里，没有引用任何 CPU Profiler 的函数，相当于整个 libprofiler 其实没有被链入程序当中。

为解决这个问题，最标准的解法，是在 -lprofiler 前后加上链接器参数，抑制这种行为：--no-as-needed 和 --as-needed。

如果因为种种原因，无法给链接器传参，则可考虑在 main 函数返回之前，加入这段代码：

```cpp
volatile bool tmp = false;
if (tmp) ProfilerStop();
```

这里，布尔变量 tmp 被 volatile 修饰，因而编译器不会将其优化掉。而因为我们没有机会改变 tmp 的值，所以 ProfilerStop() 没有机会被执行。但是，虽然我们知道这一点，但编译器并不知道。因此，在得到的目标文件之中，会有针对 ProfilerStop 及相关符号的引用。这样，哪怕不加 --no-as-needed 和 --as-needed 参数，链接器也会将需要的符号链入程序当中。