---
title: "谈谈智能指针：原理及其实现"
url: https://liam.page/2018/01/13/smart-pointer/
date: 2018-01-13
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Pointer", "Surrogate", "Handler"]
---

[前作](/2017/11/26/surrogate-in-Cpp/)中，我们借助代理类对 Animal 及其子类的实例（事实上 Animal 是纯虚类，无法实例化）进行代理。

本文，我们将对代理类进行进一步分析，察觉一些细微的差别，而后引出智能指针。

## 反思代理类

[前作](/2017/11/26/surrogate-in-Cpp/)设计的代理类主要有两个方面的考量。其一是希望代理类将被代理的对象完全地管理起来，使得程序员自己不需要手动去分配和释放内存。基于这个考量，对代理类的复制、移动、赋值都伴随着被代理对象的相应变化。其二是希望代理类在一定程度上保留被代理对象多态的特性。为此，代理类需要保存基类指针作为代理类成员，并为相关函数预留接口（单独实现的 say() 函数）。

从第二个方面来看，代理类的行为，其实类似于指针。但从第一个方面来看，代理类又破坏了指针语义，而带上了值语义。这是因为，当我们复制代理类对象时，其内部的对象也会随之复制。

考虑到对于某些类型的对象，复制操作的开销很大，甚至是在逻辑上不可行的。因此，我们需要思考，如何在保留代理类的优势时，避免不必要的复制和移动操作。这就引出了智能指针（smart pointer）的话题。

## 代理类与智能指针

要避免不必要的对被代理对象的复制和移动操作，就要反过来回顾我们为何要这样设计。若是想清楚了如此设计的原因，再能想到替代方案，就有可能避免这些多余的复制和移动操作。

在代理类中，为了保证被代理的对象的生存期覆盖相应代理类对象的生存期，我们强迫每个代理类的对象生成时，都与初始化它的对象脱离关系。脱离关系的办法，一方面是复制，一方面是移动。复制的情况下，代理类对象里保存了被代理的原对象的副本，因此二者没有关系。移动的情况下，代理类对象里保存了从原对象中窃取的资源；原对象在代理类对象生成之后，就（在逻辑上）不可用了，因此二者也没有关系。这部分的设计，从逻辑上说是不可避免的，因而是没有问题的。

除此之外，在对代理类的对象进行复制、移动时，代理类对象中被代理的部分也会被复制和移动。这样一来，代理类实现了与被代理对象的一一对应。如果「代理对象与被代理对象一一对应」是确实的需求，那么这样设计就是不可避免的，也就没有问题。然而，在大多数情况下，我们希望代理类仍然能像指针那样工作：允许多个代理类对象绑定在同一个被代理对象上。这样一来频繁的复制、移动就变成缺陷了。这样的需求是很自然的，举几例如下：

- 向函数拷贝传值时；

- 代理类对象作为函数的返回值时；

- 在循环中，将代理类对象作为临时值，用于保存中间状态时。

这样一来，我们对代理类的需求就形成了看似矛盾的两个方面：

- 代理类能控制被代理对象的生存期，也就是要处理好对象的构造、析构；

- 要允许多个代理类绑定同一个被代理对象。

为了解决这样的矛盾，我们必须付出一些代价：维护一个计数器，用于记录有多少个代理类绑定在被代理的对象之上。由于我们希望这样的代理类使用起来和指针相似，所以这样的代理类又称为智能指针。

## 第一次尝试

### 被绑定的对象

前作使用了 Animal 及其派生类 Cat/Dog 为例。不失一般性，此处先不考虑继承与多态，考虑将智能指针实现出来。因此，我们考虑代表屏幕上像素点坐标的类 Point，它的定义如下。

