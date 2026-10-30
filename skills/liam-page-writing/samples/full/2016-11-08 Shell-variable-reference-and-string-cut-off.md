---
title: "Shell 变量引用和字符串处理"
url: https://liam.page/2016/11/08/Shell-variable-reference-and-string-cut-off/
date: 2016-11-08
categories: ["Computer Skills"]
tags: ["Shell", "Variable", "String"]
---

使用 Linux，免不了和 Shell 打交道。和 Shell 打交道，就免不了和 Shell 的变量及字符串打交道。这里总结一下 Shell 对变量的引用和字符串处理的一些经验。

## 变量和变量的引用方式

Shell 的变量以 var=<value> 的方式定义，以 $var 或者 ${var} 的方式使用。Shell 的变量没有类型的分别，实际就是一个字符串。因此 Shell 变量的使用和字符串密不可分。这一节先介绍一下变量的一些特殊的引用方法。

- $var/${var} - 最基本的用法，返回变量 var 的值——一个字符串。

- ${var-"something"} - 当 var 没有被预先定义时，返回 "something"。

- ${var：-"something"} - 当 var 没有被预先定义，或者被定义为空时，返回 "something"。

- ${var="something"} - 当 var 没有被预先定义时，返回 "something"，同时设置 var="something"。

- ${var:="something"} - 当 var 没有被预先定义，或者被定义为空时，返回 "something"，同时设置 var="something"。

- ${var?"something"} - 当 var 没有被预先定义时，返回 "something"，而后终止脚本。

- ${var:?"something"} - 当 var 没有被预先定义，或者被定义为空时，返回 "something"，而后终止脚本。

- ${var+"something"} - 当 var 已经被定义时，返回 "something"。

- ${var:+"something"} - 当 var 已经被定义并且不为空时，返回 "something"。

```bash
$ echo ${var}

$ echo ${#var}  # return the length of ${var}
0
$ echo ${var-"hello"}
hello
$ echo ${var}

$ var=""
$ echo ${var-"hello"}

$ echo ${var:-"hello"}
hello
$ echo ${var}

$ echo ${#var}
0
$ unset var
$ echo ${var="hello"}
hello
$ echo ${var}
hello
$ unset var; var=""
$ echo ${var:="hello"}
hello
$ echo ${#var}
5
```

## 圆括号的使用

除了花括号之外，$ 符号还可以搭配圆括号使用。基本有两种用法：

- $(command) - 返回 command 执行完毕的输出结果，相当于 `command`。

- $((expression)) - 执行算术运算 expression 并返回运算结果，例如 $((2 + 3 * 2)) 返回 8。

## 按长度截取字符串

当 Shell 变量中保存着内容时，我们就可以按索引和长度截取字符串中的内容。Shell 变量的索引从 0 开始。主要有两种方式：

- ${var:pos} - 返回从 pos 开始一直到末尾的字符串。

- ${var:pos:len} - 返回从 pos 开始长度为 len 的字符串。

```bash
$ var="hello"
$ echo ${var}
hello
$ echo ${#var}
5
$ echo ${var:3}
lo
$ echo ${var:6}

$ echo ${var:0:3}
hel
$ echo ${var:0:6}
hello
```

## 按匹配截取字符串

Shell 的变量支持从左或者从右删除包含通配符的子串：

- 使用 # 或者 ## 从左删除子串；

- 使用 % 或者 %% 从右删除子串。

单符号的版本（#/%）尽可能短地匹配子串；双符号的版本（##/%%）尽可能长地匹配子串。

```bash
$ var="hellohello"
$ echo ${var}
hellohello
$ echo ${var#*ll}
ohello
$ echo ${var##*ll}
o
$ echo ${var%ll*}
hellohe
$ echo ${var%%ll*}
he
```

## 字符串替换

Shell 的变量也支持字符串替换。

- ${var/FROM/TO} - 将 $var 中的第一个 FROM 匹配的子串替换成 TO，然后返回。

- ${var//FROM/TO} - 将 $var 中所有的 FROM 匹配的子串替换成 TO，然后返回。

- ${var/#FROM/TO - 若 $var 从第一个字符开始能够匹配 FROM，则替换成 TO 然后返回；否则直接返回 ${var}。

- ${var/%FROM/TO} - 若 $var 从最后一个字符开始能够匹配 FROM，则替换成 TO 然后返回；否则直接返回 ${var}。

```bash
$ var="hellohello"
$ echo ${var}
hellohello
$ echo ${var/ll/xx}
hexxohello
$ echo ${var//ll/xx}
hexxohexxo
$ echo ${var/#*ll/xx}
xxo
$ echo ${var/#*lx/xx}
hellohello
$ echo ${var/%ll*/xx}
hexx
$ echo ${var/%lx*/xx}
hellohello
$ echo ${var}
hellohello
```