---
title: "程序员的自我修养（⑫）：C++ 的内存顺序·中"
url: https://liam.page/2021/12/11/memory-order-cpp-02/
date: 2021-12-11
categories: ["Algorithm and Computer Science"]
tags: ["Atomics", "Memory Model", "Memory Order"]
---

前两篇（[内存模型](/2021/06/05/memory-model-cpp/)与[内存顺序·上](/2021/06/06/memory-order-cpp-01/)）翻译了 CPPreference 上关于内存模型和内存顺序的概念，务虚伦理较多。此篇继续相关讨论，虽仍主要是[对应页面](https://en.cppreference.com/w/cpp/atomic/memory_order)的翻译，但会展开做一些讨论。

## 六种内存顺序标记

C++ 标准库定义了六中内存顺序标记（memory order tag）。他们被定义为一个枚举类型。在 C++11 之后、C++20 之前，定义为：

```cpp
typedef enum memory_order {
    memory_order_relaxed,
    memory_order_consume,
    memory_order_acquire,
    memory_order_release,
    memory_order_acq_rel,
    memory_order_seq_cst
} memory_order;
```

在 C++20 中，则使用新的 enum class 重新定义：

```cpp
enum class memory_order : /*unspecified*/ {
    relaxed, consume, acquire, release, acq_rel, seq_cst
};
inline constexpr memory_order memory_order_relaxed = memory_order::relaxed;
inline constexpr memory_order memory_order_consume = memory_order::consume;
inline constexpr memory_order memory_order_acquire = memory_order::acquire;
inline constexpr memory_order memory_order_release = memory_order::release;
inline constexpr memory_order memory_order_acq_rel = memory_order::acq_rel;
inline constexpr memory_order memory_order_seq_cst = memory_order::seq_cst;
```

我们知道，原子变量上没有数据竞争，从而提供了良定义的多线程并发读写能力。因此，原子变量有可能实际上建立了线程间的同步关系，于是建立了某种先于（happens-before）关系。

在原子操作上添加六种内存顺序标记（中的一部分），会**影响（但不一定改变；视 CPU 架构）原子操作附近的内存访问顺序（包括其他原子操作，亦包含对非原子变量的读写操作）**。注意，内存顺序（通过六种标记）讨论的实际上是线程内原子操作附近非原子操作访问内存的顺序，而非是多线程之间的执行顺序。只不过，因为原子变量自身可能建立了线程间的同步关系，所以**两个线程内各自的内存顺序会经由原子变量的同步建立间接的顺序关系**。亦即，**内存顺序本质上是在讨论单线程内指令执行顺序对多线程影响**的问题。显然，通过添加内存顺序标记，编译器优化和 CPU 指令多发射（multiple issue）、CPU 乱序执行（out-of-order execution）都可能受到一定影响。

所有原子操作默认的内存顺序标记是 std::memory_order_seq_cst，亦即，提供顺序一致性的顺序保证（后续讨论）。目前而言，在绝大多数 CPU 架构上，顺序一致性模型都需要或多或少地在原子操作前后加上内存屏障（memory fence）。因而，顺序一致性虽好，但会损失部分性能。使用其它内存顺序标记则或多或少降低顺序一致性的保证。

标记
作用

memory_order_relaxed
宽松操作：仅保证原子操作自身的原子性，对其他读写操作不做任何同步，亦无顺序上的限制。

memory_order_consume
打上此标记的 load 操作对相关内存位置施加[消费操作（consume operation）](/2021/06/06/memory-order-cpp-01/#%E6%B6%88%E8%B4%B9%E6%93%8D%E4%BD%9C%EF%BC%88consume-operation%EF%BC%89)：当前线程中，所有依赖当前 load 操作读取的值的读写操作不得重排序至当前操作之前。因此，其他线程中相同原子变量释放操作（release operation）依赖的变量的写入，对当前线程是可见的。多数平台上，该标记仅影响编译器优化。

memory_order_acquire
打上此标记的 load 操作对相关内存位置施加[占有操作（aquire operation）](/2021/06/06/memory-order-cpp-01/#%E5%8D%A0%E6%9C%89%E6%93%8D%E4%BD%9C%EF%BC%88aquire-operation%EF%BC%89)：当前线程中，所有读写操作不得重排序至当前操作之前。因此，其他线程中相同原子变量释放操作（release operation）之前的写入，对当前线程是可见的。

memory_order_release
打上此标记的 store 操作对相关内存位置施加[释放操作（release operation）](/2021/06/06/memory-order-cpp-01/#%E9%87%8A%E6%94%BE%E6%93%8D%E4%BD%9C%EF%BC%88release-operation%EF%BC%89)：当前线程中，所有读写操作不得重排至当前操作之后。因此，当前操作所在线程之前的写入操作，在其他线程中，对该原子变量施加占有操作（aquire operation）之后是可见的。也因此，当前操作所在线程中，当前操作所依赖的写入操作，在其他线程中，对该原子变量施加消费操作（consume operation）之后是可见的。

memory_order_acq_rel
打上此标记的 read-modify-write 操作既是占有操作（aquire operation）又是释放操作（release operation）：当前线程中的读写操作不能重排至当前操作之后（如果原本在之前），亦不能重排至当前操作之前（如果原本在之后）。因此，其他线程中相同原子变量释放操作（release operation）之前的写入，对当前 modification 是可见的；该 modification 对其他线程中相同原子变量占有操作（aquire operation）之后亦是可见的。

memory_order_seq_cst
打上此标记的 load 操作对相关内存位置施加占有操作（aquire operation）；打上此标记的 store 操作对相关内存位置施加释放操作（release operation）；打上此标记的 read-modify-write 对相关内存位置施加占有操作（aquire operation）和释放操作（release operation）。此外，对所有线程来说，所有打上该标记的写操作，存在一个全局修改顺序（尽管具体顺序在执行时才确定）。也就是说，对于所有线程来说，看见的这些写操作的顺序是一致的。

## 宽松顺序（Relaxed ordering）

宽松顺序仅保证原子操作自身的原子性，对其他读写操作不做任何同步，亦无顺序上的限制。因此，它们不是同步操作，仅保证原子变量上读写操作的原子性，以及各个原子变量自身修改顺序的一致性（对于同一个变量的两次修改，虽然顺序不一定，但是所有其他线程观察到的修改顺序都是相同的）。

假定 x 和 y 是两个全局变量，均被初始化为零，则下列代码执行完毕之后，存在 r1 == r2 == 42 的可能性。

```cpp
// global
std::atomic<int> x{0}, y{0};

// Thread 1:
r1 = y.load(std::memory_order_relaxed);  // A
x.store(r1, std::memory_order_relaxed);  // B

// Thread 2:
r2 = x.load(std::memory_order_relaxed);  // C
y.store(42, std::memory_order_relaxed);  // D
```

这是因为，虽然在线程 1 和线程 2 之间没有任何同步；于是，对于原子变量 y 的修改顺序（Modification Order）来说，D 可能先于 A 发生；同样，对于原子变量 x 的修改顺序（Modification Order）来说，B 可能先于 C 发生。

宽松顺序的典型场景是不断增加的计数器。计数器的增加只需有原子性的保证，而对同步或是内存顺序没有要去。例如，[std::shared_ptr](https://en.cppreference.com/w/cpp/memory/shared_ptr) 当中的引用计数的增加。实例代码：

```cpp
#include <vector>
#include <iostream>
#include <thread>
#include <atomic>

std::atomic<int> cnt = {0};

void f() {
    for (int n = 0; n < 1000; ++n) {
        cnt.fetch_add(1, std::memory_order_relaxed);
    }
}

int main() {
    std::vector<std::thread> v;
    for (int n = 0; n < 10; ++n) {
        v.emplace_back(f);
    }
    for (auto& t : v) {
        t.join();
    }
    std::cout << "Final counter value is " << cnt << '\n';
    return 0;
}
```

其输出应该是：

```plaintext
Final counter value is 10000
```

不过，对于 std::shard_ptr 当中的引用计数来说，其减少需要与析构函数当中的 load 操作有 acquire-release 的同步。

## 释放-获取顺序（Release-Acquire ordering）

若在线程 A 当中的原子 store 操作被标记上 std::memory_order_release，而若在线程 B 当中相同原子变量的 load 操作被标记上 std::memory_order_acquire，则所有在线程 A 看来先于（happens-before）该 store 操作的那些内存写入（包括非原子变量写入和宽松顺序的原子变量写入），在线程 B 中都有可见副作用（Visible side-effects）。也就是说，一旦线程 B 的原子 load 操作完成，线程 B 可见线程 A 写入内存的所有内容。

这一同步仅只建立在对同一原子变量执行释放操作和获取操作的线程中。其他线程观察到的内存访问顺序可能异于同步的线程之中的任意一个。

在部分强顺序的 CPU 架构中（例如 x86, SPARC TSO, IBM mainframe 等），释放-获取顺序对大多数操作来说都是自动保证的。因此，对于释放-获取顺序的同步来说，无需引入额外的 CPU 指令（来确保内存顺序）；但在编译器优化阶段，仍需加入一些限制（例如：编译器不能将非原子的 store 操作挪到原子 store-release 操作之后；亦不能将非原子的 load 操作挪到原子 load-acquire 操作之前）。

在弱顺序的 CPU 架构中（例如 ARM,Itanium, PowerPC），则需加入额外的 CPU 指令或是内存屏障。

互斥锁（例如 [std::mutex](https://en.cppreference.com/w/cpp/thread/mutex)/[atomic spinlock](https://en.cppreference.com/w/cpp/atomic/atomic_flag)）亦属于释放-获取同步：当锁被线程 A 释放而后被线程 B 获取，则在锁被释放之前临界区中所有对共享变量的写入操作在线程 B 获取锁之后均可见。

下例中，通过原子变量 ptr 建立起了 producer 线程和 consumer 线程之间的获取-释放同步，因此两个 assert 永远不会失败。

```cpp
#include <thread>
#include <atomic>
#include <cassert>
#include <string>

std::atomic<std::string*> ptr{nullptr};
int data{42};

void producer() {
    std::string* p  = new std::string("Hello");
    data = 42;
    ptr.store(p, std::memory_order_release);
}

void consumer() {
    std::string* p2;
    while (nullptr == (p2 = ptr.load(std::memory_order_acquire)));
    assert(*p2 == "Hello"); // never fires
    assert(data == 42); // never fires
}

int main() {
    std::thread t1(producer);
    std::thread t2(consumer);
    t1.join(); t2.join();
    return 0;
}
```

下例则展示了在三个线程之中，获取-释放顺序的传递。

```cpp
#include <thread>
#include <atomic>
#include <cassert>
#include <vector>

std::vector<int> data;
std::atomic<int> flag = {0};

void thread_1() {
    data.push_back(42);
    flag.store(1, std::memory_order_release);
}

void thread_2() {
    int expected = 1;
    while (!flag.compare_exchange_strong(expected, 2, std::memory_order_acq_rel)) {
        expected = 1;
    }
}

void thread_3() {
    while (flag.load(std::memory_order_acquire) < 2);
    assert(data.at(0) == 42); // will never fire
}

int main() {
    std::thread a(thread_1);
    std::thread b(thread_2);
    std::thread c(thread_3);
    a.join(); b.join(); c.join();
    return 0;
}
```

## 释放-消费顺序（Release-Consume ordering）

若在线程 A 当中的原子 store 操作被标记上 std::memory_order_release，而若在线程 B 当中相同原子变量的 load 操作被标记上 std::memory_order_consume，则所有在线程 A 看来先于（happens-before）该 store 操作的那些内存写入（包括非原子变量写入和宽松顺序的原子变量写入），在线程 B 中依赖该原子变量的表达式和函数看来都有可见副作用（Visible side-effects）。也就是说，一旦线程 B 的原子 load 操作完成，线程 B 中依赖该原子变量的表达式和函数可见线程 A 写入内存的所有内容。

这一同步仅只建立在对同一原子变量执行消费操作和获取操作的线程中。其他线程观察到的内存访问顺序可能异于同步的线程之中的任意一个。

在除 DEC Alpha 之外的主流 CPU 上，释放-消费顺序（亦称：依赖顺序）是自动保证的。因此，对于释放-获取顺序的同步来说，无需引入额外的 CPU 指令（来确保内存顺序）；但在编译器优化阶段，仍需加入一些限制（例如：编译器不能将非原子的 store 操作挪到原子 store-release 操作之后；亦不能将涉及到依赖链的非原子的 load 操作挪到原子 load-consume 操作之前）。

该顺序的使用，往往见于对并发共享数据结构有频繁读取而极少写入的场景（例如路由表、安全策略、防火墙规则等）。

注意，截至 2015 年 2 月，尚未有编译器追踪了依赖链条，因此，消费操作被提升为获取操作。

下例中，通过原子变量 ptr 建立起了 producer 线程和 consumer 线程之间的释放-消费同步，因此第一个 assert 永远不会失败，但第二个 assert 可能失败。

```cpp
#include <thread>
#include <atomic>
#include <cassert>
#include <string>

std::atomic<std::string*> ptr;
int data;

void producer() {
    std::string* p  = new std::string("Hello");
    data = 42;
    ptr.store(p, std::memory_order_release);
}

void consumer() {
    std::string* p2;
    while (nullptr == (p2 = ptr.load(std::memory_order_consume)));
    assert(*p2 == "Hello"); // never fires: *p2 carries dependency from ptr
    assert(data == 42); // may or may not fire: data does not carry dependency from ptr
}

int main() {
    std::thread t1(producer);
    std::thread t2(consumer);
    t1.join(); t2.join();
    return 0;
}
```

## 顺序一致顺序（Sequentially-consistent ordering）

标记上 std::memory_order_seq_cst 的原子操作不仅满足释放-获取顺序的要求（一个线程中 store-release 之前的写入操作在另一个 load-acquire 之后都可见），而且为所有如此标记的原子操作建立了**唯一的全局统一修改顺序（single total modification order）**。

正式地说，在不考虑 [std::atomic_thread_fence](https://en.cppreference.com/w/cpp/atomic/atomic_thread_fence) 的情况下，对于每个 load 原子变量 M 的操作 B（标记为 std::memory_order_seq_cst），它读取到的值来自以下三种可能：

- 在上述**唯一的全局统一修改顺序**中的上一个修改了 M 的操作 A 的结果；

- 若存在这样的 A，B 还可能读到另一个修改了 M 的操作 C，它没有标记为 std::memory_order_seq_cst，并且不先于（happens-before） A；

- 若不存在这样的 A，B 读取的结果来自另一个修改了 M 的没有标记为 std::memory_order_seq_cst的操作 D。

顺序一致对于多生产者多消费者的情形是必要的。这是因为，所有消费者必须能够以相同的顺序观察到所有生产者的行为。

在所有多核系统中（注：逻辑核），完全的顺序一致都会插入大量内存屏障指令。这使得相应的内存访问需要对所有核心进行广播，因而可能成为性能瓶颈。

下例中，顺序一致即是必要的。其他更弱的顺序模型可能导致线程 C 和线程 D 观察到原子变量 x 和 y 以不同的顺序修改，从而导致 assert 失败。

```cpp
#include <thread>
#include <atomic>
#include <cassert>

std::atomic<bool> x = {false};
std::atomic<bool> y = {false};
std::atomic<int> z = {0};

void write_x() {
    x.store(true, std::memory_order_seq_cst);
}

void write_y() {
    y.store(true, std::memory_order_seq_cst);
}

void read_x_then_y() {
    while (!x.load(std::memory_order_seq_cst));
    if (y.load(std::memory_order_seq_cst)) {
        ++z;
    }
}

void read_y_then_x() {
    while (!y.load(std::memory_order_seq_cst));
    if (x.load(std::memory_order_seq_cst)) {
        ++z;
    }
}

int main() {
    std::thread a(write_x);
    std::thread b(write_y);
    std::thread c(read_x_then_y);
    std::thread d(read_y_then_x);
    a.join(); b.join(); c.join(); d.join();
    assert(z.load() != 0);  // will never happen
    return 0;
}
```

## 与 volatile 的关系

在**同一线程**中，对 volatile 修饰的[泛左值](https://en.cppreference.com/w/cpp/language/value_category#glvalue)（包括左值和将亡值）的访问（包括读写）不允许被重排序至先序于（sequenced-before）该操作的可观测的副作用（包括其他 volatile 访问）之前，亦不允许被重排序至后序于（sequenced-after）该操作的可观测的副作用（同上）之后。然而，volatile 访问并未建立线程之间的同步，故而在其他线程中，上述顺序无法得到保证。

此外，对 volatile 修饰的泛左值的访问不是原子的（这意味着读写同一内存位置上的 volatile 变量属于[数据竞争](https://en.cppreference.com/w/cpp/language/memory_model)），同时也不影响内存顺序（非 volatile-访问可以在 volatile-访问附近自由重排序）。

一个例外是 Visual Studio。根据[微软提供的文档](https://docs.microsoft.com/en-us/cpp/cpp/volatile-cpp)，在默认设置下，volatile-读自带 acquire 语义而 volatile-写自带 release 语义。因此，这些 volatile-访问可被用来建立线程间的同步。但要注意，标准的 volatile 语义不应被用于多线程编程。（这一点在[前作](/2018/01/18/volatile-in-C-and-Cpp/)中也有讨论）