```cpp
class Point {
 private:
  int x_ = 0;                               // 1.
  int y_ = 0;

 public:
  Point() = default;                        // 2.
  Point(int x, int y) : x_{x}, y_{y} {}     // 3.

 public:
  int x() const { return x_; }              // 4.
  int y() const { return y_; }

  Point& x(int x) { x_ = x; return *this; } // 5.
  Point& y(int y) { y_ = y; return *this; }
};
```

这里，由于 (1) 处给出了数据成员的类内初始值，所以 (2) 处无需自己定义默认构造函数，让编译器合成即可。(3) 处的参数没有给函数参数默认值（即没有声明为 Point(int x = 0, int y = 0)，这是为了防止类似 Point(0) 的调用（因为对于平面上的点来说，这样初始化在语义上是不正确的）。对于移动和拷贝构造函数及赋值运算符，则可由编译器自动合成。(4) 和 (5) 利用函数重载，实现了对数据成员的访问和修改的接口。其中 (5) 处设计为返回 Point& 是为了允许类似这样的语法 point.x(42).y(42)。

### 智能指针

我们先不考虑智能指针对类型的泛用性（不使用模板），来观察对 Point 类应该如何设计智能指针类 SmartPointer。

#### 管理对象

和前作遇到的问题一样，我们也要考虑智能指针如何管理对象。为了避免被管理的对象生存期短于智能指针对象，我们只能有以下几种情况，从 Point 对象开始去构造智能指针对象。

- 传入 new 得到的指针：SmartPointer sp(new Point());；

- 传入 Point 对象，而后拷贝一份被 SmartPointer 管理：SmartPointer sp(p);；

- 将用于构造 Point 的参数传递给 SmartPointer 的构造函数，直接构造：SmartPointer sp(0, 0);。

因此，我们的 SmartPointer 类应该有以下一些构造函数。

```cpp
SmartPointer {
 public:
  SmartPointer(Point* pp);
  SmartPointer(Point p);
  SmartPointer(int x, int y);

 public:
  SmartPointer();
  SmartPointer(const SmartPointer& other);
  SmartPointer(SmartPointer&& other);
  SmartPointer& operator=(const SmartPointer& other);
  SmartPointer& operator=(SmartPointer&& other) noexcept;
  ~SmartPointer();

  // ...
};
```

#### 获取对象

我们还需要考虑，如何从智能指针对象出发，使用被绑定的对象。为此，我们可以重载 SmartPointer 类的 operator->() 和 operator*() 操作符，将相关操作转发给底层的 Point 对象。

因此，SmartPointer 类的声明又多了两个重载函数。

```cpp
SmartPointer {
 public:
  SmartPointer(Point* pp);
  SmartPointer(const Point& p);
  SmartPointer(Point&& p);
  SmartPointer(int x, int y);

 public:
  SmartPointer();
  SmartPointer(const SmartPointer& other);
  SmartPointer(SmartPointer&& other) noexcept;
  SmartPointer& operator=(const SmartPointer& other);
  SmartPointer& operator=(SmartPointer&& other) noexcept;
  ~SmartPointer();

 public:
  Point* operator->() const noexcept;
  Point& operator*() const noexcept;

  // ...
};
```

#### 引用计数

先前提到，为了实现智能指针的效果，我们必须借助一个计数器，以便随时获知有多少智能指针绑定在同一个对象上。显而易见，这个计数器不应该是 SmartPointer 的一部分。这是因为，如果计数器是 SmartPointer 的一部分，那么每次增减计数器的值，都必须广播到每一个管理着目标对象的智能指针。这样做的代价太大了。

为此，我们为 Point 类构造一个辅助类 PointCounter，来做计数器使用。PointCounter 类完全是为了实现 SmartPointer 而设计的，它不应被 SmartPointer 类以外的代码修改。因此，PointCounter 类的所有成员都应是 private 的，并声明 SmartPointer 为其友元类。

