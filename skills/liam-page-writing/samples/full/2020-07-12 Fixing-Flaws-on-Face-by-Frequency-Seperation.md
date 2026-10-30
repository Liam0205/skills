---
title: "PS 技巧：分频磨皮法"
url: https://liam.page/2020/07/12/Fixing-Flaws-on-Face-by-Frequency-Seperation/
date: 2020-07-12
categories: ["Photoshop"]
tags: ["Flaw", "Retouch"]
---

对照片进行后期时，磨皮——修复面部细微瑕疵——是很常见的需求。最简单的磨皮方法，可能是利用涂抹工具、仿制图章工具、修补工具等在原图上直接进行处理。但这些方法都有一个不可避免的缺陷：无法保留诸如皮肤纹理、毛孔等细节。

本文介绍分频磨皮法的操作技巧及其背后的原理。

## 素材图片

我们以 [Alexas_Fotos](https://pixabay.com/zh/users/Alexas_Fotos-686414/?utm_source=link-attribution&utm_medium=referral&utm_campaign=image&utm_content=3990680) 在 [Pixabay](https://pixabay.com/zh/?utm_source=link-attribution&utm_medium=referral&utm_campaign=image&utm_content=3990680) 上发布的[图片](https://pixabay.com/zh/photos/woman-pretty-portrait-girl-young-3990680/)为例，作为素材进行演示。

![](/uploads/images/photoshop/fenpinmopi_small.jpg)

可见，照片中的女性，其面部皮肤有不少暗淡瘢痕。消除她们，并保留照片中足够多的细节就是我们的目标。

## 操作步骤

### 行前准备

首先，我们在 Pixabay 上下载图片，而后用 Photoshop 打开。

而后，我们按 Command + J（Windows 是 Control + J，下同），将背景图层复制一次并命名为原片，以免误操作背景图层，而难以撤销。

![](/uploads/teaching/photoshop/fenpinmopi_1.jpg)

### 皮肤毛刺的处理

接下来，我们首先把明显的毛刺解决掉。

我们首先对原片图层做一个黑白蒙版，并降低红色通道的颜色。这样，面部皮肤上的毛刺就显得特别明显了。

![](/uploads/teaching/photoshop/fenpinmopi_2.jpg)

接下来，新建一个空白图层，放在蒙版下方。然后按 J，调出污点修复画笔工具——当然，你也可以用其他你喜欢的修复工具来修复——在工具参数栏上勾选「对所有图层采样」。接下来即可对各个毛刺进行修复处理。

![](/uploads/teaching/photoshop/fenpinmopi_3.jpg)

这里我们以人物额头部分的毛刺作为演示。

处理完成之后，删除蒙版，并将图层 1 与原片盖印在一起（Command + Alt + Shift + E），并产生新的图层，命名为「去除毛刺」。我们可以看看额头去除毛刺的效果。

![](/uploads/teaching/photoshop/fenpinmopi_3.1.jpg)

### 分频

去除毛刺之后，我们选中「去除毛刺」图层，然后按 Command + J 两次。我们将复制出来的图层，上层命名为高频，下层命名为低频。

![](/uploads/teaching/photoshop/fenpinmopi_4.jpg)

隐藏高频图层，对低频图层进行高斯模糊操作（滤镜 - 模糊 - 高斯模糊）。调整模糊半径，使得恰好看不出皮肤的纹理细节。如此，我们就得到了低频图层。可见色斑色块依然存在，但是皮肤纹理细节、汗毛就看不见了。

![](/uploads/teaching/photoshop/fenpinmopi_5.png)

记下来我们获取高频图层——纹理细节。

显示高频图层并选择它，对高频图层进行「应用图像」操作（图像 - 应用图像）。

- 在「源」当中，选择「低频」图层；

- 在「混合」当中，选择「减去」；

- 设定缩放值为 2；

- 设定补偿值为 128。

如此，我们就得到了高频图层，也就是皮肤纹理、头发都等细节。

![](/uploads/teaching/photoshop/fenpinmopi_6.jpg)

接下来，我们将高频图层的叠加模式，设置为「线性光」。此时可见「去除毛刺」图层的效果，与「高频」「低频」线性光叠加的效果完全一致。

![](/uploads/teaching/photoshop/fenpinmopi_7.jpg)

### 磨皮

我们现在进入磨皮阶段。

首先，隐藏高频图层，显示低频图层。然后调出套索工具，选定人物面部高光的部分。调出高斯模糊进行磨皮。此次高斯模糊的模糊半径可根据需要自由调整。但要注意，过大的模糊半径，会破坏画面的光暗对比。

![](/uploads/teaching/photoshop/fenpinmopi_8.jpg)

我们继续选定人物面部较暗的部分，同样进行高斯模糊磨皮。

完成磨皮后，使高频图层可见。此时我们能发现，人物面部皮肤瑕疵消失，但纹理、毛孔等细节却都保留了下来。

![](/uploads/teaching/photoshop/fenpinmopi_9.jpg)

### 保存

至此，我们就可以将修图的结果保存下来了。以下是效果。

![](/uploads/images/photoshop/fenpinmopi_after.jpg)

## 原理

分频背后的数学原理其实很简单。之前我在讲[卷积神经网络](/2017/07/27/convolutions-and-convolution-neural-network/#%E5%9B%BE%E5%83%8F%E7%9A%84%E6%BB%A4%E9%95%9C)的时候，提到了二维卷积应用在图像上的效果其实就是滤镜。

这里，低频图层的高斯模糊实际就是这里右上角的模糊化，而原片与模糊之后的结果做差，其实就起到这里右下角的边缘检测的效果。

![](/uploads/images/MachineLearning/image_filter.png)

想明白这一点就不难理解我们在 Photoshop 当中做了什么事情了。: )

**更新 2020-07-14**

我将分频的步骤保存成了 Photoshop Action，其中高斯模糊的模糊半径设置为 6px。读者可根据自己需要适当调整。可在[这里](/uploads/teaching/photoshop/actions/Protrait%20Retouch.atn)下载，其中的 Frequency Seperation 即是分频动作。