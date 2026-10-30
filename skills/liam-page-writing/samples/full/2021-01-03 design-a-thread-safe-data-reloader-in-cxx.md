---
title: "设计一个线程安全的数据重载器"
url: https://liam.page/2021/01/03/design-a-thread-safe-data-reloader-in-cxx/
date: 2021-01-03
categories: ["Algorithm and Computer Science"]
tags: ["Thread", "Thread-safe", "Data", "Dict", "Reloader"]
---

实际工程中，可能会遇见这样的场景：

一个词典，在 C++ 里实现为一个 class。它的生命周期从进程启动开始到进程杀死结束。这个词典很大，所以在多线程工作的时候，希望在全局共享一份。

现在的问题是，进程可能持续跑很长时间，比如跑几个月。在进程执行过程中，这个词典可能会更新。于是我需要重新载入词典。要求线程安全并且高效地做这个重新载入的工作。

今天我们来设计一下，要怎样实现它。

## 初步讨论

比较显然的是，这一功能将代码分成了相对独立的两个部分：词典和重载器。词典负责数据的管理，并提供数据查询的功能。重载器负责按照一定规则，触发重载动作，以及负责提供安全的词典访问机制。

为通用计，我们希望重载器能够管理多种不同的词典。这些词典可能管理不同的数据类型、格式，也可能提供不同的访问接口。就后者而言，这意味着不同词典类可能提供了不同的查询函数签名。

为解决这个问题，考虑到重载器只需负责触发重载动作，而不需关心查询接口，在 C++ 里大体有两种比较成熟的思路：

- 实现一个基类，其名为 Reloadable，并定义一个名为 load 的纯虚函数作为接口。所有词典继承 Reloadable，并实现该接口，而后作为模板类 Reloader 的模板参数，传递给重载器，重载器调用 load 接口。

- 无需基类，将词典类多种多样的读取接口，封装成各自的可调用对象（利用 std::bind 之类的工具），而后作为回调函数传递给 Reloader。

前一种方式是面向对象和模板思路，后一种方式是函数式的思路。两种方式的共同特点，是都可以在少量修改的情况下，应用于已有的词典类。相较而言，后一种方式完全不用修改已有的词典类本身，提供了更大的自由度。

但在工程中，这种自由度累积起来，往往会泛滥成灾。因此我个人更倾向于使用第一个方案。

至此，我们需要设计一个 Reloadable 和一个 Reloader 类，来实现这个需求。

## Reloadable

按讨论，Reloadable 应该是一个虚基类，其有一个名为 load 的纯虚函数作为接口，负责读入数据。我们将其定义如下。

```cpp
struct Reloadable {
  Reloadable() = default;
  virtual ~Reloadable() = default;  // 1.

  Reloadable(const Reloadable&) = delete;  // 2.a.
  Reloadable& operator=(const Reloadable&) = delete;  // 2.b.

  Reloadable(Reloadable&&) = default;  // 3.a.
  Reloadable& operator=(Reloadable&&) = default;  // 3.b.

  virtual bool load(const std::string& path) = 0;  // 4
};
```

这里，

- 我们将析构函数声明为 virtual，是因为显然 Reloadable 会是一个基类。为避免子类析构不完全造成内存泄露，我们都需要将基类的析构函数声明为虚函数。

- 由于词典数据往往很大，而又在多线程中共享。那么显然对数据的拷贝是不必要的。于是我们将拷贝构造和拷贝赋值都声明为 delete。

- 与 (2) 对应，移动操作是允许的。

- 我们将 load 接口声明为纯虚的，它留待子类实现。入参 path 是一个字符串，它通常会是一个路径，指向数据本身，或是词典的配置文件。

## Reloader

按讨论，Reloader 应该是一个虚基类模板。它有一个模板参数 Payload，是 Reloadable 的子类。而后提供几个关键接口：

- init：负责初始化重载器。由于重载器会在多线程共享，所以初始化应该只执行一次。

- inited：负责观察重载器是否已初始化成功。

- get：负责返回 Payload，供外部使用。

- terminate：负责终止重载器，通常在进程终止时调用它。

于是我们可以设计 Reloader 的大体框架。