```cpp
class PointCounter {
 private:
  friend class SmartPointer;

  Point p_;
  size_t count_;

  PointCounter() : count_{1} {}                         // 1.
  PointCounter(const Point& p) : p_{p}, count_{1} {}    // 2.
  PointCounter(Point&& p) : p_{p}, count_{1} {}         // 3.
  PointCounter(int x, int y) : p_{x, y}, count_{1} {}   // 4.
};
```

由于 PointCounter 是为了计数而设计的，因此 (1) 处的所有构造函数，在构造时都将计数器设置为 1。(2), (3) 两处则分别是调用 Point 类的拷贝和移动构造函数。(4) 则调用 Point(int x, int y)。

#### SmartPointer 的实现

至此，我们可以实现 SmartPointer 类了。

```cpp
class SmartPointer {
 public:
  SmartPointer(Point* pp) : ptctr_{new PointCounter(*pp)} {}            // 1.
  SmartPointer(const Point& p) : ptctr_{new PointCounter(p)} {}
  SmartPointer(Point&& p) : ptctr_{new PointCounter(p)} {}
  SmartPointer(int x, int y) : ptctr_{new PointCounter(x, y)} {}

 private:
  void try_decrease() {
    if (nullptr != ptctr_) {
      if (1 == ptctr_->count_) {
        delete ptctr_;
      } else {
        --(ptctr_->count_);
      }
    } else {}
  }

 public:
  SmartPointer() : ptctr_{new PointCounter} {}                          // 2.
  SmartPointer(const SmartPointer& other) : ptctr_{other.ptctr_} {      // 3.
    ++(ptctr_->count_);
  }
  SmartPointer(SmartPointer&& other) noexcept : ptctr_{other.ptctr_} {
    other.ptctr_ = nullptr;
  }
  SmartPointer& operator=(const SmartPointer& other) {                  // 4.
    try_decrease();
    ptctr_ = other.ptctr_;
    ++(ptctr_->count_);
    return *this;
  }
  SmartPointer& operator=(SmartPointer&& other) noexcept {
    try_decrease();
    ptctr_ = other.ptctr_;
    other.ptctr_ = nullptr;
    return *this;
  }
  ~SmartPointer() {
    try_decrease();
    ptctr_ = nullptr;
  }

 public:
  Point* operator->() const noexcept {                                  // 5.
    return &(ptctr_->p_);
  }
  Point& operator*() const noexcept {
    return ptctr_->p_;
  }

 private:
  PointCounter* ptctr_ = nullptr;
};
```

这里，(1) 处四个构造函数负责构造一个新的 PointCounter 对象，并将其指针赋值给 ptctr_；(2) 处的默认构造函数则构造了一个空的 PointCounter 对象（其计数值也为 1）；(3) 处的拷贝和移动构造函数负责从 other 处获得 ptctr_ 的值，并处理好计数器的值的变化；(4) 是拷贝和移动赋值运算符，在执行时，首先要先释放计数器辅助类，而后从 other 处获取新的计数器辅助类对象的指针；(5) 处重载了成员访问运算符，将成员访问的操作转发到 Point 对象上。

如此，我们就得到了第一版的智能指针的实现。

## 第二次尝试

### 分析

在第一次尝试的过程中，为了快速搭建模型，我们做一个假设：我们的例子从 Animal 切换到了 Point，从而忽略了继承和动态绑定。这个假设导致我们在后续处理引用计数的过程中，使用了十分粗暴的方式：定义一个与 Point 对应的 PointCounter 类。事实上，这种方法是很不好的。

首先，PointCounter 类内包含了一个类型为 Point 的成员，从而禁止了动态绑定。这是因为 C++ 的动态绑定是建立在基类的指针或引用的基础之上的。其次，从抽象的角度来说，SmartPointer 需要的计数器，与 SmartPointer 内绑定的对象的类型没有关系，因此不应该针对 Point 类构建一个 PointCounter 辅助类。

当前 SmartPointer 类存在的问题，促使我们继续思考去解决。基本来说，我们需要对引用技术器进行单独的抽象，将数据与计数器分离开来。

