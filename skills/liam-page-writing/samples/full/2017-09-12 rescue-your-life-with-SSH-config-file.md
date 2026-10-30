---
title: "最佳搭档：利用 SSH 及其配置文件节省你的生命"
url: https://liam.page/2017/09/12/rescue-your-life-with-SSH-config-file/
date: 2017-09-12
categories: ["Computer Skills"]
tags: ["Linux", "SSH", "Config"]
---

SSH 协议是事实上的互联网基石之一。在 SSH 协议出现之前（1995 年由 Tatu Ylonen 设计），通过互联网远程登录其他设备（telnet）的过程是明文的。这意味着，整个通信过程，很容易被旁路嗅探，泄露敏感信息。

OpenSSH 是 SSH 协议的经典实现。目前，它作为各 Linux 发行版默认自带的 SSH 工具分发；因而广为使用。

若你在学习工作生活中，需要通过 SSH 协议，登录、管理多台服务器。那么，一方面你可能会厌烦记忆各个远程服务器的主机名/IP 地址；另一方面你可能会被繁琐的口令输入过程弄得烦躁不安。特别地，若是你需要在同一台远程主机上，打开多个终端窗口进行操作时；你可能需要反复输入多次用户名和口令（在不用 screen/tmux 之类的工具的前提下）。

这篇文章首先会尝试介绍 Linux 自带的 SSH 工具的基本用法，并附带介绍 SSH 配置文件的编写规则。而后，尝试解决上述繁琐的记忆和口令输入命令。

## SSH

我们说，在创造一件事情之前，你需要想清楚这件事情的意义是什么。通常而言，创造新事物的原动力，是我们发现了旧事物和我们目标之间存在的差距（gap）；而新事物就是为了填上这一差距的。因此，讲道理，我们首先应该去分析在 SSH 协议诞生之前人们使用的远程登录协议有哪些问题；而后去分析 SSH 分别是如何解决这些问题，填上所谓的 gaps 的。

然而，「空谈误国，实干兴邦」。一方面在没有任何实践之前，大谈理论是空洞的；另一方面，我们最终也是要将理论落实到时间上去。因此这一节，我们首先介绍/回顾 SSH 的最基本用法；而后讨论 SSH 是如何解决过去远程登录协议遗留下来的问题的；借此，我们将讨论 SSH 连接建立时会发生什么；介绍完这些内容之后，我们将介绍如何免密登录。

### SSH 的基本用法

Linux 下，ssh 命令的基本用法是

```bash
ssh [params] [flags] [user@]remotehost [command]
```

先除去参数（params）和标识（flags）不论，以及不讨论后续的执行命令（command）；ssh 命令的基本用法是 ssh [user@]remotehost。若一切顺利，如此就能成功以用户 user 登录远程服务器 remotehost。其中，若你本地登录账户的用户名与远程服务器上的用户名一致，则可以省略 [user@]。

另外值得一提的是，这里说的 remotehost 指的是「逻辑上」的远程主机。实际上，若是你尝试执行下列命令，就能（利用本地回环）登录你本机的 foo 账户了。此时，本机的主机名/IP 地址，就充当了 ssh 命令中逻辑上的远程主机。

```bash
ssh foo@localhost # 127.0.0.0/24, ::1
```

127.0.0.0/24 都是本地回环的 IPv4 地址。只不过，因为 127.0.0.1 是其中第一个合法的主机地址；所以被用来指代本地回环。但千万不要以为只有 127.0.0.1 这一个地址能够本地回环。: )

### SSH 怎样防止信息泄露？

前文提到，SSH 提出的背景即是在它出现之前，远程登录协议无法保障通信安全。那么，在 SSH 出现之前，远程登录可能面临哪些信息泄露风险呢？

首先是前文提到的旁路嗅探。事实上，这是网络通信不可避免的问题；因为从我们本地主机到远程主机的通信链路，是广域网上通过 IP 协议路由实现的。在这一通信链路上，有太多我们无法控制的通信节点。因此，若是这其中但凡有一个节点被黑客控制，我们经由这条链路的通信信息，就可能被嗅探甚至篡改。

解决这一问题的根本办法是使用加密的信道。这一办法的思路在于，既然我们无法控制流量被嗅探/篡改，那么我们至少可以让敌手得到的信息是难以破译的密文（至少是破译成本远高于明文本身蕴含的价值）。SSH 协议正是这样做的：它通过非对称加密方法（公钥加密方法），在预先交换公钥的前提下，通信双方通过对方的公钥加密信息，而使用自身私钥解开密文。如此一来，若是能保证密钥交换的可信，则基于非对称加密方案的加密信道就是安全的。