```cpp
template <typename Payload,
          std::enable_if_t<std::is_base_of<Reloadable, Payload>::value, bool> = true>  // 4.
class Reloader {
 public:
  using payload_t = Payload;
  using ptr_t = std::shared_ptr<payload_t>;  // 1.a.

 public:
  Reloader() = default;
  virtual ~Reloader() = default;  // 2.a.

 private:
  Reloader(const Reloader&) = delete;  // 2.b.
  Reloader& operator=(const Reloader&) = delete;  // 2.c.

 public:  // modifiers
  bool init(const std::string& path);
  virtual void terminate() = 0;  // 3.

 public:  // observers
  bool inited() const;

  ptr_t get() const;  // 1.b.
};
```

这里，

- get 接口的返回类型是 Payload 的智能指针。此处用智能指针，有两个考虑。一是避免值语义，使用引用语义。这样避免了数据的拷贝（实际上 Payload 已经禁止了拷贝，想用值语义必然报错）。二是管理 Payload 的生命周期，避免使用裸指针时，外部通过 get 拿到数据，却为 reload 析构，造成野指针。

- 基于类似的理由，我们将 Reloader 的析构函数声明为 virtual，将拷贝动作声明为 delete。

- 和 init 不同，terminate 接口被声明为纯虚。这是因为，适应不同的重载方式，其 init 都承担了相同的指责：第一次载入数据；而 terminate 则依据重载方式会有不同的写法。

- 这里 std::enable_if_t，强制保证了模板参数 Payload 是 Reloadable。这保证了 Payload 一定有符合规范的 load 接口。

### inited

我们首先考虑观察器 inited。重载器是否初始化，这个状态对于外部，有三种：

- 未初始化

- 初始化中

- 已初始化

当然，可能还有第四种：初始化失败。我们可将其归结于「未初始化」当中。

虽有三种状态，但对于外部来说，有意义的只有「是/否」。于是，我们可用一原子变量，来维护初始化状态。于是我们有：

```cpp
template <typename Payload>
class Reloader {
  // ...

 private:
  std::atomic_bool inited_{false};
  // ...

 public:  // observers
  bool inited() const {
    return inited_.load(std::memory_order_acquire);  // 1.
  }
  // ...
};
```

- 这里唯一需要关注的是顺序标记。std::memory_order_acquire 与 release-store 组成同步关系，确保 inited() 函数返回 true 时，确实有 reload() 和 launch() 已执行完毕。

### get

显然，Reloader 应该有一个成员，保存着由其管理的数据的智能指针。当外部调用 get 接口时，我们根据初始化状态，来判断如何返回。

```cpp
template <typename Payload>
class Reloader {
  // ...

 private:
  // ...
  mutable std::shared_mutex mtx_;  // 1.a.
  ptr_t payload_;
  // ...

 public:  // observers
  // ...
  ptr_t get() const {
    if (inited()) {  // 2.
      std::shared_lock<std::shared_mutex> lk(mtx_);  // 1.b.
      return payload_;
    } else {
      return nullptr;
    }
  }
  // ...
};
```

这里，

