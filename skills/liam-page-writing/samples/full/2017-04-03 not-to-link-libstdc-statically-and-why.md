---
title: "为什么不能在动态库里静态链接？"
url: https://liam.page/2017/04/03/not-to-link-libstdc-statically-and-why/
date: 2017-04-03
categories: ["Algorithm and Computer Science"]
tags: ["Linking", "Loading", "Static", "Dynamic", "Shared Object"]
---

因为各种复杂的原因，工作中遇到了某个模块当中的一个动态库（Linux Dynamic Shared Object，我们称其为 A.so）需要使用与整个模块不同版本的 gcc 进行编译。由于 A.so 使用了高版本 libstdc++.so 中提供的接口；因此，如果让 A.so 与整个模块运行在同一个环境（即，依赖同一个低版本的 libstdc++.so），那么，整个程序运行时将会由动态链接器提示「找不到符号」的错误。

一个「看似」可行的解决办法，是在编译 A.so 的时候，将对应的高版本的 libstdc++ 以静态的方式链接到 A.so 里面。这样，如果能把来自高版本 libstdc++.a 的符号隐藏起来（不暴露给动态链接器，避免符号冲突），那么就可以解决问题了。

然而，这个解决办法，实际上是不可行的。本文将分析为什么不可行。

## 静态链接的优缺点

总结起来，静态链接有如下优点

- 得到单一的文件，可以拷贝到所有体系结构相同的操作系统上运行；

- 对环境的依赖少，在缺少相应动态库的环境里也可以运行；

- 因为减少了动态链接的步骤，所以运行起来会快一些（某些情况下）；

- 因为在链接时，链接器可以看到所有符号，并进行符号解析，所以链接器可以硬编码函数的入口地址，故而函数调用会快一些；

- 因为在链接时，链接器可以看到所有的符号，所以链接器可以优化删除一些没有被引用的符号，一定程度上减小编译出的文件的体积；

- 能够明确地知道程序使用的依赖库的版本，而无需担心 LD_LIBRARY_PATH/LD_PATH 的影响。

当然，静态链接也会有缺点（反过来就是动态链接的优点）

- 因为要把所有的符号都打包在一个文件当中，所以文件的体积会显著增大；

- 对于依赖的动态库，不论内存中是否有已经载入的副本（特别是 .text 段），对于静态链接的程序，这部分指令都必须重复载入内存，因此内存会消耗得很快；

- 对于依赖的动态库，但凡有任何更新，升级程序都必须整个编译、发布走一圈，无法简单地替换 .so 升级。

## 对装载的影响

上述优缺点，实际是站在一个非常 general 的角度对静态链接和动态链接的讨论。在本篇开头处提及的问题，实际上就是希望用到最后一条优点，让 A.so 引用指定版本的 libstdc++。

但是，在链接生成动态链接库的时候，静态链接依赖另一个静态库，是一种非常规的方法。实际上，这是一种不可行的方法。

为了说明这个问题，我们需要对程序装载进内存的过程做一个简单的梳理。

当我们在 Linux bash 当中执行命令启动一个进程的时候，bash 实际上会先做一个 fork() 系统调用，而后在子进程里做一个 execve() 系统调用执行指定的 ELF 可执行文件，原先的进程则返回等待。GLIBC 对 execve() 系统调用做了封装，提供了诸如 execlp() 的函数；但这些函数内里都会去执行 execve() 系统调用。

以下代码实现了一个简单的 minibash，模拟展示了启动一个进程的过程。

```c
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

const size_t buf_size = 1024;

int main () {
    char buf[buf_size] = {0};
    pid_t pid;
    while (1) {
        printf("minibash $ ");
        scanf("%s", buf);
        pid = fork();
        if (0 == pid) {
            if (execlp(buf, 0) < 0) {
                printf("exec error\n");
            }
        } else if (pid > 0) {
            int status;
            waitpid(pid, &status, 0);
        } else {
            pritnf("fork error %d\n", pid);
        }
    }
    return 0;
}
```

