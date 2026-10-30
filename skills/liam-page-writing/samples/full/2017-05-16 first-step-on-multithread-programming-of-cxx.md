---
title: "程序员的自我修养（五）：C++ 多线程编程初步"
url: https://liam.page/2017/05/16/first-step-on-multithread-programming-of-cxx/
date: 2017-05-16
categories: ["Algorithm and Computer Science"]
tags: ["Cpp", "C++11", "Multithread"]
---

这是[系列文章](/series/)的第五篇。

这篇文章里，我们介绍如何使用 C++ 11 的标准库，进行多线程编程。

## Babystep

好吧，不管学什么编程语言，「Hello world!」总是不会少的。虽然在 C++ 中进行多线程编程依然是在使用 C++，但是迈出 babystep 总是很重要的。让我们从 *Hello multithread!* 开始。

首先，作为对比，我们写出 *Hello world!* 程序。

```cpp
#inlcude <iostream>
int main() {
    std::cout << "Hello world!" << std::endl;
    return 0;
}
```

使用 C++ 11 的标准库，在程序中启动一个线程是很简单的。

```cpp
#include <iostream>
#include <thread>       // 1.

void greeting() {       // 2.
    std::cout << "Hello multithread!" << std::endl;
    return;
}

int main() {
    std::thread t{greeting};    // 3.
    t.join();                   // 4.
    return 0;
}
```

在编译它的时候，需要注意链接平台相关的线程库。比如在 Linux 上，需要链接 pthread 库。

```bash
$ g++ --std=c++11 -pthread hello_multithread.cpp
$ ./a.out
Hello multithread!
```

这份代码值得注意的地方有四点。

首先，我们引入了头文件 thread。在这个头文件中，C++ 11 提供了管理线程的类和函数。

之后，我们定义了一个无返回类型的函数 greeting，这个函数除了在标准输出流中打印一行文字之外什么也不做。

而后，我们定义了一个 std::thread 类型的变量 t，并用列表初始化的方式传入了 greeting 函数（的指针，参考[这里](/2017/02/05/pointer-in-C-and-Cpp/)），作为 std::thread 类构造函数的参数。传入的函数，会作为新启动的子线程的入口函数。也就是说，当子线程准备就绪之后，就会开始执行这个入口函数。

从 C++ 11 开始，推荐使用列表初始化的方式，构造类类型的变量。

最后，我们调用成员函数 t.join()，确保主线程在子线程退出之后才退出。

## 线程管理初步

上面的 Babystep 中，我们已经介绍了 C++ 11 标准库中提供的设施，并以之启动了一个线程。当然，这个线程实在是太简单了，所以在性能上没有任何的价值。这一节，我们将介绍如何使用 C++ 11 标准库提供的设施，对线程进行基本的管理

### 线程函数

首先需要说明的概念，是**线程函数**。

我们讲，任何事情都有个「开始」。对于整个程序来说，我们知道，每个程序都有一个入口。当程序被装载到内存，处于内核态完成一些初始化的工作之后，控制权就转交给程序入口，并以此为标志进入用户态。这是一个程序的开始。同样地，线程也需要有「开始」的地方。作为线程入口的函数，就是线程函数。

稍微思考一下，就不难发现，线程函数必须在启动线程之前，就准备好。这是因为，哪怕线程什么也不做——等待，也需要一条指令。因此，线程函数必须在线程启动之前准备好，并在线程初始化后立即执行。

类似地，当线程函数返回时，线程也就随之终止了。

### 启动线程

在 Babystep 一节中，我们已经可以观察到：**线程随着 std::thread 类型实例的创建而创建**。C++ 11 的标准库，将创建线程和创建实例两个动作统一起来，对于 C++ 的程序员来说，线程就变成了如内存、文件一样的资源，由 C++ 提供统一的接口进行管理。同时，我们也已知晓，创建线程需指定线程函数。那么，根据线程函数的不同，在 C++ 中使用 std::thread 直接创建线程，大致有三种不同的方式。

```cpp
void do_some_work();
std::thread wk_thread{do_some_work};
```

仿照 Babystep 中的介绍，这是在 C++ 中创建线程最简单的例子。如同我们在[指针一文](/2017/02/05/pointer-in-C-and-Cpp/)中介绍的那样，当函数的名字被当做一个值来使用的时候，实际上使用的是函数的指针。因此，我们也可以显式地传入 &do_some_work，作为 wk_thread 的构造参数。

除了普通的函数之外，**可调用类型**的实例也可以作为线程函数，创建线程。

```cpp
class ThreadTask {
 private:
    size_t count_ = 0;
 public:
    explicit ThreadTask (size_t count) : count_(count) {}
    void operator()() const {
        do_something(this->count_);
    }
};

ThreadTask task{42};
std::thread wk_thread{task};
```

对于可调用类型，这里有两件事情需要特别注意。

首先，尽管可调用类型的实例看起来和函数一样，但是它毕竟是一个类类型的对象。所以，在 wk_thread 构造时，task 会被拷贝到线程的存储空间，而后再开始执行。因此，ThreadTask 类必须做好足够的拷贝控制。

