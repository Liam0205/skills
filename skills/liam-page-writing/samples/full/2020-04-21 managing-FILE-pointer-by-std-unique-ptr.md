---
title: "使用 std::unique_ptr 管理 FILE 指针"
url: https://liam.page/2020/04/21/managing-FILE-pointer-by-std-unique-ptr/
date: 2020-04-21
categories: ["Algorithm and Computer Science"]
tags: ["Cpp", "C", "unique_ptr", "FILE"]
---

尽管 C++ 提供了 fstream 文件流来读写文件，但对操作符 << 和 >> 的重载令很多 C++ 程序员不爽。因而这些程序员还会使用 C 风格的文件流 FILE 来读写文件。

不过，C++ 的好处也是显而易见的。[RAII 的出现让资源的管理](/2017/04/09/Foundations-of-Cpp/)变得简单。文件流对于程序来说，也是一种资源。本文的目的是让 C 风格的文件流 FILE 可以更方便地享受 RAII 带来的便利。

## 自己造轮子

[前作](/2017/04/09/Foundations-of-Cpp/)为了解释 RAII，自己造了一个文件句柄类来实现文件流指针的 RAII 容器。

```cpp
class FileHandle {
 private:
  FILE* p;
 public:
  FileHandle(const char* path, const char* r) : p{nullptr} {
    p = fopen(path, r);
    if (nullptr == p) {
      throw file_error{path, r};
    }
  }
  FileHandle(const std::string& path, const char* r) : p{nullptr} {
    p = fopen(path.c_str(), r);
    if (nullptr == p) {
      throw file_error{path.c_str(), r};
    }
  }
  FileHandle(FileHandle&& orig) noexcept : p{orig.p} {
    orig.p = nullptr;
  }
  FileHandle& operator=(FileHandle&& rhs) noexcept {
    this->p = rhs.p;
    rhs.p = nullptr;
  }
  ~FileHandle() {
    fclose(p);
  }
  FILE const* p() const {
    return this->p;
  }
  // ...
 private:
  FileHandle(const FileHandle&) = delete;
  FileHandle& operator=(const FileHandle&) = delete;
};
```

这里，我们在构造函数里通过调用 fopen 打开文件，而在析构函数里调用 fclose 关闭文件释放资源。同时，通过禁用拷贝构造及拷贝赋值，避免文件流指针被多个对象持有（这样能避免一些奇怪的错误）；然后实现了移动构造和移动赋值。

若要使用针对 FILE* 设计的 C 函数，只需要做类似 fgetc(file_handle()) 这样的操作即可。

## 用 std::unique_ptr 实现

熟悉 std::unique_ptr 的读者不难发现，这其实就是一个经典的适合独占类型的智能指针发挥作用的场景。不过，std::unique_ptr 的默认删除函数是销毁其占有的指针指向的对象，亦即执行 delete p_。但是，对于文件流来说，我们需要在智能指针完成使命之后关闭文件。

```cpp
template<
    class T,
    class Deleter = std::default_delete<T>
> class unique_ptr;
```

为此，我们需要使用自定义的删除函数。也就是说，我们要给模板参数 Deleter 传入一个合适的参数。这个参数应当是以下三者之一：

- 接受 std::unique_ptr<T, Deleter>::pointer 作为参数的函数对象；

- 接受 std::unique_ptr<T, Deleter>::pointer 作为参数的函数对象的左值引用；

- 接受 std::unique_ptr<T, Deleter>::pointer 作为参数的函数。

换言之，我们得给 Deleter 传这么个东西进去：std::function<void(typename std::unique_ptr<T, Deleter>::pointer)>。于是有代码。

```cpp
#include <iostream>
#include <fstream>
#include <memory>
#include <functional>

void close_file(FILE* fp) {
  fclose(fp);
}

using FileHandler = std::unique_ptr<FILE, std::function<void(FILE*)>>;

int main() {
  std::ofstream("demo.txt") << 'x';  // ensure the file does exist

  FileHandler fp(fopen("demo.txt", "r"), close_file);
  if (nullptr != fp) {
    std::cout << static_cast<char>(fgetc(fp.get())) << std::endl;
  }

  return 0;
}
```

**UPDATE: 2020-04-23**

这样的代码能用，但是有三处不大不小的问题。

- close_file 这个函数既然是 RAII 的一部分，那么最好不要暴露给普通用户。因此要么将它包在一个 __detail 之类的名字空间里，要么用匿名函数。

- 如果 close_file 不暴露给普通用户，那么在构造 FileHandler 的时候，就应当避免传递 close_file。因此我们还需要一层封装。

- 每次使用时，需要 fp.get()。相比不封装时候的 fp，稍显麻烦了点。

显然，我们需要对 FileHandler 做进一步封装——通过继承 std::unique_ptr<FILE, std::function<void(FILE*)>> 而非持有 std::unique_ptr<FILE, std::function<void(FILE*)>>。

```cpp
#include <iostream>
#include <fstream>
#include <memory>
#include <functional>

namespace __detail {
void close_file(FILE* fp) {
  fclose(fp);
}

using file_wrapper = std::unique_ptr<FILE, std::function<void(FILE*)>>;
}  // namespace __detail

class FileHandler : public __detail::file_wrapper {
 public:
  FileHandler(const char* fname, const char* mode) :
    __detail::file_wrapper(fopen(fname, mode), __detail::close_file) {}

  FILE* operator()() const noexcept {
    return this->get();
  }
};  // class FileHandler

int main() {
  std::ofstream("demo.txt") << 'x';  // ensure the file does exist

  FileHandler fp("demo.txt", "r");
  if (nullptr != fp) {
    std::cout << static_cast<char>(fgetc(fp())) << std::endl;
  }

  return 0;
}
```

这里，通过实现 FileHandler::operator()，我们把 FileHandler 的对象变成了可调用的对象。于是，可以使用 fgetc(fp()) 来使用。这样，使用起来就方便多了。