当执行到 execve() 系统调用时，就会进入到对应的 sys_execve() 入口。这标志着由用户态向内核态的转变，同时也标志着装载的开始。对于 ELF 可执行文件，之后的调用顺序是

- sys_execve() - 进行参数检查；

- do_execve() - 找到可执行文件，读取头部的 128 字节（用以判断可执行文件的类型，例如 ELF 可执行文件的前两个字节是 0x7F，即 ELF）；

- load_elf_binary()
检查文件格式
寻找 .interp 段，设置动态链接器的路径
设置 ELF 各个段（section）对 VMA 的段（segment）的映射关系
初始化 ELF 的进程环境
返回入口地址（静态链接程序：e_entry，动态链接程序：动态链接器）

之后，系统将从内核态转回用户态，并且将控制权交给上述入口地址的指令。对于静态链接的程序来说，e_entry 记录的是整个程序的入口；从内核态转回到用户态之后，进程就从此开始执行。对于动态链接的程序来说，它们的入口是系统提供的动态链接器；从内核态转回到用户态之后，系统将控制权交给动态链接器，由动态链接器完成动态链接过程，而后再跳转到整个程序的真正入口。动态链接器大致完成这些工作：

- 启动动态链接器本身，完成自举（Bootstrap）；

- 装载所有依赖的动态库（通常是广度优先遍历，但也可以是深度优先遍历）；

- 处理全局符号表，完成重定位和初始化；

- 将系统控制权交给程序的真正入口。

关于链接、装载的详细内容，可以期待「程序员的自我修养」系列文章。

注意到，我们的模块依赖了 A.so。那么，毫无疑问，这是一个动态链接的程序。我们应该注意到，在进程装载的过程中，首先会完成所有可执行 ELF 文件本身的装载（ELF 到虚存空间的映射），而后才会进入到动态链接库的装载。此外，在动态链接库的装载过程中，动态链接库只会处理以来的动态库（Dynamic Shared Objects，即各种 .so 文件）。也就是说，动态链接程序的装载过程可以分成两个步骤：

- 装载可执行 ELF 文件静态链接的部分；

- 装载所有依赖的 .so 部分。

我们注意到，被 .so 依赖的静态库 .a 是没有机会被装载进内存的。因此，在生成 A.so 的过程中，将 libstdc++.a 静态链接进去，是不可行的。因为，这部分静态链接的指令永远没有机会被装载进进程空间执行。因此，若要解决这个问题，就只有将 libstdc++.a 解包成各个普通的目标文件 .o，而后使用链接器 ld 将这些目标文件链接打包进 A.so 当中。

## 符号冲突

现在，我们将 libstdc++ 的各个目标文件都链接进了 A.so。那么，A.so 当中会包含 libstdc++ 中的所有符号。

现在的问题是，几乎所有的使用 C++ 编写的可执行程序，都会直接或者间接地依赖 libstdc++.so。因此，当动态链接器尝试装载 libstdc++.so 和 A.so 的时候，就会有大量来自 libstdc++ 的符号重复了。这就牵扯到了所谓**全局符号调解（Global Symbol Interpose）**的问题。

对于 Linux 下的动态链接器，全局符号调解的策略很简单：先读入全局符号表的符号生效，后读入的符号被直接忽略丢弃。

因此，在这种情况下，我们无法预见整个模块使用的 libstdc++ 究竟是来自于系统环境，还是来自于 A.so 中包含的那些部分。因为，这取决于动态链接器装载动态库的顺序。

为此，我们需要在链接生成 A.so 的时候，将 libstdc++ 所含的那些符号隐藏起来。

## 全局变量更新导致的运行时问题

我们回顾一下，至此我们做了这些事情：

- 将 libstdc++.a 解包成各个 .o 文件；

- 将来自 libstdc++ 的各个 .o 文件，编译进 A.so，并隐藏这些符号。

