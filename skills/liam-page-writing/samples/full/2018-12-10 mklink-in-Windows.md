---
title: "Windows 中的 mklink 命令"
url: https://liam.page/2018/12/10/mklink-in-Windows/
date: 2018-12-10
categories: ["Computer Skills"]
tags: ["Symbolic Link"]
---

日常使用 Linux 的用户，想必对 ln 命令不会陌生。使用该命令，可以在 Linux 系统上创建针对文件或目录的符号链接，实现一个文件（目录）两个名字的功能。

Windows 上也有一个类似功能的命令，它是 mklink。不过它的行为和 ln 不太一样。此外，Windows 上还有「快捷方式」这种东西，也能实现一个文件（目录）两个名字的功能。但它和 mklink 建立的符号链接不一样，它是 Windows 上特有的一种文件格式，专门用来指向其它文件（目录）。

此篇讲讲 Windows 上的 mklink 命令。

## 速查表

不带参数
/D 参数
/H 参数
J 参数

中文名称
符号链接
符号链接
硬链接
联接

英文名称
Symbolic Link
Symbolic Link
Hard Link
Junction

作用对象
文件
目录
文件
目录

是否一定指向路径
否
否
否
是

dir 类型
SYMLINK
SYMLINK
无特殊显示
JUNCTION

资源管理器类型
.symlink
文件夹
无特殊显示
文件夹

资源管理器图标
快捷方式
文件夹快捷方式
无特殊显示
文件夹快捷方式

修改同步
是
是
是
是

删除同步
否
否
否
否

彻底删除源
删除源路径
删除源路径
删除所有硬链接
删除源路径

引用错误报错
无
引用了一个不可用的位置
-
引用了一个不可用的位置

## 详细说明

mklink 命令需要使用管理员权限，在 cmd.exe 中运行。在 Windows 7 中，可以在开始菜单中搜索 cmd，而后右键搜索结果，选择「以管理员身份运行」。

![](/uploads/images/windows/cmd_administrator.png)

执行 mklink 命令，不带任何 flags 及 arguments，可以查看它的语法说明（官方网页版[说明](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/mklink)）。

```plaintext
D:\test>mklink
创建符号链接。

MKLINK [[/D] | [/H] | [/J]] Link Target

        /D      创建目录符号链接。默认为文件
                符号链接。
        /H      创建硬链接，而不是符号链接。
        /J      创建目录联接。
        Link    指定新的符号链接名称。
        Target  指定新链接引用的路径
                (相对或绝对)。
```

### 不带参数

不带参数的 mklink 命令可以为文件创建符号链接。当源路径是目录时，不带参数的 mklink 不会报错，但是实际产生的符号链接不可用。在 cmd 中使用 dir 列出当前目录的文件列表时，符号链接显示为 SYMLINK，同时在文件名后以方括号表示链接的源地址。

```plaintext
D:\test>mklink source_link.txt source.txt
为 source_link.txt <<===>> source.txt 创建的符号链接

D:\test>mklink source_link source
为 source_link <<===>> source 创建的符号链接

D:\test>dir
 驱动器 D 中的卷是 Data
 卷的序列号是 22FA-F6AC

 D:\test 的目录

2018/12/10  16:18    <DIR>          .
2018/12/10  16:18    <DIR>          ..
2018/12/10  16:17    <DIR>          source
2018/12/10  16:17                 0 source.txt
2018/12/10  16:18    <SYMLINK>      source_link [source]
2018/12/10  16:18    <SYMLINK>      source_link.txt [source.txt]
               3 个文件              0 字节
               3 个目录 241,024,643,072 可用字节
```

不带参数的 mklink 创建的符号链接，展现在 Windows 资源管理器中的样式与普通的快捷方式没有两样——在图标的左下角有一个小箭头。不过，在资源管理器中，符号链接的文件类型是 .symlink。对于源路径是目录的情况，图标显示为一块白板。

![](/uploads/images/windows/mklink_void.png)

删除不带参数的 mklink 创建的符号链接，不会影响源路径指向的文件。删除不带参数的 mklink 创建的符号链接指向的源文件，访问符号链接时无法访问。

### 参数 /D

参数 /D 版本的 mklink 命令可以为目录创建符号链接。当源路径是文件时，不带参数的 mklink 不会报错，但是实际产生的符号链接不可用；访问时会提示「目录名称无效」。在 cmd 中使用 dir 列出当前目录的文件列表时，符号链接显示为 SYMLINK，同时在文件名后以方括号表示链接的源地址。