- 我们用一个读写锁（共享互斥量）来保护智能指针 payload_。这是因为，虽然 std::shared_ptr 当中的引用计数是原子的，但是 std::shared_ptr 本身并无线程安全保证。考虑到我们可能在多线程中同时读写 payload_，因此必须要加锁。此处细节，可参考[陈硕的雄文](https://blog.csdn.net/Solstice/article/details/8547547)。

- 这里是对 Reloader 状态的判断。若未初始化，则返回空指针。

### init

有了这些铺垫，我们可以来实现修改器 init 了。

```cpp
template <typename Payload>
class Reloader {
  // ...

 private:
  // ...
  std::once_flag init_flag_;  // 1.a.
  std::string path_;
  // ...

 public:  // modifiers
  bool init(const std::string& path) {
    std::call_once(init_flag_, [&]() -> void {  // 1.b.
      this->path(path);

      if (reload()) {  // 2.a.
        launch();  // 3.a.
        inited_.store(true, std::memory_order_release);  //4.a.
      } else {
        return;
      }
    });
    return inited();  // 4.b.
  }
  // ...

 protected:  // modifiers
  bool reload() {  // 2.b.
    ptr_t tmp = std::make_shared<payload_t>();  // 5.a.
    if (tmp->load(path_)) {  // 5.b.
      {
        std::unique_lock<shared_mutex> lk(mtx_);  // 6.
        payload_.swap(tmp);  // 7.
      }
      return true;
    } else {
      return false;
    }
  }

  void path(const std::string& p) {
    path_ = p;
  }

 private:
  virtual void launch() = 0;  // 3.b.
};
```

这里，

- 为保证 init 只执行一次，我们使用 C++ 标准中提供的 std::once_flag 和 std::call_once。

- reload 接口如其名，每次重载器触发重载动作时，都应调用它。init 实际是第一次重载，当然也会调用它。

- launch 是一个纯虚函数，它由子类模板实现。launch 负责初始化重载器的一些细节工作，以便在进程声明周期中循环/监视文件变动，触发重载。

- 维护 inited_ 原子变量，与 inited 接口遥相呼应。这里的[顺序标记](/2021/12/11/memory-order-cpp-02/)是 std::memory_order_release，是为了构造一个同步关系：当读到 inited_ 的值为 true 时，(2) 和 (3) 都确实已执行完毕。

- 重载时，为避免影响正在对外提供服务的 payload_ 指针，我们通过临时指针来载入数据。

- 若临时指针载入数据成功，我们在读写锁（共享互斥量）的「写入状态」的保护下，更新 payload_ 的值。

- 这里使用 payload_.swap(tmp) 而非 payload_ = std::move(tmp) 的原因在于，后者会导致立即析构 payload_ 先前指向的对象。考虑到此时尚在写入锁保护下，而析构词典对象可能非常耗时，这种做法是不明智的。使用 swap 延迟析构旧对象（在 return 处，析构 tmp 时），是更好的选择。

至此，Reloader 的主要接口，我们就已实现完备。

## 更多

在现有的 Reloadable 和 Reloader 的基础上，我们可借助[前文提到的时间循环器](/2020/10/14/implement-a-timed-looper-in-cxx/)来实现一个基于倒计时轮询的重载器；又可借助[前文提到的单例模式](/2020/10/27/implement-a-singleton-class-template-in-cxx/)，让重载器于多线程共享。另附一个[仓库](https://github.com/Liam0205/data-reloader)，供来者学习参考。

## 对不同意见的回复

文章出来已经收到了一些反对意见。此处做一些回复。

### Reloadable 不是必须的，只需实现相同的接口即可。

诚然，若能保证所有用到 Reloader 的类，都实现了相同的接口，那么 Reloadable 及对应的 std::enable_if_t 可以去掉。但在实际工程中，这是一个相当高的要求，通常很难达到。这是因为，很可能在实现 Reloader 类模板时，代码库当中已有不少词典、模型类。这些 legacy codes 可能并不遵循现下定义的标准接口。若要使它们为 Reloader 所管理，则需要细致地修改，而后祈祷编译不出错。而若是使它们继承 Reloadable，则编译器会告诉你哪些词典/模型类还未正确修改。——编译器要么提示你，尚有纯虚函数未实现而无法实例化；要么提醒你 Reloader 的 Payload 类并非由 Reloadable 派生而得。

退一步说，即使能够通过口头/文档约束，达到接口统一的要求；那么，既然你已经在代码上约束大家实现 load 接口了，那么交给编译器去用 std::enable_if_t 做一次校验岂非更好？

因此，我们倾向于保留 Reloadable 及相应的 std::enable_if_t 之设计。

### 在 Reloader 类当中，实现一个 lookup 接口，避免通过 get 接口返回词典类，是否更好？

若能约束所有词典类，都有一个统一的 lookup 接口，那这样做自然可以。但 Reloader 并非单纯针对词典类设计，例如带有 predict 接口的模型类，也能为 Reloader 所管理。讲到底，Reloader 只是为管理进程运行时可能需要重载的资源而设计的，对于资源是什么，Reloader 本身并不关心。

即便 Reloader 仅仅只为词典设计，这样封装接口也有至少三个劣势。

- 基于与前一问题类似的理由，对于 legacy codes 的修改，会比较麻烦。

- 过早地约束了词典可用的接口，而忽略了词典的多样性。于是在将来的使用中，新的词典（比如涉及到二段查询的词典）可能无法轻易套用 Reloader。

- 在单次请求中，我们希望对词典的多次查询的结果稳定。但在 Reloader<Payload>::lookup() 当中，我们无法保证这一点。因为在单次请求过程中，可能触发了 reload 动作，于是相邻两次查询时，词典内容可能已经发生变化，造成对业务不可知的影响。

反过来讲，通过对内部智能指针加锁，返回只能指针的拷贝，则基本避免了这种影响。

- legacy codes 只需 sed 替换即可。

- 不约束词典可用接口。

- 通过拷贝传递出去的智能指针，hook 住词典内容；即便在使用过程中触发 reload 动作，词典内容也不会提前析构，保证结果统一性。