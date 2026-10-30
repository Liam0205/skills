---
title: "程序员的自我修养（六）：保护线程间的共享数据"
url: https://liam.page/2017/06/10/protecting-data-sharing-between-threads/
date: 2017-06-10
categories: ["Algorithm and Computer Science"]
tags: ["C++11", "Multithread", "Race Conditions", "Lock", "Mutex"]
---

进入到[系列文章](/series/)的第六篇。

我们在[前文](/2017/05/06/cxx-concurrency-multithread-basic-problems/)中提到，多进程和多线程最本质的区别在于共享和隔离的程度不同。对于多进程方式来说，因为隔离程度高，所以程序员很少需要去担心进程空间的数据被破坏；但是并发任务之间共享数据就变得很困难了。对于多线程方式来说，因为隔离程度低，所以共享数据非常容易；但是，相应地，程序员需要更多地考虑如何在线程之间安全地共享数据。这就引出了所谓的「线程安全」问题。

此篇，我们讨论如何在线程之间安全地共享数据。

## 在线程间共享数据的问题

### 引子

让我们先来看一个有味道的例子。

假设你邀请朋友到家里来派对。这个派对有些特殊，需要各自准备好食材，而后烹饪成美味——大家比比手艺。朋友 A 准备做辣椒炒肉，而朋友 B 决定用韭菜炒蛋一展身手——他们都已经备好了菜等待下锅。

不幸的是，你家只有一口锅，但是朋友 A 和 B 两不相让。他们在几乎同一时间，分别把自己手头备好的菜下了油锅：

- 朋友 A 把切好的辣椒下了油锅——嘶~

- 朋友 B 把打好的蛋液下了油锅——哗~

于是，厨房里传出了辣椒炒蛋的香味……

在这个例子里，最终朋友 A 和朋友 B 合作了一盘「辣椒炒蛋」。虽然这不是他们预期的结果，但好歹没有引起灾难性的后果。不过，这种「好结果」并不是每次都能发生；更多的时候，可能会做出一堆奇奇怪怪的黑暗料理。

这件事情和我们今天要讨论的问题很是相像，我们看看下面这张表。

美食派对
线程间数据共享

厨房
进程空间

油锅
可在线程间共享的数据

朋友 A 和朋友 B
两个线程

对于没事派对中的这个小插曲，显而易见地，作为主人需要定下一些规矩。对于这个问题，主人需要规定：别人使用完毕之前，其他人不能用锅子（当然也包括锅铲、煤气灶之类的）。在线程间共享数据也是如此。程序员在设计多线程并发程序时，需要协调好多个线程对数据的操作：应当在何时，如何操作数据，并与其它线程进行通信。

### 不变量

在具体讨论之前，我们先了解一下「不变量」这个概念。

所谓不变量，指的是**对于某个数据结构，当其合法可用时，总是成立的一个命题**。在编程时引入不变量，可以帮助程序员正确地处理数据。为了更好地理解不变量，我们来看一下下面这个简单的例子。

```cpp
int sum{0};
constexpr size_t times{100};
// invariant: `i` is the number of integer that we have added to `sum`.
for (size_t i{0}; i != times; ++i) {
    sum += i + 1;
}
// some use of `sum`
```

这是一个非常简单的例子，此处仅用于说明不变量。

在注释中，我已经注明了此处用到的不变量：i 是已经累加的次数。对于 i 来说，它在循环开始前、每次循环迭代之后、循环结束的瞬间，都应该是合法可用的。因此，作为不变量，应该在这三种情形下都成立。若不然，则说明循环写错了。

- 开始前：在循环开始前，我们尚未进行过累加，因此 i == 0 成立；

- 迭代过后：每迭代一次，++i 保证了不变量成立；

- 循环结束：由于 i 自 0 开始自增，直到第一次满足 i != times 的条件终止循环，因此在循环终止时，i == times 成立。

经过这样的验证，我们应当很有信心地说：我的代码是正确的。

注 1：应当写明显没有错误的代码，比如这个例子。注 2：在这个例子中，之所以将循环条件记为 i != times 而不是 i < times，正式因为有不变量的存在。若是记作 i < times，那么循环中止时，应有 i >= times；对应到不变量上，就是「至今为止，已经累加了不小于 times 次」，而这与代码的意图是不一致的。故而，对 C++ 程序员来说，建议写作 i != times 而不是 i < times。注 3：此外，C++ 对 STL 容器引入了「迭代器」的概念。迭代器重载了 == 和 != 等符号，但并不一定重载了了 < 号。事实上，对两个迭代器进行「大小比较」是没有意义的。为了保证一致性，从迭代器的角度说，也不建议 C++ 程序员将此类循环条件写作 i < times。

回过头，再来看一下这个简短的例子。我们不难发现，在执行完 sum += i + 1 的一瞬间，事实上不变量并不成立。比如，当 i == 30 时，我们执行完毕上述赋值表达式时，已经进行了 31 次累加。这告诉我们：**在对操作数据时，有可能会破坏不变量**。这样一来，循环迭代后，对 i 的自增操作，就可以理解为是「维护不变量」了。这件事情告诉我们：**不变量不成立，预示着数据不可用**（通常表示数据操作进行到一半）；**操作数据后，需要维护不变量**。

