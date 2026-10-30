---
title: "Python 中的黑暗角落（三）：模块与包"
url: https://liam.page/2017/07/23/modules-and-packages-of-python/
date: 2017-07-23
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Packages", "Modules"]
---

如果你用过 Python，那么你一定用过 import 关键字加载过各式各样的模块。但你是否熟悉 Python 中的模块与包的概念呢？或者，以下几个问题，你是否有明确的答案？

- 什么是模块？什么又是包？

- from matplotlib.ticker import Formatter, FixedLocator 中的 matplotlib 和 ticker 分别是什么？中间的句点是什么意思？

- from matplotlib.pyplot import * 中，import * 的背后会发生什么？

鲁迅先生说：「于无声处听惊雷」，讲的是平淡时却有令人惊奇、意外的事情。import 相关的模块、包的概念也是如此。如果你对上面几个问题存有疑问，那么这篇就是为你而作的。

## 模块

### 为什么要有模块

众所周知，Python 有一个交互式的解释器。在解释器中，你可以使用 Python 的所有功能。但是，解释器是一次性的。也就是说，如果你关掉解释器，那么先前定义、运行的一切东西，都会丢失不见。另一方面，在解释器中输入代码是一件很麻烦的事情；这是因为在解释器中复用代码比较困难。

为此，人们会把相对稳定、篇幅较长的代码保存在一个纯文本文件中。一般来说，我们把这样扩展名为 .py 的文件称为 Python 脚本。为了提高代码复用率，我们可以把一组相关的 Python 相关的定义、声明保存在同一个 .py 文件中。此时，这个 Python 脚本就是一个 Python 模块（Module）。我们可以在解释器中，或者在其他 Python 脚本中，通过 import 载入定义好的 Python 模块。

### 模块的识别

和 Python 中的其它对象一样，Python 也为模块定义了一些形如 __foo__ 的变量。对于模块来说，最重要的就是它的名字 __name__ 了。每当 Python 执行脚本，它就会为该脚本赋予一个名字。对于「主程序」来说，这一脚本的 __name__ 被定义为 "__main__"；对于被 import 进主程序的模块来说，这一脚本的 __name__ 被定义为脚本的文件名（base filename）。因此，我们可以用 if __name__ == "__main__": 在模块代码中定义一些测试代码。

```python
def fib_yield(n):
    a, b = 0, 1
    while b < n:
        yield b
        a, b = b, a+b

def fib(n):
    for num in fib_yield(n):
        print(num)

if __name__ == "__main__":
    fib(10)
```

我们将其保存为 fibonacci.py，而后在 Python 解释器中 import 它。

```python
In [1]: import fibonacci

In [2]: dir(fibonacci)
Out[2]:
['__builtins__',
 '__doc__',
 '__file__',
 '__name__',
 '__package__',
 'fib',
 'fib_yield']

In [3]: print(fibonacci.__name__)
fibonacci

In [4]: fibonacci.fib(5)
1
1
2
3

In [5]: for num in fibonacci.fib_yield(5):
   ...:     print(num)
   ...:
1
1
2
3
```

可以观察到，fibonacci.py 在作为模块引入时，fibonacci.__name__ 被设置为文件名 "fibonacci"。但若在命令行直接执行 python fibonacci.py，则 if 语句块会被执行，此时 __name__ 是 "__main__"。

### 模块的内部变量和初始化

Python 为每个模块维护了单独的符号表，因此可以实现类似 C++ 中名字空间（namespace）的功能。Python 模块中的函数，可以使用模块的内部变量，完成相关的初始化操作；同时，import 模块的时候，也不用担心这些模块内部变量与用户自定义的变量同名冲突。

```python
foo = 0

def show():
    print(foo)

if __name__ == "__main__":
    show()
```

此处我们在模块 module_var 内部定义了内部变量 foo，并且在函数 show 中引用了它。

```python
In [7]: import module_var
   ...:
   ...: foo = 3
   ...:
   ...: print(foo)
   ...: print(module_var.foo)
   ...:
   ...: module_var.show()
   ...:
3
0
0
```

