---
title: "在 C++ 中实现一个线程安全的频率限制器"
url: https://liam.page/2020/05/17/Implementing-a-Thread-safe-Rate-Limiter-in-C/
date: 2020-05-17
categories: ["Algorithm and Computer Science"]
tags: ["C++", "QPS", "Rate Limiter", "Thread-safe"]
---

很早以前，在学习使用 Python 的 deque 容器时，我[实现了一个玩具版的频率限制器](/2016/09/23/using-deque-to-implement-marquee-and-rate-limiter/)。最近需要压测线上服务的性能，又不愿意总是在 QA 那边排队，于是需要自己写一个压测用的客户端。其中一个核心需求就是要实现 QPS 限制。

于是，终究逃不开要在 C++ 中实现一个线程安全的频率限制器。

## 设计思路

所谓频率限制，就是要在一个时间段（inteval）中，限制操作的次数（limit）。这又可以引出两种强弱不同的表述：

- 强表述：在任意一个长度等于设定的时间段（interval）的滑动窗口中，频率限制器放行的操作次数（count）都不高于限制次数（limit）。

- 弱表述：在一组长度等于设定的时间段（interval）且紧密相连的固定窗口中，每一个窗口里频率限制器放行的操作次数（count）都不高于限制次数（limit）。

不难发现，强表述通过「滑动窗口」的方式，不仅限制了频率，还要求了操作在时间上的均匀性。前作的频率限制器，实际上对应了这里的强表述。但实际工程中，我们通常只需要实现弱表述的频率限制器就足够使用了。

对于弱表述，实现起来主要思路如下：

- 当操作计数（count）小于限制（limit）时直接放行；

- 当操作计数（count）不小于限制（limit）时，继续判断当前时间与上一次记录时间戳（timestamp）的差值。
若差值不小于设定的时间段（interval），则更新记录时间戳、将计数重置为 1 并放行；
否则拒绝操作。

## 单线程实现

在不考虑线程安全时，不难给出这样的实现。

```cpp
struct ms_clock {
  using rep        = std::chrono::milliseconds::rep;
  using period     = std::chrono::milliseconds::period;
  using duration   = std::chrono::duration<rep, period>;
  using time_point = std::chrono::time_point<ms_clock, duration>;

  static
  time_point now() noexcept {
    return time_point(std::chrono::duration_cast<duration>(
                  std::chrono::steady_clock::now().time_since_epoch()));
  }
};
}  // namespace __details

class RateLimiter {
 public:
  using clock    = __details::ms_clock;  // 1.

 private:
  const uint64_t        limit_;
  const clock::duration interval_;
  const clock::rep      interval_count_;

  mutable uint64_t   count_{std::numeric_limits<uint64_t>::max()};  // 2.a.
  mutable clock::rep timestamp_{0};                                 // 2.b.

 public:
  constexpr RateLimiter(uint64_t limit, clock::duration interval) :
    limit_(limit), interval_(interval), interval_count_(interval_.count()) {}

  RateLimiter(const RateLimiter&) = delete;             // 3.a.
  RateLimiter& operator=(const RateLimiter&) = delete;  // 3.b.
  RateLimiter(RateLimiter&&) = delete;                  // 3.c.
  RateLimiter& operator=(RateLimiter&&) = delete;       // 3.d.

  bool operator()() const;
  double qps() const {
    return 1000.0 * this->limit_ / this->interval_count_;
  }
};

bool RateLimiter::operator()() const {
  auto orig_count = this->count_++;
  if (orig_count < this->limit_) {  // 4.
    return true;
  } else {
    auto ts  = this->timestamp_;
    auto now = clock::now().time_since_epoch().count();
    if (now - ts < this->interval_count_) {  // 5.
      return false;
    }
    this->timestamp_ = now;
    this->count_     = 1;
    return true;
  }
}
```

这里，

- (1) 表明频率限制器使用单位为毫秒的时钟。在实际使用时，也可以按需改成微妙甚至纳秒。

