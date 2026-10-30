---
title: "让所有的公式都使用正文直立字体"
url: https://liam.page/2015/05/07/make-every-equations-in-your-document-upright/
date: 2015-05-07
categories: ["LaTeX"]
tags: ["Font", "Equation", "Upright"]
---

首先说明，**这是邪道**，除非你知道自己在干什么，请不要使用这篇文章提到的方法。这篇文章纯粹是一个技巧的记录，在某些时候可能会有用。

有时候我们会需要将公式字体修改为正文的 \rmfamily\upright\normalsize 的样式。虽然看起来很复杂，其实却很简单。我们只需要在导言区末尾添加以下两行代码：

```tex
\everymath\expandafter{\the\everymath\mathgroup0}
\everydisplay\expandafter{\the\everydisplay\mathgroup0}
```

### 解释

这里实际起作用的是 \mathgroup0。它将数学字体设置为第 0 组字体，也就是正文字体。

而 \expandafter{\the\everymath 能在外层的 \everymath 起作用之前，先将内层的 \everymath 展开。这样可以将 \everymath 的结果保留。若不然，比如有代码：

```tex
\everymath{\displaystyle}
\everymath{\mathgroup0}
```

作者的本意是将每个行内数学公式都是用 \displaystyle，同时设置字体为正文字体。但实际上，由于第二行的存在，第一行的效果被覆盖掉了。为了保证我们添加的代码不影响已有的设置，所以要用 \expandafter{\the\everymath 的方式对已有的设置进行保护。例如，下面的代码则可以达到目的：

```tex
\everymath{\displaystyle}
\everymath\expandafter{\the\everymath\mathgroup0}
```