值得一提的是，模块的初始化操作（这里指 foo = 0 这条语句），仅只在 Python 解释器第一次处理该模块的时候执行。也就是说，如果同一个模块被多次 import，它只会执行一次初始化。

### from ... import ...

模块提供了类似名字空间的限制，不过 Python 也允许从模块中导入指定的符号（变量、函数、类等）到当前模块。导入后，这些符号就可以直接使用，而不需要前缀模块名。

```python
In [8]: from fibonacci import fib_yield, fib

In [9]: fib(10)
1
1
2
3
5
8
```

值得一提的是，被导入的符号，如果引用了模块内部的变量，那么在导入之后也依然会使用模块内的变量，而不是当前环境中的同名变量。

```python
In [11]: from module_var import show

In [12]: foo = 3

In [13]: show()
0
```

也有更粗暴的方式，导入模块内的所有公开符号（没有前缀 _ 的那些）。不过，一般来说，除了实验、排查，不建议这样做。因为，通常你不知道模块定义了哪些符号、是否与当前环境有重名的符号。一旦有重名，那么，这样粗暴地导入模块内所有符号，就会覆盖掉当前环境的版本。从而造成难以排查的错误。

### 模块搜索路径

之前我们都在讨论模块的好处，但是忽略了一个问题：Python 怎样知道从何处找到模块文件？

如果你熟悉命令行，那么这个问题对你来说就不难理解。在命令行中执行的任何命令，实际上背后都对应了一个可执行文件。命令行解释器（比如 cmd, bash）会从一个全局的环境变量 PATH 中读取一个有序的列表。这个列表包含了一系列的路径，而命令行解释器，会依次在这些路径里，搜索需要的可执行文件。

Python 搜寻模块文件，也遵循了类似的思路。比如，用户在 Python 中尝试导入 import foobar，那么

- 首先，Python 会在内建模块中搜寻 foobar；

- 若未找到，则 Python 会在当前工作路径（当前脚本所在路径，或者执行 Python 解释器的路径）中搜寻 foobar；

- 若仍未找到，则 Python 会在环境变量 PYTHONPATH 中指示的路径中搜寻 foobar；

- 若依旧未能找到，则 Python 会在安装时指定的路径中搜寻 foobar；

- 若仍旧失败，则 Python 会报错，提示找不到 foobar 这个模块。

```python
In [14]: import foobar
---------------------------------------------------------------------------
ImportError                               Traceback (most recent call last)
<ipython-input-14-909badd622c0> in <module>()
----> 1 import foobar

ImportError: No module named foobar
```

### pyc 文件

和 LaTeX 中遇到的问题一样：装载大量文本文件是很慢的。因此 Python 也采用了类似 LaTeX 的解决方案：将模块编译成容易装载的文件，并保存起来（相当于 LaTeX 中的 dump 格式文件 .fmt）。这些编译好并保存起来的文件，有后缀名 .pyc。

当 Python 编译好模块之后，下次载入时，Python 就会读取相应的 .pyc 文件，而不是 .py 文件。而装载 .pyc 文件会比装载 .py 文件更快。

值得一提的是，对于 .pyc，很多人一直有误解。事实上，从运行的角度，装载 .pyc 并不比装载 .py 文件更快。此处的加速，仅只在装载模块的过程中起作用。因此 .pyc 中的 C 更多地可以理解为 cache。

## 包

包（package）是 Python 中对模块的更高一级的抽象。简单来说，Python 允许用户**把目录当成模块看待**。这样一来，目录中的不同模块文件，就变成了「包」里面的子模块。此外，包目录下还可以有子目录，这些子目录也可以是 Python 包。这种分层，对模块识别、管理，都是非常有好处的。特别地，对于一些大型 Python 工具包，内里可能有成百上千个不同功能的模块。若是逐个模块发布，那简直成了灾难。

科学计算领域，SciPy, NumPy, Matplotlib 等第三方工具，都是用包的形式发布的。

### 目录结构

Python 要求每一个「包」目录下，都必须有一个名为 __init__.py 的文件。从这个文件的名字上看，首先它有 __ 作为前后缀，我们就知道，这个文件肯定是 Python 内部用来做某种识别用的；其次，它有 init，我们知道它一定和初始化有关；最后，它有 .py 作为后缀名，因此它也是一个 Python 模块，可以完成一些特定的工作。