其次，若是在创建线程的时候，传入的是临时构造的实例，需要注意 C++ 的语法解析规则。这种情况下，推荐使用 C++ 的列表初始化。

```cpp
std::thread wk_thread(ThreadTask());    // 1
std::thread wk_thread{ThreadTask{}};    // 2
```

在 (1) 处，作者的本意，是想构造一个 ThreadTask 实例，作为可调用对象作为 wk_thread 线程的线程函数。但实际上，[指针一文](/2017/02/05/pointer-in-C-and-Cpp/)介绍过，ThreadTask() 是一个函数指针的类型——这个函数没有参数 (void)，返回值的类型是 ThreadTask。因此，整个 (1) 会被 C++ 理解为一个函数声明：参数是一个函数指针（前述），返回类型是 std::thread。显而易见，这不是作者想要的。

我们说，构造函数和普通的函数是有一些不同的。构造函数执行完毕之后，就产生了一个可用的实例。产生这样误解的本质原因，是 std::thread 的构造函数也是函数，因而采用 () 接受参数列表；这样一来，从形式上构造函数就没有任何特殊性了。C++ 11 引入了列表初始化的概念，允许程序员以花括号代替圆括号，将参数传递给构造函数。这样一来，(2) 就没有歧义了。

C++ 11 引入了 lambda-表达式（或者你可以简单地称其为 lambda-函数）。在创建线程时，我们也可以将 lambda-表达式作为线程函数，传入 std::thread 的构造函数。

```cpp
std::thread wk_thread{[](){
    do_something();
}};
```

### 线程结束的控制

正如申请了内存，必须主动释放一样，对线程的管理也讲究有始有终。当线程启动之后，我们必须在 std::thread 实例销毁之前，显式地说明我们希望如何处理实例对应线程的结束状态。如果上述实例销毁之时，程序员尚未显式说明如何处理对应线程的结束状态，那么在上述实例的析构函数中，会调用 std::terminate() 函数，终止整个程序。

在主线程中，我们可以选择「接合 (join)」或者「分离 (detach)」产生的子线程。具体来说，就是对 std::thread 实例调用 join() 或者 detach() 成员函数。

```cpp
void do_something();
std::thread join_me{do_something};
std::thread detach_me{do_something};

if (join_me.joinable()) {       // 1
    join_me.join();
}
if (detach_me.joinable()) {     // 1
    detach_me.detach();
}
```

在这里，不论是接合或是分离，我们都首先调用了 joinable() 成员函数。它在尚未决定接合/分离时，返回 true；而若已经决定了接合/分离（通过调用 join()/detach()），则返回 false。

如果选择接合子线程，则主线程会阻塞住，直到该子线程退出为止。这就好像将子线程尚未执行完的部分，接合在主线程的当前位置，而后顺序执行。

如果选择分离子线程，则主线程丧失对子线程的控制权，其控制权转交给 C++ 运行时库。这就引出了两个需要注意的地方

- 主线程结束之后，子线程可能仍在运行（因而可以作为守护线程）；

- 主线程结束伴随着资源销毁，需要保证子线程没有引用这些资源。

```cpp
struct func {
    size_t& i_ = 0;
    func(int& i): i_(i) {}      // 1
    void operator()() {
        for (size_t j{0}; j!= 1000000; ++j) {
            do_something(i);    // 2
        }
    }
};

void bad_reference() {
    size_t working{42};
    func wk_func{working};
    std::thread wk_thread{wk_func};
    wk_thread.detach();         // 3
    return;                     // 4
}
```

在这里，我们定义了一个可调用的类。在循环内，我们不断尝试对外部传来的引用 (1) 进行一些操作 (2)。然而，在分离子线程之后 (3)，子线程所依赖的外部引用，随着函数的退出而销毁 (4)。这样，子线程后续使用该引用 (2) 的行为就是未定义的了，这是非常危险的。

至此，关于线程结束的控制，你已经了解大半了。你应该已经知道必须要在 std::thread 实例销毁之前，决定接合或是分离相应的线程。并且你也应该知道，对于分离的线程，要保证其数据的完整性。一般来说，「你」所能做的事情，就到此为止了。但是，总有例外的情况，需要特别处理。

对于大多数程序员来说，可能甚少处理「异常」。很多程序员，会在代码里做「防御式」编程，以规避各种可能导致异常的可能。在一些情况下，这样做无可厚非。但是，不论如何，我们应该记住「任何代码都有可能发生异常」这一原则。特别地，运行在子线程里的代码，也有可能发生异常。如果子线程里扔出的异常，没有被任何调用者处理，那么这个异常最终会导致整个程序终止。又如果子线程里扔出的异常，调用者在处理时没有决定线程的接合或分离，那么 std::thread 的销毁很可能会绕过正常逻辑中的接合或分离的逻辑，从而调用 std::terminate() 终止整个进程。

