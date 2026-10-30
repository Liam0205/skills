---
title: "在 macOS 上对单个文件取消「来自互联网的应用」之限制"
url: https://liam.page/2019/10/29/How-to-fix-This-is-an-application-downloaded-from-the-Internet/
date: 2019-10-29
categories: ["Computer Skills"]
tags: ["macOS", "xattr", "quarantine"]
---

macOS 上有对未正确签名的应用程序进行[隔离](https://support.apple.com/zh-cn/HT202491)的设定。具体来说，如果用户下载了一个来自互联网的应用，但该应用没有使用 Apple 认可的签名，则 Apple 会在用户尝试执行应用程序时提示「应用程序来自互联网」，要求用户确认后才能执行。

中文网络上对这种情况的解决办法，一般都是进入系统偏好设置，在安全性设置中允许来自任意位置的应用。这其实是取消了 macOS 的隔离功能，无疑会降低系统安全性。特别地，对于某些特定的程序，我们确切知道它是无害的，于是我们希望 macOS 对它打开绿灯，但对其它来自互联网的应用程序仍保持必要的隔离措施。这时，整个儿取消 macOS 的隔离功能就不合适了。

为解决这一问题，我们需要使用命令行工具 xattr。这是一个 macOS 下用来展示和修改文件（包括目录、符号链接）扩展属性的功能。「是否隔离」正是 macOS 的一项文件扩展属性。其用法如下：

```plaintext
Syntax
   List attributes
      xattr [-lrsvx] file ...

   Print the value associated with the given attribute:
      xattr -p [-lrsvx] attr_name file ...

   Write a given attribute name with a value:
      xattr -w [-rsx] attr_name attr_value file ...

   Delete the given attribute from file:
      xattr -d [-rsv] attr_name file ...

   Clear all attributes including their associated values:
      xattr -c [-rsv] file ...

   Display help:
      xattr -h | --help

Key
   -c  CLear all Atrributes.

   -d  Delete the given attribute.

   -h  Help.

   -l  By default, the first two command forms either display just the attribute names or
       values, respectively. The -l option causes both the attribute names and corresponding
       values to be displayed. For hex display of values, the output is preceeded with the hex
       offset values and followed by ASCII display, enclosed by '|'.

   -p  Print the value associated with the given attribute.

   -r  If a file argument is a directory, act as if the entire contents of the directory
       recursively were also specified (so that every file in the directory tree is acted upon).

   -s  If a file argument is a symbolic link, act on the symbolic link itself, rather than
       the file that the symbolic link points at.

   -v  Force the the file name to be displayed, even for a single file.

   -w  Write a given attribute name with a value.

   -x  Force the attribute value to be displayed in the hexadecimal representation.
```

这里，我们需要在终端里，执行 xattr -d com.apple.quarantine /path/to/quarantined/file 来移除加在 /path/to/quarantined/file 上的隔离属性。而后在执行相应应用程序，就不会被 macOS 的隔离机制限制了。