除了旁路嗅探，信息泄露的另一大风险来自所谓的中间人攻击。中间人攻击的源头依然来自广域网路由的不可控性。设想，在我们的主机和目标远程主机的通信链路中间，有一个节点充当双面间谍：一方面，它在链路中间截获我们发出的信号，并伪装成目标主机予以返回；另一方面，它在链路中间伪装成我们的主机，转发我们的流量，给真实的远程主机。在这个过程中，如果没有恰当的身份验证手段，那么无论是我们的主机还是远程主机，都无法验证对方的身份。因此，事实上，一方面发起中间人攻击的敌手可以获取所有通信流量，另一方面它可以随意篡改通信流量而难以发现。考虑到上述加密信道的可信性，一方面基于非对称加密的安全性（在这里我们假设为 ground truth，不作怀疑），另一方面基于密钥交换的可信性；那么，由于中间人攻击可能在密钥交换阶段从中作梗，则若 SSH 协议不能妥善解决这一问题，则其安全性就仍然存疑。

这样一来，问题实际上转换成了密钥交换过程的身份验证问题。考虑到我们反复提及的广域网上的通信链路是不可信的；仅凭借当前通信进行身份验证，就变成了「鸡生蛋、蛋生鸡」的循环问题。因此，这类验证不得不采用所谓的「盘外招」。

SSH 的思路的关键点在于：既然正常信道建立后，远程主机需要将自己的公钥发送给本地主机，那么这一公钥本身就能看作是远程主机的一个身份：若是无法验证远程主机的身份，那么本地主机使用这一公钥进行信息加密是不安全的（因为公钥可能来自敌手，而加密信息可能被敌手使用正确私钥解密而窃取）；若是验证了远程主机的身份，则这一公钥就能放心地用来加密信息。因此，在 SSH 建立链接的过程中，它会要求本地主机的操作者确认远程主机返回的公钥的 hash 值。若这一 hash 值和操作者通过其他方式（盘外招）得到的值一致，则认可远程主机的身份。当然，这一验证不需要每次 SSH 连接时都进行——只需要验证一次，而后交由本地计算机验证 hash 与前次连接获得的 hash 的一致性即可。而这又要求本地计算机将远程主机的公钥 hash 值保存下来，以便下次核对。

### SSH 远程登录的流程

当本机发起登录请求时，SSH 会依次执行以下几个主要步骤：

- 通过远程主机公钥 hash，确认远程主机身份；

- 若通过，远程主机验证登录身份，例如：提示输入远程主机目标用户的口令；

- 本地主机将用户键入的口令，使用远程主机的公钥加密，并发送给远程主机；

- 远程主机使用上述公钥对应的私钥，对得到的密文进行解密；

- 远程主机验证解密后的口令；

- 若通过，则建立 SSH 连接，成功登录。

前面已经说过，localhost 也可以充当逻辑上的远程主机。这里我们就以 localhost 为例，验证一下这一过程。

```bash
$ ssh liamhuang@localhost
The authenticity of host 'localhost (127.0.0.1)' can't be established.
ECDSA key fingerprint is 4d:28:ed:f1:3d:40:fe:68:c8:b3:b0:9b:a7:dc:5d:7e.
Are you sure you want to continue connecting (yes/no)?
```

执行 ssh liamhuang@localhost 尝试以 liamhuang 的用户身份登录（逻辑上的）远程主机 localhost 时，SSH 如我们预期一样，提示我们验证远程主机的身份。这段文字翻译如下。

无法验证主机 'localhost (127.0.0.1)' 的真实性。ECDSA 密钥指纹为 4d:28:ed:f1:3d:40:fe:68:c8:b3:b0:9b:a7:dc:5d:7e。你是否要继续连接？(yes/no)

标准的操作，我们必须通过额外的方式，与远程主机取得联系，验证这一指纹是否真实。不过，此处我们略去这一步骤，键入 yes。

```bash
$ ssh liamhuang@localhost
The authenticity of host 'localhost (127.0.0.1)' can't be established.
ECDSA key fingerprint is 4d:28:ed:f1:3d:40:fe:68:c8:b3:b0:9b:a7:dc:5d:7e.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'localhost' (ECDSA) to the list of known hosts.
liamhuang@localhost's password:
Last login: Tue Sep 12 17:49:33 2017 from 127.0.0.1
```