- (2) 使用 mutable 修饰内部状态 count_ 和 timestamp_。这是因为两个 limit_ 和 interval_ 相同的频率限制器，在逻辑上是等价的，但他们的内部状态却不一定相同。因此，为了让 const 成员函数能够修改内部状态（而不改变逻辑等价），我们要给内部状态数据成员加上 mutable 修饰。
(2.a) 处将 count_ 设置为类型可表示的最大值是为了让 (4) 的判断失败，而对 timestamp_ 进行初始化。
(2.b) 处将 timestamp_ 设置为 0 则是基于同样的原因，让 (5) 的判断失败。
(2.a) 和 (2.b) 处通过巧妙的初值设计，将初始化状态与后续正常工作状态的逻辑统一了起来，而无须丑陋的判断。

- (3) 禁止了对象的拷贝和移动。这是因为一个频率限制器应绑定一组操作，而不应由两组或更多组操作共享（对于拷贝的情形），或是中途失效（对于移动的情形）。

如此一来，函数调用运算符就忠实地实现了前述逻辑。

## 多线程改造

### 第一步改造

当有多线程同时调用 RateLimiter::operator() 时，显而易见，在 count_ 和 timestamp_ 上会产生竞争。我们有两种办法解决这个问题：要不然加锁，要不然把 count_ 和 timestamp_ 设为原子变量然后用原子操作解决问题。于是，对函数调用运算符，我们有如下第一步的改造。

```cpp
class RateLimiter {
  // 其余保持不变
 private:
  mutable std::atomic<uint64_t>   count_{std::numeric_limits<uint64_t>::max()};  // 1.a.
  mutable std::atomic<clock::rep> timestamp_{0};                                 // 1.b.
  // 其余保持不变
};

bool RateLimiter::operator()() const {
  auto orig_count = this->count_.fetch_add(1UL);  // 2.
  if (orig_count < this->limit_) {
    return true;
  } else {
    auto ts  = this->timestamp_.load();  // 3.
    auto now = clock::now().time_since_epoch().count();
    if (now - ts < this->interval_count_) {
      return false;
    }
    this->timestamp_.store(now);  // 4.
    this->count_.store(1UL);  // 5.
    return true;
  }
}
```

这里，

- (1) 将 count_ 和 timestamp_ 声明为原子的，从而方便后续进行原子操作。

- (2) -- (5) 则将原有操作分别改为对应的原子操作。

这样看起来很完美，但其实是有 bug 的。我们重点关注 (4) 这里。(4) 的本意是更新 timestamp_，以备下一次 orig_count >= this->limit_ 时进行判断。准确设置这一 timestamp 是频率限制器正确工作的基石。但是，**如果有两个（或更多）线程，同时走到了 (4)** 会发生什么？

- 因为原子操作的存在，两个线程会先后执行 (4)。于是 timestamp_ 的值究竟是什么，我们完全不可预期。

- 此外，两个线程会先后执行 (5)，即原子地将 count_ 置为 1。但是你想，频率限制器先后放行了两次操作，但为什么 count_ 是 1 呢？这是不是就「偷跑」了一次操作？

为此，我们要保证只有一个线程会真正设置 timestamp_，而拒绝其他同样走到 (4) 位置的线程的操作，以避免其重复设置 timestamp_ 以及错误地将 count_ 再次置为 1。

### 第二步改进

于是有以下改进。

```cpp
bool RateLimiter::operator()() const {
  auto orig_count = this->count_.fetch_add(1UL);  // 3.
  if (orig_count < this->limit_) {  // 4.
    return true;
  } else {
    auto ts  = this->timestamp_.load();
    auto now = clock::now().time_since_epoch().count();
    if (now - ts < this->interval_count_) {  // 5.
      return false;
    }
    if (not this->timestamp_.compare_and_exchange_strong(ts, now)) {  // 1.
      return false;
    }
    this->count_.store(1UL);  // 2.
    return true;
  }
}
```

