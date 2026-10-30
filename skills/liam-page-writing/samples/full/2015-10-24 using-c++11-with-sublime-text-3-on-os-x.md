---
title: "在 OS X 上使用 Sublime Text 编译 C++11"
url: https://liam.page/2015/10/24/using-c++11-with-sublime-text-3-on-os-x/
date: 2015-10-24
categories: ["Algorithm and Computer Science"]
tags: ["Sublime Text", "OS X", "C++", "C++11"]
---

OS X 上使用的 g++ 包含了 C++11，但默认情况下并没有打开。因此，在 Sublime Text 中编译 C++ 代码时，如果代码中使用了 C++11 引入的新的语言特性，编译器就会报错。

## 查看 g++ 的帮助

首先，我们要搞清楚，启用 g++ 的 C++11 模块，应该给 g++ 加入那些 flag。我们在终端中执行：

```plaintext
Liam@Mac OS X  [17:58:30]:~/Documents/git-dev/blog-source/.hexo
$ g++ --help
OVERVIEW: clang LLVM compiler

USAGE: clang [options] <inputs>

OPTIONS:

...
-std=<value>            Language standard to compile for
...
```

在 g++ 打出的帮助文件里，我们看到：

- 在 OS X 里使用的 g++ 实际上是 clang；

- 使用 -std=<value> 选项可以指定语言标准。

## 编写 sublime-build 文件

在 Sublime Text 窗口中，找到菜单栏上的 Tools -> Build System -> New Build System...。点击之后，Sublime Text 会打开一个新文件，将如下内容复制进文件：

```json
{
    "cmd": ["g++", "${file}", "-std=c++11", "-stdlib=libc++", "-o", "${file_path}/${file_base_name}"],
    "file_regex": "^(..[^:]*):([0-9]+):?([0-9]+)?:? (.*)$",
    "working_dir": "${file_path}",
    "selector": "source.c, source.c++, source.cxx, source.cc",

    "variants":
    [
        {
            "name": "Run",
            "cmd": ["bash", "-c", "g++  '${file}' -std=c++11 -stdlib=libc++ -o '${file_path}/${file_base_name}' && '${file_path}/${file_base_name}'"]
        }
    ]
}
```

将其保存为 /Users/<USERNAME>/Library/Application Support/Sublime Text 3/Packages/User/C++11.sublime-build。

## 测试

选择 Tools -> Build System -> Automatic，而后编辑如下文件：

```cpp
#include <iostream>

int main () {

  for (auto i = 0; i != 10; ++i)
    std::cout << "I love Sophia!" << std::endl;

  return 0;
}
```

按下组合键 CMD + Shift + B，选择「C++11 - Run」即可。

![](//liam.page/attachment/attachment/images/Sublime/cpp11.png)