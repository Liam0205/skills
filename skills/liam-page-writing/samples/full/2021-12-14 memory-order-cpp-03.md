---
title: "程序员的自我修养（⑬）：C++ 的内存顺序·下"
url: https://liam.page/2021/12/14/memory-order-cpp-03/
date: 2021-12-14
categories: ["Algorithm and Computer Science"]
tags: ["Atomics", "Memory Model", "Memory Order"]
---

在前三篇文章中，我们捡着重要的部分翻译和扩展了 cppreference 网站上关于[内存模型](/2021/06/05/memory-model-cpp/)和内存顺序（[上](/2021/06/06/memory-order-cpp-01/)、[中](/2021/12/11/memory-order-cpp-02/)）的文章。坦率地说，因为涉及内容相对底层，所以通篇相对晦涩。所以它们虽然阐述了相关内容，但不易读。

此篇讨论的内容在前三篇文章中都有讨论，但将从一系列例子出发，从实践的角度去讨论内存模型和内存顺序。

## 最简单的例子

让我们从一个最简单的生产者/消费者的例子出发。

```cpp
#include <atomic>
#include <chrono>
#include <iosteram>
#include <thread>
#include <vector>

std::vector<int> data;  // 1.a.
std::atomic<bool> ready{false};  // 1.b.

void producer() {
  data.push_back(1024);  // 2.
  ready.store(true);  // 3.
}

void consumer() {
  while (!ready.load()) {  // 4.
    std::this_thread::sleep(std::milliseconds(1));
  }
  std::cout << data[0] << std::endl;  // 5.
}

int main() {
  std::thread a{producer}, b{consumer};
  a.join(); b.join();
  return 0;
}
```

此处，(1) 初始化了全局共享的数据 data 和原子标记 ready。生产者线程中，(2) 对全局共享的数据进行修改，并在 (3) 处将标记设置为 true。消费者线程中，(4) 循环等待原子标记（当然，它效率极低；作为示例我们暂时忽略这个问题），而后在 (5) 处读取共享数据。

我们知道，在多个线程中，并发读写同一个内存位置（此处的 &data[0]）可能造成数据竞争，必须有相应的同步机制。此处同步机制由原子标记 ready 协助建立。

- (2) 先于（happens-before） (3)；

- **当 (4) 读到 ready.load() 为真**，则 (3) 与 (4) 建立同步（synchronizes-with）关系，因而有 (3) 先于（happens-before） (4)；

- (4) 先于（happens-before） (5)。

在原子标记 ready 的协助下，我们建立了对 data 的写先于（happens-before）读的顺序关系，数据竞争的风险就此解除。

整体看下来，这一过程非常符合直觉。而我们知道，原子变量除了保证其上原子操作的原子性之外，各个操作还有内存顺序标记。不同的顺序标记会影响编译器优化和 CPU 执行时的行为；更准确地，影响原子操作附近访问内存的顺序。默认的顺序标记是 std::memory_order_seq_cst。之所以将它作为默认标记，是因为它能带来这一符合直觉的结果。

接下来，我们顺势讨论先于（happens-before）关系和同步（synchronizes-with）关系。

## 两种关系

### 同步（synchronizes-with）关系

同步（synchronizes-with）关系，追根究底只能由原子操作提供。我们能见到的所有产生同步关系的办法，其底层都包含了某些原子操作。同步关系是这样建立的，

- 首先有在线程 A 中对原子变量 x 打上恰当标记的写入操作 W；

- 而后有在线程 B 中对原子变量 x 打上恰当标记的读取操作 R。

若 R 读到的值，来自以下任意一种情况，则说 W 与 R 同步（synchronizes-with）。

- W 的写入；或者

- 线程 A（W 所在线程）中，W 之后的某次写入；或者

- 任意线程中的一系列 read-modify-write 操作中的写入值，其中第一次 read-modify-write 操作读到的值来自 W 的写入。

这得到一个最基本的认知：（在顺序标记恰当的情况下，）如果线程 B 的读取操作读到的是线程 A 的写入操作的写入值，则写入操作与读取操作同步。

如此一来，所有的细节就在「恰当」二字之上了。不过，我们先来讨论先于（happens-before）关系。

## 先于（happens-before）关系

先于（happens-before）关系是讨论内存顺序中最重要的基石。若 A 先于（happens-before） B，则 B 能看到 A 带来的副作用。

在单线程里面，先于（happens-before）关系很简单。单线程当中的先于（happens-before）关系即是先序（sequenced-before）关系。一般来说，不考虑编译器优化重排和 CPU 乱序执行重排时，在代码当中，靠前的语句当中的操作先于（happens-before）靠后的语句当中的操作。但实际上，我们需要考虑编译器优化和 CPU 乱序执行对先序关系带来的影响。