我们再来看一个稍微复杂一些的例子。

```cpp
// invariant: suppose we have two nodes `A` and `B`,
// then if `A->next_ == B`, then we must have `B->perv_ == A`.
template<typename DataType>
class Node {
 private:
    Node* prev_ = nullptr;
    Node* next_ = nullptr;
    DataType data;
 public:
    // ...
    void Delete() {
        auto prev = this->prev_;
        auto next = this->next_;
        if (nullptr != prev) {
            prev->next_ = next; // 1.
        }
        if (nullptr != next) {
            next->prev_ = perv; // 2.
        }
        this->Destroy();
        return;
    }
};
```

这是一个双链表中结点的简单示例。同样，我在代码注释中已经标明了不变量，即在双链表可用时，对两个合法结点来说，应当有 A->next_->perv_ == A。然而，在删除结点时（更新数据结构时），不变量会被破坏。比如，当 (1) 已经执行完毕，但 (2) 尚未执行时，上述不变量就是不成立的。

假设现在有两个线程，在对同一个双链表进行操作。其中之一尝试从前向后遍历双链表；另一则在删除其中某一个结点。我们之前说，删除结点会临时破坏不变量，而不变量被破坏则表示数据结构是不可用的。那么正在执行删除操作的线程，就可能导致正在遍历的线程出错甚至崩溃。

线程 1
线程 2
注释

if (nullptr != curr->next())

此时检查成功

prev->next_ = next
next 有可能是 nullptr

注意此时不变量被破坏了

work = curr->next()

现在 work 可能是 nullptr

data = work->data()

解引用 nullptr，段错误

上表展现了两个线程同时操作一个双链表时，可能出现的情况。在这种情况下，线程 1 可能因为解引用空指针，而引发段错误，导致整个进程崩溃。

### 竞争状态

我们再看一个有小情绪的例子。

对于国人来说，「春运」总是很头疼的问题。在春运期间，火车票总是不够的。基本上，任何一次买票行为，其结果（能不能买到火车票），都取决于你下手的时机——是否足够快。对于你来说，同样是「点击鼠标确认」这个动作，其结果实际上是不确定的。具体是何种结果，取决于你的行为与其他人行为的相对顺序。

在计算机世界中，我们把**结果取决于多个线程执行指令的相对顺序的情形，称为「竞争状态」**。若是竞争状态发生在多个线程对同一个数据结构的修改上，则称其为「数据竞争」。因为竞争状态的结果是不确定的，所以数据竞争可能导致未定义行为（Undefined Behavior, 缩写 UB，读作「有病」）。

结合不变量的概念，不难理解。如果一个行为可能在其中间状态破坏不变量，则由此行为引发的竞争状态，可能导致灾难后果。而若要破坏不变量，通常来说意味着该操作需要更新多个变量，而这些更新操作无法在单个指令完成——因而有被打断的可能。由数据竞争导致的问题通常难以排查。这是因为，尽管这些操作可能被打断，但并不是每次都会打断。通常来说，只有当系统负载很高，CPU 需要频繁地切换上下文时，数据竞争的可能性才会增大。因此，排查由数据竞争导致的问题，一般来说是非常困难的。

### 避免恶性数据竞争

既然数据竞争通常可能会招致 UB，那么我们就要想办法避免它。通常来说，避免恶性数据竞争有几个思路。

- 保护数据结构，确保在数据结构更新过程中，其不变量被破坏的中间状态只有一个线程能够看到。

- 修改数据结构的实现，确保任何对数据结构的更新，在外界看来不变量都是成立的。

- 将所有对数据结构的修改，都交给第三方串行执行。

对于第三种方案，以之前购买火车票的例子来说，可以实现为：当你点击确认按钮后，购票网站将你的请求发送给服务器，服务器将请求加入一个队列，并返回一个状态。例如：「当车次剩余车票 1000 张，在您之前有 800 个尚未处理的请求」。这样一来，通常来说，购票行为的结果就是确定的了。

然而，C++ 标准库并没有实现上述第三种方案。故此，此处我们不做更深入的讨论。

## 使用互斥量保护数据

保护数据的最基本方法是使用所谓的「互斥量」（**mut**ual **ex**clusion, *mutex*）。

互斥量的基本逻辑是这样的。

- 访问某个数据结构时，首先检查互斥量。
若互斥量被锁住，则等待，直到互斥量解锁。
若互斥量没有被锁住，则锁住互斥量，而后更新数据，再解锁。

听起来是个挺美好的事情，若能实现，那么数据竞争就能被解决。然而，所谓「没有银弹」，并不是说引入互斥量就能完美解决所有问题。

- 首先，互斥量起作用是有前提的。
所有可能引发数据竞争的数据结构都被保护起来了；
所有可能引发数据竞争的操作，都正确地使用了互斥量。

