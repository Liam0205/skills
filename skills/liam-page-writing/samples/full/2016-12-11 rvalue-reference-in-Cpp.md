---
title: "谈谈 C++ 中的右值引用"
url: https://liam.page/2016/12/11/rvalue-reference-in-Cpp/
date: 2016-12-11
categories: ["Algorithm and Computer Science"]
tags: ["Cpp", "Reference", "rvalue", "move", "move_iterator"]
---

最近在改 XGBoost 的代码。XGBoost 在代码中使用了很多来自 C++11 标准中的特性，让我比较好奇和困惑的，就有其中关于右值引用的部分。涉及到代码里，有比较明显的两类用法：

```cpp
std::move(foo)
```

```cpp
std::vector<std::unique_ptr<T>>
```

前者是使用 std::move 返回 foo 的右值引用；后者则在容器 std::vector 中放入了不可复制只能移动的类的对象（智能指针 std::unique_ptr），当你尝试用常规方法将整个 std::vector 中的元素依次加入另一个 std::vector 的时候，编译器就会报错，提示 std::unique_ptr 的拷贝构造函数是被删除的。

因为好奇和困惑，所以想要把它们搞清楚，于是有了这篇文章。

## 左值和右值

左值和右值，最早是从 C 语言继承而来的。在 C 语言，或者继承版本，的解释中，

- 左值是可以位于赋值运算符 = 左侧的表达式（当然，左值也可以位于 = 的右侧），而

- 右值是不可以位于赋值运算符 = 左侧的表达式。

对于这个经典的解释，我们有如下示例

```cpp
int foo(42);
int bar(43);

// foo, bar 都是左值
foo = bar;
bar = foo;
foo = foo * bar;

// foo * bar 是右值
int baz;
baz = foo * bar;  // OK: 右值在赋值运算符右侧
foo * bar = 42;   // Err: 右值在赋值运算符左侧
```

这个解释很经典，也容易懂。不过在 C++ 里面，左值和右值不能这样定义。根据《C++ Primer》的说法，左值和右值可以这样区分：

一个表达式是左值还是右值，取决于我们使用的是它的值还是它在内存中的位置（作为对象的身份）。也就是说一个表达式具体是左值还是右值，要根据实际在语句中的含义来确定。例如

```cpp
int foo(42);
int bar;

// 将 foo 的值赋给 bar，保存在 bar 对应的内存中
// foo 在这里作为表达式是右值；bar 在这里作为表达式是左值
// 但是 foo 作为对象，既可以充当左值又可以充当右值
bar = foo;
```

因为 C++ 中的对象本身可以是一个表达式，所以这里有一个重要的原则，即

- 在大多数情况下，需要右值的地方可以用左值来替代，但

- 需要左值的地方，一定不能用右值来替代。

又有一个重要的特点，即

- 左值存放在对象中，有持久的状态；而

- 右值要么是字面常量，要么是在表达式求值过程中创建的临时对象，没有持久的状态。

## 左值引用和右值引用

在 C++ 中，有两种对对象的引用：左值引用和右值引用。

左值引用是常见的引用，所以一般在提到「对象的引用」的时候，指得就是左值引用。如果我们将一个对象的内存空间绑定到另一个变量上，那么这个变量就是左值引用。在建立引用的时候，我们是「将内存空间绑定」，因此我们使用的是一个对象在内存中的位置，这是一个左值。因此，我们不能将一个右值绑定到左值引用上。另一方面，由于常量左值引用保证了我们不能通过引用改变对应内存空间的值，因此我们可以将右值绑定在常量引用上。

```cpp
int foo(42);
int& bar = foo;  // OK: foo 在此是左值，将它的内存空间与 bar 绑定在一起
int& baz = 42;   // Err: 42 是右值，不能将它绑定在左值引用上
const int& qux = 42;  // OK: 42 是右值，但是编译器可以为它开辟一块内存空间，绑定在 qux 上
```

右值引用也是引用，但是它**只能且必须**绑定在右值上。

```cpp
int foo(42);
int& bar = foo;        // OK: 将 foo 绑定在左值引用上
int&& baz = foo;       // Err: foo 可以是左值，所以不能将它绑定在右值引用上
int&& qux = 42;        // OK: 将右值 42 绑定在右值引用上
int&& quux = foo * 1;  // OK: foo * 1 的结果是一个右值，将它绑定在右值引用上
int& garply = foo++;   // Err: 后置自增运算符返回的是右值，不能将它绑定在左值引用上
int&& waldo = foo--;   // OK: 后置自减运算符返回的是右值，将它绑定在右值引用上
```

由于右值引用只能绑定在右值上，而右值要么是字面常量，要么是临时对象，所以：

