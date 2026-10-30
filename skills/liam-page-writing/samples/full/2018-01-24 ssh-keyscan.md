---
title: "利用 ssh-keyscan 获取集群机器 SSH 公钥指纹"
url: https://liam.page/2018/01/24/ssh-keyscan/
date: 2018-01-24
categories: ["Computer Skills"]
tags: ["SSH", "FingerPrint"]
---

[前作](/2017/09/12/rescue-your-life-with-SSH-config-file/)提到为了防止中间人攻击，SSH 会要求 client 用户确认 server 的密钥指纹。这个设计很有用，但是如果在可靠环境里有大量机器组成的集群，而我们需要自动化地进行 SSH 访问和相关部署，交叉地去确认密钥指纹是很大的工作量。

前作提到了 ssh-keygen 命令，用以在机器上生成密钥。此处我们需要用到 ssh-keyscan 命令，批量获取集群上机器的密钥指纹。

## ssh-keyscan

ssh-keyscan 的语法是

```bash
ssh-keyscan [-46Hv] [-f file] [-p port] [-T timeout] [-t type] [host | addrlist namelist] ...
```

-46 是限定以 IPv4 或者 IPv6 连接机器；-H 则会对机器名进行散列，隐藏真实机器名，但仍能用于 SSH 相关连接；-v 则打印大量调试信息。

host | addrlist namelist 是需要扫描的机器列表；而 -f 指定一个文件，包含若干需要扫描的机器列表。-f - 表示从标准输入读取机器列表。

-p 指定连接远端 server 时的端口号；-T 指定超时时间；-t 则选择需要获取哪些类型的公钥指纹。

## 获取公钥指纹

首先应准备好需要获取公钥指纹的 IP 或 HOSTNAME 列表，保存在文件中。例如演示用的文件是这样的。

```bash
127.0.0.1
127.0.0.2
```

而后执行命令

```bash
$ ssh-keyscan -f hostlist.txt
# 127.0.0.1 SSH-2.0-OpenSSH_6.6.1
127.0.0.1 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCWBZ3XrIajPmnd6R+g/wcUuOPOiRBMOYjAl4Dv8SfcZtgHqKTK6Zb1EeG3u/uzRYxqXMctG/2A4iXRDG9mvg9H9bimCWbA3xtR79NImPYg4m7BNuH9C+OXRYYJwoOGpjVMs0rGLXkq3/WVkXvQreBuhVD8NI2pEPnQsT1J5abdVbCHlwFYG6wVCJQqFY6jdntJJlxQv5EJu6w4/+Fd4LvdjysH+ngqArac6HMJUxqSxLQjzMdCRWEQKp3ySwmnRp9rHYVaJnnsXeYPfnMN1iMjdIQJPzc89Mepg4ip1q2bCMbMcx2XFO3I7YjYRdcOameFNafMGY0q5RHzhvgnNnal
# 127.0.0.1 SSH-2.0-OpenSSH_6.6.1
127.0.0.1 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCPWoEQ7iCCYDrpyb5KeMmCaQ8aOnSfehqmrplZRkbqqnkS9++PdSX/eSLJ0tkFd5902/C+HTCqbDgso4mCKpMo=
# 127.0.0.2 SSH-2.0-OpenSSH_6.6.1
127.0.0.2 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCWBZ3XrIajPmnd6R+g/wcUuOPOiRBMOYjAl4Dv8SfcZtgHqKTK6Zb1EeG3u/uzRYxqXMctG/2A4iXRDG9mvg9H9bimCWbA3xtR79NImPYg4m7BNuH9C+OXRYYJwoOGpjVMs0rGLXkq3/WVkXvQreBuhVD8NI2pEPnQsT1J5abdVbCHlwFYG6wVCJQqFY6jdntJJlxQv5EJu6w4/+Fd4LvdjysH+ngqArac6HMJUxqSxLQjzMdCRWEQKp3ySwmnRp9rHYVaJnnsXeYPfnMN1iMjdIQJPzc89Mepg4ip1q2bCMbMcx2XFO3I7YjYRdcOameFNafMGY0q5RHzhvgnNnal
# 127.0.0.2 SSH-2.0-OpenSSH_6.6.1
127.0.0.2 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCPWoEQ7iCCYDrpyb5KeMmCaQ8aOnSfehqmrplZRkbqqnkS9++PdSX/eSLJ0tkFd5902/C+HTCqbDgso4mCKpMo=
```

如此，将标准错误的输出重定向到 /dev/null 即可获得机器列表的公钥指纹了。

```bash
$ ssh-keyscan -f hostlist.txt 1>>~/.ssh/known_hosts 2>/dev/null
```

而后将 ~/.ssh/known_hosts 用 scp 拷贝到 hostlist.txt 中的所有机器上即可。