- 其次，互斥量可能引发所谓的「死锁」问题。

- 最后，若互斥量过多或过少地保护了数据，都可能出现问题。

### 在 C++ 中使用互斥量

在 C++ 中，标准库提供的互斥量是 std::mutex，它被定义在 mutex 这个头文件中。

互斥量是「锁」的一种，按照我们在 [C++ 的几个基本原理和技术](/2017/04/09/Foundations-of-Cpp/)中的介绍，锁也是一种资源。因此为了保证资源被正确释放（正确使用互斥量的条件之一），我们最好是用 RAII 技术将其包装起来。C++ 标准库直接提供了这样的封装，名为 std::lock_guard，它也定义在 mutex 这个头文件当中。

我们来看一个简单的例子。

```cpp
#include <list>
#include <mutex>
#include <algorithm>

typedef std::lock_guard<std::mutex> guarded_mutex;

std::list<int> data_list;               // 1.
std::mutex data_mutex;                  // 2.

void add_to_list(int new_value) {
    guarded_mutex guard{data_mutex};    // 3.
    data_list.push_back(new_value);
}

bool list_contains(int value_to_find) {
    guarded_mutex guard{data_mutex};    // 4.
    return (data_list.end() != std::find(data_list.begin(), data_list.end(), value_to_find));
}
```

例中，(1) 和 (2) 分别定义了全局变量。此处，我们意图用 (2) 定义的全局互斥量保护对 (1) 定义的链表进行保护。(3) 和 (4) 通过 RAII 容器 std::lock_guard 在构造时，对传入的互斥量 data_mutex 上锁，并在 guard 销毁时自动解锁。

在这个例子中，若是 add_to_list 和 list_contains 分别在不同线程中执行，则他们都会尝试锁上 data_mutex 这个互斥量。显而易见，同一时刻，只能有一个函数能成功锁上它；于是该函数正常执行，而另外一个函数则会陷入等待。这样一来，data_list 更新期间，不变量被破坏的中间状态，就只有修改它的线程能看到。而对于其他线程来说，data_list 要么没有被修改，要么已经修改完成，因而总是可用的。

在这个简单的例子里，被保护的数据和互斥量都是全局变量。显而易见，这是不好的。首先，使用全局变量，意味着任何函数都有可能修改它。其次，除了 data_list 和 data_mutex 的定义连在一起，它们之间在代码上没有其他的联系。因此，很可能出现程序员使用 data_mutex 来保护其他数据；或者使用其他互斥量来保护 data_list 的现象。这样一来，保护就不完整了。因此，在实际使用中，通常我们会选择将 data_list 和 data_mutex 封装在同一个类当中。

### 限制被保护数据的使用范围

上一节，我们了解了如何使用互斥量保护数据。此外，谈到了「正确使用」的要求之一：锁上互斥量之后必须解锁（否则其他线程永远无法上锁，就可能陷入无休止的等待）。这一节讨论正确使用的另一个要求：必须限制被保护数据的使用范围。简单来说，就是**不要**将被保护数据的**指针或引用**通过返回值、函数参数的方式，传到无法控制的范围内。这个约定，是基于一个简单的假设：你无法保证在你无法控制的范围内，其他程序员是否按照约定使用互斥量保护这份数据。

我们看一个**不好的**例子。

```cpp
template<typename DataType>
class Container {
 private:
    typedef std::lock_guard<std::mutex> guarded_mutex;
    std::mutex mtx_;                    // 1.
    DataType* data_;                    // 2.
 public:
    // ...
    template<typename FuncType>
    void process_data(FuncType func) {  // 3.
        guarded_mutex l(this->mtx_);
        func(this->data);               // 4.
        return;
    }
};

std::list* unprotected;

void malicious_function(std::list* protected_data) {
    unprotected = protected_data;       // 5.
    return;
}

Container<std::list> ctn;

void foo () {
    ctn.process_data(malicious_function);
    unprotected->clear();               // 6.
}
```

在这个例子当中，Container 使用 (1) mtx_ 保护 (2) data_。但需要注意的是，(3) 接收的函数 func 是一个外部函数。由于在写 Container 这段代码时，你无法与之以后的用户，会传递何种 func 进来。所以对于 Container 的作者来说，func 是不可控的。但是，(4) 将内部被保护的数据的指针，作为参数传递给了 func。接下来的事情就变得糟糕了。首先我们定义了一个恶意函数 malicious_function，在其中 (5) 将传递进来的指针赋值给了一个没有任何保护的全局指针变量 unprotected。而最后，在没有任何保护的情况下，(6) 清空了整个链表。这个操作是非常危险的。

因此，在使用互斥量保护数据的时候，需要注意：

- 不能将被保护数据的指针或引用以函数返回值的形式，返回给外部不可控的调用者；

- 不能将被保护数据的指针或引用以函数参数的形式，传递给外部不可控的调用者。

### 死锁及其解法

