---
title: "在 C++ 中实现一个正确的时间循环器"
url: https://liam.page/2020/10/14/implement-a-timed-looper-in-cxx/
date: 2020-10-14
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Mutex", "Threading", "ConditionVariable"]
---

实际工程中可能会有这样一类普遍需求：在服务中，单独起一个线程，以一个固定的时间间隔，周期性地完成特定的任务。我们把这种问题抽象成一个时间循环器。

## Naive Way

```cpp
#include <atomic>
#include <thread>
#include <cstdint>
#include <chrono>

class TimerCircle {
 private:
  std::atomic_bool running_{false};
  uint64_t         sleep_{0UL};
  std::thread      thread_;

 public:
  explicit TimerCircle(uint64_t s) : sleep_{s} {}
  ~TimerCircle() {
    if (thread_.joinable()) {
      terminate();
      thread_.join();
    }
  }
  TimerCircle(const TimerCircle&) = delete;
  TimerCircle& operator=(const TimerCircle&) = delete;
  TimerCircle(TimerCircle&&) = default;
  TimerCircle& operator=(TimerCircle&&) = default;

 public:
  void launch() {
    thread_ = std::move(std::thread(&TimerCircle::loop, this));
  }
  void terminate() {
    running_.store(false);
  }
  void loop() {
    running_.store(true);
    while (running_.load()) {
      do_something();
      std::this_thread::sleep_for(std::chrono::seconds(sleep_));
    }
  }

 private:
  void do_something() const = 0;
};
```

实现简单平凡，一眼就能看出来没啥问题，于是也没啥好说的。

## 细节里的魔鬼

唯一的魔鬼藏在细节里。如果 TimerCircle 类型的对象发生析构，那么析构该对象的线程最多会被阻塞 sleep_ 秒。如果周期很长，比如长达 6 小时，那这显然是不可接受。

为此，我们需要借助标准库的[条件变量 std::condition_variable 的 wait_for 函数](https://en.cppreference.com/w/cpp/thread/condition_variable/wait_for)的帮助。首先看其函数签名

```cpp
template <typename Rep, typename Period, typename Predicate>
bool wait_for(std::unique_lock<std::mutex>& lock,
              const std::chrono::duration<Rep, Period>& rel_time,
              Predicate pred);
```

函数接受三个参数。lock 是一个 unique_lock，它必须为调用 wait_for 的线程所锁住；rel_time 是一个时间段，表示超时时间；pred 是一个谓词，它要么返回 true 要么返回 false。

一旦调用，函数会阻塞当前线程，直到两种情况返回：

- 超时；此时函数返回 pred()。

- 条件变量被通知，且谓词返回 true；此时函数返回 true。

于是我们可以实现一个 Countdown 类

```cpp
#include <chrono>
#include <condition_variable>
#include <mutex>

class Countdown final {
 private:
  bool    running_ = true;
  mutable std::mutex              mutex_;
  mutable std::condition_variable cv_;

 public:
  Countdown() = default;
  ~Countdown() = default;
  Countdown(const Countdown&) = delete;
  Countdown& operator=(const Countdown&) = delete;
  Countdown(Countdown&&) = delete;
  Countdown& operator=(Countdown&&) = delete;

 public:
  void terminate() {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      running_ = false;
    }
    cv_.notify_all();
  }

  template <typename Rep, typename Peroid>
  bool wait_for(std::chrono::duration<Rep, Peroid>&& duration) const {
    std::unique_lock<std::mutex> lock(mutex_);
    bool terminated = cv_.wait_for(lock, duration, [&]() { return !running_; });
    return !terminated;
  }
};
```

于是，TimerCircle 就变成

```cpp
#include <atomic>
#include <thread>
#include <cstdint>
#include <chrono>

class TimerCircle {
 private:
  uint64_t    sleep_{0UL};
  Countdown   cv_;
  std::thread thread_;

 public:
  explicit TimerCircle(uint64_t s) : sleep_{s} {}
  ~TimerCircle() {
    if (thread_.joinable()) {
      terminate();
      thread_.join();
    }
  }
  TimerCircle(const TimerCircle&) = delete;
  TimerCircle& operator=(const TimerCircle&) = delete;
  TimerCircle(TimerCircle&&) = default;
  TimerCircle& operator=(TimerCircle&&) = default;

 public:
  void launch() {
    thread_ = std::move(std::thread(&TimerCircle::loop, this));
  }
  void terminate() {
    cv_.terminate();
  }
  void loop() {
    while (cv_.wait_for(std::chrono::seconds(sleep_))) {
      do_something();
    }
  }

 private:
  void do_something() const = 0;
};
```

简单，明了。