这里，(1) 是一个 CAS 原子操作。它会原子地比较 timestamp_ 和 ts 的值（Compare）：若他们相等，则将 now 的值写入 timestamp_（Swap），并返回 true；若他们不相等，则将 timestamp_ 的值写入 ts，并返回 false。如果没有其他线程抢先修改 timestamp_ 的值，那么 CAS 操作应该成功并返回 true，继续执行后面的代码；否则，说明其他线程已经抢先修改了 timestamp_，当前线程的操作被记入上一个周期而被频率限制器拒绝。

现在要考虑 (2)。如果执行完 (1) 之后立即立刻马上没有任何延迟地执行 (2)，那么当然一切大吉。但如果这时候当前线程被切出去，会发生什么？我们要分情况讨论。

- 如果 ts == 0，也就是「当前线程」是频率限制器第一次修改 timestamp_。于是，当前线程可能会在 (3) 处将 count_ （溢出地）自增为 0，从而可能有其他线程通过 (4)。此时，当前线程在当前分片有可能应当被拒绝操作。为此，我们需要在 (1) 和 (2) 之间做额外的判断。
```cpp
if (ts == 0) {
  auto orig_count = this->count.fetch_add(1UL);
  return (orig_count < this->limit_);
}
```

- 如果 ts != 0，也就是「当前线程」并非频率限制器第一次修改 timestamp_。那么其他线程在 (4) 处必然判断失败，但在 (5) 处的判断可能成功，从而可能继续成功执行 (1)，从而接连两次执行 (2)。但这不影响正确性。因为通过 (5) 表明相对当前线程填入的 timestamp_，已经由过了一个时间段（interval），而在这个时间段里，只有当前线程的一次操作会被接受。

### 第三次改进

由此，我们得到：

```cpp
bool RateLimiter::operator()() const {
  auto orig_count = this->count_.fetch_add(1UL);
  if (orig_count < this->limit_) {
    return true;
  } else {
    auto ts  = this->timestamp_.load();
    auto now = clock::now().time_since_epoch().count();
    if (now - ts < this->interval_count_) {
      return false;
    }
    if (not this->timestamp_.compare_and_exchange_strong(ts, now)) {
      return false;
    }
    if (ts == 0) {
      auto orig_count = this->count.fetch_add(1UL);
      return (orig_count < this->limit_);
    }
    this->count_.store(1UL);
    return true;
  }
}
```

至此，我们的代码在逻辑上已经成立了，接下来要做一些性能方面的优化。

原子操作默认采用 std::memory_order_seq_cst 的内存模型。这是 C++ 中最严格的内存模型，它有两个保证：

- 程序指令和源码顺序一致；

- 所有线程的所有操作都有一致的顺序。

为了实现顺序一致性（sequential consistency），编译器会使用很多对抗编译器优化和 CPU 乱序执行（Out-of-Order Execution）的手段，因而性能较差。对于此处的 count_，我们无需顺序一致性模型，只需要获取释放-模型（Aquire-Release）模型就足够了。对 count_ 施加获取-释放模型之后，timestamp_ 就只需宽松模型即可。

### 第四次改进

于是有第四次改进：

```cpp
bool RateLimiter::operator()() const {
  auto orig_count = this->count_.fetch_add(1UL, std::memory_order_acq_rel);
  if (orig_count < this->limit_) {
    return true;
  } else {
    auto ts  = this->timestamp_.load(std::memory_order_relaxed);
    auto now = clock::now().time_since_epoch().count();
    if (now - ts < this->interval_count_) {
      return false;
    }
    if (not this->timestamp_.compare_and_exchange_strong(ts, now, std::memory_order_relaxed, std::memory_order_relaxed)) {
      return false;
    }
    if (ts == 0) {
      auto orig_count = this->count.fetch_add(1UL, std::memory_order_acq_rel);
      return (orig_count < this->limit_);
    }
    this->count_.store(1UL, std::memory_order_release);
    return true;
  }
}
```

至此，我们就完整实现了一个频率限制器，可以愉快地开始拉 QPS 压测了！