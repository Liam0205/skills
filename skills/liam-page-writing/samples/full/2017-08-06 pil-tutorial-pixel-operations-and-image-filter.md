---
title: "PIL 简明教程 - 像素操作与图像滤镜"
url: https://liam.page/2017/08/06/pil-tutorial-pixel-operations-and-image-filter/
date: 2017-08-06
categories: ["Algorithm and Computer Science"]
tags: ["Python", "PIL", "ImageFilter"]
---

这是系列文章的第三篇，参见[系列](/series)中的相关内容。

这篇文章介绍如何利用 PIL 库，获取图像中的像素内容、修改后生成新的图像。此外，在修改的过程中，我们会引入卷积滤镜，进而引出 PIL 中的图像滤镜库 ImageFilter。

## 获取像素内容

位图是有一个个像素组成的。因此，读入一张图片，实际上就是读入了一系列的像素内容。这些像素内容，按照不同的[模式](http://pillow.readthedocs.io/en/3.4.x/handbook/concepts.html#concept-modes)具有不同的格式。对于三通道的 RGB 位图来说，每个像素是一个 8-bit 整数的三元组。例如 rgb(0, 0, 0) 表示纯黑色，而 rgb(255, 255, 255) 则表示纯白色。

前文介绍过，Image.open() 可以打开一张图片，返回一个 Image 类的对象。那么，我们怎样获得这一图片的像素内容呢？

PIL 提供了 PIL.Image.getdata(band = None) 方法，用来获取 Image 类的对象中的像素内容。

该方法会将图片中的像素内容，逐行逐行地拼接起来（俗称降维打击），作为一个完整的序列返回。方法的返回类型，是 PIL 库的内部类型。我们可以用 list(im.getdata()) 得到标准的 Python list 对象。

该方法的参数中，band 意味「通道」。当 band = None 时，方法返回所有通道的像素内容；当 band = 0 时，则返回第一个通道的像素内容。例如，对于 RGB 模式的位图，band = 0 返回 R 通道的内容；band = 2 返回 B 通道的内容。

示例代码：

```python
from PIL import Image

im = Image.open('cat.jpg')

rgb_pixels = list(im.getdata())
r_pixels   = list(im.getdata(band = 0))
g_pixels   = list(im.getdata(band = 1))
b_pixels   = list(im.getdata(band = 2))

print(rgb_pixels[:10])
print(r_pixels[:10])
print(g_pixels[:10])
print(b_pixels[:10])
```

可能的输出：

```python
[(130, 82, 8), (132, 84, 8), (136, 87, 10), (141, 90, 11), (143, 90, 10), (145, 90, 7), (144, 88, 3), (144, 87, 0), (147, 85, 0), (148, 84, 0)]
[130, 132, 136, 141, 143, 145, 144, 144, 147, 148]
[82, 84, 87, 90, 90, 90, 88, 87, 85, 84]
[8, 8, 10, 11, 10, 7, 3, 0, 0, 0]
```

## 写入像素内容

上一节介绍了如何从一个 Image 类的对象中获得像素内容。现在我们考虑它的镜像问题：如何将已知的像素内容写入一个新的 Image 类的对象。

在介绍 PIL.Image.getdata() 的过程中，我们提到，该方法返回的内容是一个一维的序列。这个过程，实际上丢失了图像的模式、尺寸等信息。那么在从像素内容恢复到 Image 类的对象的过程中，我们就必须补足这些信息。因此，我们首先需要获取原图像的模式和尺寸。

```python
from PIL import Image

im = Image.open('cat.jpg')

mode = im.mode
width, height = im.size

imn = Image.new(mode, (height, width))
```

如此，我们就创建了一个新的 Image 类的对象。它的模式与 im 保持一致，尺寸则相对 im 长宽颠倒。现在，我们可以向 imn 中写入像素内容了。

PIL.Image.putdata(data, scale=1.0, offset=0.0) 方法允许我们将像素内容写入 Image 类的对象。

该方法将序列类型 data 拷贝进 Image 类的对象，直到 Image 类的对象容纳不下更多的像素或 data 内容已耗尽。scale 和 offset 则是针对每一个像素值进行调整：pixel = value * scale + offset。

据此，我们可以写出完整的代码。首先来看看原图。

![一只惊讶的猫](/uploads/images/python/cat.jpg)

示例代码：

```python
from PIL import Image

im = Image.open('cat.jpg')

mode = im.mode
width, height = im.size
rgb_pixels = list(im.getdata())

imn = Image.new(mode, (height, width))
imn.putdata(data = rgb_pixels)

imn.save('funny_cat.jpg')
```

结果：

![一只扭曲的猫](/uploads/images/python/funny_cat.jpg)

## 实际操作看看——实现卷积滤镜

用固定的矩阵扫描更大的矩阵，这个操作称为卷积。若后者是一张图片，那么这一操作，就是对图像的滤镜操作了。我们在[前作](/2017/07/27/convolutions-and-convolution-neural-network/#%E5%9B%BE%E5%83%8F%E7%9A%84%E6%BB%A4%E9%95%9C)中介绍了这种操作，此处我们来实践看看。

示例代码：

```python
from PIL import Image
import numpy as np
from scipy import signal

def read_image(fname):
    im     = Image.open(fname)
    width, height = im.size
    mode   = im.mode
    pixels = list(im.getdata())
    im.close()

    r_pxs  = map(lambda x:x[0], pixels)
    g_pxs  = map(lambda x:x[1], pixels)
    b_pxs  = map(lambda x:x[2], pixels)
    r_pxs  = [r_pxs[i * width:(i + 1) * width] for i in xrange(height)]
    g_pxs  = [g_pxs[i * width:(i + 1) * width] for i in xrange(height)]
    b_pxs  = [b_pxs[i * width:(i + 1) * width] for i in xrange(height)]

    return mode, (width, height), (r_pxs, g_pxs, b_pxs)

def convolve2d(x, ker, mode = 'same', boundary = 'wrap'):
    a = np.asarray(x, dtype = float)
    b = np.asarray(ker, dtype = float)
    res = signal.convolve2d(a, b, mode, boundary)
    return res

def filter_image(mode, size, rgb, kernel, fname):
    r   = convolve2d(rgb[0], kernel)
    g   = convolve2d(rgb[1], kernel)
    b   = convolve2d(rgb[2], kernel)

    int_it = lambda f:int(round(f, 0))

    pixels = map(lambda x, y, z: (int_it(x), int_it(y), int_it(z)),
                                            r.flat, g.flat, b.flat)

    res = Image.new(mode, size)
    res.putdata(pixels)
    res.save(fname)
    res.close()
    return None

if __name__ == '__main__':
    base, ext = 'cat', 'jpg'

    ifname = "%s.%s" % (base, ext)

    ofname = "%s_blur.%s" % (base, ext)
    blur_5 = [[1.0 / 25.0] * 5] * 5
    mode, size, rgb = read_image(ifname)
    filter_image(mode, size, rgb, blur_5, ofname)

    ofname = "%s_shrp.%s" % (base, ext)
    shrp_3 = [[0, -1, 0],
              [-1, 5, -1],
              [0, -1, 0]]
    mode, size, rgb = read_image(ifname)
    filter_image(mode, size, rgb, shrp_3, ofname)

    ofname = "%s_dtct.%s" % (base, ext)
    dtct_3 = [[-1, -1, -1],
              [-1, 8, -1],
              [-1, -1, -1]]
    mode, size, rgb = read_image(ifname)
    filter_image(mode, size, rgb, dtct_3, ofname)
```

此处 read_image 函数从一个图像文件中读入其模式、尺寸及 RGB 三通道矩阵。convolve2d 函数利用了 scipy 库中的 signal.convolve2d 函数，对图像的单通道进行卷积操作——滤镜。filter_image 函数则是对 convolve2d 的封装，从上述模式、尺寸及 RGB 三通道矩阵开始，使用 kerner 作为卷积核进行滤镜操作，并将图片保存下来。

此处我们选择了三个卷积核。blur_5 将目标像素周围的 5*5 的像素平均起来，起到 box-模糊化的作用。shrp_3 加强了目标像素的作用，同时减弱了上下左右四个像素的干扰，起到了锐化的作用。dtct_3 则凸显了哪些与周围 8 个像素具有明显差异的像素，起到了边缘检测的作用。三个滤镜的效果可以参见：[原图](/uploads/images/python/cat.jpg)/[模糊化](/uploads/images/python/cat_blur.jpg)/[锐化](/uploads/images/python/cat_shrp.jpg)/[边缘检测](/uploads/images/python/cat_dtct.jpg)。

## 使用 ImageFilter 预定义的滤镜

PIL 库在 ImageFilter 模块中已经为我们预定义好了一些滤镜。同时 Image 模块也提供了 filter 方法应用滤镜：Image.filter(filter_object)。因此，我们可以用 ImageFilter 提供的 Kernel 滤镜，很方便地复现上一节中的滤镜效果。（Kernel 当前仅支持 3*3 或 5*5 的滤镜，sad）。

示例代码：

```python
from PIL import Image
from PIL import ImageFilter

im = Image.open('cat.jpg')

imn = im.filter(ImageFilter.Kernel(size = (5, 5), kernel = [1.0 / 25.0] * 25))

imn.show()
```

效果：

![](/uploads/images/python/cat_blur.jpg)

你可以在[官方文档](http://pillow.readthedocs.io/en/3.4.x/reference/ImageFilter.html)中找到更多的滤镜。