回到我们最开始有味道的例子。

假设现在你给锅、铲都加上了互斥量。这样一来，你希望朋友 A 和朋友 B 不会在同一时间共用锅铲，避免未定义的行为。然而，新的问题又来了。

朋友 A
朋友 B
注释

给锅铲上锁

给锅子上锁

开始使用锅子

开始使用锅铲

尝试获取锅子的锁

朋友 A 开始等待

尝试获取锅铲的锁
朋友 B 开始等待

现在，因为有锁的保护，所以朋友 A 和朋友 B 不会再同时使用锅或铲了，避免了「辣椒炒蛋」的闹剧。但是，现在朋友 A 和朋友 B 来到你的面前，向你哭诉：「我的心在等待，永远在等待」。

朋友 A 期待使用锅子，然而因为锅子对应的锁被朋友 B 锁上，所以朋友 A 不得不等待朋友 B 使用完毕之后才行；另一方面，朋友 B 需要使用锅铲，对应的锁却被朋友 A 锁上了。这样一来，由于朋友 A 和朋友 B 互相等待，但各自又什么都做不了。于是两人只能大眼瞪小眼，永远「耗下去」。

在并发编程领域中，我们把这种现象称之为「死锁」。对于由「锁」引起的「死锁」，它有几个特点：

- 完成一个任务，需要获取多把锁；

- 存在数据竞争；

- 各自持有一部分数据对应的锁，互相等待，永不释放。

为了解决死锁问题，前辈们曾经提出了很多方案。其中最基本的一个方案是说：在操作需要获取多把锁时，总是以固定的顺序获取这些锁。比如，在我们的例子里，如果要求必须先获取锅铲对应的锁，再去获取锅子对应的锁；那么由于锅铲对应的锁被朋友 A 首先持有，那么朋友 B 就只能等待 A 做好菜之后，才能一展身手。这样一来，死锁的问题就解决了。

然而，这样的建议并不能解决所有问题。所谓「固定顺序」的前提是我们能够以某种方式定义出稳定的顺序关系。然而，有时候我们无法在代码中定义这样的顺序。比如，假设有两个对象，它们是同一个类的两个实例。现在，我们希望在某个线程里，交换二者的内容。显而易见，我们应该要用对应的锁分别保护两个对象，避免被并发的其他线程破坏。然而，在此二者之间，你很难定义具体的顺序。索性，C++ 标准库提供了 std::lock() 函数，用于同时锁住多个互斥量，并且没有死锁的风险。

以下示例展示了如何用 std::lock() 函数同时锁住两个互斥量。

```cpp
template<typename DataType>
void swap(DataType& lhs, DataType& rhs);

template<typename DataType>
class Container {
 private:
    typedef std::lock_guard<std::mutex> guarded_mutex;
    std::mutex mtx_;
    DataType data_;
 public:
    friend void swap(Container<DataType>& lhs, Container<DataType>& rhs) {
        if (&lhs == &rhs) { return; }                   // 1.
        std::lock(lhs.mtx_, rhs.mtx_);                  // 2.
        guarded_mutex g_lhs(lhs.mtx_, std::adopt_lock); // 3.
        guarded_mutex g_rhs(rhs.mtx_, std::adopt_lock); // 4.
        swap(lhs.data_, rhs.data_);
    }
};
```

例子中，首先我们在 (1) 处判断传入的两个容器是否不同。这是因为，对同一个 std::mutex 在线程中反复上锁是未定义行为。而后我们在 (2) 处使用 std::lock() 函数，同时锁住 lhs 和 rhs 的互斥量。之后，我们在 (3) 和 (4) 处使用 RAII 容器接管已经上锁的互斥量。注意，这里传入的 std::adopt_lock 表示该互斥量已经上锁，std::lock_guard 只需要接管互斥量的所有权即可，不需要再次上锁。在此之后，我们就可以安心地调用 swap 函数交换两个 DataType 中的内容了。

### 当 std::lock 解决不了死锁的时候

对于死锁，std::lock 函数能够保证一次性锁住多把锁，从而在一定程度上解决了问题。之所以说它只是在一定程度上解决问题，是因为还有很多情况，是无法使用 std::lock 的。比如，有一些情况必须要在不同的位置，分别锁上不同的锁。这时候，std::lock 就不适用了。此外，死锁问题并不仅仅是发生在和互斥量相关的情形中，此时使用 std::lock 也解决不了问题——因为根本不存在锁的问题。

对于 std::lock 解决不了的死锁情况，想要写出不会死锁的代码，就需要靠一些规玄矩学来保证了。对于这些规矩，我们简单罗列如下。

- 避免需要获取多个锁的情况：从根本上避免死锁的可能；

- 持有锁的时候，不要调用不可控的用户函数：因为你不知道用户函数会做什么，比如它可能会锁上另一把锁；

- 如果必须获取多个锁，那么按顺序上锁：从而避免竞争；

- 使用层次锁，强制要求上锁的顺序：这是在上一条规矩的基础上衍生而来的。

