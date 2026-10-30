---
title: "在 C++ 中实现一个单例类模板"
url: https://liam.page/2020/10/27/implement-a-singleton-class-template-in-cxx/
date: 2020-10-27
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Mutex", "Threading", "Singleton"]
---

单例模式是最简单的设计模式之一。在实际工程中，如果一个类的对象重复持有资源的成本很高，且对外接口是线程安全的，我们往往倾向于将其以单例模式管理。

此篇我们在 C++ 中实现正确的单例模式。

## 选型

在 C++ 中，单例模式有两种方案可选。

- 一是实现一个没有可用的公开构造函数的基类，并提供 GetInstance 之类的静态接口，以便访问子类唯一的对象。由于子类构造必须调用基类构造，但基类无公开构造函数可用，这使得子类对象只能由基类及基类的友元来构造，从而在机制上保证单例。

- 二是实现一个类模板，其模板参数是希望由单例管理的类的名字，并提供 GetInstance 之类的静态接口。这种做法的好处是希望被单例管理的类，可以自由编写，而无需继承基类；并且在需要的时候，可以随时脱去单例外衣。

此篇选择实现一个单例类模板，其形如：

```cpp
template <typename T>
struct Singleton {
  static T* get();
  T* operator->() const {
    return get();
  }
};
```

这里重载成员访问运算符，是为了可以实现这样的简写 Singleton<T>()->func()。

显然，单例的实现核心在于静态成员函数 T* get()。

## 一个典型的错误实现

一个典型的错误实现，是使用所谓的双重检查（double check）。

```cpp
#include <mutex>

template <typename T>
struct Singleton {
  static T* get() {
    static T* p{nullptr};
    if (nullptr == p) {
      std::lock_guard<std::mutex> lock{mtx};
      if (nullptr == p) {
        p = new T;
      }
    }
    return p;
  }
  T* operator->() const {
    return get();
  }

 private:
  static std::mutex mtx;
};

template <typename T>
std::mutex Singleton<T>::mtx;
```

外层的检查，是为了避免锁住过大的区域，从而导致锁的竞争特别频繁；内层的检查，是为了确保只在别的线程没有提前抢占锁完成初始化工作而设计的。这种做法在 Java 下是正确的，但是在 C++ 下则没有保证。具体解析可以参看[这篇旧文](/2017/01/17/layers-and-operation-system/#CPU-%E5%8A%A8%E6%80%81%E8%B0%83%E5%BA%A6)。

另外，值得一提的是，这里 p 的初始化的线程安全性，是由 C++ 标准保证的。——在 C++11 之后，标准保证函数静态成员的初始化是线程安全的；对其读写则不保证线程安全。

## 使用标准库提供的设施

在单例的实现中，我们实际上是希望实现「执行且只执行一次」的语义。C++11 之后，标准库实际已经提供了这样的设施。其名为 std::once_flag 和 std::call_once。它们内部利用互斥量和条件变量组合，实现这样的语义。值得一提的是，如果执行过程中抛出异常，标准库的设施不认为这是一次「成功的执行」。于是其他线程可以继续抢占锁来执行函数。

我们利用标准库设施来实现这个类模板。

```cpp
#include <mutex>

template <typename T>
struct Singleton {
  static T* get() {
    static T* p{nullptr};
    std::call_once(flag, [&]() -> void {
      p = new T;
    });
    return p;
  }
  T* operator->() const {
    return get();
  }

 private:
  static std::once_flag flag;
};

template <typename T>
std::once_flag Singleton<T>::flag;
```

于是你可以写出类似这样的代码：

```cpp
#include <mutex>
#include <iostream>
#include <future>
#include <vector>

#include "singleton.h"

struct Foo {
  void address() const {
    std::lock_guard<std::mutex> lock{mtx};
    std::cout << static_cast<void*>(const_cast<Foo*>(this)) << '\n';
  }
  mutable std::mutex mtx;
};

int main() {
  Singleton<Foo>()->address();
  std::vector<std::future<void>> futs;
  for (size_t i = 0; i != 10; ++i) {
    futs.emplace_back(std::async(&Foo::address, Singleton<Foo>::get()));
  }
  for (auto& fut : futs) {
    fut.get();
  }
  return 0;
}
```

得到的输出类似这样：

```bash
$ ./a.out
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
0x7fbc6f405a10
```

Bonus：需要注意的是，所有的 std::once_flag 内部共享了同一对互斥量和条件变量。因此当存在很多 std::call_once 的时候，性能会有所下降。这一点可能需要注意一下。不过，如果存在很多 std::call_once，大概也说明程序设计不合理吧……

Bonus：注意我们这里没有释放 p 指向的对象。这是因为 C++ 程序对静态变量的析构顺序是不确定的。如果静态变量之间有相互依赖，析构被依赖的对象可能会导致段错误。因此干脆就不释放了，这是所谓的 LeakySingleton。当然，如果你的工程当中有实现一个通用的 ExitManager，是有可能正确析构的。但考虑到还可能大量使用第三方库，而第三方库不可能使用你实现的 ExitManager，于是管理所有静态变量的析构又变得不可能，于是干脆就不管它了。

## 如此如此，这般这般

如果你仔细读了这篇文章，你可能会忽然意识到刚才看到了这句话：「在 C++11 之后，标准保证函数静态成员的初始化是线程安全的；对其读写则不保证线程安全。」

既然如此，我们为啥还要费劲使用 std::once_flag 和 std::call_once 呢？直接利用 static hack 出一个单例类模板不就好了吗？

```cpp
template <typename T>
struct Singleton {
  static T* get() {
    static T ins;
    return &ins;
  }
  T* operator->() const {
    return get();
  }
};
```

以上。