我们在[前作](/2017/04/09/Foundations-of-Cpp/)中讲到，对于可能发生资源泄漏的情况，我们可以考虑用 RAII 的思想，将资源封装在一个 handle 或者 guard 当中，从而防止资源泄漏。同时，前文也提到，**线程也是一种资源**。因此，我们可以考虑构造一个 ThreadGuard 来处理这种异常安全的问题。

```c++
struct ThreadGuard {
 private:
    std::thread& t_;
 public:
    explicit ThreadGuard(std::thread& t) : t_(t) {}
    ~ThreadGuard() {
        if (this->t_.joinable()) {          // 1
            this->t_.join();                // 2
        }
    }
    ThreadGuard  (const ThreadGuard&) = delete;
    ThreadGuard& operator=(const ThreadGuard&) = delete;
};

void do_something();

void show() {
    std::thread wk_thread;                  // default constructed
    ThreadGuard g{wk_thread};
    wk_thread = std::thread{do_something};  // 3

    do_domething_in_current_thread();
    return;                                 // 3
}
```

这是一个典型的利用 RAII 保护资源的例子。不论 wk_thread 对应的线程如何退出 (3)，守卫变量 g 都会在声明周期结束是，帮助 wk_thread 确认结束状态 (1)(2)。

## 向线程函数传递参数

前一节中提到，线程函数即是作为线程入口的函数。作为函数，它自然可以接受参数；只不过此前我们举的例子，都是无参数的函数。这一节介绍如何向线程函数传递参数。

首先我们要确认：在线程启动时，向线程函数传递参数是可行的。具体做法，是

- 向 std::thread 的构造函数传递参数，将参数拷贝进线程的内部存储空间；

- 而后，由线程构造函数，将参数传递给线程函数。

### 预先转换格式

我们来看看，如何向线程函数传参。

```cpp
void demo(int, const std::string&);
std::thread demo_t{demo, 42, "hello thread"};
```

这里，我们就新建了一个线程，它调用线程函数 demo(42, "hello thread")。需要注意的是构造函数的第三个参数 "hello thread"，

- 首先，它作为 const char* 被拷贝进入线程内部；

- 而后，它被传递给 demo 作为第二个参数；

- 此时，由于 demo 的第二个参数类型为 const std::string&，所以会发生类型转换。

在这里，被转换的是一个字符串常量，看上去没什么问题。但是，当替换 const char* 为 char* 时，就可能引发严重的后果。

```cpp
void demo(int, const std::string&);

void bad_buffer(const int param) {
    char buffer[2014];                  // 1
    sprintf(buffer, "%i", param);
    std::thread wk_t(demo, 42, buffer); // 2
    wk_t.detach();
    return;                             // 3
}
```

同样地，buffer 是数组名 (1)，作为值使用时被当做指针 (2)，传入 std::thread 的构造函数。而后，在调用 demo 时，尝试转换为 std::string。若 bad_buffer 函数退出 (3) 于上述转换完成之前，那么就会产生一个未定义的行为（Undefined Behavior），这是非常危险的。

因此，关于线程函数传参的铁律是：**必须在参数传递给线程构造之前，就转换好格式**。

### 也需要准备好引用、右值等

由于传参给 std::thread 的过程只是简单的拷贝，当线程函数需要引用或者移动语义的时候，也可能出现问题。

```cpp
void update(double weight, WeightedData& data); // 1

void bad_update(double weight) {
    WeightedData data;
    std::thread wk_t(update, weight, data);     // 2
    t.join();
    process(data);                              // 3
    return;
}
```

代码的意图是通过引用 (1)，在子线程中更新 data 的权值 (2)。然而，由于 (2) 对 data 的处理是简单的拷贝，因此实际上线程函数得到的引用，是对「线程存储空间中的拷贝的引用」。于是，(3) 处理的 data，实际是未有更新的数据。这种情况未必会报错，但是却埋下了难以排查的隐患。

```cpp
void update(double weight, WeightedData& data);

void bad_update(double weight) {
    WeightedData data;
    std::thread wk_t(update, weight, std::ref(data)/* #include <functional> */);
    t.join();
    process(data);
    return;
}
```

类似地，对于一些不可拷贝的类型，我们需要准备好移动语义——在传参的时候，使用 std::move() 得到右值，传递给 std::thread 的构造函数。

### 以非静态成员函数为线程函数

类的非静态成员函数也是函数，因而也可以作为线程函数使用。不过，相比一般的函数（包括静态成员函数），将其作为线程函数使用时，有两个特殊之处。

- 必须显式地使用函数指针，作为 std::thread 构造函数的第一个参数；

- 非静态成员函数的第一个参数，实际上是类实例的指针，在创建线程时，需要显式地填入这个参数。

```cpp
class Foo {
 public:
    void bar(void);
};

void demo() {
    Foo baz;
    std::thread temp_t{&Foo::bar, &baz};
    temp_t.join();
    return;
}
```

此外，必须说明的是，脱离了实例的非静态成员函数是没有意义的。因此，在将非静态成员函数作为线程函数时，必须保证对应的实例可用。