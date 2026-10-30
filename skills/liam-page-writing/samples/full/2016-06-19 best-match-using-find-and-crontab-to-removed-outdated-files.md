---
title: "最佳搭档：利用 find 和 crontab 命令清理过期文件"
url: https://liam.page/2016/06/19/best-match-using-find-and-crontab-to-removed-outdated-files/
date: 2016-06-19
categories: ["Computer Skills"]
tags: ["Find", "Crontab"]
---

不论是生活中还是工作中，总有一些文件会不断产生。这些文件可能是日志文件，也可以是系统核心转储文件。如若不加清理，查询特定文件就会非常困难，抑或是过多的核心转储文件占满了磁盘空间，影响正常程序执行。

为此，我们需要有一个简单高效的方式，定期清理过期文件。

## crontab: 在时间的八音盒上翩翩起舞

crontab 命令是 Linux 中用来设定重复执行命令或脚本的工具。它能够在指定的时间段内，按照需求以某一时间间隔执行命令或脚本。

### crontab 的基本用法

```bash
crontab [-u <user>] [-e|-l|-r]
crontab <filename>
```

crontab <filename> 可以读入一个以 crontab 语法书写的文件，并依照文件内的指示执行定时任务。与此同时，crontab -l 能够在标准输出上列出当前用户所有的定时任务情况。因此，我们可以用 crontab -l > <filename> 来保存当前 crontab 的状况，在有需要的时候（比如误删除）用 crontab <filename> 读入恢复。

crontab -e 则会启动系统默认的编辑器。这个编辑器由系统环境变量 EDITOR 指定；例如 export EDITOR=vi，则 crontab -e 会启动 vi 来编辑当前用户的 crontab 定时任务文件。crontab -r 则会删除用户的所有 crontab 定时任务。

用来指定用户的 -u <user> 选项则会改变 -e/-l/-r 等选项的行为。如果不通过 -u 指定用户，则默认的操作都是针对当前用户的；反之，则针对指定的用户。例如 crontab -u Liam -r 则会删除用户 Liam 的 crontab 定时任务——当然，你需要有足够的权限这么做。

### crontab 文件的格式

不管是用 crontab <filename> 从文件读入定时任务，还是用 crontab -e 编辑定时任务，我们都会接触到 crontab 格式的命令。crontab 的命令格式如下：

![](/uploads/images/Linux/crontab_cheatsheet.png)

从上图我们可以看出：

- 一条 crontab 命令分成六列，写在一行内；

- 前 5 列用于定时，指明什么时候开始执行；

- 第 6 列用于指定需要定时执行的命令或脚本；

此外，和 Shell 脚本一样，在 crontab 文件中，我们也可以用 # 来表示注释。

### 花式定时

在 crontab 命令中用于定时的前 5 列中，支持以下符号，用于「花式定时」：

- 星花（*）：代表所有可能的值；

- 逗号（,）：用逗号隔开同一字段的不同范围；

- 连字符（-）：用连字符连接两个整数，表示整数范围；

- 斜线（/)：实际上是除法斜线，用来指定时间间隔频率。

### 一些例子

有了这些知识，我们就可以看一些实例了。

```bash
# 每分钟执行一次
* * * * * command
# 每 5 分钟执行一次
*/5 * * * * command
# 每个小时的 15 分和 45 分执行一次
15,45 * * * * command
# 晚上 20:00 -- 20:15 每分钟执行一次
0-15 20 * * * command
# 每周一上午 10 点执行一次
0 10 * * 1 command
```

## find —— 找些乐子

man find 给出的 find 命令的一般形式是：

```bash
find [-H] [-L] [-P] [-D debugopts] [-Olevel] path ... [expression]
```

其中 [-H] [-L] [-P] [-D debugopts] [-Olevel] 很少会用到。因此，find 命令的一般形式可以简化为 find path ... [expression]；亦即，在一些路径（默认递归地包含子路径）中找到合适的文件，然后根据 expression 执行相应动作。

- path ...: find 命令查找的路径

- expression: 具体形式是 -parameters [-exec -ok]
-parameters 有很多，待下一节具体介绍常用的参数
-exec command {} \; 执行一条 Shell 命令
-ok command {} \; 同 -exec 的作用，不过在执行每条命令前，都会提示用户确认

### 常用的参数

- -name: 按照文件名查找文件，接受通配符
find . -name "*.cpp": 在当前目录 (.) 及子目录下递归地查找所有后缀为 .cpp 的文件，并打印在标准输出中

- -perm: 按照文件权限查找文件
find . -perm 755: 在当前目录 (.) 及子目录下递归地查找所有权限为 755 的文件（目录），并打印在标准输出中
find . -perm 644 -name "*.cpp": 在当前目录及子目录下 (.) 递归地查找所有权限为 644 的 .cpp 文件，并打印在标准输出中

- -group: 按照文件的所属组查找

- -user: 按照文件的所有者查找
find . -user search: 在当前目录 (.) 及子目录下递归地查找所有 search 账号所属的文件，并打印在标准输出中

- -atime, -mtime, -amin, -mmin: a 开头的表示「按照上次访问时间查找」，m 开头的表示「按照上次修改时间查找」；-n 表示 n 时间内，+n 表示 n 时间以前
find . -atime +7: 在当前目录 (.) 及子目录下递归地查找所有上次访问在 7 天以前的文件，并打印在标准输出中
find . -mmin -10: 在当前目录 (.) 及子目录下递归地查找所有上次修改在 10 分钟以内的文件，并打印在标准输出中

- -newer file1 ! file2: 查找比 file1 新但是比 file2 旧的文件

- -type [b|d|c|p|l|f]: 按照文件类型查找
b: 块设备文件
d: 目录
c: 字符设备文件
p: 管道文件
l: 符号链接文件
f: 普通文件

- -follow: 如果 find 命令遇到符号链接文件，就跟踪至链接所指向的文件

- -delete: 删除查找到的文件或目录

## 定期清理

至此，定期清理无用的文件就变得很简单了。我们只需要在 crontab 里结合 find 命令的 -delete 选项即可。

```bash
0 8 * * * find /home/s/coredump -user search -type f -mtime +7 -delete
```

这里，我们在每天早上 8 点整执行 find 命令；该命令会在 /home/s/coredump 目录下寻找 search 用户创建的普通 7 天前的文件，然后删除掉。