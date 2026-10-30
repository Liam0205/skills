---
title: "设计一个线程池"
url: https://liam.page/2022/05/05/design-a-thread-pool/
date: 2022-05-05
categories: ["Algorithm and Computer Science"]
tags: ["Thread", "Threadpool"]
---

此篇我们通过逐步实现线程池，来探讨线程池中的关键技术。

## 初步讨论

### 为什么需要线程池？

自 C++11 起，在 C++ 中使用线程就变得很简单。最基本地，可以用 std::thread 来管理一个线程。若是要异步地执行任务，搭配使用 std::async 和 std::future 也很方便。在有这些基础设施的基础上，我们为什么还需要线程池？或者说，我们什么时候需要线程池？

众所周知，线程作为一种系统资源，其创建和销毁是需要时间的。因此，如果创建和销毁线程的时间和执行任务所需的时间处在同一个数量级，那么频繁地创建和销毁线程带来的性能损耗就会变得十分可观。此时，我们就要考虑使用线程池。

### 线程池应有哪些特点？

线程池的本质就是一组待用的线程。在 C++ 中，它可以表示为一个 std::thread 的数组或是向量。在实际工程中，为便于进行可能的扩展，使用 std::vector<std::thread> 显然会更加合适。

对于线程池中的每个线程，它都可能在某个时刻接收到一个任务。而这个任务具体是什么，在线程创建时并不知道。用 C++ 的语言表达就是说，线程池中的线程：

- 应当可以执行任意函数——支持任何参数列表，也支持任何返回值类型；

- 应当可以将任务的执行结果反馈给任务的发布者；

- 应当可以在需要时被唤醒执行任务，而在无需时不占用过多 CPU 资源；

- 应当可以被主控线程控制，在适当的时候暂停任务、停止接收任务、丢弃未完成任务等。

对于第一条，modern C++ 的做法应该是利用 functional 头文件提供的基础设施（std::bind, std::function 等）结合模板参数包来实现。对于第二条，old-fashion 的做法是在发布任务时同时注册回调函数；modern C++ 的做法应该是利用 std::packaged_task 结合 std::future 来实现。对于第三条，若是任务来得不那么频繁，应当考虑使用 std::condition_variable 来实现；若是任务十分频繁，则可以考虑使用 std::this_thread::yield。对于第四条，则可以设置一个内部变量作为标记，让每个工作线程都定期检查该标记来实现。

我们讨论到了任务。显然，我们会需要一个线程安全的队列来管理其他线程发布的任务。

## 线程安全队列

我们不妨直接从代码入手，逐步分析。

```cpp
template <typename T>
class blocking_queue : protected std::queue<T> {  // 1.
 public:
  using wlock = std::unique_lock<std::shared_mutex>;  // 2.a
  using rlock = std::shared_lock<std::shared_mutex>;  // 2.b

 public:
  blocking_queue() = default;
  ~blocking_queue() {
    clear();
  }
  blocking_queue(const blocking_queue&) = delete;  // 3.a
  blocking_queue(blocking_queue&&) = delete;  // 3.b
  blocking_queue& operator=(const blocking_queue&) = delete; // 3.c
  blocking_queue& operator=(blocking_queue&&) = delete;  // 3.d

 public:
  bool empty() const {
    rlock lock(mtx_);  // 4.a
    return std::queue<T>::empty();
  }

  size_t size() const {
    rlock lock(mtx_);  // 4.b
    return std::queue<T>::size();
  }

 public:
  void clear() {
    wlock lock(mtx_);
    while (!std::queue<T>::empty()) {
      std::queue<T>::pop();
    }
  }

  void push(const T& obj) {
    wlock lock(mtx_);  // 5.a
    std::queue<T>::push(obj);
  }

  template <typename... Args>
  void emplace(Args&&... args) {
    wlock lock(mtx_);  // 5.b
    std::queue<T>::emplace(std::forward<Args>(args)...);
  }

  bool pop(T& holder) {  // 6.
    wlock lock(mtx_);
    if (std::queue<T>::empty()) {
      return false;
    } else {
      holder = std::move(std::queue<T>::front());
      std::queue<T>::pop();
      return true;
    }
  }

 private:
  mutable std::shared_mutex mtx_;  // 7.
};
```