至此，我们的程序在链接和装载的过程中，不会遇到任何问题——系统能够正常地将控制权交给模块真正的入口了。但是，如此解决方案仍然有问题。

众所周知，诸如 libstdc++/libpthread 这些库，会在进程空间自行维护一套全局变量和数据结构，用于维护和记录当前的运行状态。很多第三方库，也会有类似的全局变量和数据结构。现在，我们为了使得两个版本的 libstdc++（来自系统环境的，以及来自 A.so 的）在符号的层面上得以共存，就引起了这样的问题：整个进程空间里，这些全局变量和数据结构存在了两份。比如

- 文件描述符（FD，File Description)；

- 内存边界；

- 错误码 errorno；

- libpthread 的定时器等。

这样一来，在这些全局变量和数据结构的角度，进程在运行时就会出现很多自相矛盾的状态；甚至直接引起运行时异常。而因为全局变量和数据结构存在两份，这些问题在追查的过程中会极其困难。

回顾整个过程，我们不难发现，这样的需求会产生很多问题。尽管从编译、链接、装载的角度，我们可以用一些很 tricky 的方法解决问题；但是，等到程序执行过程中，仍然可能会隐藏各种难以发现、解决的问题。因此，我们说**不应该尝试向动态库静态编译标准库或第三方库**。

## 附录：如何将依赖的库静态链接进可执行程序

我们先来看一个耳熟能详的 Hello world! 程序。

```c++
#include <iostream>

using std::cout;
using std::endl;

int main() {
    cout << "Hello world!" << endl;
    return 0;
}
```

众所周知，如果要将它编译为可执行程序，只需要执行 g++ hello.cpp -o hello 就可以了。在这个过程中，g++ 这个命令，隐藏了编译、链接的细节。我们在这里把步骤拆开，依次进行。

首先，我们对其进行编译。

```bash
$ g++ -c hello.cpp -o hello.o
```

在这里，-c 参数告知 g++ 命令，我们只希望编译就可以了，之后的链接不要自动执行。

我们知道，编译器会将代码中的函数、变量等，翻译成一个个的符号（symbol）。我们可以用 nm 命令，查看 hello.o 当中包含了哪些符号。而后可以用 c++filt 命令，查看符号背后对应的函数签名或者变量名。

```bash
$ nm hello.o | wc -l
14
$ nm hello.o
000000000000003e t _GLOBAL__I_main
0000000000000000 t _Z41__static_initialization_and_destruction_0ii
                 U _ZNSolsEPFRSoS_E
                 U _ZNSt8ios_base4InitC1Ev
                 U _ZNSt8ios_base4InitD1Ev
                 U _ZSt4cout
                 U _ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
0000000000000000 b _ZSt8__ioinit
                 U _ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
                 U __cxa_atexit
                 U __dso_handle
                 U __gxx_personality_v0
0000000000000054 t __tcf_0
000000000000006c T main
$ c++filt _Z41__static_initialization_and_destruction_0ii
__static_initialization_and_destruction_0(int, int)
```

我们看到，hello.o 当中，只有 14 个符号。并且，在这些符号中，有很多是未定义的符号——第二列提示 U 表示未定义。这表明，hello.o 用到了这些符号，但是这些符号对应的函数、变量，定义在其他目标文件当中。

接下来我们执行链接这一步。

```bash
$ g++ hello.o -o hello
$ ./hello
Hello world!
$ nm hello | wc -l
49
$ nm hello
0000000000600ae8 d _DYNAMIC
0000000000600cb0 d _GLOBAL_OFFSET_TABLE_
0000000000400816 t _GLOBAL__I_main
0000000000400958 R _IO_stdin_used
                 w _Jv_RegisterClasses
00000000004007d8 t _Z41__static_initialization_and_destruction_0ii
                 U _ZNSolsEPFRSoS_E@@GLIBCXX_3.4
                 U _ZNSt8ios_base4InitC1Ev@@GLIBCXX_3.4
                 U _ZNSt8ios_base4InitD1Ev@@GLIBCXX_3.4
...
0000000000400844 T main
```

