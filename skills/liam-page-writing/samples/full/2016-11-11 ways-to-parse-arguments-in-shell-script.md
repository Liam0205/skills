---
title: "在 Shell 脚本中解析选项"
url: https://liam.page/2016/11/11/ways-to-parse-arguments-in-shell-script/
date: 2016-11-11
categories: ["Computer Skills"]
tags: ["Argument", "Shell", "Script", "Option", "Flag", "getopts"]
---

大多数命令行工具，都会提供一些选项。在不同的选项组合之下，这些工具会有不同的行为。GNU 标准的命令行选项解析工具是 getopts，它比其兄弟 getopt 更为强大。除了介绍 getopts 的用法之外，这里还会介绍两种手工解析参数的方法。

在正式介绍之前，有必要区分几个概念（在 Shell 脚本中）。

- Argument, Option: 中文对应「选项」，形如 -a, --save 的都是选项；选项可以接收参数（Parameter），也可以不接受参数。

- Flag: 中文对应「标签」，形如 -v(verbose)；标签是布尔值，不接受参数。

下面正式开始介绍。

## 手工解析

手工解析部分比较简单，这里不做过多的展开。涉及到参数截取的内容，可以参考[前作](/2016/11/08/Shell-variable-reference-and-string-cut-off/)。

手工解析部分提供两种传参的方式：

- 形如 --save foo.txt；

- 形如 --save=foo.txt。

```bash
#!/usr/bin/env bash
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -e|--extension)
    EXTENSION="$2"
    shift # past argument
    ;;
    -s|--searchpath)
    SEARCHPATH="$2"
    shift # past argument
    ;;
    -l|--lib)
    LIBPATH="$2"
    shift # past argument
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done
echo FILE EXTENSION  = "${EXTENSION}"
echo SEARCH PATH     = "${SEARCHPATH}"
echo LIBRARY PATH    = "${LIBPATH}"
echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi
```

```bash
#!/usr/bin/env bash

for i in "$@"
do
case $i in
    -e=*|--extension=*)
    EXTENSION="${i#*=}"
    shift # past argument=value
    ;;
    -s=*|--searchpath=*)
    SEARCHPATH="${i#*=}"
    shift # past argument=value
    ;;
    -l=*|--lib=*)
    LIBPATH="${i#*=}"
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done
echo "FILE EXTENSION  = ${EXTENSION}"
echo "SEARCH PATH     = ${SEARCHPATH}"
echo "LIBRARY PATH    = ${LIBPATH}"
echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi
```

## getopts 的用法

getopts 是成熟的选项解析工具，因此功能相对手工解析来说自然是更加完备和强大。我们先来看看使用 getopts 解析选项的脚本的一个用法示例。

```bash
mybackup -x -f /etc/mybackup.conf ./foo.txt ./bar.txt
```

这里，mybackup 是一个 Shell 脚本，它接收了几个选项：

- -x，这是一个标签，由 - 和标签名字 x 组成；

- -f，这是一个选项，它的参数是 /etc/mybackup.conf；

- ./foo.txt 和 ./bar.txt 则是余下的参数，他们作为操作数 (operands) 传递给脚本。

使用 getopts 的话，这个调用方法等价于

```bash
mybackup -xf /etc/mybackup.conf ./foo.txt ./bar.txt
```

### getopts 的工作方式

通常来说，我们会将 getopts 放在 while 循环的条件判断式中。getopts 在顺利解析到参数的时候，会返回 TRUE；否则返回 FALSE，用以结束循环。（类似 C++ 中 while (cin >> var) 的用法）

getopts 在两种情况下会停止解析并返回 FALSE：

- getopts 读入不以 - 开始的字符串；

- getopts 读入连续的两个 - (i.e. --)。

注意：getopts 不支持两个连字符引导的选项，而是将两个连续的连字符作为「选项结束的标志」。

```bash
while getopts ...; do
    ...
done
```

### 变量和用法

- OPTIND: getopts 在解析传入 Shell 脚本的参数时（也就是 #@），并不会执行 shift 操作，而是通过变量 OPTIND 来记住**接下来要解析的参数的位置**。

- OPTARG: getopts 在解析到选项的参数时，就会将参数保存在 OPTARG 变量当中；如果 getopts 遇到不合法的选项，择把选项本身保存在 OPTARG 当中。

getopts 的用法如下

```bash
getopts OPTSTRING VARNAME [ARGS...]
```

这里

- OPTSTRING 记录合法的选项列表（以及参数情况）；