- blocking_queue 继承 std::queue，最基本的队列的实现交给标准库。

- 利用 std::shared_mutex 结合 std::unique_lock 和 std::shared_lock 实现读写锁。

- 此处我们禁用了拷贝和移动构造函数及对应的赋值运算符。这纯粹是因为在实现线程池的过程中我们用不到它们。如果需要，是可以按需实现的。

- 在两个 observers 当中，我们使用了只读锁。

- push 和 emplace 是类似的操作，都是在队尾追加元素。他们的区别与联系就和标准库容器的接口一样。注意在 emplace 当中，我们用到了完美转发技术。

- 这里的 pop 其实更合适称作 try_pop。因为 pop 动作在此处并不一定成功，在队列为空时，函数返回 false 而不会对队列做任何修改。

- 这是一把针对整个队列的粗粒度锁。实际上，因为队列的 push 和 pop 一定程度上是分开的，小心地话，可以实现一个细粒度版本的锁，在 push 和 pop 操作都频繁的情况下会有显著的性能提升。关于这一点，我们之后可以单列一篇文章进行讨论。

## 线程池

### 接口定义

按先前的讨论，我们可以整理出线程池的大致模样：

```cpp
class threadpool {
 public:  // 1.
  void init(int num);
  void terminate();  // stop and process all delegated tasks
  void cancel();     // stop and drop all tasks remained in queue

 public:  // 2.
  bool inited() const;
  bool is_running() const;
  int size() const;

 public:  // 3.
  template <class F, class... Args>
  auto async(F&& f, Args&&... args) const -> std::future<decltype(f(args...))>;

 private:
  std::vector<std::thread> workers_;  // 4.
  mutable blocking_queue<std::function<void()>> tasks_;  // 5.
};
```

- 第一组的三个接口是整个线程池的控制接口。init 接口启动线程池，其参数 num 即是线程池中线程的数量。terminate 接口终止线程池，不再接受新的任务，并保证将已接受的任务处理完毕。cancel 与 terminate 类似，但它将丢弃已接受但未处理完毕的任务。

- 第二组的三个接口均是 observers。

- 第三组中的唯一一个接口是线程池接受外部任务的接口。它和标准库提供的 std::async 几乎一致，接受任意函数，并返回一个 std::future。

- 这是线程池本体。

- 这是任务队列。

### 线程池的控制接口

接下来我们讨论控制接口的具体实现。

```cpp
inline void threadpool::init(int num) {
  std::call_once(once_, [this, num]() {  // 1.
    wlock lock(mtx_);  // 2.
    stop_ = false;
    cancel_ = false;
    workers_.reserve(num);
    for (int i = 0; i < num; ++i) {
      workers_.emplace_back(std::bind(&threadpool::spawn, this));  // 3.a
    }
    inited_ = true;
  });
}

inline void threadpool::spawn() {  // 3.b
  for (;;) {
    bool pop = false;
    std::function<void()> task;
    {
      wlock lock(mtx_);
      cond_.wait(lock, [this, &pop, &task] {
        pop = tasks_.pop(task);
        return cancel_ || stop_ || pop;  // 4.
      });
    }
    if (cancel_ || (stop_ && !pop)) {  // 5.a
      return;
    }
    task();  // 5.b
  }
}

inline void threadpool::terminate() {  // 6.a
  {
    wlock lock(mtx_);
    if (_is_running()) {
      stop_ = true;  // 7.a
    } else {
      return;
    }
  }
  cond_.notify_all();
  for (auto& worker : workers_) {
    worker.join();
  }
}

inline void threadpool::cancel() {  // 6.b
  {
    wlock lock(mtx_);
    if (_is_running()) {
      cancel_ = true;  // 7.b
    } else {
      return;
    }
  }
  tasks_.clear();  // 8.
  cond_.notify_all();
  for (auto& worker : workers_) {
    worker.join();
  }
}

inline bool threadpool::_is_running() const {
  return inited_ && !stop_ && !cancel_;
}
```

