---
title: "使用 Virtual Audio Cable 解决 CamStudio 在部分 ThinkPad 机型上无法内录的问题"
url: https://liam.page/2014/05/23/CamStudio-WaveoutGetSelectControl-Virtual_Audio_Cable/
date: 2014-05-23
categories: ["Computer Skills"]
tags: ["ThinkPad", "CamStudio", "Virtual Audio Cable", "Vitual Sound Card", "WaveoutGetSelectControl"]
---

最近因为一些缘故，需要在 Win7 上实现录屏和声音内录功能：前者记录计算机屏幕的内容变化，后者记录通过计算机扬声器或耳机线路发出的声音（Speaker 的声音）。在朋友圈中问了一圈，结合自己搜索之后，决定使用开源的 [CamStudio](http://camstudio.org/) 来录屏。

CamStudio 十分优秀，视频上支持多种区域方式（全屏、区域、固定大小、窗口），声音上支持计算机内录和从麦克风输入录制，甚至可选鼠标和键盘操作的录制。但在实际操作中 CamStudio 的内录功能无法正常进行，提示 WaveoutGetSelectControl() failed 的错误，并且官方似乎也没有定位问题所在，导致在多个版本中都存在这个错误（见[官方论坛的讨论](http://camstudio.org/forum/discussion/33/waveoutgetselectcontrol-failed/p1)）。

Woedge 在上述[讨论](http://camstudio.org/forum/discussion/33/waveoutgetselectcontrol-failed/p1)中给出了一个解决方案，帮助一些用户解决了问题。这个方案的关键步骤，是打开 Windows 系统录音设备中的禁用设备——立体声混响（Stereo Mix）功能，然后使用立体声混响将系统内部声音和麦克风声音混在一起，交付给 CamStudio 进行录制。

这个方案无疑帮很多用户解决了问题，但在许多 ThinkPad 机型上却不行。原因是部分 ThinkPad 安装的声卡并不支持 Stereo Mix 功能，故而上述关键步骤无法执行。

经过一番研究之后，决定使用 Virtual Audio Cable 来解决问题。

## 需求分析

- 将计算机扬声器/耳机音频信号直接输入计算机麦克风

- 在内录进行时，保证计算机扬声器的正常工作（不能静音）

## 解决思路

大约是十年前，中国大陆地区流行 MP3 播放器的时候，部分播放器就提供了这种「内录」功能。这些 MP3 播放器大都随机提供了一只内录电缆（Line-in Cable）——类似常见的耳机，只不过正常耳机一头是插头另一头是耳机，而内陆电缆两头都是一模一样的插头，将电缆的一头插入朋友的 MP3 耳机插口中，一头插入自己 MP3 的麦克风插口中，开启录音模式就能录制朋友 MP3 中的歌曲了。当年可是用这个办法节省了不少上网费用（当年家里还是 56K 的拨号上网，一小时六块钱，可贵了）。

这种方式对我来说固然好，但是不免要浪费朋友的时间——内录进行过程中朋友是无法使用 MP3 听音乐的。作为一个爱动手的好孩子，我制作了一个音频分线器，起作用大约就相当于大家普遍使用的 USB 分线器（当计算机 USB 接口不够时，将它接到计算机的 USB 上，然后让其他设备，比如 U 盘，插入到分线器上）。当然，后来才知道这东西到处都有卖，也很便宜。

![3.5mm 音频分线器](//liamsblog.qiniudn.com/post35mmhub.jpg)

今次我们要做的事情和十年前我曾经做过的事情如出一辙。我们当然也可以用一个分线器加一条内录电缆来达到目的，更好的办法无疑是在计算机内部使用软件来模拟分线器和内录电缆的效果来达到目的。为此，我们需要 Virtual Audio Cable.

## 配置 Virtual Audio Cable

我将我使用的版本上传到了[这里](//liam.page/attachment/attachment/soft/Virtual_Audio_Cable_4_10.zip)，你可以下载安装。

接下来我们模拟「内录电缆」的效果。Virtual Audio Cable 在默认设置下，为计算机配置了一些新的输入输出设备。我们暂时不需要修改 Virtual Audio Cable 的设置，直接使用默认设置提供的这些设备即可。

右键 Windows 任务栏上的音量合成器按钮，选择「播放设备」，将「Line 1」设备设置为默认。

![配置播放设备](//liamsblog.qiniudn.com/2014-05-23-CamStudio-WaveoutGetSelectControl-Virtual_Audio_Cableline1_input.png)

然后切换到「录制」标签，同样，将「Line 1」设备设置为默认。

![配置录制设备](//liamsblog.qiniudn.com/2014-05-23-CamStudio-WaveoutGetSelectControl-Virtual_Audio_Cableline1_output.png)

这样 Virtual Audio Cable 就接管了操作系统音频的输入与输出，相当于将一条 Line-in 电缆接在了计算机耳机和麦克风的接口上。

这时，因为计算机的音频输出完全由 Virtual Audio Cable 的虚拟设备「Line 1」接管，计算机的扬声器/耳机中是没有音频信号的，因此我们听不到任何声音。为此，我们需要打开 Virtual Audio Cable 的中继器功能，来模拟前文所述的音频分线器。Virtual Audio Cable 提供了两个中继器模式，分别是 MME 和 KS, 你需要根据你的设备型号来选择。如果你不清楚你的设备型号，不知道选择哪一个的话，也不用担心。因为二者内部的配置完全相同；并且如果当前模式不支持你的硬件，Virtual Audio Cable 就会报错，这时候换另一个就行了。

![Virtual Audio Cable 的中继器](//liamsblog.qiniudn.com/2014-05-23-CamStudio-WaveoutGetSelectControl-Virtual_Audio_CableAudio_Repeater.png)

打开中继器窗口之后，将 Wave In 设置为「Line 1」，将 Wave Out 设置为你的系统扬声器。这样就相当于我们用音频分线器将「Line 1」中的信号分流到了系统扬声器之中，同时又输入到了麦克风信号当中。而这正是我们希望的效果。此时点击 Start 启动中继器，计算机的扬声器就会照常工作了。

![中继器窗口的设置](//liamsblog.qiniudn.com/2014-05-23-CamStudio-WaveoutGetSelectControl-Virtual_Audio_CableAudio_Repeater_in_n_out.png)

这样我们就成功模拟了「内录电缆」和「分线器」的功能，打开 CamStudio 开始录屏吧！