```plaintext
D:\test>mklink /D source_link source
为 source_link <<===>> source 创建的符号链接

D:\test>mklink /D source_link.txt source.txt
为 source_link.txt <<===>> source.txt 创建的符号链接

D:\test>dir
 驱动器 D 中的卷是 Data
 卷的序列号是 22FA-F6AC

 D:\test 的目录

2018/12/10  16:27    <DIR>          .
2018/12/10  16:27    <DIR>          ..
2018/12/10  16:17    <DIR>          source
2018/12/10  16:17                 0 source.txt
2018/12/10  16:27    <SYMLINKD>     source_link [source]
2018/12/10  16:27    <SYMLINKD>     source_link.txt [source.txt]
               1 个文件              0 字节
               5 个目录 241,024,618,496 可用字节
```

参数 /D 版本的 mklink 命令创建的符号链接，展现在 Windows 资源管理器中的样式与普通的快捷方式没有两样——在图标的左下角有一个小箭头。不过，在资源管理器中，符号链接的文件类型是「文件夹」。对于源路径是文件的情况，图标显示为空目录的样式。

![](/uploads/images/windows/mklink_d.png)

删除参数 /D 版本的 mklink 命令创建的符号链接，不会影响源路径指向的文件。删除参数 /D 版本的 mklink 命令创建的符号链接指向的源文件，访问符号链接时无法访问；提示「引用了一个不可用的位置」。

### 参数 /H

参数 /H 版本的 mklink 命令可以为文件创建硬链接。当源路径是目录时，不带参数的 mklink 会报错「拒绝访问」。在 cmd 中使用 dir 列出当前目录的文件列表时，硬链接的样式与正常文件没什么不同。

```plaintext
D:\test>mklink /H source_link.txt source.txt
为 source_link.txt <<===>> source.txt 创建了硬链接

D:\test>mklink /H source_link source
拒绝访问。

D:\test>dir
 驱动器 D 中的卷是 Data
 卷的序列号是 22FA-F6AC

 D:\test 的目录

2018/12/10  16:38    <DIR>          .
2018/12/10  16:38    <DIR>          ..
2018/12/10  16:35    <DIR>          source
2018/12/10  16:17                 0 source.txt
2018/12/10  16:17                 0 source_link.txt
               2 个文件              0 字节
               3 个目录 241,024,421,888 可用字节
```

参数 /H 版本的 mklink 命令创建的硬链接，展现在 Windows 资源管理器中的样式与源文件一致。

![](/uploads/images/windows/mklink_h.png)

删除参数 /H 版本的 mklink 命令创建的硬链接，不会影响源路径指向的文件。删除参数 /H 版本的 mklink 命令创建的硬链接指向的源文件，也不会影响硬链接。只有当一个文件的所有硬链接都被删除时，文件才被真正删除。

### 参数 /J

参数 /J 版本的 mklink 命令可以为目录创建联接。当源路径是文件时，不带参数的 mklink 不会报错，但是实际产生的联接不可用；访问时会提示「目录名称无效」。在 cmd 中使用 dir 列出当前目录的文件列表时，联接显示为 JUNCTION，同时在文件名后以方括号表示链接的源地址的绝对路径。

```plaintext
D:\test>mklink /J source_link.txt source.txt
为 source_link.txt <<===>> source.txt 创建的联接

D:\test>mklink /J source_link source
为 source_link <<===>> source 创建的联接

D:\test>dir
 驱动器 D 中的卷是 Data
 卷的序列号是 22FA-F6AC

 D:\test 的目录

2018/12/10  16:43    <DIR>          .
2018/12/10  16:43    <DIR>          ..
2018/12/10  16:35    <DIR>          source
2018/12/10  16:41                 2 source.txt
2018/12/10  16:43    <JUNCTION>     source_link [D:\test\source]
2018/12/10  16:43    <JUNCTION>     source_link.txt [D:\test\source.txt]
               1 个文件              2 字节
               5 个目录 241,024,319,488 可用字节
```

参数 /J 版本的 mklink 命令创建的联接，展现在 Windows 资源管理器中的样式与普通的快捷方式没有两样——在图标的左下角有一个小箭头。不过，在资源管理器中，联接的文件类型是「文件夹」。对于源路径是文件的情况，图标显示为空目录的样式。

![](/uploads/images/windows/mklink_j.png)

删除参数 /J 版本的 mklink 命令创建的联接，不会影响源路径指向的文件。删除参数 /J 版本的 mklink 命令创建的联接指向的源文件，访问联接时无法访问；提示「引用了一个不可用的位置」。