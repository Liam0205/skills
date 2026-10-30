---
title: "【LaTeX Tips】选择加载的图片类型"
url: https://liam.page/2013/12/07/LaTeX-Choose-picture-format/
date: 2013-12-07
categories: ["LaTeX"]
tags: ["Graphicx", "Images", "Format"]
---

我们在排版很长的文章或者书籍的时候，编译一次通常需要花费很长时间，并且生成文件的体积也会比较大。而通常我们会希望文档中的图片足够高清，但在写文章的时候又希望能节省时间（同时声称小体积的文件供预览）。因此有一个快速选择图片类型的方法就变得很有必要了。

在 LaTeX 中，相同文件名加载图片的顺序是：

```plaintext
.png .pdf .jpg .mps .jpeg .jbig2 .jb2 .PNG .PDF .JPG .JPEG .JBIG2 .JB2
```

而这一顺序存储在宏 \Gin@extensions 之中。因此，若是在相同目录下同时含有 dummy.png 和 dummy.pdf, 编译引擎将会选择前者（假设支持）。你可以用 \DeclareGraphicsExtensions 命令来声明并改变这些扩展名的顺序，比如：

```tex
\DeclareGraphicsExtensions{
    .png,.PNG,%
    .pdf,.PDF,%
    .jpg,.mps,.jpeg,.jbig2,.jb2,.JPG,.JPEG,.JBIG2,.JB2}
```

这样就能确保 png 文件在 pdf 文件之前被载入了——在最终输出之时只需要交换两行的顺序即可。

另外 grfext 宏包提供了 \PrependGraphicsExtensions 命令实现同样的效果：

```tex
\usepackage{grfext}
\PrependGraphicsExtensions*{.png,.PNG}
```

选自 [egreg](http://profs.scienze.univr.it/~gregorio/) 在 [TeX.SX](http://tex.stackexchange.com/a/45502/38350) 上的回答。