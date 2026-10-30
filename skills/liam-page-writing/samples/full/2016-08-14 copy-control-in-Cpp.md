---
title: "C++ 中类的拷贝控制"
url: https://liam.page/2016/08/14/copy-control-in-Cpp/
date: 2016-08-14
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Class", "Copy Control"]
---

数据成员有指针，构造函数 new 一坨，析构函数 delete 掉，然后不实现深拷贝构造函数。你咋不上天？

为了避免「上天」，我们有必要讨论一下 C++ 中类的拷贝控制。

## 问题重现

为了说明问题的严重性，我们先来重现一下这个问题。

```c++
#include <iostream>
using namespace std;

int main () {
    int* p = new int[100];
    auto q = p;
    delete[] p; p = nullptr;
    delete[] q; q = nullptr; // core dumped!

    return 0;
}
```

这段代码很简单，展现的问题也很清楚。

首先，我们在 main 函数里，在栈里动态分配了一个 int 型数组，返回的内存地址保存在 p 中。而后，通过赋值运算符，将 p 的值赋值给 q。这样，我们就有了 p 和 q，两个指针指向栈中同一块内存空间。

接下来，我们调用 delete[]，将 p 对应的内存空间释放，并将 p 置空。注意，这里是不够的！因为，p 和 q 原本指向同一块内存空间，而我们通过 p 将内存释放了，q 就变成野指针了。于是，在下面的操作中，delete[] q 就变成了对同一内存空间的第二次释放，这是未定义的行为。更有甚者，如果后续程序中，依然使用 q 对相应的内存空间进行存取访问，那么——我就呵呵一笑……

## 拷贝与赋值的问题

上述错误，根本原因是我们通过赋值运算符，将指针 p 的值赋给 q 之后，p 和 q 指向了同一块内存空间。于是，任何对 p/q 其一的操作，都等同于对另一的操作。莫说是多次释放可能造成问题，在正常使用过程中，p 与 q 相互干扰，也可能产生不符合预期的结果——而且很难追查。

这就是说，对于指针的复制，特别是指向动态内存的指针的复制，我们要特别小心。实际上，我们可能期待的是这样的效果：

```c++
int* p = new int[100];
// set value of elements in p
// do a **deep copy**
int* q = new int[100];
for (size_t i = 0; i != 100; ++i) {
    q[i] = p[i];
}
```

也就是说，我们需要一个「深度拷贝」，将 q 与 p 指向不同的内存空间；只不过，它们所包含的元素内容完全相同。如此一来，p 与 q 除了内里一致，其实完全是两块不相干的内存空间。之后，按照既定的规矩来操作，都会是安全可控的。

## 拷贝构造函数与赋值运算符重载

对于 C++ 的内置类型，其拷贝（赋值）过程我们都非常熟悉，也不会出错。

```c++
int i_tmp  = 100;
int i_copy = i_tmp;
```

涉及到类实例（instance of a Class, aka object of a Class）的拷贝和赋值，看似熟悉的问题，就不那么清晰了。每个类的实例当中，都存在若干成员变量。在我们的直觉中，类实例的拷贝和赋值，无非就是将一个实例中的全部成员变量，挨个拷贝、赋值给新的实例。大体上，也没错。但关键是，这些操作，谁来执行呢？

我们知道，在 C++ 中，大多数的操作都是通过某个函数实现的。类实例的拷贝和赋值，也不例外。类实例的拷贝，是通过**拷贝构造函数**来实现的；而类实例的赋值，则是通过**重载过的赋值运算符**来实现的——运算符也是一种函数。不熟悉这个话题的读者，可能没有听说过「拷贝构造函数」或者「重载赋值运算符」。这是因为，一般情况下，编译器会为你**合成**这两个函数。

```c++
SalesData {
    public:
        SalesData (const SalesData&);
        SalesData& operator= (const SalesData&);
        // other functions
    private:
        std::string ID;
        size_t sold_count;
};

// fake: synthesized copy constructor
SalesData::SalesData (const SalesData& orig) :
    ID (orig.ID),                // call the copy constructor of std::string
    sold_count (orig.sold_count) // copy size_t
    {}                           // empty function body

// fake: synthesized overloaded operator
SalesData&
SalesData::operator= (const SalesData& rhs) {
    this->ID         = rhs.ID;          // call std::string::operator=
    this->sold_count = rhs.sold_count;  // operator= for size_t
    return *this;
}
```