经过链接之后，可执行文件 hello 当中的符号多了不少：从 14 个增加到了 49 个。这说明，经过链接之后，可执行文件补充了一些执行过程中需要的符号。但是我们也看到，在 hello 当中，仍然存在被标记为 U 的未定义的符号。这说明，hello 在运行时仍旧会动态地依赖系统中的动态库。我们可以用 ldd 命令查看一个 ELF 文件依赖的动态库。

```bash
$ ldd hello
        linux-vdso.so.1 =>  (0x00007fffb3bfd000)
        libstdc++.so.6 => /opt/gcc/lib64/libstdc++.so.6 (0x00002ada4968e000)
        libm.so.6 => /lib64/libm.so.6 (0x0000003576c00000)
        libgcc_s.so.1 => /opt/gcc/lib64/libgcc_s.so.1 (0x00002ada49996000)
        libc.so.6 => /lib64/libc.so.6 (0x0000003576000000)
        /lib64/ld-linux-x86-64.so.2 (0x0000003575c00000)
```

这里

- linux-vdso.so.1 是 Linux 的一个内核模块；

- libstdc++.so.6 是 C++ 标准库对应的动态库；

- libm.so.6/libgcc_s.so.1/libc.so.6 都是 gcc 相关的动态库；

- /lib64/ld-linux-x86-64.so.2 则是动态链接器对应的动态库（实际上也是一个可执行的 ELF）。

如果想要将这些依赖的动态库对应的符号，都静态链接到可执行文件中的话，则需要在链接的时候加上 -static 参数。

```bash
$ g++ hello.o -o hello -static
$ ./hello
Hello world!
$ nm hello | wc -l
4425
$ ldd hello
        not a dynamic executable
$ nm hello | grep " U "
                 U __tls_get_addr
```

我们看到，相对不加 -static 参数的版本，新的 hello 多出了四千多个符号；并且，以 ldd 查看 hello 依赖的动态库，命令提示 hello 没有依赖其他的动态库；最后，我们发现，hello 的所有符号中，仅有 __tls_get_addr 是未定义的。

tls 是 Thread Local Storage 的缩写，__tls_get_addr() 接收一个参数（数据结构 tls_index 的起始地址），返回一个 Thread Local Variable 的在当前段的偏移量和长度。这个函数是专为动态链接器设计的，在静态链接时这个符号对应的函数无意义（参见 ELF/SymbolTable.cpp）。

因此，我们说，对于静态链接版本的 hello 来说，它已经包含了运行所需的所有符号。

若是想要静态链接 libstdc++，其他的部分依然保留动态链接，则可以使用 g++ 的参数 -static-libstdc++。

```bash
$ g++ hello.o -o hello -static-libstdc++
$ ./hello
Hello world!
$ ldd hello
        linux-vdso.so.1 =>  (0x00007fffcd5fd000)
        libm.so.6 => /lib64/libm.so.6 (0x0000003576c00000)
        libgcc_s.so.1 => /opt/gcc/lib64/libgcc_s.so.1 (0x00002b6ccb401000)
        libc.so.6 => /lib64/libc.so.6 (0x0000003576000000)
        /lib64/ld-linux-x86-64.so.2 (0x0000003575c00000)
$ nm hello | wc -l
3022
$ nm hello | grep " U " | grep -v GLIBC | grep -v GCC
```

可以看到，使用 -static-libstdc++ 之后，hello 不再依赖 libstdc++.so 了。同时，其中包含的符号相比动态链接 libstdc++ 的版本要多出不少，而相对完全静态链接的版本又少了不少；介于二者之间。此外，我们也验证了，hello 中包含的未定义的符号，除开 GLIBC 和 GCC 相关的符号之外，就没有了。