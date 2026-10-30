---
title: "PIL 简明教程 - 基本用法"
url: https://liam.page/2015/04/22/pil-tutorial-basic-usage/
date: 2015-04-22
categories: ["Algorithm and Computer Science"]
tags: ["Python", "PIL", "Image"]
---

这是系列文章的第一篇，参见[系列](/series)中的相关内容。

PIL (Python Image Library) 是 Python 平台处理图片的事实标准，兼具强大的功能和简洁的 API。这篇文章将从 PIL 的安装开始，介绍 PIL 的基本情况和基本用法。

## 安装

虽然本篇介绍的是 PIL，但实际上安装的却是 Pillow。PIL 的更新速度很慢，而且存在一些难以配置的问题，不推荐使用；而 Pillow 库则是 PIL 的一个分支，维护和开发活跃，Pillow 兼容 PIL 的绝大多数语法，推荐使用。

在安装 Pillow 之前，需要安装好一些开源库。对于 Mac OS X 而言，可以用 HomeBrew 来安装：

```bash
sudo chown -R $USER:admin /usr/local
brew install libtiff libjpeg libpng webp little-cms2 freetype
sudo pip install Pillow
```

安装好之后，打开 Python 解释器，输入 from PIL import Image 来测试是否安装成功。

## 新建一个 Image 类的实例

PIL 的主要功能定义在 Image 类当中，而 Image 类定义在同名的 Image 模块当中。使用 PIL 的功能，一般都是从新建一个 Image 类的实例开始。新建 Image 类的实例有多种方法。你可以用 Image 模块的 open() 函数打开已有的图片档案，也可以处理其它的实例，或者从零开始构建一个实例。

```python
from PIL import Image
sourceFileName = "source.png"
avatar         = Image.open(sourceFileName)
```

上述代码引入了 Image 模块，并以 open() 方法打开了 source.png 这个图像，构建了名为 avatar 的实例。如果打开失败，则会抛出 IOError 异常。

接下来你可以使用 show() 方法来查看实例。注意，PIL 会将实例暂存为一个临时文件，而后打开它。

```python
avatar.show()
```

