---
title: "在 Linux 上挂载/卸载磁盘"
url: https://liam.page/2019/08/23/mount-and-unmount-disk-in-Linux/
date: 2019-08-23
categories: ["Computer Skills"]
tags: ["Linux", "Disk"]
---

昨天正在训练线上模型的机器被人误操作，不得不重做系统。万幸模型相关的训练状态保存在另一块磁盘上，没有受到影响。要想恢复训练状态相关数据，就必须把磁盘挂载好。因为这个操作不常用，一时居然都没想起来怎么做。因此这里「烂笔头」记录下来。

## 查看机器上的磁盘

fdisk 是 Linux 上用来操作磁盘分区表的工具。使用 fdisk -l 命令，可以列出系统识别的所有磁盘及其分区。

```shell
Disk /dev/sda: 599.1 GB, 599051206656 bytes, 1170021888 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 262144 bytes / 262144 bytes
Disk label type: # masked
Disk identifier: # masked

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1            2048   204802047   102400000   83  Linux
/dev/sda2       204802048   213190655     4194304   82  Linux swap / Solaris
/dev/sda3   *   213190656  1170020351   478414848   83  Linux

Disk /dev/sdb: 6118.5 GB, 6118546079744 bytes, 11950285312 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 262144 bytes / 262144 bytes
```

/dev 目录下的 sd? 即是物理磁盘。例如 sda 是系统读到的第一块磁盘，sdb 则是第二块磁盘。在较老的 kernel 中，由于没有 ATA 支持，因此物理磁盘可能是 /dev/hd?（IDE）或者是 /dev/sd?（SCSI）。

/dev/sda? 则是 sda 这块物理磁盘上的分区。/dev/sda1 是该磁盘上的第一块分区。

这里 /dev/sdb 这块磁盘尚未被正确挂载，而正是它保存了所需的数据。

## 创建挂载点

在挂载磁盘之前，首先要为它创建一个挂载点。挂载点说白了是一个目录，在执行 mount 命令挂载前，它必须是已经存在的目录。挂载成功后，访问该目录即可访问相应磁盘的内容。若挂载前挂载点中存在内容，则挂载后这些内容暂不可见，当卸载后这些内容又会变得可见。

比如我想将磁盘挂载于 /mnt/data 就要创建这样一个空目录。

```shell
mkdir -p /mnt/data
```

## 确定磁盘文件系统类型

在挂载磁盘之前，还需要确定磁盘（分区）的文件系统类型。若不然，挂载时选错文件系统类型可能造成一系列奇怪的现象。为此，我们需要执行 parted -l 命令。

```shell
# parted -l
Model: # masked
Disk /dev/sda: 599GB
Sector size (logical/physical): 512B/4096B
Partition Table: msdos
Disk Flags:

Number  Start   End    Size    Type     File system     Flags
 1      1049kB  105GB  105GB   primary  xfs
 2      105GB   109GB  4295MB  primary  linux-swap(v1)
 3      109GB   599GB  490GB   primary  xfs             boot

Model: # masked
Disk /dev/sdb: 6119GB
Sector size (logical/physical): 512B/4096B
Partition Table: loop
Disk Flags:

Number  Start  End     Size    File system  Flags
 1      0.00B  6119GB  6119GB  ext4
```

由此可见，目标磁盘 /dev/sdb 的文件系统类型是 ext4。

## 挂载磁盘

此时，我们就能挂载磁盘了。

```shell
mount -t ext4 /dev/sdb /mnt/data
```

这里 -t ext4 表示目标磁盘（分区）的文件系统类型是 ext4，/dev/sdb 是待挂载的磁盘（分区），/mnt/data 是目标挂载点。

## 卸载磁盘

与 mount 相对的命令是 umount。注意是 umount 而不是 unmount——没有那个 n。

卸载时，给 umount 的参数可以是挂载点，也可以是磁盘（分区）的名字。在这里，以下两种操作等价：

```shell
umount /dev/sdb
umount /mnt/data
```

若是希望挂载的磁盘正在被其他进程读写，则 Linux 会提示 device is busy。此时，可以执行 umount -l 命令，让 Linux 在无其他进程读写目标磁盘时，再行卸载。或者，也可以用 ps 命令查看使用该磁盘的进程有哪些，然后妥当处理后再卸载。