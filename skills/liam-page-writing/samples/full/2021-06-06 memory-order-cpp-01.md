---
title: "程序员的自我修养（⑪）：C++ 的内存顺序·上"
url: https://liam.page/2021/06/06/memory-order-cpp-01/
date: 2021-06-06
categories: ["Algorithm and Computer Science"]
tags: ["Atomics", "Memory Model"]
---

此篇继[前文](/2021/06/05/memory-model-cpp/)讨论内存模型，继续讨论 C++ 的内存顺序。类似地，文中内容基本上是 CPP reference 上[对应页面](https://en.cppreference.com/w/cpp/atomic/memory_order)术语部分的翻译，有删减和补充。

线程间同步及内存顺序决定表达式的求值（evaluations）及其副作用（side effects）在不同线程中的顺序。首先有相关术语的定义。

## 消费操作（consume operation）

配置了 [std::memory_order_consume](https://en.cppreference.com/w/cpp/atomic/memory_order) 或更强的内存顺序的原子读操作是消费操作（consume operation）。

注意：std::atomic_thread_fence 引入的同步机制比消费操作更强。

## 占有操作（aquire operation）

配置了 [std::memory_order_acquire](https://en.cppreference.com/w/cpp/atomic/memory_order) 或更强的内存顺序的原子读操作是占有操作（aquire operation）。在[互斥量（mutex）](https://en.cppreference.com/w/cpp/named_req/Mutex)上执行 lock() 操作亦属于占有操作。

注意：std::atomic_thread_fence 引入的同步机制比占有操作更强。

## 释放操作（release operation）

配置了 [std::memory_order_release](https://en.cppreference.com/w/cpp/atomic/memory_order) 或更强的内存顺序的原子读操作是释放操作（release operation）。在[互斥量（mutex）](https://en.cppreference.com/w/cpp/named_req/Mutex)上执行 unlock() 操作亦属于释放操作。

注意：std::atomic_thread_fence 引入的同步机制比释放操作更强。

## 表达式求值（evaluations of expressions）

对一个表达式求值（evaluation）包含以下两个部分：

- 值计算（value computations）：计算表达式的返回值。其中可能涉及到对象的识别（identity of the object；左值求值）或是读取对象中保存的值（右值求值）。前者例如返回某个对象的引用，后者例如返回一个数值。

- 副作用（side effect）：通过一个易变左值访问（读/写）对象；修改对象；调用函数库中的 I/O 函数；或调用包含上述操作的其他函数。

## 先序（sequenced-before）关系

先序关系描述同一个线程中两次求值之间的偏序关系。

- 若 A 先序于（sequenced-before） B，则 A 将在 B 开始执行之前完成。

- 若 A 不先序于 B，而 B 先序于 A，则 B 将在 A 开始执行之前完成。

- 若 A 不先序于 B 而 B 亦不先序于 A，则有两种可能性
A 和 B 的求值不存在序列关系：二者可能以任意顺序求值，并且它们的求值动作在时间上可能重叠（在同一线程中，编译器可能打乱组成 A 和 B 的指令的顺序，使他们相互穿插）。
A 和 B 的求值序列关系不确定：二者可能以任意顺序求值，但它们的求值动作在时间上不可能重叠。此外，程序再次执行时，二者的执行顺序可能和上一次不同。

## 带去依赖（Carries dependency）

在同一线程中，若 A 先序于 B，则在下列情况下，A 为 B 带去依赖（即，B 依赖于 A）：

- A 的返回值是 B 的操作数，但下列情形除外：
B 是对 [std::kill_dependency](https://en.cppreference.com/w/cpp/atomic/kill_dependency) 的调用；
A 的返回值是内建 &&, ||, ?: 或是 , 运算符的左操作数。

- 执行 A 的过程中写入标量 M，而执行 B 的过程读取标量 M。

- A 为 X 带去依赖，而 X 为 B 带去依赖。（即依赖关系具有传递性）

## 修改顺序（Modification Order）

对于某个原子变量来说，其全部写入操作组成一个全局修改顺序。

所有原子操作都保证符合以下四个要求：

- 写写一致性：若对原子变量 M 的写入操作 A 先于（happens-before）对同一原子变量的写入操作 B。则在 M 的修改顺序（modification order）中，A 在 B 之前。

- 读读一致性：若 A 和 B 的值计算均读取原子变量 M，且 A 先于 B；又假定 A 读到的原子变量 M 的值来自某个对 M 有写操作的表达式 X；则 B 读到的值，要么来自 X 的写入，要么来自在 M 的修改顺序（modification order）中晚于 X 的某个写入 Y。

- 读写一致性：若 A 的值计算读取原子变量 M 而 B 写入 M，且 A 先于 B；则 A 读到的值来自在 M 的修改顺序（modification order）中早于 B 的某个写入 X。

- 写读一致性：若 X 对原子变量 M 有写入，而 B 的值计算读取原子变量 M；又假定 X 先于 B；则 B 读到的值要么来自 X 的写入，要么来自在 M 的修改顺序（modification order）中晚于 X 的某个写入 Y。

## 释放序列（Release sequence）

假定 A 是原子变量 M 上的一个释放操作（release operation）。则在 M 的修改顺序中，**位于 A 之后**的由下列操作组成的最长连续子序列被称为以 A 为首的释放序列（release sequence）：

- 执行 A 的线程中，对 M 的写入操作（until C++20）；

- 任意线程对 M 的读-改-写操作（CAS 成功时的操作）。

## 依赖顺序上先于（Dependency-ordered before）

满足下列某个情况时，我们称表达式 A 在依赖顺序上先于（dependency-ordered before）表达式 B——其中 A 和 B 处于不同线程。

- A 对原子变量 M 执行释放操作（release operation），在另一线程中 B 对同一原子变量 M 执行消费操作（consume operation），且 B 读取的值来自 A（以 A 为首的释放序列（release sequence）中的任意部分（until C++20））的写入。

- A 在依赖顺序上先于 X，而 X 为 B 带去依赖。

## 线程间先于（Inter-thread happens-before）

若满足下列条件之一，则称对表达式 A 的求值线程间先于（inter-thread happens-before）对表达式 B 的求值：

- A 与 B 同步（synchronizes-with）；

- A 依赖顺序上先于 B；

- A 与某个表达式 X 同步，而 X 先序于 B；

- A 先序于 某个表达式 X 的求值，而 X 线程间先于 B；

- A 线程间先于 某个表达式 X 的求值，而 X 线程间先于 B。

## 先于（happens-before）

无论线程情况如何，若满足下列条件之一，则称对表达式 A 的求值先于（happens-before）对表达式 B 的求值：

- A 先序于（sequenced-before） B；

- A 线程间先于（inter-thread happens-before） B。

编译器实现应当引入必要的同步措施，以保证表达式求值之间的先于关系链不成环。（仅当引入消费操作（consume operation）时有此必要；参见 [Betty 等的论文](http://www.cl.cam.ac.uk/~pes20/cpp/popl085ap-sewell.pdf)）

若某个求值操作修改了一个内存位置（见[前文](/2021/06/05/memory-model-cpp/)），另一个求值操作读写同一内存位置，且至少其一不是原子操作，除非二者之间存在先于关系，程序行为未定义（程序有数据竞争）。

## 简单先于（Simply happens-before；since C++20）

无论线程情况如何，若满足下列条件之一，则称对表达式 A 的求值简单先于（happens-before）对表达式 B 的求值：

- A 先序于（sequenced-before） B；

- A 与 B 同步（synchronizes-with）；

- A 简单先于 某个表达式 X 的求值，而 X 简单先于 B。

注：没有消费操作（consume operation）时，简单先于等价于先于。

## 强先于（Strongly happens-before）

无论线程情况如何，若满足下列条件之一，则称对表达式 A 的求值强先于（strongly happens-before）对表达式 B 的求值：

### until C++20

- A 先序于（sequenced-before） B；

- A 与 B 同步（synchronizes-with）；

- A 强先于 某个表达式 X 的求值，而 X 强先于 B。

注：C++20 之前的强先于，即是 C++20 及之后的简单先于。

### since C++20

- A 先序于（sequenced-before） B；

- A 与 B 同步（synchronizes-with），且 A/B 均为顺序一致（sequentially consistent）的原子操作；

- A 先序于（sequenced-before） X，X 简单先于 Y，Y 先序于（sequenced-before） B；

- A 强先于 某个表达式 X 的求值，而 X 强先于 B。

注：不正式地讲，若 A 强先于（strongly happens-before） B，则在任何上下文中，A 都先于 B 求值。

注：强先于关系排除了消费操作（consume operation）。

## 可见副作用（Visible side-effects）

若下列条件均成立，则 A 对于标量 M 的副作用（写操作）于在标量 M 上的求值 B（读操作）可见：

- A 先于 B；

- 任意满足 A 先于 X 且 X 先于 B 的表达式 X 对标量 M 没有副作用。

若 A 的副作用对 B 可见，则在 M 的修改顺序当中 B 之前的最长连续副作用子集称之为 B 可见的副作用序列。（B 见到的 M 的值是上述副作用其中之一写入的）

注：线程间同步本质是要通过建立先于（happens-before）关系来避免数据竞争以及定义在哪些条件下哪些副作用可见。