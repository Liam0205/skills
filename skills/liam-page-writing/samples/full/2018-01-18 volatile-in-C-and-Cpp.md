---
title: "谈谈 C/C++ 中的 volatile"
url: https://liam.page/2018/01/18/volatile-in-C-and-Cpp/
date: 2018-01-18
categories: ["Algorithm and Computer Science"]
tags: ["C++", "C", "volatile"]
---

最近在讨论多线程编程中的一个可能的 false sharing 问题时，有人提出加 volatile 可能可以解决问题。这种错误的认识荼毒多年，促使我写下这篇文章。

## 约定

Volatile 这个话题，涉及到计算机科学多个领域多个层次的诸多细节。仅靠一篇博客，很难穷尽这些细节。因此，若不对讨论范围做一些约定，很容易就有诸多漏洞。到时误人子弟，就不好了。以下是一些基本的约定：

- 这篇博文讨论的 volatile 关键字，是 C 和 C++ 语言中的关键字。Java 等语言中，也有 volatile 关键字。但它们和 C/C++ 里的 volatile 不完全相同，不在这篇博文的讨论范围内。

- 这篇博文讨论的 volatile 关键字，是限定在 C/C++ 标准之下的。这也就是说，我们讨论的内容应该是与平台无关的，同时也是与编译器扩展无关的。

- 相应的，这篇文章讨论的「标准」指的是 C/C++ 的标准，而不是其他什么东西。

- 我们希望编写的代码是 (1) 符合标准的，(2) 性能良好的，(3) 可移植的。这里 (1) 保证了代码执行结果的正确性，(2) 保证了高效性，(3) 体现了平台无关性（以及编译器扩展等的无关性）。

## 含义

### 单词 volatile 的含义

在谈及 C/C++ 中的 volatile 关键字时，总有人会拿 volatile 这个英文单词的中文解释说事。他们把 volatile 翻译作「易变的」。但事实上，对于翻译来说，很多时候目标语言很难找到一个词能够反映源语言中单词的全部含义和细节。此处「易变的」就无法做到这一点。

Volatile 的意思，若要详细理解，还是应该查阅权威的英英字典。在柯林斯高阶学习词典中，volatile 是这样解释的：

A situation that is volatile is likely to change suddenly and unexpectedly.

这里对 volatile 的解释有三个精髓的形容词和副词，体现了 volatile 的含义。

- likely：可能的。这意味着被 volatile 形容的对象「有可能也有可能不」发生改变，因此我们不能对这样的对象的状态做出任何假设。

- suddenly：突然地。这意味着被 volatile 形容的对象可能发生瞬时改变。

- unexpectedly：不可预期地。这与 likely 相互呼应，意味着被 volatile 形容的对象可能以各种不可预期的方式和时间发生更改。

因此，volatile 其实就是告诉我们，被它修饰的对象出现任何情况都不要奇怪，我们不能对它们做任何假设。

### 程序中 volatile 的含义

对于程序员来说，程序本身的任何行为都必须是可预期的。那么，在程序当中，什么才叫 volatile 呢？这个问题的答案也很简单：程序可能受到程序之外的因素影响。

考虑以下 C/C++ 代码。

```c
volatile int *p = /* ... */;
int a, b;
a = *p;
b = *p;
```

若忽略 volatile，那么 p 就只是一个「指向 int 类型的指针」。这样一来，a = *p; 和 b = *p; 两句，就只需要从内存中读取一次就够了。因为从内存中读取一次之后，CPU 的寄存器中就已经有了这个值；把这个值直接复用就可以了。这样一来，编译器就会做优化，把两次访存的操作优化成一次。这样做是基于一个假设：我们在代码里没有改变 p 指向内存地址的值，那么这个值就一定不会发生改变。

此处说的「读取内存」，包括了读取 CPU 缓存和读取计算机主存。

然而，由于 MMIP（Memory mapped I/O）的存在，这个假设不一定是真的。例如说，假设 p 指向的内存是一个硬件设备。这样一来，从 p 指向的内存读取数据可能伴随着**可观测的副作用**：硬件状态的修改。此时，代码的原意可能是将硬件设备返回的连续两个 int 分别保存在 a 和 b 当中。这种情况下，编译器的优化就会导致程序行为不符合预期了。

总结来说，被 volatile 修饰的变量，在对其进行读写操作时，会引发一些**可观测的副作用**。而这些可观测的副作用，是由**程序之外的因素决定的**。

### 关键字 volatile 的含义