### 引用计数器

我们从最基本的部分开始。

一个引用计数器类，至少应该包含一个指向无符号整数类型的指针。使用无符号的整数，是因为我们的目的是引用计数，它不会小于零。使用指针是因为我们希望为这个计数器动态分配内存，使得多个引用计数器类的对象可以共享。

因此，考虑构造函数、析构函数、赋值运算符，引用计数器类的定义目前看起来是这样。

```cpp
class RefCount {
 private:
  size_t* count_ = nullptr;

 private:
  void try_decrease() {
    if (nullptr != count_) {
      if (1 == *count_) {
        delete count_;
      } else {
        --(*count_);
      }
    } else {}
  }

 public:
  RefCount() : count_{new size_t(1)} {}
  RefCount(const RefCount& other) : count_{other.count_} { ++(*count_); }
  RefCount(RefCount&& other) : count_{other.count_} { other.count_ = nullptr; }
  RefCount& operator=(const RefCount& other) {
    try_decrease();
    count_ = other.count_;
    ++(*count_);
    return *this;
  }
  RefCount& operator=(RefCount&& other) {
    try_decrease();
    count_ = other.count_;
    other.count_ = nullptr;
    return *this;
  }
  ~RefCount() {
    try_decrease();
    count_ = nullptr;
  }

  // ...
};
```

回顾 SmartPointer 的析构函数，我们不难发现：为了在合适的实际销毁 Point 对象，我们必须有办法知道当前析构的 SmartPointer 是否为最后一个绑定在目标 Point 对象上的智能指针。因此，我们的 RefCount 类必须提供这样的接口。

```cpp
class RefCounter {
  // ...

 public:
  bool only() const { return (1 == *count_); }
};
```

### 重新实现智能指针

至此，我们可以考虑重新实现智能指针类了。

```cpp
class SmartPointer {
 public:
  SmartPointer(Point* pp) : point_{pp} {}                   // 1.
  SmartPointer(const Point& p) : point_{new Point(p)} {}
  SmartPointer(Point&& p) : point_{new Point{p}} {}
  SmartPointer(int x, int y) : point_{new Point{x, y}} {}

 public:
  SmartPointer() : point_{new Point} {}
  SmartPointer(const SmartPointer& other) = default;        // 2.
  SmartPointer(SmartPointer&& other) noexcept : point_{other.point_}, refc_{std::move(other.refc_)} {
    other.point_ = nullptr;
  }
  SmartPointer& operator=(const SmartPointer& other) {      // 3.
    if (refc_.only()) {
      delete point_;
    }
    refc_  = other.refc_;
    point_ = other.point_;
    return *this;
  }
  SmartPointer& operator=(SmartPointer&& other) noexcept {
    if (refc_.only()) {
      delete point_;
    }
    refc_  = std::move(other.refc_);
    point_ = other.point_;
    other.point_ = nullptr;
    return *this;
  }
  ~SmartPointer() {                                         // 4.
    if (point_ and refc_.only()) {
      delete point_;
      point_ = nullptr;
    }
  }

 public:
  Point* operator->() const noexcept {
    return point_;
  }
  Point& operator*() const noexcept {
    return *point_;
  }

 private:
  Point* point_ = nullptr;
  RefCount refc_;
};
```

这里，(1) 处定义的四个构造函数，由于无需再使用 PointCounter 类，变得简单了一些；由于 SmartPointer 的所有数据成员都能自己处理好拷贝和移动，因此 (2) 处 SmartPointer 的拷贝构造函数可以让编译器自动生成；(3) 处实现的拷贝和移动赋值运算符和之前相比也有了很大变化：由于 RefCount 可以提供了 only() 接口，同时由于 RefCount 能够自行处理好拷贝和移动赋值，赋值运算的实现变得简单了很多；基于同样的原因，(4) 处的析构函数也无需处理 RefCount 类型的数据成员——交给它自己处理即可。