## 奇行种，以及一些其他问题

### 层次锁

首先我们看一个名为层次锁的奇行种。

层次锁是为了保证上锁顺序而设计出来的奇怪物种。当一个线程尝试对一个层次锁上锁时，需要检查当前已经上锁的锁的层次，从而保证当前尝试上锁的层次低于已经上锁的层次。以下是对层次锁的一个简单实现。

```cpp
class hierarchial_mutex {
 private:
    typedef size_t level;
    typedef std::lock_guard<std::mutex> guarded_mutex;
    static constexpr
    level max_level = std::numeric_limits<std::size_t>::max();
 private:
    std::mutex mtx_;
    const level mtx_level_  = 0;
    level prev_mtx_level_   = 0;
    static thread_local
    level thread_mtx_level;

    inline void check_level() {
        if (not(mtx_level_ < thread_mtx_level)) {
            throw std::logic_error("mutex hierarchy violated!");
        }
        return;
    }
    inline void update_level() {
        prev_mtx_level_  = thread_mtx_level;
        thread_mtx_level = mtx_level_;
        return;
    }
    inline void recover_level() {
        thread_mtx_level = prev_mtx_level_;
        return;
    }
    hierarchial_mutex(const hierarchial_mutex&) = delete;
    hierarchial_mutex& operator=(const hierarchial_mutex&) = delete;
 public:
    hierarchial_mutex() :
        mtx_level_{0}, prev_mtx_level_{0} {}
    hierarchial_mutex(const level& value) :
        mtx_level_{value}, prev_mtx_level_{0} {}
    void lock() {
        check_level();
        mtx_.lock();
        update_level();
    }
    void unlock() {
        recover_level();
        mtx_.unlock();
    }
    bool try_lock() {
        check_level();
        if (not(mtx_.try_lock())) {
            return false;
        } else {
            update_level();
            return true;
        }
    }
};
thread_local hierarchial_mutex::level
hierarchial_mutex::thread_mtx_level{hierarchial_mutex::max_level};
```

在接口上，hierarchial_mutex 基本上完整地实现了 std::mutex 的接口。不同的是，首先，每个 hierarchial_mutex 都有一个自己的等级 mtx_level_；在 lock(), unlock() 和 try_lock() 时，hierarchial_mutex 需要对 thread_mtx_level 以及 prev_mtx_level_ 进行维护。其中，thread_mtx_level 是 static thread_local 的，这意味着，同一个线程的不同 hierarchial_mutex 公用一个 thread_mtx_level，而不同线程之间则是不同的 thread_mtx_level。

### 允许额外上锁的 RAII 容器：std::unique_lock

前文提到了 RAII 容器 std::lock_guard。它会在构造时对传入的互斥量上锁（如果没有 std::adopt_lock 标志的话），并在销毁时解锁。然而，std::lock_guard 实例没有 lock(), unlock() 以及 try_lock() 函数，因此一旦锁上，就必须等待实例销毁才能解锁互斥量。若是在锁住互斥量的过程中，有一些不必上锁但特别耗时的外部 I/O 操作，那么 std::lock_guard 的这一特性就会降低并发效率。

std::unique_lock 和 std::lock_guard 一样，都是对互斥量的 RAII 容器。不同的是，std::unique_lock 提供了 lock(), unlock() 和 try_lock() 函数，能够通过 RAII 容器锁住/解锁内部的互斥量。除此之外，std::unique_lock 还能保证在销毁时正确解锁内部的互斥量。

之前的 swap 示例，若使用 std::unique_lock 则应是如下光景。

```cpp
template<typename DataType>
void swap(DataType& lhs, DataType& rhs);

template<typename DataType>
class Container {
 private:
    typedef std::unique_lock<std::mutex> guarded_mutex;
    std::mutex mtx_;
    DataType data_;
 public:
    friend void swap(Container<DataType>& lhs, Container<DataType>& rhs) {
        if (&lhs == &rhs) { return; }
        guarded_mutex g_lhs(lhs.mtx_, std::defer_lock); // 1.
        guarded_mutex g_rhs(rhs.mtx_, std::defer_lock); // 2.
        std::lock(lhs.mtx_, rhs.mtx_);
        swap(lhs.data_, rhs.data_);
    }
};
```

此处，我们在 (1) 和 (2) 中提供了对互斥量的封装，并声明 std::defer_lock，以在后面使用 std::lock 一次性锁住两个互斥量。当然，在这个例子中，std::unique_lock 相对 std::lock_guard 的优势并没有体现出来，仅只是一个示例。

### 锁的粒度

多线程提高执行效率的根源，在于多个线程可以同时执行不同的指令。然而，锁的存在会破坏这一特性。当多个线程同时尝试访问被互斥量保护的数据时，除了成功获取锁的线程，其它线程都被阻塞住，等待锁被释放。当然，为了线程安全，这种阻塞是不可避免的；然而，另一方面，过多的阻塞，必然降低并发效率，「吃掉」并发带来的性能提升。