[CPP reference 网站](http://en.cppreference.com/w/Cppreference:FAQ)是对 C 和 C++ 语言标准的整理。因此，绝大多数时候，我们可以通过这个网站对语言标准进行查询。关于 volatile 关键字，有 [C 语言标准](http://en.cppreference.com/w/c/language/volatile)和 [C++ 语言标准](http://en.cppreference.com/w/cpp/language/cv)可查。这里摘录两份标准对 volatile 访问的描述。

C 语言：Every access (both read and write) made through an lvalue expression of volatile-qualified type is considered an observable side effect for the purpose of optimization and is evaluated strictly according to the rules of the abstract machine (that is, all writes are completed at some time before the next sequence point). This means that within a single thread of execution, a volatile access cannot be optimized out or reordered relative to another visible side effect that is separated by a sequence point from the volatile access.C++ 语言：Every access (read or write operation, member function call, etc.) made through a glvalue expression of volatile-qualified type is treated as a visible side-effect for the purposes of optimization (that is, within a single thread of execution, volatile accesses cannot be optimized out or reordered with another visible side effect that is sequenced-before or sequenced-after the volatile access. This makes volatile objects suitable for communication with a signal handler, but not with another thread of execution, see std::memory_order). Any attempt to refer to a volatile object through a non-volatile glvalue (e.g. through a reference or pointer to non-volatile type) results in undefined behavior.

这里首先解释两组概念：值类型和序列点（执行序列）。

值类型指的是左值（lvalue）右值（rvalue）这些概念。关于左值和右值，[前作](/2016/12/11/rvalue-reference-in-Cpp/)有过介绍。简单的理解，左值可以出现在赋值等号的左边，使用时取的是作为对象的身份；右值不可以出现在赋值等号的左边，使用时取的是对象的值。除了 lvalue 和 rvalue，C++ 还定义了其他的值类型。其中，xvalue 大体可以理解为返回右值引用的函数调用或表达式，而 glvalue 则是 lvalue 和 xvalue 之和。

序列点则是 C/C++ 中讨论执行顺序时会提到的概念。对于 C/C++ 的表达式来说，执行表达式有两种类型的动作：(1) 计算某个值、(2) 副作用（例如访问 volatile 对象，原子同步，修改文件等）。因此，如果在两个表达式 E1 和 E2 中间有一个序列点，或者在 C++ 中 E1 于序列中在 E2 之前，则 E1 的求值动作和副作用都会在 E2 的求值动作和副作用之前。关于序列点和序列顺序规则，可以参考：[这里](https://en.wikipedia.org/wiki/Sequence_point)和[这里](http://en.cppreference.com/w/cpp/language/eval_order#Rules)。

因此我们讲，在 C/C++ 中，对 volatile 对象的访问，有编译器优化上的副作用：

- 不允许被优化消失（optimized out）；

- 于序列上在另一个对 volatile 对象的访问之前。

这里提及的「不允许被优化」表示对 volatile 变量的访问，编译器不能做任何假设和推理，都必须按部就班地与「内存」进行交互。因此，上述例中「复用寄存器中的值」就是不允许的。

需要注意的是，无论是 C 还是 C++ 的标准，对于 volatile 访问的序列性，都有单线程执行的前提。其中 C++ 标准特别提及，这个顺序性在多线程环境里不一定成立。

## volatile 与多线程

volatile 可以解决多线程中的某些问题，这一错误认识荼毒多年。例如，在[知乎「volatile」话题下的介绍](https://web.archive.org/save/https://www.zhihu.com/topic/20034193/hot)就是「多线程开发中保持可见性的关键字」。为了拨乱反正，这里先给出结论（注意这些结论都基于本文第一节提出的约定之上）：

- volatile 不能解决多线程中的问题。

- 按照 [Hans Boehm & Nick Maclaren 的总结](http://web.archive.org/web/20180120044239/http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2006/n2016.html)，volatile 只在三种场合下是合适的。
和信号处理（signal handler）相关的场合；
和内存映射硬件（memory mapped hardware）相关的场合；
和非本地跳转（setjmp 和 longjmp）相关的场合。

以下我们尝试来用 volatile 关键字解决多线程同步的一个基本问题：happens-before。

### naïve case

首先我们考虑这样一段（伪）代码。

```cpp
// global shared data
bool flag = false;

thread1() {
    flag = false;
    Type* value = new Type(/* parameters */);
    thread2(value);
    while (true) {
        if (flag == true) {
            apply(value);
            break;
        }
    }
    thread2.join();
    if (nullptr != value) { delete value; }
    return;
}

thread2(Type* value) {
    // do some evaluations
    value->update(/* parameters */);
    flag = true;
    return;
}
```

这段代码将 thread1 作为主线程，等待 thread2 准备好 value。因此，thread2 在更新 value 之后将 flag 置为真，而 thread1 死循环地检测 flag。简单来说，这段代码的意图希望实现 thread2 在 thread1 使用 value 之前执行完毕这样的语义。

对多线程编程稍有了解的人应该知道，这段代码是有问题的。问题主要出在两个方面。其一，在 thread1 中，flag = false 赋值之后，在 while 死循环里，没有任何机会修改 flag 的值，因此在运行之前，编译器优化可能会将 if (flag == true) 的内容全部优化掉。其二，在 thread2 中，尽管逻辑上 update 需要发生在 flag = true 之前，但编译器和 CPU 并不知道；因此编译器优化和 CPU 乱序执行可能会使 flag = true 发生在 update 完成之前，因此 thread1 执行 apply(value) 时可能 value 还未准备好。

### 加一个 volatile 试试？

在错误的理解中，此时就到了 volatile 登场的时候了。

首先我们考虑这样一段（伪）代码。

```cpp
// global shared data
volatile bool flag = false;  // 1.

thread1() {
    flag = false;
    Type* value = new Type(/* parameters */);
    thread2(value);
    while (true) {
        if (flag == true) {  // 2.
            apply(value);
            break;
        }
    }
    thread2.join();
    if (nullptr != value) { delete value; }
    return;
}

thread2(Type* value) {
    // do some evaluations
    value->update(/* parameters */);
    flag = true;
    return;
}
```

这里，在 (1) 处，我们将 flag 声明为 volatile-qualified。因此，在 (2) 处，由于 flag == true 是对 volatile 变量的访问，故而 if-block 不会被优化消失。然而，尽管 flag 是 volatile-qualified，但 value 并不是。因此，编译器仍有可能在优化时将 thread2 中的 update 和对 flag 的赋值交换顺序。此外，由于 volatile 禁止了编译器对 flag 的优化，这样使用 volatile 不仅无法达成目的，反而会导致性能下降。

### 再加一个 volatile 呢？

在错误的理解中，可能会对 value 也加以 volatile 关键字修饰；颇有些「没有什么是一个 volatile 解决不了的；如果不行，那就两个」的意思。

```cpp
// global shared data
volatile bool flag = false;

thread1() {
    flag = false;
    volatile Type* value = new Type(/* parameters */);   // 1.
    thread2(value);
    while (true) {
        if (flag == true) {
            apply(value);
            break;
        }
    }
    thread2.join();
    if (nullptr != value) { delete value; }
    return;
}

thread2(volatile Type* value) {
    // do some evaluations
    value->update(/* parameters */);                    // 2.
    flag = true;
    return;
}
```

在上一节代码的基础上，(1) 将 value 声明为 volatile-qualified。因此 (2) 处对两个 volatile-qualified 变量进行访问时，编译器不会交换他们的顺序。看起来就万事大吉了。

然而，volatile 只作用在编译器上，但我们的代码最终是要运行在 CPU 上的。尽管编译器不会将 (2) 处换序，但 CPU 的乱序执行（out-of-order execution）已是几十年的老技术了；在 CPU 执行时，value 和 flag 的赋值仍有可能是被换序了的（store-store）。

也许有人会说，x86 和 AMD64 架构的 CPU（大多数个人机器和服务器使用这两种架构的 CPU）只允许 store-load 乱序，而不会发生 store-store 乱序；或者在诸如 IA64 架构的处理器上，对 volatile-qualified 变量的访问采用了专门的指令。因而，在这些条件下，这段代码是安全的。尽管如此，使用 volatile 会禁止编译器优化相关变量，从而降低性能，所以也不建议依赖 volatile 在这种情况下做线程同步。另一方面，这严重依赖具体的硬件规范，超出了本文的约定讨论范围。

### 到底应该怎样做？

回顾一下，我们最初遇到的问题其实需要解决两件事情。一是 flag 相关的代码块不能被轻易优化消失，二是要保证线程同步的 happens-before 语义。但本质上，设计使用 flag 本身也就是为了构建 happens-before 语义。这也就是说，两个问题，后者才是核心；如有其他不用 flag 的办法解决问题，那么 flag 就不重要。

对于当前问题，最简单的办法是使用原子操作。

```cpp
// global shared data
std::atomic<bool> flag{false};  // #include <atomic>

thread1() {
    flag = false;
    Type* value = new Type(/* parameters */);
    thread2(value);
    while (true) {
        if (flag == true) {
            apply(value);
            break;
        }
    }
    thread2.join();
    if (nullptr != value) { delete value; }
    return;
}

thread2(Type* value) {
    // do some evaluations
    value->update(/* parameters */);
    flag = true;
    return;
}
```

由于对 std::atomic<bool> 的操作是原子的，同时构建了良好的内存屏障，因此整个代码的行为在标准下是良定义的。

除此之外，还可以结合使用互斥量和条件变量。

```cpp
// global shared data
std::mutex m;                   // #include <mutex>
std::condition_variable cv;     // #include <condition_variable>
bool flag = false;

thread1() {
    flag = false;
    Type* value = new Type(/* parameters */);
    thread2(value);
    std::unique_lock<std::mutex> lk(m);
    cv.wait(lk, [](){ return flag; });
    apply(value);
    lk.unlock();
    thread2.join();
    if (nullptr != value) { delete value; }
    return;
}

thread2(Type* value) {
    std::lock_guard<std::mutex> lk(m);
    // do some evaluations
    value->update(/* parameters */);
    flag = true;
    cv.notify_one();
    return;
}
```

这样一来，由线程之间的同步由互斥量和条件变量来保证，同时也避免了 while (true) 死循环空耗 CPU 的情况。