## 第三次尝试

### 分析

相比第一版，第二版的 SmartPointer 有了不少改进。但是，它有点名不副实——虽然类的名字是 SmartPointer，但是却只能和 Point 这一个类联用。为此，我们需要 C++ 中的模板技术。

在第二版 SmartPointer 实现中，大多数的内容都与 Point 类无关，唯独构造函数 SmartPointer(int x, int y) 是专为 Point 类设计的。这一构造函数所作的唯一一件事情，是将收到的参数转发给 Point 相应的构造函数。我们希望 SmartPointer 类的形式是 template <typename T> class SmartPointer;。但 T 的构造函数可以千奇百怪，于是若要将 T 的构造函数都在 SmartPointer 中做转发，就不得不变成 template <typename T, typename... Args> class SmartPointer;。这很不好；因此，我们需要将这类构造函数从 SmartPointer 的定义中迁移出去。

另一方面，我们又希望能够保留从 T 的构造函数出发，直接构造 SmartPointer 的能力。为此，我们需要引入一个函数模板 make_smart。

```cpp
template<typename T, typename... Args>
SmartPointer<T> make_smart(Args&&... args);
```

这个函数模板能够接受任意个数及类型的参数，并构造一个 SmartPointer<T> 类型的智能指针。

接下来，我们首先改造 SmartPointer 的定义，然后实现 make_smart 函数模板。

### 改造智能指针

将 SmartPointer 改造成类模板是很容易的事情：只需要将所有的 Point 改成 T，并声明为类模板即可——当然，要去掉上述构造函数。为了区分，这里将 SmartPointer 重命名为 smart_ptr。

```cpp
template<typename T>
class smart_ptr {
 public:
  using value_type = T;

 public:
  smart_ptr(value_type* pp) : value_{pp} {}
  smart_ptr(const value_type& p) : value_{new value_type(p)} {}
  smart_ptr(value_type&& p) : value_{new value_type{p}} {}

 public:
  smart_ptr() : value_{new value_type} {}
  smart_ptr(const smart_ptr& other) = default;
  smart_ptr(smart_ptr&& other) = default;
  smart_ptr& operator=(const smart_ptr& other) {
    if (refc_.only()) {
      delete value_;
    }
    refc_  = other.refc_;
    value_ = other.value_;
    return *this;
  }
  smart_ptr& operator=(smart_ptr&& other) noexcept {
    if (refc_.only()) {
      delete value_;
    }
    refc_  = std::move(other.refc_);
    value_ = other.value_;
    other.value_ = nullptr;
    return *this;
  }
  ~smart_ptr() {
    if (value_ and refc_.only()) {
      delete value_;
      value_ = nullptr;
    }
  }

 public:
  value_type* operator->() const noexcept {
    return value_;
  }
  value_type& operator*() const noexcept {
    return *value_;
  }

 private:
  value_type* value_ = nullptr;
  RefCount refc_;
};
```

### 实现 make_smart 函数模板

基础版本的 make_smart 也是很容易的，只需要将接收到的参数转发给 T 的构造函数即可。

```cpp
template<typename T, typename... Args>                     // 1.
smart_ptr<T> make_smart(Args&&... args) {                  // 2.
  return smart_ptr<T>(new T(std::forward<Args>(args)...)); // 3.
}
```

这里，(1) 处使用了 C++11 中名为「参数包」的技术，使得函数模板可以接收任意多个任意类型的参数；(2) 处对参数包进行解包，使用右值引用模式接受参数，借助「引用折叠」技术接收任意类型的参数；(3) 处使用了 std::forward，将接收到的参数原封不动地完美地转发给 T 的构造函数。

关于参数包技术，将在未来的博文中介绍。

至此，完整代码可见[这里](/uploads/codes/cpp/smart_ptr.cc)。