这样一来，使用合适的粒度，减少不必要的等待就显得很有必要了。一般来说，锁的粒度可以定义为：被锁保护的数据的量在时间上的累积。

$$ \text{锁的粒度} \overset{\small\text{def}}{=} \text{被保护的数据量}\times \text{因持有锁而阻塞其他线程的时间}. $$

显而易见，如果一个锁保护的数据量很大，那么其它线程获取相应的锁的次数就会相应增加；另一方面，如果某个线程长时间持有锁，那么其他线程因此阻塞等待的时间就会很长。因此，在保证线程安全的情况下，我们应该尽可能降低锁的粒度。

为了减小锁的粒度，一方面我们可以减少锁保护的数据量，另一方面则可以降低线程持有锁的时间。前者需要具体问题具体分析地进行竞答细算；后者则相对容易分析。

对于数据结构的操作，大体可以分为以下三个步骤：

- 读取数据（可能是其中一部分）；

- 处理数据；

- 回写处理结果。

通常来说，对数据进行处理，这件事情本身不会破坏数据结构的不变量，因而不用加锁；而读取和写入数据是需要用锁保护的。因此，如果粗犷地用锁将上述整个过程保护起来，而处理数据的时间很长（例如有网络 I/O），那么这样无疑效率是很低的。因此，我们可以考虑在处理数据的过程中，释放锁；而仅用锁保护对数据的读取和回写过程。

```cpp
void get_process_write() {
    std::unique_lock<std::mutex> lk(a_mutex);   // 1.
    Data chunk = get_data_chunk();
    lk.unlock();                                // 2.
    Result res = process_data_chunk(chunk);
    lk.lock();                                  // 3.
    write_back(chunk, res);
}
```

代码简单展现了应用 std::unique_lock 管理互斥量 (1) 的过程。在读操作完成之后，解锁互斥量 (2)，而在写操作之前，再次锁住互斥量 (3)。这样一来，在 process_data_chunk 的过程中，当前线程并不持有锁，因而降低了锁的粒度。

### 读写锁与 std::shared_mutex 和 std::shared_lock

在进一步探讨锁的粒度之前，我们回顾一下在介绍竞争状态的时候，我们讲到，线程安全需要解决的本质问题，是保证不变量被破坏的中间状态，数据结构仅只对修改它的那个线程可见。从此出发，我们不难理解以下两个推论。

- 因为仅仅「读取」数据不会破坏不变量，所以多个线程同时读取某个数据结构是安全的。

- 但是，另一方面，如果有一个线程尝试对数据进行修改，那么若有其他线程在访问该数据结构（不论读写），都可能是不安全的。

这样一来，不难发现，对于「读」和「写」两类操作，数据结构所需的「保护」，其程度是不一样的。

- 若一个线程仅只是读取一个数据结构，那么只需保证没有其他线程同时写入即可，但其它线程对数据结构的读操作是安全的。

- 若一个线程尝试修改一个数据结构（写操作），那么其它线程对该数据结构的读写操作都是不安全的，因而应该被禁止。

对一个频繁进行写操作的数据结构来说，按照读写操作，区分保护程度意义不大。这是因为，区分两种程度的保护，必然带来额外的开销。而若是某个数据结构的读操作的频率远远大于写操作，那么进行这样的区分，从而降低锁的粒度，收益就很客观了。

为此，我们引入 std::shared_mutex 的概念。除了和一般的 std::mutex 一样提供 lock(), try_lock() 和 unlock() 之外，std::shared_mutex 还提供了 lock_shared(), try_lock_shared() 和 unlock_shared() 三个操作。

阻塞情况表
自由
被共享锁住
被独占锁住

lock()
以独占方式锁住
阻塞
阻塞

lock_shared()
以共享方式锁住
以共享方式锁住
阻塞

std::shared_mutex 直到 C++17 才被引入。若你的编译器不支持 C++17，请升级你的编译器，或者使用 boost::shared_mutex 代替。

于是，我们可以使用 std::shared_mutex 保护频繁读取而甚少写入的数据结构，并在读取时使用 lock_shared() 锁住互斥量，而在写入时使用 lock() 锁住互斥量。

