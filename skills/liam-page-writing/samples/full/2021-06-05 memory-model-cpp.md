---
title: "程序员的自我修养（十）：C++ 的内存模型"
url: https://liam.page/2021/06/05/memory-model-cpp/
date: 2021-06-05
categories: ["Algorithm and Computer Science"]
tags: ["Atomics", "Memory Model"]
---

上一次写这个系列好像还是 COVID-19 疫情爆发之前。此篇讨论一下 C++ 当中的内存模型。文中内容基本上是 CPP reference 上[对应页面](https://en.cppreference.com/w/cpp/language/memory_model)的翻译，有删减和补充。

内存模型为 C++ 抽象机器定义了计算机内存存储语义。

C++ 程序可用的内存是一个或多个连续的字节序列。每个字节有自己独有的内存地址。

## 字节（Byte）

字节是内存中的最小可寻址单元，由连续的多个比特组成。C++ 中，char/unsigned char/signed char 的对象存储和[值表示](https://en.cppreference.com/w/cpp/language/object)均使用恰好 1 字节。于是，字节中有多少比特，可以通过 [std::numeric_limits<unsigned char>::digits](http://en.cppreference.com/w/cpp/types/numeric_limits)取得。

## 内存位置（Memory Location）

内存位置是

- [标量类型](https://en.cppreference.com/w/cpp/language/type)（算数类型、指针类型、枚举类型或是 std::nullptr_t）的对象；

- 或是，长度不为零的[位域](https://en.cppreference.com/w/cpp/language/bit_field)组成的最长连续序列。

```cpp
struct S {
    char a;     // memory location #1
    int b : 5;  // memory location #2
    int c : 11, // memory location #2 (continued)
          : 0,  // zero-length, as a delimiter of continued sequence of bit-fields
        d : 8;  // memory location #3
    struct {
        int ee : 8; // memory location #4
    } e;
} obj; // The object 'obj' consists of 4 separate memory locations
```

注意：语言中的许多特性会引入额外的内存位置。这些内存位置程序无法访问，而是为编译器实现自行管理。这些特性例如：[引用](https://en.cppreference.com/w/cpp/language/reference)和[虚函数](https://en.cppreference.com/w/cpp/language/virtual)。

## 线程与数据竞争（Thread and data races）

程序中的线程是自 [std::thread::thread](https://en.cppreference.com/w/cpp/thread/thread/thread), [std::async](https://en.cppreference.com/w/cpp/thread/async) 或者其他方式调用顶层函数开始的控制流。

任一线程都可能访问程序中的任意对象。其中，原子及[线程内部存储](https://en.cppreference.com/w/cpp/language/storage_duration)亦可能为其它线程通过指针或引用来访问。

在没有同步或阻塞的情况下，不同线程可并发访问（读/写）不同内存位置。

若一个表达式求值对某一内存位置进行写操作，而另一求值过程对同一内存位置进行读或写操作，则两个求值过程存在冲突。除非满足下列条件，程序中冲突的求值操作将引发数据竞争：

- 存在冲突的求值操作在同一线程中执行，或在同一[信号处理函数](https://en.cppreference.com/w/cpp/utility/program/signal#Signal_handler)中执行；或者

- 存在冲突的求值操作均是原子操作（参见 [std::atomic](https://en.cppreference.com/w/cpp/atomic/atomic)）；或者

- 存在冲突的求值操作，其一先于（happens-before）另一发生（参见 [std::memory_order](https://en.cppreference.com/w/cpp/atomic/memory_order)）。

数据竞争将导致未定义行为。

```cpp
int cnt = 0;
auto f = [&]{ cnt++; };
std::thread t1{f}, t2{f}, t3{f};  // undefined behavior
```

```cpp
std::atomic<int> cnt{0};
auto f = [&]{ cnt++; };
std::thread t1{f}, t2{f}, t3{f};  // OK, by using atomic variable
```

特别地，对于同一个 [std::mutex](https://en.cppreference.com/w/cpp/thread/mutex)，在一个线程中释放它与在另一线程中获取它是同步的（synchronized-with），故而释放动作先于（happens-before）获取动作。因此，可用 std::mutex 来避免数据竞争。

```cpp
int cnt{0};
std::mutex mtx;
auto f = [&]{ std::lock_guard<std::mutex> lk(mtx); cnt++; };
std::thread t1{f}, t2{f}, t3{f};  // OK, by using mutex to ensure happens-before semantic
```

## 内存顺序（Memory Order）

线程自某个内存位置取值时，读到的可能是它的初始值，也可能是当前线程写入的值，亦可能是其他线程写入的值。有关内存顺序的细节可参见 [std::memory_order](https://en.cppreference.com/w/cpp/atomic/memory_order)；其中讨论了线程的写入操作在其他线程可见性的问题。

## 前向执行（Forward Progress）

### 无阻塞（Obstruction freedom）

仅有一个未被标准库函数阻塞的线程在执行无锁[原子函数（atomic function）](https://en.cppreference.com/w/cpp/atomic)时，该原子函数必能执行完毕（标准库内所有无锁操作均[无阻塞](obstruction-free)）。

### 无锁（Lock freedom）

一个或更多无锁原子函数并发执行时，至少其中之一必能执行完毕（标准库内所有无所操作均[无锁](https://en.wikipedia.org/wiki/Non-blocking_algorithm#Lock-freedom)——编译器实现会保证它们不会被一直锁住，例如持续地被窃走缓存行（cache-line stealing；一种因为执行其他线程的 CPU 核心对内存数据做预取而导致当前 CPU 核心缓存行变脏的现象））。

关于 cache-line stealing，参见：[这篇论文](https://www.researchgate.net/publication/221497089_Tackling_Cache-Line_Stealing_Effects_Using_Run-Time_Adaptation)。

### 执行之担保（Progress guarantee）

在正确的 C++ 程序当中，所有线程终将执行到下列情形之一：

- 终止；

- 调用 I/O 库的函数；

- 经由[易变（volatile）](https://en.cppreference.com/w/cpp/language/cv)的左值（lvalue）或者将亡值（xvalue）——拥有内存地址的长寿对象——访问外部设备；

- 执行原子操作或是同步操作。

若一个线程执行上述任一操作（I/O, volatile, 原子操作或是同步操作），或是阻塞在标准库函数当中，亦或是因其他为阻塞线程正在并发执行导致调用一个无锁原子操作却尚未完成，则称该线程有进展（make progress）。

### 并发前向执行（Concurrent forward progress; since C++17）

若某线程有并发前向执行之担保（concurrent forward progress guarantee），则在它终止之前，无论其他线程（若有）是否有进展，它都将于有限时间内取得如上定义之进展（make progress）。

C++ 标准鼓励（但并不强求）主线程和其他由 std::thread 启动的线程提供并发前向执行之担保。

### 并行前向执行（Parallel forward progress; since C++17）

若某线程有并行前向执行之担保（parallel forward progress guarantee），则

- 在它尚未执行任何步骤（I/O, volatile, 原子操作或是同步操作）时，编译器实现不保证它在有限时间内有进展；

- 而一旦它执行了某一步骤，它提供并发前向执行之担保。

此规则表明，线程池中的线程可以按照任意顺序执行任务。

### 弱并行前向执行（Weakly parallel forward progress; since C++17）

若某线程有弱并行前向执行之担保（weakly parallel forward progress guarantee），则无论其他线程是否有进展，它都不保证它在有限时间内有进展。