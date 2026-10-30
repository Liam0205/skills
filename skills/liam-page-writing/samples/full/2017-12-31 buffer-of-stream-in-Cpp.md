---
title: "谈谈 C++ 中流的缓冲区"
url: https://liam.page/2017/12/31/buffer-of-stream-in-Cpp/
date: 2017-12-31
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Stream", "Buffer"]
---

众所周知，C++ 语言本身并不提供 I/O 功能。C++ 的 I/O 是通过标准库中输入输出流来实现的。标准库在 iostream 头文件当中，预定义了六个流对象，他们是：

- istream <- std::cin/std::wcin，对应标准输入的输入流；

- ostream <- std::cout/std::wcout，对应标准输出的输出流；

- ostream <- std::cerr/std::wcerr，对应标准错误的输出流。

稍有经验的 C++ 程序员都应对这些流熟悉（至少对非宽字符版本的三个流对象熟悉），因此此篇不介绍它们的基本用法，而是讨论流的缓冲区。

## 为什么要有缓冲区？

首先需要思考的问题是：为什么要有缓冲区，而不是与相关的文件/设备进行直接的读写操作。提出这个问题是很显然的。这是因为任何决定都是一种在代价和收益中的权衡。考虑到加上缓冲区是有代价的（代码变得更加复杂、需要控制的内容增多），所以加上缓冲区必然有随之而来的收益。

众所周知，相对于 CPU 的指令执行和主存访问，I/O 操作是非常慢的。这也就是说，在不考虑缓冲区的情况下，如果程序有频繁的 I/O 操作，那么相当于程序的「高速」部分就会被频繁打断。这对于程序的整体性能是不利的。有了缓冲区，程序就可以避免频繁的 I/O 操作，而是对缓冲区进行读写，只有在必须的情况下，才通过刷新缓冲区进行真实的 I/O 操作。这样一来，程序就能将多个缓慢的 I/O 操作合并成一个，从而在整体上提高了程序的性能。

因此，问题的答案是：使用缓冲区有助于提高程序的整体性能。

## 缓冲区要做哪些工作？

确定了必须要使用缓冲区，接下来的问题就是，这种缓冲区应该有哪些功能。

从上一节的描述中，不难发现缓冲区向上连接了程序的输入输出请求，向下连接了真实的 I/O 操作。作为中间层，必然需要分别处理好与上下两层之间的接口，以及要处理好上下两层之间的协作。（后者即是中间层本身的功能）

在 C++ 中，流的缓冲区之基类是定义在 streambuf 头文件当中的 std::basic_streambuf。这是一个类模板；其声明如下：

```cpp
template<
    class CharT,
    class Traits = std::char_traits<CharT>
> class basic_streambuf;
```

std::basic_streambuf 包含两个字符序列，并提供对这两个序列控制和访问的能力：

- 受控字符序列（controlled character sequence）：又称缓冲序列（buffer sequence），由读取区（get area）和/或写入区（put area）组成。此二者分别用来缓冲上层流的读写操作。

- 关联字符序列（associated character sequence）：对于输入流来说又称源（source），对于输出流来说又称槽（sink）。关联字符序列通常是通过系统 API 与 I/O 设备关联，或是与 std::vector/array/字符串字面值等能作为源或槽的对象关联。

对于关联字符序列来说，需要 std::basic_streambuf 自己实现的功能不多。因为，大多数情况可通过系统 API 或是相关对象的接口来实现。std::basic_streambuf 大多数的功能集中在对受控字符序列的管理上。

读取区或写入区，通常实现为相应 CharT 的 C 风格数组，并辅以 3 个指针，以实现对受控字符序列的控制：

- 起始指针（beginning pointer）：用于标识相应缓冲序列可用范围的起始位置；

- 终止指针（end pointer）：用于标识相应缓冲序列可用范围的尾后位置；

- 工作指针（next pointer）：指向相应缓冲序列中，下一个等待读/写的元素的位置。

若是一个受控字符序列单单是读取区或写入区，则它必然有这三个指针；若一个受控字符序列同时是读取区和写入区，那么则有两套共六个这样的指针。通过这些指针，std::basic_streambuf 就能实现对换受控字符序列的控制。

## 流中的缓冲区

在头文件 ios 当中，定义着两个类（模板）：std::ios_base 和 std::basic_ios。前者是所有 I/O 类的祖先，提供了状态信息、控制信息、内部存储、回调等设施。后者继承自前者，额外提供了与 std::basic_streambuf 的接口；同时允许多个 std::basic_ios 对象绑定同一个 std::basic_streambuf 对象。它们的声明分别是：

```cpp
class ios_base;
template<
    class CharT,
    class Traits = std::char_traits<CharT>
> class basic_ios;  // : public ios_base
```

由于 std::ios_base 没有提供与 std::basic_streambuf 的接口，std::basic_ios 才是标准库内所有 I/O 类（模板）事实上的最近共同祖先。std::basic_ios 的成员函数 rdbuf 是读取和设置流对象（std::basic_ios 的对象）绑定缓冲区的成员函数，它有两个不同的重载形式，分别如下：