与 std::unique_lock 对应，标准库也提供了 std::shared_lock 容器。它会在构造时，尝试以 lock_shared() 锁住传入的[共享互斥量](http://en.cppreference.com/w/cpp/concept/SharedMutex)，并在销毁时，确保以 unlock_shared() 的方式释放共享互斥量。同时，std::shared_lock 也提供了 lock() 和 unlock() 接口，用于以共享的方式锁住或者解锁构造时关联的共享互斥量。

std::shared_lock 直到 C++14 才被引入。若你的编译器不支持 C++14，请升级你的编译器，或者使用 boost::shared_lock 代替。

读写锁的一个典型应用场景是线程共享的数据缓存。对于缓存来说，存在于缓存内的条目（entry）通常会被频繁读取，而写操作则相对来说低频很多。比如，DNS 服务器上的缓存就是这样的情况。DNS 解析记录一般来说是非常稳定的——频繁更换解析结果的域名总是少数。这里以 DNS 缓存作为读写锁的简单示例。

```cpp
#include <unordered_map>
#include <string>
#include <mutex>
#include <shared_mutex>

class DNSEntry;

class DNSCache {
 public:
    typedef std::unordered_map<std::string, DNSEntry> RecMap;

 private:
    RecMap entries_;
    mutable std::shared_mutex entry_mutex_;                     // 1.

 public:
    DNDEntry find_entry(const std::string& domain) const {
        std::shared_lock<std::shared_mutex> slk(entry_mutex_);  // 2.
        const RecMap::const_iterator target = entries_.find(domain);
        const bool found = (target !+ entries_.end());
        return found ? target->second : DNSEntry();
    }
    void update_one_entry(const std::string& domain, const DNSEntry& entry) {
        std::unique_lock<std::shared_mutex> ulk(entry_mutex_);  // 3.
        entries_[domain] = entry;
        return;
    }
};
```

此处 (1) 为保护 RecMap 引入了一个共享互斥量，它是 mutable 的，因而[允许在 const 成员函数中做修改](/2017/05/25/the-mutable-keyword-in-Cxx/)。(2) 通过 std::shared_lock 容器，以共享的方式锁住互斥量，保证读操作的稳定；(3) 则通过 std::unique_lock 容器，以独占的方式锁住互斥量，保证写操作的安全。

### 保护数据的初始化过程

我们在[前作](/2017/01/17/layers-and-operation-system/#CPU_%E5%8A%A8%E6%80%81%E8%B0%83%E5%BA%A6)中，介绍了一个 GetInstance 函数。通常，这种用法适用于构造过程开销很大，而使用过程本身是线程安全的情况（比如连接数据库的过程）。在线程中使用 GetInstance 函数获取数据的指针，而不是在进程启动时构造数据，可以加快程序的启动速度，减少总体的等待时间。为了避免额外的获取锁的操作，前作首先使用了两次指针检查的方式。

```cpp
volatile T* pInst = nullptr;
T* GetInstance() {
    if (nullptr == pInst) {
        lock();
        if (nullptr == pInst) {
            pInst = new T;
        }
        unlock();
    }
    return pInst;
}
```

然而，由于 CPU 的动态调度，这样的代码可能引发严重的问题。于是，前作引入了基于操作系统架构的解决方案。

```cpp
#define barrier() __asm__ volatile("mfence")
volatile T* pInst = nullptr;
T* GetInstance() {
    if (nullptr == pInst) {
        lock();
        if (nullptr == pInst) {
            T* temp = new T;
            barrier();
            pInst   = temp;
        }
        unlock();
    }
    return pInst;
}
```

然而，mfence 是 i386 架构特有的指令。因此，这份代码在别的架构上无法正确执行。为了保证通用性，C++11 引入了 std::once_flag 和 std::call_once 解决这类问题。

```cpp
#include <mutex>

volatile T* pInst = nullptr;
std::once_flag flag_T;                          // 1.

void ConstructInstance() {                      // 2.
    pInst = new T;
}

T* GetInstance() {
    std::call_once(flag_T, ConstructInstance);  // 3.
    return pInst;
}
```

此处，(1) 初始化了一个对于类型 T 的哨兵变量，用于标记 T 类型的实例是否已经初始化。(2) 则是对实例初始化的封装。在 (3) 处，我们使用 std::call_once 确保 ConstructInstance 有且只有一次调用，从而返回正确的实例对象的指针。

## 锁解决不了的竞争状态

### 接口固有的竞争状态

使用锁保护数据，通过阻塞其它线程的方式，可以避免一些竞争状态。因此，在一些数据结构中，使用锁可以保证数据结构对外的几个接口互相之间是线程安全的。然而，这并不意味着在外部调用这些接口就一定是线程安全的。事实上，这些接口本身可能存在**固有的竞争状态**，因而在其内部使用锁保护数据不能完全解决问题。

举例来说，对于一个标准的栈，除去其构造函数和交换函数 swap()，还有五个接口：

- push(): 将新元素压栈；

- pop(): 弹出栈顶元素；

- top(): 返回栈顶元素；

- empty(): 判断栈是否为空；

- size(): 返回栈的大小。

这五个接口中，隐含了两类固有的竞争状态。

第一类：通过 empty() 或 size() 判断栈状态，而后对栈做其他操作。这是竞争状态的原因在于，在多线程环境中，empty() 和 size() 的返回值是不可信的。比如，在 A 线程调用 empty() 并返回 false 之后，B 线程可能紧接着清空了整个栈，而后 A 线程基于上述 false 判断调用 top() 函数就会产生不可描述不符合预期的结果。

第二类：首先通过 top() 获取栈顶元素，而后通过 pop() 弹栈该元素。之所以这也是竞争状态，是因为在 top() 和 pop() 之间，其它线程可能进行额外的 push() 或者 pop() 操作，于是当前线程弹出的元素不一定是通过 top() 获取的那个元素。

不难发现，因为这两类固有的竞争状态，不论栈的内部如何实现，外部使用栈时，都可能有线程不安全的情况。

### top() 和 pop() 分离的原因

上述两类固有的竞争状态源自栈的接口设计。对于第一类竞争状态来说，如此设计似乎情有可原。但是，为什么要将 top() 和 pop() 分离开呢？

简单来说，top() 将栈顶元素返回给调用者的过程意味着存在一次元素的拷贝。如果栈顶元素体积很大，比如是一个非常长的 std::vector<int>，那么在拷贝的过程中，可能因为系统负载相对资源过高，而抛出 std::bad_alloc 异常。对于现有的实现来说，即使抛出异常，栈内的元素还是完整的。但若是将 pop() 实现在弹栈之后将被弹栈的栈顶元素返回给调用者，则在上述异常可能发生在栈已经被修改之后。若是前一种情况（即当前的实现），调用者在收到异常时，可以尝试进行一些处理；但是，在后一种情况下，即使调用者尝试做了一些内存清理工作，栈中的目标元素也已经被销毁了。

### 修改接口，实现线程安全

以下是一个线程安全的栈的简单实现，分析后附。

```cpp
#include <exception>
#include <memory>
#include <mutex>
#include <stack>

struct empty_stack : public std::exception {                    // 1.
    const char* what() const throw();
};

template<typename T>
class threadsafe_stack {
 private:
    std::stack<T> stack_;                                       // 2.
    mutable std::mutex mtx_;                                    // 3.

 public:
    threadsafe_stack() {}
    explicit threadsafe_stack(const threadsafe_stack& source) {
        std::lock_guard<std::mutex> slk(source.mtx_);
        stack_ = source.stack_;
    }
    threadsafe_stack& operator=(const threadsafe_stack& source) {
        std::lock_guard<std::mutex> slk(source.mtx_);
        stack_ = source.stack_;
    }

    bool empty() const {                                        // 4.
        std::lock_guard<std::mutex> slk(mtx_);
        return stack_.empty();
    }
    size_t size() const {
        std::lock_guard<std::mutex> slk(mtx_);
        return stack_.size();
    }

    void push(T element) {
        std::lock_guard<std::mutex> ulk(mtx_);
        stack_.push(element);
    }
    std::shared_ptr<T> pop() {                                  // 5.
        std::lock_guard<std::mutex> ulk(mtx_);
        if (stack_.empty()) {
            throw empty_stack();
        }
        std::shared_ptr res{std::make_shared<T>(stack_.top())};
        stack_.pop();
        return res;
    }
    void pop(T& ref_holder) {                                   // 6.
        std::lock_guard<std::mutex> ulk(mtx_);
        if (stack_.empty()) {
            throw empty_stack();
        }
        ref_holder = stack_.top();
        stack_.pop();
    }
};
```

此处我们实现了名为 threadsafe_stack 的模板类。其中，显而易见，我们的线程安全栈的实现是基于标准库中的栈的 (2)，并且为了实现线程安全，我们使用了一个互斥量来保护栈对象 (3)。此外，尽管存在一些只读的公开成员函数 (4)；但是，考虑到实际使用中，大量的栈操作都是写操作，因此 (3) 没有使用读写锁。

为了解决第一类固有竞争状态，我们首先在 (1) 处定义了空栈异常——我们让对空栈进行的 pop() 操作 (5, 6) 抛出空栈异常。如此，在调用处使用 try ... catch ... 语句块，就能实现预期的行为，同时避免接口竞争。

为了避免第二类固有竞争状态，我们取消了 top() 函数，而将它的功能合并入 pop() 函数。同时，为了避免在抛出 std::bad_alloc 时元素已弹栈导致的数据丢失的问题，我们在内部栈对象弹栈之前，尝试将目标元素拷贝 (5) 或赋值 (6) 到其它地方。最后，我们返回拷贝的结果的指针 (5) 或引用 (6) 传给调用者。如此，就避免了第二类竞争。

## 小结

如我们在[前作](/2017/01/17/layers-and-operation-system/)最后提到的，「线程安全」是一个烫手山芋，不存在放之四海而皆准的解决方案（所谓「没有银弹」）。因此，为了写出线程安全的代码，我们必须在理解问题之起因的基础上，具体问题具体分析。

为此，此篇从「不变量」开始，引出在线程中共享数据的「竞争状态」——线程安全问题的根源。而后就如何解决问题展开了一系列的讨论。首先，我们介绍了如何使用标准库提供的「锁」来保护共享数据结构，并介绍了和锁相关的一些话题（如死锁问题、锁的粒度等）。而后，我们通过实现线程安全的栈，讨论了锁无法解决问题时，应当怎么办。

此篇无法穷尽所有和线程安全、锁、死锁相关的话题和技术。但是，建立在理解的基础上，读者应该能对线程安全有直观的认识。我想这应该是有益的。