![使用 `show()` 方法查看实例的内容 ](//liam.page/attachment/attachment/images/Python/pil-tutorial/Image_show.png)

## 查看实例的属性

Image 类的实例有 5 个属性，分别是：

- format: 以 string 返回图片档案的格式（JPG, PNG, BMP, None, etc.）；如果不是从打开文件得到的实例，则返回 None。

- mode: 以 string 返回图片的模式（RGB, CMYK, etc.）；完整的列表参见 [官方说明·图片模式列表](http://effbot.org/imagingbook/concepts.htm#mode)

- size: 以二元 tuple 返回图片档案的尺寸 (width, height)

- palette: 仅当 mode 为 P 时有效，返回 ImagePalette 示例

- info: 以字典形式返回示例的信息

我们接着上面的代码：

```python
print avatar.format, avatar.size, avatar.mode
```

![查看示例的属性 ](//liam.page/attachment/attachment/images/Python/pil-tutorial/Image_attrib.png)

这里我们看到返回了图片的格式 PNG、图片的大小 (400, 400) 和图片的模式 RGB。

## 实例的方法

Image 类定义了许多方法，这里无法一一列出（也无必要）。如果有需要，可以参看 [官方说明·Image 模块](http://effbot.org/imagingbook/image.htm)。这里仅列出几个有趣的应用。

### 图片 IO - 转换图片格式

Image 模块提供了 open() 函数打开图片档案，Image 类则提供了 save() 方法将图片实例保存为图片档案。

save() 函数可以以特定的图片格式保存图片档案。比如 save('target.jpg', 'JPG') 将会以 JPG 格式将图片示例保存为 target.jpg。不过，大多数时候也可以省略图片格式。此时，save() 方法会根据文件扩展名来选择相应的图片格式。

我们以一个转换图片格式的脚本进行分析。

```python
import os, sys
from PIL import Image

for infile in sys.argv[1:]:
    f, e = os.path.splitext(infile)
    outfile = f + ".jpg"
    if infile != outfile:
        try:
            Image.open(infile).save(outfile)
        except IOError:
            print "cannot convert", infile
```

这里，f 是除去扩展名之外的文件名。在 try 语句中，我们尝试打开图片档案，然后以 .jpg 为扩展名保存图片档案。save() 方法会根据扩展名，将图片以 JPG 格式保存为档案。如果图片档案无法打开，则在终端上打印无法转换的消息。

### 制作缩略图

Image 类的 thumbnail() 方法可以用来制作缩略图。它接受一个二元数组作为缩略图的尺寸，然后将示例缩小到指定尺寸。

```python
import os, sys
from PIL import Image

for infile in sys.argv[1:]:
    outfile = os.path.splitext(infile)[0] + ".thumbnail"
    if infile != outfile:
        try:
            im   = Image.open(infile)
            x, y = im.size
            im.thumbnail((x//2, y//2))
            im.save(outfile, "JPEG")
        except IOError:
            print "cannot create thumbnail for", infile
```

这里我们用 im.size 获取原图档的尺寸，然后以 thumbnail() 制作缩略图，大小则是原先图档的四分之一。同样，如果图档无法打开，则在终端上打印无法执行的提示。

### 剪裁图档

以前也写过 [一篇博客](http://liam0205.me/2014/01/27/Py-Incise-Images/)，讲述如何用 PIL 批量剪裁图档，供参考。

### 变形与粘贴

transpose() 方法可以将图片左右颠倒、上下颠倒、旋转 90°、旋转 180° 或旋转 270°。paste() 方法则可以将一个 Image 示例粘贴到另一个 Image 示例上。

我们尝试将一张图片的左半部分截取下来，左右颠倒之后旋转 180°；将图片的右半边不作更改粘贴到左半部分；最后将修改过的左半部分粘贴到右半部分。

```python
from PIL import Image

imageFName = 'source.png'

def iamge_transpose(image):
    '''
        Input: a Image instance
        Output: a transposed Image instance
        Function:
            * switches the left and the right part of a Image instance
            * for the left part of the original instance, flips left and right\
                and then make it upside down.
    '''
    xsize, ysize = image.size
    xsizeLeft    = xsize // 2 # while xsizeRight = xsize - xsizeLeft

    boxLeft      = (0, 0, xsizeLeft, ysize)
    boxRight     = (xsizeLeft, 0, xsize, ysize)
    boxLeftNew   = (0, 0, xsize - xsizeLeft, ysize)
    boxRightNew  = (xsize - xsizeLeft, 0, xsize, ysize)

    partLeft     = image.crop(boxLeft).transpose(Image.FLIP_LEFT_RIGHT).\
        transpose(Image.ROTATE_180)
    partRight    = image.crop(boxRight)

    image.paste(partRight, boxLeftNew)
    image.paste(partLeft, boxRightNew)
    return image

avatar = Image.open(imageFName)
avatar = iamge_transpose(avatar)
avatar.show()
```

image_transpose() 函数定义之前的部分很简单，而函数本身也由文档叙述得比较清楚。

这里我们以 xsize 和 ysize 接收图片的宽和高，然后以 xsizeLeft 计算得到左半边图片的大小。需要注意的是，我们构建了四个元组，并命名为盒子。这个盒子用直角坐标的值在 image 的画布上框定了一个区域。注意，Image 模块以图片的左上角为直角坐标原点，向右为 x 轴正方向，向下为 y 轴正方向。元组中的前两个数，代表区域左上角的坐标值；后两个数代表区域右下角的坐标值。

接下来的代码相当易懂。我们先用 crop() 方法将原图 boxLeft 的区域（也就是原图的左半边）切下来，然后用 transpose() 方法先后进行左右颠倒和旋转 180° 的工作，并最周公将它保存在 partLeft 这个实例中。而 partRight 的操作更为简单。

函数的最后，我们用 paste() 方法，将前两步得到的 partLeft 和 partRight 分别粘贴到指定的区域；并最终返回 image 示例。

代码片段的最后，我们用 show() 方法展示图片。

![变形和旋转 ](//liam.page/attachment/attachment/images/Python/pil-tutorial/transpose_paste.png)