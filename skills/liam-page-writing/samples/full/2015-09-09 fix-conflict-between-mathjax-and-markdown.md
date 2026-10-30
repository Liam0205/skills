---
title: "解决 MathJax 与 Markdown 的冲突"
url: https://liam.page/2015/09/09/fix-conflict-between-mathjax-and-markdown/
date: 2015-09-09
categories: ["Computer Skills"]
tags: ["Markdown", "MathJax", "Conflict"]
---

[MathJax](https://www.mathjax.org/) 是一个 JavaScript 引擎，能够将 LaTeX 语法书写的公式在网页上显示出来，而且效果杠杠的。[Markdown](https://zh.wikipedia.org/zh/Markdown) 是一种轻量级的标记语言。用 Markdown 书写的文章，可以用 Markdown 解释器处理成标准的 HTML 文档。因此 Markdown 很适合用来写网络日志。

作为数学系毕业的学生，写博客时不可避免地会涉及到一些数学公式。可惜不巧，用 Markdown 写博客的我，在使用 MathJax 的时候遇到了一点麻烦。

在 Markdown 中，下划线 _ 被保留，用作标记符号。比如 _Slant_ 会生成倾斜的 *Slant*。在 LaTeX 中，下划线 _ 被用作下标记号。比如 x_i 会生成 $x_i$。

由于 Markdown 在 MathJax 之前起作用，有时下标记号会被 Markdown 吃掉，变成 HTML 标记 <i> 而失去 LaTeX 的下标效果，造成数学公式显示不正常。比如 This is an example: $f_i = f_{i + 1}$ 里的两个下划线会被 Markdown 理解成倾斜的标记，这就不对了。

## 分析与思路

问题的本质在于，下划线 _ 首先被 Markdown 处理，变成 HTML 标记 <i>。之后，MathJax 会认为相关代码是不合法的公式代码，不予处理。比如上述例子，在 MathJax 看来会变成这样：This is an example: $f<i>i = f<i>{i + 1}$——这是什么鬼（MathJax 内心独白）。因此，我们要做的，就是在 Markdown 处理文本的时候，将公式中的下划线保留起来；然后，再让 MathJax 去处理保留下来的下划线。

在 Markdown 中，我们可以用 backtip (`) 来做原样抄写（Verbatim）。也就是说，包含在两个 ` 中间的内容，会被 Markdown 原样保留下来。这正符合我们「保护下划线」的需求。于是，上述例子应该写成 This is an example: `$f_i = f_{i + 1}$` 。

问题看似解决了，不过却又引发了下一个问题。被反引号包括的部分，被 Markdown 当做代码来处理，会加上 HTML 标签 <code>。这样一来，MathJax 在处理文档时，就会跳过这一部分——虽然下划线被保留了，但是整个公式都被忽略了。

一个妥协的办法，是用 JavaScript 处理所有的 <code> 标签：如果发现 <code> 标签内包含数学公式（以美元符号 $ 开头结尾），那么就剥离标签，并调用 MathJax 处理。

下面我们来实现这一思路。

## JavaScript 代码

```javascript
<script type="text/javascript">
function yuuki_query_all_nodes_as_array(selector) {
  return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
}

function replace_code_to_span(node) {
  is_inline_math = /^\$(.*)\$$/.exec(node.textContent);
  is_display_math = /^\$\$(.*)\$\$$/ms.exec(node.textContent) ||
          /^\\begin\{.+\}(.*)\\end\{.+\}/ms.exec(node.textContent);
  if (is_inline_math || is_display_math) {
    var parent = node.parentNode;
    var replacement = document.createElement('span');
    if (is_display_math) {
      replacement.class = "yuuki_mathjax_inline"
    } else {
      replacement.class = "yuuki_mathjax_display"
    }
    replacement.textContent = node.textContent;
    parent.replaceChild(replacement, node);
  }
}

document.addEventListener('DOMContentLoaded', function() {
  yuuki_query_all_nodes_as_array("code").map(replace_code_to_span);
});
</script>
```

或者更简洁的

```javascript
<script type="text/javascript">
window.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('code').forEach(code => {
    const text = code.innerHTML;
    is_inline_math = /^\$(.*)\$$/.exec(text);
    is_display_math = /^\$\$(.*)\$\$$/ms.exec(text) || /^\\begin\{.+\}(.*)\\end\{.+\}/ms.exec(text);
    if (is_inline_math || is_display_math) {
      code.parentElement.classList.add('has-jax');
      if (is_inline_math) {
        code.outerHTML = "<span class=yuuki_mathjax_inline>" + text + "</span>";
      } else {
        code.outerHTML = "<span class=yuuki_mathjax_display>" + text + "</span>";
      }
    }
  });
});
</script>
```

这里，我们用正则表达式匹配了 <code> 标签内的美元符号，然后将 <code> 标签替换成 <span class=hpl_mathjax_inline> 标签。

经过这样一番处理，This is an example: `$f_i = f_{i + 1}$`  就可以被正确处理为「This is an example: $f_i = f_{i + 1}$」了。