在线程之间，若线程 A 的写入操作与线程 B 的读取操作同步（synchronizes-with），则该写入操作线程间先于（inter-thread happens-before）该读取操作，也因此该写入操作先于（happens-before）该读取操作。

## 三种顺序模型

按前文，顺序标记共有六种：

- std::memory_order_relaxed

- std::memory_order_consume

- std::memory_order_acquire

- std::memory_order_release

- std::memory_order_acq_rel

- std::memory_order_seq_cst

六种标记又能组成三种顺序模型：

- 顺序一致模型（sequentially consistent ordering）：最强的顺序模型。对编译器优化限制最多，所需额外 CPU 同步指令最多，性能也最差；但最符合直觉。涉及到的顺序标记是 std::memory_order_seq_cst。

- 宽松模型（relaxed ordering）：最弱的顺序模型。对编译器优化限制最少（几乎没有），所需额外 CPU 同步指令最少（几乎没有），性能也最好；但无法建立线程间的同步关系。涉及到的顺序标记是 std::memory_order_relaxed。

- 获取-释放模型（acquire-release ordering）：介于二者之间。对编译器优化限制适中，所需额外的 CPU 同步指令也适中（在部分平台上，不许额外同步指令），性能也适中；可以建立线程间的同步关系。涉及到的顺序标记是 std::memory_order_acq_rel, std::memory_order_acquire, std::memory_order_release 和 std::memory_order_consume。

注意，std::memory_order_consume 与 std::memory_order_acquire 相似，但比后者更弱。但完整地实现 std::memory_order_consume 的语义，需要追踪变量之间的依赖链。目前，还没有已知的编译器实现了它。现有的编译器，都将 std::memory_order_consume 提升为 std::memory_order_acquire。故而此处也将 std::memory_order_consume 归在获取-释放模型当中。此外，考虑 std::memory_order_consume 的语义可能发生变化，目前标准也不建议使用 std::memory_order_consume。

### 顺序一致模型（sequentially consistent ordering）

默认的顺序模型是「顺序一致模型」。如果所有原子操作的顺序标记都是 std::memory_order_seq_cst，那么多线程程序的行为就好像这些操作以某一特定的顺序在单一的线程中执行一样。特别地，站在所有被打上 std::memory_order_seq_cst 标记的操作上来看，所有先于该操作发生的原子操作（std::memory_order_seq_cst），都具有同样的顺序。

这是最符合直觉的模型。多数人第一次接触到多线程，会假定多线程中的各个操作是可能并发执行的，因此将他们理解为按照某个不确定的顺序穿插执行。然后在脑海中想象并构建这一固定的顺序，并按照这一顺序假定各个线程会如何工作。但这种符合直觉的模型并不总是成立。这种多线程之间全局统一的顺序，即是顺序一致性带来的保证。一旦保证不了顺序一致性，则这种基于「穿插执行」假定出来的全局统一顺序也就不成立了。

站在同步的角度来看，顺序一致 store 操作与读到本次写入值的顺序一致的 load 操作同步（synchronizes-with）。如前所述，这种同步关系在线程之间提供了一定的顺序限制。但顺序一致模型还保证，在这一顺序一致的 load 操作之后的顺序一致操作，在其他所有使用顺序一致原子操作的线程看来，也是发生在此次顺序一致 store 之后的。注意，如若某一线程中的某个原子操作没有使用 std::memory_order_seq_cst 标记，则在该操作看来，顺序一致的诸多操作的顺序可能与其他线程看到的不同。