- 右值引用的对象，是临时的，即将被销毁；并且

- 右值引用的对象，不会在其它地方使用。

敲黑板：这是重点！

这两个特性意味着：**接受和使用右值引用的代码，可以自由地接管所引用的对象的资源，而无需担心对其他代码逻辑造成数据破坏**。

## 引用的值类型与引用叠加

### 值类型

我们思考一个问题：右值引用本身是左值还是右值？或者可以先思考一下它的对偶问题：左值引用本身是左值还是右值？

先看下面的代码：

```cpp
int foo(42);
int& bar = foo;     // bar 是对 foo 的左值引用
int& baz = bar;     // baz 是对 bar 的左值引用，因而 bar 是左值
int qux = ++foo;    // 前置自增运算符返回左值引用，在这里赋值给 qux，此时左值引用作为右值
```

观察上面代码，不难发现，左值引用本身既可以是左值，又可以是右值。它具体是左值还是右值，依然取决于它作为表达式时候的作用。更仔细地观察可以发现，如果左值引用作为一个变量被保存下来了，那么它就可以是左值（当然也可以起到右值的作用）；而如果左值引用是一个临时变量（例如函数的返回值），那么它就是右值。

同理可以用在右值引用上。

```cpp
class Type;
void foo(Type&& bar) {
    // 将右值引用作为 Type 的构造函数的参数
    // 此时匹配 Type::Type(const Type& orig), 即拷贝构造函数
    // bar 是左值
    Type baz(bar);
}
Type&& qux();
quux = qux();   // qux 的返回值是 Type 类型的右值引用，此时右值引用是右值
```

和左值引用一样，右值引用本身也既可以作为左值也可以作为右值。并且，同样的是：如果右值引用作为变量被保存下来了，那么应该把它当做是一个左值看待；否则应当作为右值看待。

因此，不论是左值引用还是右值引用，都有

- 当引用作为变量被保存下来，那么它是左值；否则

- 它是右值。

### 叠加

我们先来看一段代码。

```cpp
typedef int& intR;
typedef intR& intRR;

int main() {
    int foo = 42;
    intR bar = foo;
    intRR baz = bar;
    return 0;
}
```

在这里，intR 实际上是 int&。因此 intRR 就变成了 int& &，注意两个 & 之间有一个空格，表示这是对 int 类型引用的引用，也就是引用的叠加。在 C++11 之前，编译这份代码是会报错的：

```plaintext
ref_test.cpp:2:15: 错误：无法声明对‘intR {aka int&}’的引用
```

这是因为在 C++11 之前，C++ 标准没有写明引用叠加。在 C++11 中，引用叠加有如下规则：

```plaintext
Type&  &  -> Type&
Type&  && -> Type&
Type&& &  -> Type&
Type&& && -> Type&&
```

这有点类似布尔代数中的与运算：左值引用是 0，右值引用是 1。因此，在 C++11 中，上述代码中的 intRR 实际就是 int& 类型。这样一来，代码就合法了。

同样的引用叠加规则，也可以应用到模板参数推导中。看这个例子

```cpp
template <typename T> void func(T&& foo);
auto fp = func<int&&>;
```

在这里，func 是一个模板函数，fp 是函数指针。要确定 fp 的实际类型，就要先确定模板函数参数的类型。

- 在模板中，T 被 int&& 替换，因此 T 是 int 的右值引用；

- 在函数参数列表声明中，foo 是 T&& 类型，因此是 int&& && 类型，根据叠加规则，实际 foo 是 int&& 类型。

这样一来，fp 就是 void (*)(int&&) 类型的指针了。

## 右值引用怎么用

说了这么多右值引用的概念，应该说点实际的用途了，这样右值引用这件事情看起来才会显得自然。

### move 语义

假设 class Container 有这样的定义

```cpp
#include <iostream>
#include <string>

class Container {
 private:
  typedef std::string Resource;

 public:
  Container() {
    resource_ = new Resource;
    std::cout << "default constructor." << std::endl;
  }
  explicit Container(const Resource& resource) {
    resource_ = new Resource(resource);
    std::cout << "explicit constructor." << std::endl;
  }
  ~Container() {
    delete resource_;
    std::cout << "destructor" << std::endl;
  }
  Container(const Container& rhs) {
    resource_ = new Resource(*(rhs.resource_));
    std::cout << "copy constructor." << std::endl;
  }
  Container& operator=(const Container& rhs) {
    delete resource_;
    resource_ = new Resource(*(rhs.resource_));
    std::cout << "copy assignment." << std::endl;
    return *this;
  }

 private:
  Resource* resource_ = nullptr;
};
```

于是当你执行类似这样的代码的时候，你会很郁闷地发现，效率很低：