如前所述，为了下次自动地验证远程主机的身份，本地主机会将远程主机的公钥指纹保存下来。新出现的提示，翻译如下。

警告：已将 'localhost' (ECDSA) 永久地加入已知主机列表之中。

在输入远程主机目标用户的口令之后（无终端回显），本地主机会将输入的口令以远程主机提供的密钥加密并发送给远程主机。待远程主机解密并验证通过后，即提示成功登录。

上一次成功登录：2017 年 9 月 12 日（周四）17:49:33，自 127.0.0.1。

那么，具体来说，本地主机将这一信息保存在哪里了呢？答案是当前用户的 ${HOME}/.ssh/known_hosts 文件当中。我们可以执行 exit 命令，退出远程主机；而后使用 tail 命令可以查看刚刚插入在该文件末尾的远程主机信息。

```bash
$ tail -1 ${HOME}/.ssh/known_hosts
localhost ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCPWoEQ7iCCYDrpyb5KeMmCaQ8aOnSfehqmrplZRkbqqnkS9++PdSX/eSLJ0tkFd5902/C+HTCqbDgso4mCKpMo=
```

### 使用公钥验证身份

现在我们考虑下一个问题：除去输入远程主机用户口令的方式，是否还有其他方式能够验证登录者的身份？

对于身份认证来说，通常有三种手段：

- 你知道的（例如账户口令）；

- 你独有的（例如网银的 U 盾）；

- 你身上的（例如指纹）。

通常来说，对于没有极端的安全性要求的场景，通过其一验证即可。在上述登录过程中，我们采取了「你知道的」这一手段来验证登陆者的身份。考虑到，对于远程登录来说，很难通过生物信息识别来验证身份；剩下可行的方案就是验证「你独有的」特殊物件来验证身份了。

对于「你独有的」这一手段来说，使用类似网银的 U 盾显然不现实。一则制作成本太高，二则相关的认证过于复杂。因此，我们须得考虑其他更易行的手段。

在 SSH 协议中，信道的安全是通过非对称加密保证的。事实上，非对称加密需要持有私钥。因此，私钥这件事情本身，也可以认为是一种「你独有的」东西。考虑到，在 SSH 登录成功之前，在不完整的信道中，从本地主机向远程主机通信是安全的（因为有远程主机的公钥可用于加密），而远程主机可以用持有的私钥解密本地主机发来的信息。（例如口令登录验证的过程）。类似的过程也可以反过来用：

- 本地主机生成一对非对称密钥；

- 本地主机将公钥交付远程主机；

- 远程主机在收到登录请求时，使用上述公钥加密一串无害的随机信息；

- 本地主机将接收到的密文，以本地持有的私钥解密，而后通过远程主机的公钥再进行加密；

- 远程主机使用相应私钥解密，并与上述随机信息进行比对；

- 若一致，则认可登录者的身份，许可登录。

在这个过程中，远程主机对比一来一回前后随机信息的一致性，验证了本地主机确实持有一个安全介质——本地主机生成的私钥。因此，这就不需要输入远程主机的用户口令了。

为此，我们首先需要生成一对密钥。

```bash
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/test/.ssh/id_rsa): /home/test/.ssh/id_rsa.test
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/test/.ssh/id_rsa.test.
Your public key has been saved in /home/test/.ssh/id_rsa.test.pub.
The key fingerprint is:
91:cb:1d:45:65:27:76:cc:66:02:4d:e5:1f:c4:64:6d liam@localhost
The key's randomart image is:
+--[ RSA 2048]----+
|         .o.*o*=.|
|        .o o.=== |
|        +  E .o.=|
|       . =     +o|
|        S  o    .|
|                 |
|                 |
|                 |
|                 |
+-----------------+
```

ssh-keygen 是 OpenSSH 的一部分，它用于生成供 SSH 使用的密钥。默认情况下，ssh-keygen 生成的是 RSA 密钥（本机上是 2048 位 RSA），并将私钥保存在 ${HOME}/.ssh/id_rsa 当中。为了避免与已有的密钥冲突，这里我们另存为 id_rsa.test。随后，ssh-keygen 要求我们为生成的私钥设置口令（passphrase）。这一口令是对私钥进行保护的口令，可以留空。这样一来，我们就生成了一对 RSA 密钥。其中，私钥保存在 /home/test/.ssh/id_rsa.test 而公钥保存在 /home/test/.ssh/id_rsa.test.pub。