```cpp
std::basic_streambuf<CharT, Traits>*
rdbuf() const;                                      // 1.
std::basic_streambuf<CharT, Traits>*
rdbuf( std::basic_streambuf<CharT, Traits>* sb );   // 2.
```

两个重载版本，第一版不接受任何参数，第二版接受一个指向 std::basic_streambuf<CharT, Traits> 类型对象的指针。

不接受参数的版本返回流对象绑定的缓冲区对象的指针；而若流对象未绑定任何缓冲区对象，则返回空指针 nullptr。接受指针的版本首先返回上述指针，而后与先前绑定的缓冲区对象（如果有）解绑，再绑定参数中传入指针指向的缓冲区对象；而若传入空指针 nullptr，则流对象不与任何缓冲区对象绑定。

## 巧妙设置流中的缓冲区

通过巧妙设置流中的缓冲区，可以达成各种特殊的效果。这里给出几个演示。

### 输出流共享缓冲区

从机制上说，std::basic_ios 允许多个流对象绑定同一个缓冲区对象。当然，虽然机制上允许，一般来说这样做却不是好主意。不过，在某些情况下，让多个流对象绑定同一个缓冲区对象，也是有好处的。

在具体介绍具体操作之前，还有一事必须说明。如前所述，缓冲区对象是在流和 I/O 设备之间加入的抽象中间层。因此，实际上对于流的所有操作，都会反馈在缓冲区对象之上，而非直接作用域 I/O。这也就是说，一旦流对象绑定的缓冲区对象发生变化，最终的 I/O 效果也会随之发生变化。

众所周知，头文件 iomanip 当中定义了许多与 std::ios_base 相关的格式控制函数与对象。通过这些函数与对象，程序员可以控制从 I/O 流的行为。但若上述行为需要频繁在若干状态之间发生切换，则代码会显得相当繁琐。此时，让多个流对象绑定同一个缓冲区对象就是有好处的了。程序员可以让多个流对象绑定同一个缓冲区对象，而后为每个流对象设置不同的 I/O 行为，即可在需要的时候使用对应的流对象。由于这些流对象绑定了同一个缓冲区对象，这些 I/O 操作最终会合在一起。如此，就达成了目的。

以下是让输出流共享缓冲区的示例。

```cpp
#include <iostream>
#include <iomanip>

int main() {
    std::ostream fixed{std::cout.rdbuf()};                          // 1.
    std::ostream sci{std::cout.rdbuf()};

    fixed.setf(std::ios_base::fixed, std::ios_base::floatfield);    // 2.
    fixed.precision(5);
    sci.setf(std::ios_base::scientific, std::ios_base::floatfield);
    sci.precision(3);

    fixed << 15.518 << '\n';                                        // 3.
    sci   << 15.518 << '\n';

    return 0;
}
```

此处，(1) 将新建的两个流对象 fixed 和 sci 都与 std::cout 的缓冲区对象绑定，而后在 (2) 处分别设置两个流对象的输出格式，最后在 (3) 处用两个不同的流对象输出同一浮点数。编译后得到的结果如下。

```bash
$ g++ -std=c++11 ostream_shares_buf.cc
$ ./a.out
15.51800
1.552e+01
```

### 替换输入流的缓冲区

标准库的 std::cin 默认与关联标准输入的缓冲区对象绑定。因此，使用 std::cin 可以从标准输入中读取输入。不过，在某些情况下，程序员也会希望改变这一点。例如，在 Online Judge 训练时，程序员可能会希望让 std::cin 从本地的测试文件中读取测试用例。考虑到 C++ 中的流对象实际上是对缓冲区进行操作；此时，替换 std::cin 的缓冲区，即可达成目的。

以下是替换标准输入流的示例。

```cpp
#include <iostream>
#include <string>

#ifdef DEBUG_                                           // 1.
#include <fstream>
namespace {                                             // 2.
const constexpr char* kTestFileName = "oj.test.txt";
std::ifstream fin{kTestFileName};                       // 3.
auto cin_buf = std::cin.rdbuf(fin.rdbuf());             // 4.
}  // namespace
#endif  // DEBUG_

int main() {
#ifdef DEBUG_
    std::cin.tie(nullptr);                              // 5.
#endif  // DEBUG_

    std::string temp;
    std::getline(std::cin, temp);
    std::cout << temp << '\n';

    return 0;
}
```

此处，(1) 在 DEBUG_ 宏有定义的情况下，进行 (2)(3)(4)(5) 的步骤。其中 (2) 启用了一个匿名空间，起到 C 语言中文件 static 的作用（C++ 也支持这样的用法，但是已经不推荐）；(3) 声明了一个与测试文件关联的文件输入流；(4) 将 std::cin 与上述文件输入流的缓冲区绑定，同时将 std::cin 原本的缓冲区指针保存在 cin_buf 当中。由于在 DEBUG_ 宏有定义的情况下，std::cin 与标准输入解绑，因此无需与标准输入绑定，故而 (5）处取消这种绑定。编译后得到的结果如下。

```bash
$ cat oj.test.txt
This is a file for testing.
$ g++ -std=c++11 -DDEBUG_ istream_replace_buf.cc
$ ./a.out
This is a file for testing.
```

可见，无需在标准输入手工输入测试样例，程序在 DEBUG_ 有定义时，直接从测试样例文件中读取测试。