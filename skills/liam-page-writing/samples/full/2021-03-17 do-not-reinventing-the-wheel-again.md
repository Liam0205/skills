---
title: "Again：不要重新造轮子"
url: https://liam.page/2021/03/17/do-not-reinventing-the-wheel-again/
date: 2021-03-17
categories: ["Algorithm and Computer Science"]
tags: ["Python", "JavaScript", "Software Engineering"]
---

最近，宝玉在群里抛了一个 case，大意是说，因为 npm 更新了上游一个包，导致他们的服务性能下降明显。排查之后发现，上游把一个处理字符串的函数（用于将 &<>" 替换为相应的 HTML 转义）从类似 str.replace(/"/g, '&quot;') 的写法，改成了循环遍历 str，然后逐个字符检查，再用 += 拼接到新的输出字符串上。

显然，这又是一个重新造的轮子不圆引发的问题。

为啥这么说呢？我不了解 JavaScript，但对 Python 有所了解。我找了一下 Python 对字符串 replace 的实现，一下就看明白了差距。

```c
// https://svn.python.org/projects/python/trunk/Objects/stringobject.c
Py_LOCAL(PyStringObject *)
replace(PyStringObject *self,
    const char *from_s, Py_ssize_t from_len,
    const char *to_s, Py_ssize_t to_len,
    Py_ssize_t maxcount)
{
    if (maxcount < 0) {
        maxcount = PY_SSIZE_T_MAX;
    } else if (maxcount == 0 || PyString_GET_SIZE(self) == 0) {
        /* nothing to do; return the original string */
        return return_self(self);
    }

    if (maxcount == 0 ||
        (from_len == 0 && to_len == 0)) {
        /* nothing to do; return the original string */
        return return_self(self);
    }

    /* Handle zero-length special cases */

    if (from_len == 0) {
        /* insert the 'to' string everywhere.   */
        /*    >>> "Python".replace("", ".")     */
        /*    '.P.y.t.h.o.n.'                   */
        return replace_interleave(self, to_s, to_len, maxcount);
    }

    /* Except for "".replace("", "A") == "A" there is no way beyond this */
    /* point for an empty self string to generate a non-empty string */
    /* Special case so the remaining code always gets a non-empty string */
    if (PyString_GET_SIZE(self) == 0) {
        return return_self(self);
    }

    if (to_len == 0) {
        /* delete all occurances of 'from' string */
        if (from_len == 1) {
            return replace_delete_single_character(
                self, from_s[0], maxcount);
        } else {
            return replace_delete_substring(self, from_s, from_len, maxcount);
        }
    }

    /* Handle special case where both strings have the same length */

    if (from_len == to_len) {
        if (from_len == 1) {
            return replace_single_character_in_place(
                self,
                from_s[0],
                to_s[0],
                maxcount);
        } else {
            return replace_substring_in_place(
                self, from_s, from_len, to_s, to_len, maxcount);
        }
    }

    /* Otherwise use the more generic algorithms */
    if (from_len == 1) {
        return replace_single_character(self, from_s[0],
                                        to_s, to_len, maxcount);
    } else {
        /* len('from')>=2, len('to')>=1 */
        return replace_substring(self, from_s, from_len, to_s, to_len, maxcount);
    }
}
```

跳过边界检查，Python 的 C 实现当中，对 from_s 和 to_s 不同长度的情况作了不同的处理。当二者长度相同的时候，由于无需额外分配内存，可以使用 in-place 的方式解决问题。当二者长度不同时，若 from_s 的长度为 1，走特定优化的版本；否则，走最通用的版本。

对应到宝玉遇到的问题，显然落到了 from_s 长度为 1 的情形。我们继续再深入看一下。

```c
/* len(self)>=1, len(from)==1, len(to)>=2, maxcount>=1 */
Py_LOCAL(PyStringObject *)
replace_single_character(PyStringObject *self,
                         char from_c,
                         const char *to_s, Py_ssize_t to_len,
                         Py_ssize_t maxcount)
{
    char *self_s, *result_s;
    char *start, *next, *end;
    Py_ssize_t self_len, result_len;
    Py_ssize_t count, product;
    PyStringObject *result;

    self_s = PyString_AS_STRING(self);
    self_len = PyString_GET_SIZE(self);

    count = countchar(self_s, self_len, from_c, maxcount);
    if (count == 0) {
        /* no matches, return unchanged */
        return return_self(self);
    }

    /* use the difference between current and new, hence the "-1" */
    /*   result_len = self_len + count * (to_len-1)  */
    product = count * (to_len-1);
    if (product / (to_len-1) != count) {
        PyErr_SetString(PyExc_OverflowError, "replace string is too long");
        return NULL;
    }
    result_len = self_len + product;
    if (result_len < 0) {
        PyErr_SetString(PyExc_OverflowError, "replace string is too long");
        return NULL;
    }

    if ( (result = (PyStringObject *)
          PyString_FromStringAndSize(NULL, result_len)) == NULL)
        return NULL;
    result_s = PyString_AS_STRING(result);

    start = self_s;
    end = self_s + self_len;
    while (count-- > 0) {
        next = findchar(start, end-start, from_c);
        if (next == NULL)
            break;

        if (next == start) {
            /* replace with the 'to' */
            Py_MEMCPY(result_s, to_s, to_len);
            result_s += to_len;
            start += 1;
        } else {
            /* copy the unchanged old then the 'to' */
            Py_MEMCPY(result_s, start, next-start);
            result_s += (next-start);
            Py_MEMCPY(result_s, to_s, to_len);
            result_s += to_len;
            start = next+1;
        }
    }
    /* Copy the remainder of the remaining string */
    Py_MEMCPY(result_s, start, end-start);

    return result;
}
```

不难看出，这是一个对特定情况的专门优化。

- 遍历原字符串，计数 from_c 出现的次数；

- 计算目标字符串的长度 len(str) + count * (len(to_str) - 1)，提前分配内存；

- 循环地找 from_str 下一次出现的位置，然后 memcpy 原始字符串 + memcpy to_str。

这种操作，肯定会比不断用 += 追加单个字符要快得多。因此有标题：Again, 不要重复造轮子。