```cpp
Container get() {
  Container ret("tag");
  return ret;
}

int main() {
  Container foo;
  // ...
  foo = get();
  return 0;
}
// $ ./a.out
// default constructor.
// explicit constructor.
// copy assignment.
// destructor
// destructor
```

在执行 bar = foo() 的时候，会进行这样的操作：

- 从函数返回值中得到临时对象 rhs；

- 销毁 bar 中的资源（delete resource_;）；

- 将 rhs 中的资源拷贝一份，赋值给 bar 中的资源（resource_ = new Resource(*(rhs.resource_));）；

- 销毁 rhs 这一临时对象。

仔细想想你会发现，销毁 bar 中的资源，再从临时对象中复制相应的资源，这件事情完全没有必要。我们最好能直接抛弃 bar 中的资源而后直接接管 foo 返回的临时对象。这就是 move 语义。

这样一来，就意味着我们需要重载 Container 类的赋值操作符，它应该有这样的函数声明：

```cpp
Container& Container::operator=(<mystery type> rhs)
```

为了与拷贝版本的赋值运算符区分，我们希望，当 Container::operator= 的右操作数是右值引用时，调用这个版本的赋值运算符，那么毫无疑问，<mystery type> 应该是 Container&&。于是我们定义它（称为移动赋值运算符，以及同时定义移动构造函数）：

```cpp
class Container {
 private:
  typedef std::string Resource;

 public:
  Container() {
    resource_ = new Resource;
    std::cout << "default constructor." << std::endl;
  }
  explicit Container(const Resource& resource) {
    resource_ = new Resource(resource);
    std::cout << "explicit constructor." << std::endl;
  }
  ~Container() {
    delete resource_;
    std::cout << "destructor" << std::endl;
  }
  Container(const Container& rhs) {
    resource_ = new Resource(*(rhs.resource_));
    std::cout << "copy constructor." << std::endl;
  }
  Container& operator=(const Container& rhs) {
    delete resource_;
    resource_ = new Resource(*(rhs.resource_));
    std::cout << "copy assignment." << std::endl;
    return *this;
  }
  Container(Container&& rhs) : resource_(rhs.resource_) {
    rhs.resource_ = nullptr;
    std::cout << "move constructor." << std::endl;
  }
  Container& operator=(Container&& rhs) {
    Resource* tmp = resource_; resource_ = rhs.resource_; rhs.resource_ = tmp;
    std::cout << "move assignment." << std::endl;
    return *this;
  }

 private:
  Resource* resource_ = nullptr;
};
```

亦即，我们只需要对两个指针的值进行操作就可以了。这样一来，相同代码的执行过程会变成：

```cpp
Container get() {
  Container ret("tag");
  return ret;
}

int main() {
  Container foo;
  // ...
  foo = get();
  return 0;
}
// $ ./a.out
// default constructor.
// explicit constructor.
// move assignment.
// destructor
// destructor
```

- 从函数返回值中得到临时对象 rhs；

- 交换 foo.resource_ 和 rhs.resource_ 两个指针的值；

- 销毁 rhs 这一临时对象。

这相当于我们将临时对象 rhs 中的资源「移动」到了 foo 当中，避免了销毁资源再拷贝赋值的开销。

### 完美转发（perfect forwarding）

首先我们来看一个工厂函数

```cpp
template<typename T, typename ArgT>
std::shared_ptr<T> factory(const ArgT& arg) {
    return shapred_ptr<T>(new T(arg));
}
```

factory 函数有两个模板参数 T 与 ArgT，并假定类型 T 有一个构造函数，可以接受 const ArgT& 类型的参数，进行 T 类型对象的构造，然后返回一个 T 类型的智能指针，指向构造出来的对象。

毫无疑问，在这个例子里，factory 函数的 arg 变量既可以接受左值，也可以接受右值（允许将右值绑定在常量左值引用上）。但这里还有一个问题，按照之前的分析，不论 arg 接受的是什么类型，到了 factory 函数内部，arg 本身都将是一个左值。这样一来，假设类型 T 的构造函数支持对 ArgT 类型的右值引用，也将永远不会被调用。也就是说，factory 函数无法实现 move 语义，也就无法不能算是完美转发。

这里我们引入一个函数，它是标准库的一部分：

```cpp
template<class S>
S&& forward(typename std::remove_reference<S>::type& a) noexcept
{
  return static_cast<S&&>(a);
}
```

当 a 的类型是 S& 的时候，函数将返回 S&；当 a 的类型是 S&& 的时候，函数将返回 S&&。因此，在这种情况下，我们只需要稍微改动工厂函数的定义就可以了：