前作当中的[例子](/2021/12/11/memory-order-cpp-02/#%E9%A1%BA%E5%BA%8F%E4%B8%80%E8%87%B4%E9%A1%BA%E5%BA%8F%EF%BC%88Sequentially-consistent-ordering%EF%BC%89)很好地说明了顺序一致性的效果。

这种便利是有代价的。在默认的顺序保证相对较弱的平台上（如 ARM），顺序一致模型会引入可观的性能代价。这是因为，全局顺序一致需要在 CPU 逻辑核心之间保持一致性，这使得 CPU 逻辑核心之间需要使用代价高昂的同步操作。相较而言，部分处理器架构（例如 x86 和 x86-64）保证顺序一致性的代价较低。为避免这种同步代价，我们需要拥抱非顺序一致性模型。

在处理非顺序一致性模型时，我们就要丢弃脑海中那种简洁漂亮的交替执行的思维模型。**它不存在了**。在没有顺序一致性保障的情况下，各个线程看到的原子操作的顺序并不保证统一。也就是说，虽然依旧是并发（所以穿插执行），但是每个线程看到的穿插的顺序可能是不一样的。在非顺序一致模型下写代码时，要时刻关注这一点。

不过，也有一致的地方。虽说各个线程观察到的原子操作发生的顺序可能不一致，但是，对于**每一个特定的原子变量**，作用在其上的原子操作的修改顺序（modification-order），在各个线程看来是统一的。

为了充分理解非顺序一致性模型，我们可以先考虑宽松模型。待对非顺序一致性有足够了解之后，再回到获取-释放模型。

### 宽松模型（relaxed ordering）

顺序标记为 std::memory_order_relaxed 的原子操作不参与构建同步（synchronizes-with）关系。在同一线程中，对**同一**原子变量的原子操作的顺序遵循源代码中的先序（sequenced-before）关系（从而有先于（happens-before）关系）。但是，在另外的线程看来，这种顺序无法保证。由于未加任何同步限制，顺序标记为 std::memory_order_relaxed 的原子操作只是简单地遵循各个原子变量自身的修改顺序（modification-order）而已。

首先看一段简单的代码。

```cpp
#include <assert.h>

#include <atomic>
#include <thread>

std::atomic<bool> x{false}, y{false};
std::atomic<int> z{0};

void write_x_then_y() {
  x.store(true, std::memory_order_relaxed);  // 1.
  y.store(true, std::memory_order_relaxed);  // 2.
}

void read_y_then_x() {
  while (!y.load(std::memory_order_relaxed));  // 3.
  if (x.load(std::memory_order_relaxed)) {  // 4.
    z.fetch_add(1);
  }
}

int main() {
  std::thread a(write_x_then_y), b(read_y_then_x);
  a.join();
  b.join();
  assert(0 != z.load());  // 5.
  return 0;
}
```

按照经典的「穿插思维模型」（即顺序一致性模型），(3) 处循环等待直到 y 为真，那么**由于 (1) 先于 (2) 发生，(3) 先于 (4) 发生**，所以 (4) 必然为真，因此 (5) 的断言永不失效。但实际上，由于 (1) -- (4) 的顺序标记都是 std::memory_order_relaxed，此处并无同步保证，也没有单线程中的先序关系保证。这也就是说，上述两个先于关系不一定成立；即便成立，(2) 不必然与 (3) 同步（synchronizes-with），因此也就无法传递上述两个先于关系。所以站在 (4) 的角度看，并不保证 (1) 先于（happens-before） (4) 发生。所以 (4) 可能读到 false 导致断言失败。

接下来再看一个更加复杂的例子。

```cpp
#include <atomic>
#include <iostream>
#include <thread>

std::atomic<int> x{0}, y{0};
std::atomic<bool> ready{false};

static const size_t upper{10UL};

struct Snapshot {
  int x{0};
  int y{0};
};

Snapshot t1[upper];
Snapshot t2[upper];
Snapshot t3[upper];

void increase(std::atomic<int>* var, Snapshot* snapshots) {
  while (!ready) {  // 1.a.
    std::this_thread::yield();
  }

  for (size_t i = 0; i != upper; ++i) {
    auto& snapshot = snapshots[i];
    snapshot.x = x.load(std::memory_order_relaxed);  // 2.a.
    snapshot.y = y.load(std::memory_order_relaxed);  // 3.a.
    var->store(i + 1, std::memory_order_relaxed);  // 4.
    std::this_thread::yield();
  }
}

void observe(Snapshot* snapshots) {
  while (!ready) {  // 1.b.
    std::this_thread::yield();
  }

  for (size_t i = 0; i != upper; ++i) {
    auto& snapshot = snapshots[i];
    snapshot.x = x.load(std::memory_order_relaxed);  // 2.b.
    snapshot.y = y.load(std::memory_order_relaxed);  // 3.b.
    std::this_thread::yield();
  }
}

void print(const Snapshot* snapshots) {
  for (size_t i = 0; i != upper; ++i) {
    const auto& snapshot = snapshots[i];
    if (i > 0) {
      std::cout << ',';
    }
    std::cout << "(" << snapshot.x << "," << snapshot.y << ")";  // 5.
  }
  std::cout << std::endl;
}

int main() {
  std::thread T1(increase, &x, t1);
  std::thread T2(increase, &y, t2);
  std::thread T3(observe, t3);

  ready.store(true);  // 1.c.

  T3.join();
  T2.join();
  T1.join();

  print(t1);
  print(t2);
  print(t3);

  return 0;
}
```

可能的输出如下：

```bash
$ ./a.out
(0,2),(1,4),(2,5),(3,6),(4,7),(5,8),(6,9),(7,10),(8,10),(9,10)
(0,0),(0,1),(0,2),(1,3),(2,4),(3,5),(4,6),(5,7),(6,8),(7,9)
(1,3),(2,4),(2,5),(3,6),(4,7),(5,8),(6,8),(7,9),(8,10),(8,10)
```

我们首先来观察一下代码和结果。

代码部分，

- increase 等待 ready 信号之后 (1)，开始执行 upper 次循环。每次循环以 std::memory_order_relaxed 的顺序标记读取 x(2) 和 y(3) 的值，并记录在快照 snapshot 当中，而后以 std::memory_order_relaxed 的顺序标记更新 var 指向的原子变量（要么是 x，要么是 y）。

- observe 等待 ready 信号之后 (1)，开始执行 upper 词循环。每次循环以 std::memory_order_relaxed 的顺序标记读取 x(2) 和 y(3) 的值，并记录在快照 snapshot 当中。

- print 打印历次循环得到的快照 (5)。每个二元组中，第一个数是当次循环读到的 x 的值；第二个数是对应的 y 的值。

- ready 变量确保三个线程在几乎相同的时间开始，以防（例如说）T1 已经执行完毕而 T3 还尚未开始执行。

结果部分，

- 第一行、第二行、第三行分别记录了 T1, T2, T3 在历次循环过程中记录下来的 x 和 y 的值的快照。

- 关于写
对于 T1 来说，只有该线程修改 x 的值，每次读到它，都恰好自增 1；
同样对于 T2 来说，y 每次自增 1。

- 关于读
对于 T1 和 T3 来说，它们只读 y 的值。因为 y 的修改序列中，y 的值是递增的；因此 T1 和 T3 每次读到的 y 的值都不小于前一次读到的 y 的值；但递增的步长不一定均衡。
对于 T2 和 T3 来说，它们只读 x 的值。基于同样的理由，它们每次读到的 x 的值都是非递减的；但递增的步长不一定均衡。

这里我们只给出了一个可能的结果，实际上，符合上述规律的结果，都是可能出现的。

接下来我们正式地描述宽松模型下的规律。

- 对于任意给定的原子变量，其修改顺序（modification-order）是全局唯一的。

- 对于任意线程，
若未曾读取过该变量的值，则可能读取到修改顺序上任意可能的值。
一旦读取了某个原子变量在修改顺序上的某个值，将来再读取时，要么读取相同的值，要么读取到在修改顺序上更靠后的值，而不可能读到在修改顺序上更靠前的值。

- 对于任意线程，一旦写入了某个原子变量，将来再读取时，要么读取到此次写入的值，要么读取到修改顺序上相对此次写入更靠后的值。

我们可以使用这一规律来回顾本节第一段代码。对于变量 x 来说，其修改顺序是：默认值 false，由 write_x_then_y 写入的值 true。在 read_y_then_x 线程当中，由于从未读取过 x 的值，因此可能读到 x 的修改顺序上的任意值。——可能是 false，亦可能是 true。故而断言可能失败。

### 获取-释放模型（acquire-release ordering）

接下来，我们讨论居于宽松模型和顺序一致模型当中的获取-释放模型（acquire-release ordering）。

获取-释放模型当中，依然不存在顺序一致模型当中那样的全局唯一操作顺序，但相较宽松模型，增加了部分同步能力。在获取-释放模型当中，

- 原子-store 操作是释放操作（release-operation）（std::memory_order_acquire）；

- 原子-load 操作是获取操作（acquire-operation）（std::memory_order_release）；

- 原子-read-modify-write 操作（例如 fetch_add 或是 exchange）则要么是释放操作，要么是获取操作，要么同时是释放-获取操作（std::memory_order_acq_rel）。

同步总是在线程之间成对出现的。一个线程中的释放操作与另一个线程中读到该次写入的获取操作同步（synchronizes-with）。这意味着，不同线程可能观察到不同的操作顺序，但这些顺序是有所限制的。

同样地，我们来看一个示例。这个例子是从顺序一致性模型的例子上稍加修改而来。

```cpp
#include <thread>
#include <atomic>
#include <cassert>

std::atomic<bool> x = {false};
std::atomic<bool> y = {false};
std::atomic<int> z = {0};

void write_x() {
  x.store(true, std::memory_order_release);  // 1.
}

void write_y() {
  y.store(true, std::memory_order_release);  // 2.
}

void read_x_then_y() {
  while (!x.load(std::memory_order_acquire));  // 3.
  if (y.load(std::memory_order_acquire)) {  // 4.
    ++z;
  }
}

void read_y_then_x() {
  while (!y.load(std::memory_order_acquire));  // 5.
  if (x.load(std::memory_order_acquire)) {  // 6.
    ++z;
  }
}

int main() {
  std::thread a(write_x);
  std::thread b(write_y);
  std::thread c(read_x_then_y);
  std::thread d(read_y_then_x);
  a.join(); b.join(); c.join(); d.join();
  assert(z.load() != 0);  // can fire
  return 0;
}
```

在本例中，断言可能失败。我们来做进一步分析。

(1) 处是释放操作；(3) 处通过循环确保读到 (1) 写入的值。因而 (1) 的释放操作与 (3) 的获取操作配对，建立同步（synchronizes-with）关系，于是 (1) 顺势与 (4) 建立先于（happens-before） 关系。同理，(2) 与 (5) 之间也有同步关系，(2) 顺势与 (6) 建立先于（happens-before） 关系。

然而，我们无法建立 (1) 先于（happens-before） (6) 的关系。故而 (6) 可能读到变量 x 的修改序列上的任意值。例如说，可能读到 false。同理 (4) 也可能读到 false。二者同时发生时，断言失败。

因为 store 操作发生在不同的线程，故而我们无法借助一个原子变量的同步关系，构造另一个原子变量的写与读之间的先于关系。这告诉我们两件事情。一是，对于多写多读的场景，我们往往需要顺序一致性模型。二是，若要应用获取-释放模型，store 操作应当发生在同一线程。

接下来我们再看一例。

```cpp
#include <assert.h>

#include <atomic>
#include <thread>

bool x{false};
std::atomic<bool> y{false};
int z{0};

void write_x_then_y() {
  x = true;  // 1.
  y.store(true, std::memory_order_release);  // 2.
}

void read_y_then_x() {
  while (!y.load(std::memory_order_acquire)) {  // 3.
    std::this_thread::yield;
  }
  if (x) {  // 4.
    ++z;
  }
}

int main() {
  std::thread a(write_x_then_y), b(read_y_then_x);
  a.join(); b.join();
  assert(z != 0):  // 5.
  return 0;
}
```

考虑 (1) 和 (2) 在同一线程中，有先序（sequenced-before）关系（release 语义保证不乱序）；(3) 处的 spin-wait 保证读到 (2) 的写入，因而 (2) 与 (3) 同步（synchronizes-with），再有 (3) 与 (4) 在同一线程中，也有先序关系（acquire 语义保证不乱序）。故而 (1) 必须先于 (4)，从而 (4) 的判断必定成立，而 (5) 的断言永不失败。

## 内存屏障

C++ 标准库也提供了内存屏障 std::atomic_thread_fence，它也可以打上顺序标签。

理解起来，带上 std::memory_order_release 的内存屏障，倾向于向下结合一个 store 操作，将它的内存顺序提升为 std::memory_order_release（如果原本是 std::memory_order_relaxed 的话）。带上 std::memory_order_acquire 的内存屏障，倾向于向上结合一个 load 操作，将它的内存顺序提升为 std::memory_order_acquire（如果原本是 std::memory_order_relaxed 的话）。从而建立获取-释放的同步关系。

我们可以将上例稍加修改得到：

```cpp
#include <assert.h>

#include <atomic>
#include <thread>

bool x{false};
std::atomic<bool> y{false};
int z{0};

void write_x_then_y() {
  x = true;  // 1.
  std::atomic_thread_fence(std::memory_order_release);  // 2.a.
  y.store(true, std::memory_order_relaxed);  // 2.b.
}

void read_y_then_x() {
  while (!y.load(std::memory_order_relaxed)) {  // 3.a.
    std::this_thread::yield;
  }
  std::atomic_thread_fence(std::memory_order_acquire);  // 3.b.
  if (x) {  // 4.
    ++z;
  }
}

int main() {
  std::thread a(write_x_then_y), b(read_y_then_x);
  a.join(); b.join();
  assert(z != 0):  // 5.
  return 0;
}
```

这里，(2.a) 的 release-屏障向下与 (2.b) 的宽松-store 操作结合，使得该操作提升为 release-store；(3.b) 的 acquire-屏障向上与 (3.a) 的宽松-load 操作结合，使得该操作提升为 acquire-load。reloease-store 和 acquire-load 构成同步（synchronizes-with），又有 release/acquire 语义保证局部顺序，因此有 (1) 先于（happens-before） (4)，从而 (5) 的断言不会失败。