---
title: "PIL 简明教程 - 在现有的图片上涂涂改改"
url: https://liam.page/2015/05/05/pil-tutorial-imagedraw-and-imagefont/
date: 2015-05-05
categories: ["Algorithm and Computer Science"]
tags: ["Python", "PIL", "ImageDraw", "ImageFont"]
---

这是系列文章的第二篇，参见[系列](/series)中的相关内容。

[上一篇文章](/2015/04/22/pil-tutorial-basic-usage/) 介绍了 PIL 的基本情况，以及 Image 模块的基本用法。这篇文章，我们讨论一下 ImageDraw 和 ImageFont 两个模块的基本用法，说说如何用 PIL 在现有的图片上涂涂改改。

## ImageDraw 模块

ImageDraw 模块提供了 Draw 类，它能在 Image 实例上进行简单的 2D 绘图。当然复杂的绘图动作是由简单的动作合成而得的，理论上这些动作 ImageDraw 模块也能做，只是相对复杂。如果你想在 Image 实例上做复杂的绘图动作，最好是自行对 ImageDraw 模块提供的各种方法做一些封装。

### 创建一个 Draw 类的实例

要在 Image 实例上绘制新的图样，首先要做的就是创建一个 Draw 类的实例。

```python
from PIL import Image, ImageDraw
sourceFileName = "source.png"
avatar         = Image.open(sourceFileName)
drawAvatar     = ImageDraw.Draw(avatar)
```

代码前三行我们已经见过，唯一的差别在于 import 之后除了我们已经见过的 Image 模块，还有今次我们要使用的 ImageDraw 模块。

### 从画两条平行线开始

Draw 类提供了 line(xy, options) 方法绘制直线。

其中 xy 表示坐标列表，其形式可以是

- [(x1, y1), (x2, y2), ...] - 包含若干个元组的列表

- [x1, y1, x2, y2, ...] - 按照顺序包含坐标信息的列表

- [x1, y1, (x2, y2), ...] - 以上两种情况的混合

- ((x1, y1), (x2, y2), ...) - 包含若干个元组的元组

- (x1, y1, x2, y2, ...) - 按照顺序包含坐标信息的元组

- (x1, y1, (x2, y2), ...) - 以上两种情况的混合

options 中可用的选项有

- fill = (R, G, B) - 用于指定线条的颜色，其中 R、G、B 都是 0 -- 255 的整数

- width = integer - 用于指定线条的宽度，单位是像素

```python
from PIL import Image, ImageDraw
sourceFileName = "source.png"
avatar         = Image.open(sourceFileName)
drawAvatar     = ImageDraw.Draw(avatar)

xSize, ySize = avatar.size

drawAvatar.line([0, 0.33 * ySize, xSize, 0.33 * ySize],\
    fill = (255, 100, 0), width = 3)
drawAvatar.line([0, 0.67 * ySize, xSize, 0.67 * ySize],\
    fill = (255, 0, 0), width = 3)
del drawAvatar

avatar.show()
```

这里我们在图片的两个三等分位置分别画了一条宽度为 3 像素的平行线。一条颜色为 (255, 100, 0)，另一条则是 (255, 0, 0)。

值得注意的是代码的第 14 行，我们直接用 avatar.show() 来展现绘图的结果。可见**Draw 类的实例将直接在 Image 实例上进行操作**。

![line 方法效果示例 ](//liam.page/attachment/attachment/images/Python/pil-tutorial/draw-line.png)

### 画一段弧

Draw 类也提供了 arc(xy, start, end, options) 方法来绘制弧。

这里的 xy 是一个长度为 4 的列表，用来表示一个 bounding box（参考上一篇文章）。start 和 end 则是弧的起止角度，单位是 °。其中水平向右的方向为 0°，竖直向下的方向为 90°，水平向左的方向为 180°，竖直向上的方向为 270°。

options 中可用的选项有

- fill = (R, G, B) - 用于指定线条的颜色，其中 R、G、B 都是 0 -- 255 的整数

arc 方法将在内切于 bounding box 的椭圆中，按照给定的起止角度切下一段弧，并绘制于 Image 示例之上。

```python
from PIL import Image, ImageDraw
sourceFileName = "source.png"
avatar         = Image.open(sourceFileName)
drawAvatar     = ImageDraw.Draw(avatar)

xSize, ySize = avatar.size

drawAvatar.arc([0, 0, xSize, ySize], 0, 90,\
    fill = (255, 100, 255))
del drawAvatar

avatar.show()
```

![arc 方法效果示例 ](//liam.page/attachment/attachment/images/Python/pil-tutorial/draw-arc.png)

### 在图片上写字

Draw 类提供了 text(position, string, options) 方法，该方法可以在 Image 实例上写字。

需要说明的是，position 指定的是文本左上角的顶点，而不是文本中心。这里可用的 options 有

- font = ImageFont instance - 指定字体，接受一个 ImageFont 的实例

- fill = (R, G, B) - 用于指定线条的颜色，其中 R、G、B 都是 0 -- 255 的整数

```python
from PIL import Image, ImageDraw
sourceFileName = "source.png"
avatar         = Image.open(sourceFileName)
drawAvatar     = ImageDraw.Draw(avatar)

xSize, ySize = avatar.size

drawAvatar.text([0.9 * xSize, 0.1 * ySize - drawAvatar.textsize("3")[1]],\
    "3", fill = (128, 0, 128))
del drawAvatar

avatar.show()
```

![text 方法效果示例 ](//liam.page/attachment/attachment/images/Python/pil-tutorial/draw-text.png)

由于没有用 font 选项指定字体，这里使用了 ImageDraw 的默认字体。不难发现，相对图片，字体太小了。为了调整字体，我们需要借助 ImageFont 模块。

## ImageFont 模块

ImageFont 模块很简单，它定义了一个同名的类。ImageFont 类的实例可以传给 ImageDraw 中 text 方法的 font 的参数，起到字体选择的作用。

ImageFont 模块中的 load 函数可以加载一个 Image 格式的字体，并返回 ImageFont 实例；其中的 truetype(fontfile, fontsize) 函数则可以加载 TrueType 或 OpenType 格式的字体，并返回 ImageFont 参数。不过 truetype 函数需要额外安装 _imagingft 模块。

配置好之后，我们可以对上一节末尾的代码稍作修改：

```python
from PIL import Image, ImageDraw, ImageFont

sourceFileName = "source.png"
avatar         = Image.open(sourceFileName)
drawAvatar     = ImageDraw.Draw(avatar)

xSize, ySize = avatar.size
fontSize     = min(xSize, ySize) // 11

myFont       = ImageFont.truetype("/Library/Fonts/OsakaMono.ttf", fontSize)

drawAvatar.text([0.9 * xSize, 0.1 * ySize - fontSize],\
    "3", fill = (255, 0, 0), font = myFont)
del drawAvatar

avatar.show()
```

这里我们引入了 ImageFont 模块，并且创建了 myFont 实例。创建实例的时候，传入的字体尺寸由图片大小决定。最后在图片上写字的位置也与字体大小有关。

这样以来，我们就在图片的右上角写了一个红色的数字，就好像微信未读消息提示的那种效果。

![引入 font 选项的 text 方法效果示例 ](//liam.page/attachment/attachment/images/Python/pil-tutorial/draw-text-font.png)

## 小结

ImageDraw 模块还有许多其他的功能，比如绘制椭圆、多边形、矩形等。限于篇幅，这里就不一一介绍了。感兴趣的读者可以参看官方文档：

[http://effbot.org/imagingbook/imagedraw.htm#methods](http://effbot.org/imagingbook/imagedraw.htm#methods)