接下来，我们需要将生成的密钥交付给远程主机。为此，我们需要使用 ssh-copy-id 这一命令。

```bash
$ ssh-copy-id -i ~/.ssh/id_rsa.test liamhuang@localhost
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
liamhuang@localhost's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'liamhuang@localhost'"
and check to make sure that only the key(s) you wanted were added.
```

ssh-copy-id 会将 ~/.ssh/id_rsa.test 对应的公钥，交付给 liamhuang@localhost。在这个过程中，我们需要输入用户 liamhuang 在远程主机 localhost 上的口令。注意，此处我们使用了 -i 参数，指定了需要交付的密钥。若是省略 -i 参数，则 ssh-copy-id 会将默认的密钥 ~/.ssh/id_rsa 对应的公钥交付给远程主机。

之后，我们就可以「免密登录」了。同样，我们需要使用 -i 参数指定所需使用的私钥。

```bash
$ ssh -i ~/.ssh/id_rsa.test liamhuang@localhost
Last login: Tue Sep 12 17:53:11 2017 from 127.0.0.1
```

类似上面提到过的 ~/.ssh/known_hosts，保存这类公钥也有一个特定的文件：远程主机目标用户的 ${HOME}/.ssh/authorized_keys。登录远程主机后，我们可以使用 tail 命令来查看刚刚添加的公钥。

```bash
$ tail -1 ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiDajuJwE1cyrRxDiDNB+2T2WiWB29l7C61zfnSTFA31SrsWU2DGuC9qoFqRtsbXUXS57E0kmPSJzmkwj+EihHJmZUt6AXYx8UdwXtzSPyhkLH6K/iH2W4fxe9vMvzSdbhM58LUi9+4d1I3Zte9zdG1/boHPIH/+6reU/2V1l2rr44+/LzZoeoyVWICIq2gf7ZMxdJzLLUtuFUBMLIxre3sob6EYSeIJFPvMXfpk9D/Qxio+x8U+PdFOl5avA0m0BaaatXyBe0jhTs43YJOgONnbBQAuJOEJ8RKHgnEVUh1Wu7eIKheaHAeOqBiNW3UMEUDGY9dyInhvFR0tlY8jg5 test@localhost
$ tail -1 ~/.ssh/authorized_keys | md5sum
293b27ababace5a6004427af4b0739b9  -
```

返回到本地主机，可见它正是我们刚刚生成的公钥。

```bash
$ cat ~/.ssh/id_rsa.test.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiDajuJwE1cyrRxDiDNB+2T2WiWB29l7C61zfnSTFA31SrsWU2DGuC9qoFqRtsbXUXS57E0kmPSJzmkwj+EihHJmZUt6AXYx8UdwXtzSPyhkLH6K/iH2W4fxe9vMvzSdbhM58LUi9+4d1I3Zte9zdG1/boHPIH/+6reU/2V1l2rr44+/LzZoeoyVWICIq2gf7ZMxdJzLLUtuFUBMLIxre3sob6EYSeIJFPvMXfpk9D/Qxio+x8U+PdFOl5avA0m0BaaatXyBe0jhTs43YJOgONnbBQAuJOEJ8RKHgnEVUh1Wu7eIKheaHAeOqBiNW3UMEUDGY9dyInhvFR0tlY8jg5 test@localhost
$ cat ~/.ssh/id_rsa.test.pub | md5sum
293b27ababace5a6004427af4b0739b9  -
```

须得注意的是，出于安全性考虑，若要保证这一特性打开，远程主机上的相关文件必须限制除当前用户之外的权限。个人建议 .ssh 目录权限必须不高于 700；且 authorized_keys 文件权限必须不高于 600。

若是你的机器不支持 ssh-copy-id，也可以直接将公钥信息写入远程主机目标用户的 ${HOME}/.ssh/authorized_keys 当中。

```bash
$ ssh liamhuang@localhost 'mkdir -p .ssh && chmod 700 .ssh && cat >> .ssh/authorized_keys && chmod 600 .ssh/authorized_keys' < ~/.ssh/id_rsa.test.pub
```

## SSH 的配置文件

我们在文章开头处提出了利用 SSH 登录管理大量机器的两个不便：