这里我们手动实现了 SalesData 类的拷贝构造函数和重载了 SalesData 类的赋值运算符。这两个函数都接收 SalesData 类的常量引用；不同的是，拷贝构造函数没有返回值（因为它是构造函数），而赋值运算符返回了 SalesData 类的左值引用——这与默认的赋值运算符的行为是一致的。

我们注意到，在编译器合成的拷贝构造函数中，在初始化列表里，我们依次调用数据成员的拷贝构造函数，将成员的值拷贝到新的实例中。如果数据成员本身是类实例（而不是基本类型），那么在这个过程中，又会调用这些类的拷贝构造函数。编译器重载的赋值运算符的行为和编译器合成的拷贝构造函数行为类似。只不过，操作由调用拷贝构造函数，变为了调用相应成员变量的赋值运算符。

## 浅拷贝与深拷贝

至今为止，我们看过的拷贝构造函数（与重载的赋值运算符）都还能如预期一样正常工作。但是，在一些情况下，类似编译器合成的拷贝构造函数和赋值运算符，就没法如预期一样工作了：

- 类成员中有静态变量，并且构造函数要操作这些静态变量（比如类实例计数）；

- 类成员中有指针，并且在类示例的生存期内会将它指向动态开辟的内存空间。

在这两种情况下，编译器合成的拷贝构造函数和赋值运算符，就都没办法正常工作了。在静态变量的情形中，默认的拷贝构造函数和复制运算符，不会操作静态变量——因为编译器合成的两个函数只操作实例中的数据成员，但类的静态变量属于类本身，而不属于任何单独的类实例。此时，如果依赖编译器自动合成的两个函数，就无法正确地维护静态变量。在动态开辟内存的情形中，则可能形成本文第一节中多次释放同一块内存空间的问题，引发核心转储。

我们将简单地对数据成员按位赋值的拷贝方式称为**浅拷贝**。毫无疑问，编译器自动合成的拷贝构造函数和赋值运算符，都属于浅拷贝。根据上述分析，我们知道，浅拷贝在某些情况下是不合适的。于是，在这些情况下，我们需要**深拷贝**。

所谓深拷贝，就是在拷贝的过程中，我们需要小心地处理类的静态变量或者动态内存空间。在第一节中，解决复制指针导致两次释放同一块内存空间的实践中，我们就用到了深拷贝。以下是一个深拷贝的例子：

```c++
#define MAX_BUFFER 10240
SalesData {
    public:
        SalesData () = default;
        SalesData (const SalesData&);
        SalesData& operator= (const SalesData&);
        ~SalesData ();
        // other functions
    private:
        std::string ID;
        size_t sold_count;
        size_t* p_buffer;
};

SalesData::SalesData () :
    ID (""), sold_count (0) {
    p_buffer = new size_t [MAX_BUFFER];
}

SalesData::SalesData (const SalesData& orig) :
    ID (orig.ID),                // call the copy constructor of std::string
    sold_count (orig.sold_count) // copy size_t
    {
    this->p_buffer = new size_t [MAX_BUFFER];
    for (size_t i = 0; i != MAX_BUFFER; ++i) {
        this->p_buffer[i] = orig.p_buffer[i];
    }
}

SalesData&
SalesData::operator= (const SalesData& rhs) {
    this->ID         = rhs.ID;          // call std::string::operator=
    this->sold_count = rhs.sold_count;  // operator= for size_t
    this->p_buffer   = new size_t [MAX_BUFFER];
    for (size_t i = 0; i != MAX_BUFFER; ++i) {
        this->p_buffer[i] = rhs.p_buffer[i];
    }
    return *this;
}

SalesData::~SalesData () {
    delete[] p_buffer;
    p_buffer = nullptr;
}
```

## 什么时候需要手工实现深拷贝

在 C++ 中，如果需要你手工实现一个析构函数，通常意味着你的类实例中有动态开辟的内存空间——因为只有这种情况，需要程序员手工在析构实例的时候释分配的内存空间。而我们注意到，一旦类实例中涉及到动态内存空间，在拷贝实例的时候，就需要用深拷贝小心地处理这些内存空间。于是，我们得到了第一条结论**如果需要实现手工的析构函数，那么就需要实现手工的拷贝构造函数和重载赋值运算符**。

此外，**如果类定义中包含静态成员变量，并且这些成员变量在构建、析构实例的时候需要修改，那么通常我们也需要手工实现拷贝构造函数和重载复制运算符**。