```cpp
template<typename T, typename ArgT>
std::shared_ptr<T> factory(ArgT&& arg) {
    return std::shapred_ptr<T>(new T(std::forward<ArgT>(arg)));
}
```

于是：

- 当 arg 是接受的参数是 Type& 时，ArgT 是 Type&，arg 的类型是 Type&，T::T(Type&) 被调用；

- 当 arg 是接受的参数是 Type&& 时，ArgT 是 Type&&，arg 的类型是 Type&&，T::T(Type&&) 被调用。

这样一来，就保留了 move 语义，实现了完美转发。

### std::move

标准库还定义了 std::move 函数，它的作用就是将传入的参数以右值引用的方式返回。

```cpp
template<class T>
typename std::remove_reference<T>::type&&
std::move(T&& a) noexcept
{
  typedef typename std::remove_reference<T>::type&& RvalRef;
  return static_cast<RvalRef>(a);
}
```

首先，出现了两次 std::remove_reference<T>::type&&，它确保不论 T 传入的是什么，都将返回一个真实类型的右值引用。static_cast<RvalRef>(a) 则将 a 强制转换成右值引用并返回。有了 std::move，我们就可以调用 std::unique_ptr 的移动赋值运算符了（当然，单独这样调用可能没有什么意义）：

```cpp
std::unique_ptr<Type> new_ptr = std::move(old_ptr);
// old_ptr 应当立即被销毁，或者赋予别的值
// 不应对 old_ptr 当前的状态做任何假设
```

在这里，因为使用了 std::move 窃取了 old_ptr 中的资源，然后将他们移动到了 new_ptr 中去。这就隐含了一层意思：接下来我们不会在用 old_ptr 做任何事情，除非我们显式地对 old_ptr 赋予新值。事实上，我们不应对 old_ptr 当前的状态做任何假设，它就和已定义但未初始化的状态一样。因为，old_ptr 当前的状态，完全取决于 std::unique_ptr<Type>::operator=(unique_ptr<Type>&&) 的行为。

### 移动迭代器（move_iterator）

现在假设有这样一个容器 std::vector<std::unique_ptr<RegTree>>，即在向量中保存了若干指向 RegTree 的 unique_ptr 智能指针；又有一个函数 BoostNewTrees(std::vector<std::unique_ptr<RegTree>>& ret)，将会首先清洗 ret 中的数据，然后再将新的数据放入 ret 中。

现在，我需要循环多次执行 BoostNewTrees 函数，并将他们生成的数据依次放入一个容器里。那么，下面的代码会产生编译错误：

```cpp
std::vector<std::unique_ptr<RegTree>> ret;
for (size_t i(0); i != limit; ++i) {
    std::vector<std::unique_ptr<RegTree>> tmp;
    BoostNewTrees(tmp);
    ret.insert(ret.end(), tmp.begin(), tmp.end());  // compile error!
}
```

这是因为，在调用 ret.insert() 函数时，传入的迭代器 tmp.begin() 在解引用时，会返回 std::unique_ptr<RegTree>&，进而尝试调用拷贝构造函数 unique_ptr<RegTree>(const unique_ptr<RegTree>&)，复制内容。然而，该函数被声明为「删除的」，不允许用户调用，于是报错。

为此，我们需要调用 std::make_move_iterator 函数（定义在 iterator 头文件里），将普通的迭代器转换为移动迭代器。相比普通迭代器，移动迭代器仅仅在解引用时的行为有不同：它将返回元素类型的右值引用（而不是普通迭代器返回的左值引用）。这相当于对普通迭代器每次解引用之后，都调用一次 std::move 获取右值引用。于是，在进行 insert 的时候，调用的就是移动构造函数 unique_ptr<RegTree>(unique_ptr<RegTree>&&) 了，而这是允许的。

```cpp
std::vector<std::unique_ptr<RegTree>> ret;
for (size_t i(0); i != limit; ++i) {
    std::vector<std::unique_ptr<RegTree>> tmp;
    BoostNewTrees(tmp);
    ret.insert(ret.end(),
        std::make_move_iterator(tmp.begin()),
        std::make_move_iterator(tmp.end()));
}
// now we get `ret`.
```

## 参考

- 《C++ Primer, 5th Edition》

- [http://thbecker.net/articles/rvalue_references/section_01.html](http://thbecker.net/articles/rvalue_references/section_01.html)

- [https://accu.org/index.php/journals/227](https://accu.org/index.php/journals/227)

- [http://www.ibm.com/support/knowledgecenter/SSGH3R_13.1.2/com.ibm.xlcpp131.aix.doc/language_ref/reference_collapsing.html](http://www.ibm.com/support/knowledgecenter/SSGH3R_13.1.2/com.ibm.xlcpp131.aix.doc/language_ref/reference_collapsing.html)