- VARNAME 则传入一个 Shell 变量的名字，用于保存 getopts 解析到的选项的名字（而不是参数值，参数值保存在 OPTARG 里）；

- ATGS... 是可选的，默认是 $@，即传入 Shell 脚本的全部参数。

### OPTSTRING

通过 OPTSTRING，我们可以告诉 getopts 哪些参数是合法的，哪些参数又是需要接受参数的。OPTSTRING 的格式很简单，就是一个简单的字符串。字符串里，每一个字母（大小写均可，但区分大小写）都是一个选项的名字。

值得一提的是冒号 (:)。在 OPTSTRING 中，冒号有两种含义：

- 首位的 : 表示「不打印错误信息」；

- 紧邻字母（选项名字）的 : 表示该选项接收一个参数。

举几个例子。

```bash
getopts fAx VARNAME
```

表示 getopts 会寻找 -f, -A 和 -x 三个选项。它们都是标签，不接受参数。

```bash
getopts :f:Ax VARNAME
```

表示 getopts 会寻找 -f, -A 和 -x 三个选项，并且不打印错误信息。其中 -A 和 -x 是标签，不接受参数；-f 是可以接受参数的选项。

### 举个栗子

```bash
#!/usr/bin/env bash

while getopts ":a" opt; do
  case $opt in
    a)
      echo "-a was triggered!" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
```

首先给一点解释。

我们首先看 getopts 的 OPTSTRING 部分：:a。按照上面的介绍，我们知道，getopts 将不会打印错误信息，并且会寻找 -a 这个选项。而后，VARNAME 是 opt。这就是说，getopts 会将找到的选项的名字（例如 a）存在 opt 这个 Shell 变量当中。在后续的处理过程中，我们可以引用它。

将上述内容保存为 getopts_test.sh，然后就可以验证了。

**啥也不做**

```bash
$ ./getopts_test.sh
$
```

getopts 解析的内容是 $@，在这个例子里是空。于是 getopts 返回 FALSE 结束循环。整个脚本什么也不做。

**传入不是选项的参数**

```bash
$ ./getopts_test.sh foo.txt
$
```

这次 $@ 有东西了。但是 foo.txt 不以连字符 - 开始，所以 getopts 仍然返回 FALSE，结束循环。整个脚本什么也不做。

**传入参数**

```bash
$ ./getopts_test.sh -a
-a was triggered!
$
```

如约打印了「标签 a 激活了」的字样。

```bash
$ ./go_test.sh -a -x -b -c
-a was triggered!
Invalid option: -x
Invalid option: -b
Invalid option: -c
$
```

注意，这里传入的 -x, -b 和 -c 都是不合法的选项，于是 getopts 将 ? 存入 $opt，而将非法的选项名字 x, b 和 c 保存在 $OPTARG 当中；进而被 case 语句抓住，并打印相关内容。

### 又一个栗子

```bash
#!/usr/bin/env bash

while getopts ":a:" opt; do
  case $opt in
    a)
      echo "-a was triggered, Parameter: $OPTARG" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
```

参照之前的例子和已有的解释，不难理解这个脚本会有怎样的行为。除去和上一个例子相同的测试之外，我们看看下面两个测试。

**合法选项、缺少参数**

```bash
$ ./another_test.sh -a
Option -a requires an argument.
$
```

在遇到 : 时，getopts 尝试解析一个参数却失败了。此时，getopts 将 : 保存在 $opt 当中，而后将参数名（这里是 a）保存在 $OPTARG 当中。

**合法选项和参数**

```bash
$ ./another_test.sh -a /etc/passwd
-a was triggered, Parameter: /etc/passwd
$
```

### 一点黑魔法：-- 的妙用

*nix 中，ls 命令是用来列出当前目录下的文件和子目录的。它可以接受一些选项（如 -lrt）。现在的问题是，如果有一个文件，它的名字叫做 -foobar，要怎样才能列出它的相关信息呢？

实际上 ls 内部使用了 getopts 解析参数。于是我们可以这样

```bash
ls -lrt -- -foobar
```

利用两个连续的连字符 --，显式地告诉 getopts：到这为止！然后，ls 会读入 -foobar 作为文件名，显示它的相关信息。

## 参考文献

- [http://stackoverflow.com/a/14203146/3419508](http://stackoverflow.com/a/14203146/3419508)

- [http://wiki.bash-hackers.org/dict/terms/end_of_options](http://wiki.bash-hackers.org/dict/terms/end_of_options)