- 需要记忆大量机器的主机名；

- 需要记忆、输入大量机器上的用户口令。

在上一节中，我们通过在本地主机生成公钥并交付远程主机，利用「你独有的」这条渠道完成了身份认证；从而避免了在登录时输入远程主机用户的口令。虽然，在示例中，我们不得不使用 -i 参数来指定希望使用的私钥文件路径。但这一方面是为了避免与本地主机当前用户默认密钥冲突，另一方面是为了演示这一参数的作用，再者也表明了本地主机用户可以使用功能多个密钥分别用于连接不同主机。

然而，尽管避免了输入口令，但是「需要记忆大量主机名」的问题没有解决；同时还引出了新的问题：需要使用 -i 参数指定私钥路径。怎样解决这些问题呢？

SSH 的配置文件与用户实际执行 ssh 命令时传入的参数协同作用。按照优先级，低优先级的配置项可视作默认值；而高优先级的配置项则会覆盖默认值。按优先级，有如下排序：

- 用户实际执行 ssh 时传入的参数；

- 用户的 SSH 配置文件 ${HOME}/.ssh/config；

- 系统的 SSH 配置文件 /etc/ssh/ssh_config。

这样一来，通过 SSH 配置文件，我们可以按访问的主机来配置 SSH 的默认行为。

### SSH 配置文件的说明

SSH 的配置文件有很多配置项可供配置。限于篇幅，此处显然是不可能穷尽的。因此，有兴趣的读者可以通过 man ssh_config 查看可用的配置项。

SSH 的配置文件采用空格分割的键值形式。例如 Host localhost 表示键 Host 对应的值为 localhost。此篇涉及到的键如下：

- Host：值为通配符的模式（Pattern）；该键之后的键值对，将用于匹配于该模式的主机。

- HostName：值为真实的目标远程主机名；在值中，%h 可用于命令行接收到的主机名字的转义。

- User：值为希望登录的远程主机的用户名；

- IdentityFile：值为希望登录时使用的密钥文件。

### 一个简单的例子

这样一来，我们可以在配置文件中写入如下内容。

```plaintext
Host localliam
    HostName localhost
    User liamhuang
    IdentityFile /home/test/.ssh/id_rsa.test
```

这样一来，执行 ssh localliam 就相当于执行了 ssh -i /home/test/.ssh/id_rsa.test liamhuang@localhost 了。

```bash
$ ssh localliam
Last login: Tue Sep 12 19:03:16 2017 from 127.0.0.1
```

### 批量管理

现在我们构建这样一个场景。我们有 1000 台服务器；它们的主机名编号从 w-i0.test.sh.localnet 一直到 w-i999.test.sh.localnet。那么，为了免密以 cloud 用户的身份登录这 1000 台机器，我们可以首先将准备好的公钥上传到这 1000 台机器上；而后在 SSH 配置文件里配置如下内容。

```plaintext
Host i? i?? i???
    Host w-%h.test.sh.localnet
    User cloud
    IdentityFile ~/.ssh/id_rsa.test
```

这样一来，我们就只需要使用 ssh i73 就能以 cloud 用户的身份，登录 w-i73.test.sh.localnet 了。

### 更多场景

在实际使用中，任何基于 SSH 之上的程序，都可以借助 SSH 配置文件达到简化的目的。例如，代码托管网站 [bitbucket](https://bitbucket.org/) 支持通过 Git 来管理代码。而 Git 又是支持 SSH 方式与远程仓库进行通信。这样一来，我们就可以通过 SSH 配置文件，简化对 bitbucket 的访问；另一方面，通过 SSH 配置文件，我们可以将访问 bitbucket 时使用的密钥与其它密钥区分开。

首先，我们使用 ssh-keygen 生成一对专用于 bitbucket 的密钥；保存在 ~/.ssh/id_rsa.bitbucket 当中。而后，我们需要将 ~/.ssh/id_rsa.bitbucket.pub 中的内容，粘贴到 bitbucket 的账户设置中去。而后，我们可以在 SSH 配置文件中记录：

```plaintext
Host bitb
    HostName bitbucket.org
    IdentityFile ~/.ssh/id_rsa.bitbucket
```

这样一来，git clone git@bitb:foo/bar.git 就能克隆 bitbucket 上 foo 用户的 bar 仓库了（前提是你的账户对这个仓库有访问权限）。