现在假设你想编写一个 Python 工具包，用来处理图片，它可能由多个 Python 模块组成。于是你会考虑把它做成一个 Python 包，内部按照功能分成若干子包，再继续往下分成不同模块去实现。比如会有这样的目录结构。

```plaintext
picture/                        Top-level package
      __init__.py               Initialize the picture package
      formats/                  Subpackage for file format conversions
              __init__.py
              jpgread.py
              jpgwrite.py
              pngread.py
              pngwrite.py
              bmpread.py
              bmpwrite.py
              ...
      filters/                  Subpackage for filters
              __init__.py
              boxblur.py
              gaussblur.py
              sharpen.py
              ...

```

此处 picture 目录下有 __init__.py，因此 Python 会将其作为一个 Python 包；类似地，子目录 formats 和 filters 就成了 picture 下的子包。这里，子包的划分以功能为准。formats 下的模块，设计用于处理不同格式的图片文件的读写；而 filters 下的模块，则被设计用于实现各种滤镜效果。

### 使用 Python 包

Python 包的使用和模块的使用类似，是很自然的方式。以我们的 picture 包为例，若你想使用其中具体的模块，可以这样做。

```python
import picutre.filters.gaussblur
```

如此，你就导入了 picture 包中 filters 子包中的 gaussblur 模块，你就能使用高斯模糊模块提供的功能了。具体使用方式，和使用模块也保持一致。

```python
picture.filters.gaussblur.gaussblur_filter(input, output)
```

这看起来很繁琐，因此你可能会喜欢用 from ... import ... 语句，脱去过多的名字限制。

```python
from picture.filters import gaussblur
```

这样一来，你就可以直接按如下方式使用高斯模糊这一滤镜了。

```python
gaussblur.gaussblur_filter(input, output)
```

### __init__.py

之前简单地介绍了 __init__.py 这个特殊的文件，但未展开。这里我们展开详说。

首先的问题是，为什么要设计 __init__.py，而不是自动地把任何一个目录都当成是 Python 包？这主要是为了防止重名造成的问题。比如，很可能用户在目录下新建了一个子目录，名为 collections；但 Python 有内建的同名模块。若不加任何限制地，将子目录当做是 Python 包，那么，import collections 就会引入这个 Python 包。而这样的行为，可能不是用户预期的。从这个意义上说，设计 __init__.py 是一种保护措施。

接下来的问题是，__init__.py 具体还有什么用？

首先来说，__init__.py 可以执行一些初始化的操作。这是因为，__init__.py 作为模块文件，会在相应的 Python 包被引入时首先引入。这就是说，import picture 相当于是 import picture.__init__。因此，__init__.py 中可以保留一些初始化的代码——比如引入依赖的其他 Python 模块。

其次，细心的你可能发现，上一小节中，我们没有介绍对 Python 包的 from picture import * 的用法。这是因为，从一个包中导入所有内容，这一行为是不明确的；必须要由包的作者指定。我们可以在 __init__.py 中定义名为 __all__ 的 Python 列表。这样一来，就能使用 from picture import * 了。

具体来说，我们可以在 picture/__init__.py 中做如下定义。

```python
import collections          # import the built-in package

__all__ = ["formats", "filters"]
```

此时，若我们在用户模块中 from picture import *，则首先会引入 Python 内建的 collections 模块，而后引入 picture.formats 和 picture.filters 这两个 Python 子包了。

### 在包内使用相对层级引用其他模块

细心的你应该已经发现，在引入 Python 包中的模块时，我们用句点 . 代替了斜线（或者反斜线）来标记路径的层级（实际上是包和模块的层级）。在 Python 包的内部，我们也可以使用类似相对路径的方式，使用相对层级来简化包内模块的互相引用。

比如，在 gaussblur.py 中，你可以通过以下四种方式，引入 boxblur.py，而它们的效果是一样的。

```python
import boxblur
from . import boxblur
from ..filters import boxblur
from .. import filters.boxblur as boxblur
```