- init 完成的工作，在逻辑上只能进行一次。但我们无法保证用户代码确实如我们所想地这样执行。因此，我们利用 std::call_once 保证相关工作只执行一次。

- 因为涉及到修改 threadpool 的状态，所以此处使用写入锁。

- spawn 接口是线程函数，也就是线程启动后一直运行的函数。

- 当线程被唤醒时（无论是意外唤醒，还是被 notify_* 函数唤醒），若线程池没有被 cancel 或是 terminate，也没能从任务队列中取出任务，则线程应该继续沉眠，否则就应该醒来继续处理。

- 如果线程池被 cancel，则不执行当前任务；如果线程池被停止并且没能从任务队列中取出任务，则也不执行当前任务；否则就执行当前任务。

- terminate 和 cancel 的实现几乎完全相同；

- 唯独 terminate 修改 stop_ 变量而 cancel 修改 cancel_ 变量。

- 此外，cancel 接口显式地清空了任务队列。

### 线程池的观察器

观察器比较简单，唯一值得一提的是这里使用了读取锁。

```cpp
inline bool threadpool::inited() const {
  rlock lock(mtx_);
  return inited_;
}

inline bool threadpool::is_running() const {
  rlock lock(mtx_);
  return _is_running();
}

inline int threadpool::size() const {
  rlock lock(mtx_);
  return workers_.size();
}
```

### 任务接口

```cpp
template <class F, class... Args>
auto threadpool::async(F&& f, Args&&... args) const
    -> std::future<decltype(f(args...))> {
  using return_t = decltype(f(args...));  // 1.a
  using future_t = std::future<return_t>;  // 1.b
  using task_t = std::packaged_task<return_t()>;  // 1.c

  {
    rlock lock(mtx_);  // 2.
    if (stop_ || cancel_)
      throw std::runtime_error(
          "Delegating task to a threadpool "
          "that has been terminated or canceled.");
  }

  auto bind_func = std::bind(std::forward<F>(f), std::forward<Args>(args)...);  // 3.
  std::shared_ptr<task_t> task = std::make_shared<task_t>(std::move(bind_func));  // 4.a
  future_t fut = task->get_future();  // 4.b
  tasks_.emplace([task]() -> void { (*task)(); });  // 5.
  cond_.notify_one();  // 6.
  return fut;  // 4.c
}
```

- 利用 using 定义的三个类型，见文知意。

- 这里不涉及对线程池状态的修改，因此只需要读取锁即可。显然，此处我们禁止对已经 terminate 或是 cancel 的线程池继续发布任务。

- 由于任务队列只接收 std::function<void()> 的可调用对象，此处我们利用 std::bind 先匹配参数列表。

- 此处我们利用 std::packaged_task 将待执行的任务与一个 std::future 关联起来，并将 std::future 返回给外界，以便任务发布者可以在将来取得任务执行结果。

- 这里我们利用一个 lambda，既执行了任务，又将返回值抹去（但会被 future 管理），以便匹配 std::function<void()>。

- 此处我们通过条件变量唤醒工作线程。

### 完整实现

完整实现可见 [Liam0205/toy-threadpool](https://github.com/Liam0205/toy-threadpool)，其中包括了单元测试和相比 std::async 的性能对比。

## 跋

这里我们实现了一个可看使用的线程池。但如 GitHub 的 repo 名字一样，它还只是个玩具。若要在工程中使用，还可以做一系列优化。例如说：

- 对线程安全队列进行优化，使用更细粒度的锁（完整实现当中已有），或者换用无锁实现。

- 完善的线程池，除了支持本文提到的几种状态，还可以有暂停、扩张（任务过多时自动扩张）、收缩（空闲线程过多时自动收缩）等能力。

这些内容都可以继续去深挖、优化。