---
title: "使用 vimdiff 时忽略白空格的修改"
url: https://liam.page/2019/08/06/ignnore-white-space-differences-when-using-vimdiff/
date: 2019-08-06
categories: ["Computer Skills"]
tags: ["VIM"]
---

使用 vimdiff 能够方便地观察多个文件之间的异同。但有时我们会希望 VIM 忽略白空格的变化。比如，对于 Python 脚本，有时我们会修改缩进来对代码进行格式化；此时对比新旧文件之间的差异时，我们更多地是希望看看有没有手误修改了其他不应修改的部分，从而应当忽略白空格的变化。

这篇文章简单记录一下这个问题的解法。

这个问题其实不难解决，只需在 vimrc 中加入以下内容即可：

```bash
set diffopt+=iwhite
```

不过，这样设定也会影响到 VIM 正常编辑时所处的模式。如果希望这一设定只限定在 vimdiff 模式，则可以这样修改：

```bash
if &diff
    set diffopt+=iwhite
endif
```

若是想要自由切换，则可以这样做：

```bash
if &diff
  map gs :call IwhiteToggle()<CR>
  function! IwhiteToggle()
    if &diffopt =~ 'iwhite'
      set diffopt-=iwhite
    else
      set diffopt+=iwhite
    endif
  endfunction
 endif
```

最后，若不想修改 vimrc 可以在命令行这样启动命令：

```bash
vimdiff -c 'set diffopt+=iwhite'
```