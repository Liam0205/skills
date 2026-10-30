---
title: "用 Python 将中文数字转换成阿拉伯数字"
url: https://liam.page/2016/07/26/translate-Chinese-digits-to-Arabic-number/
date: 2016-07-26
categories: ["Algorithm and Computer Science"]
tags: ["Chinese", "Number", "Python", "Arabic"]
---

在工作中，时不时会遇到需要将中文数字或者全角数字转换为半角阿拉伯数字的情形，于是写了一个简单的脚本来处理这样的情况。

脚本很简单，唯一需要思考一下的是，为什么「万」和「亿」不能与「千」、「百」、「十」放在一起处理。这个问题想通了，代码也就好理解了。

不多说，上代码。

```python
chs_arabic_map = {u'零':0, u'一':1, u'二':2, u'三':3, u'四':4,
        u'五':5, u'六':6, u'七':7, u'八':8, u'九':9,
        u'十':10, u'百':100, u'千':10 ** 3, u'万':10 ** 4,
        u'〇':0, u'壹':1, u'贰':2, u'叁':3, u'肆':4,
        u'伍':5, u'陆':6, u'柒':7, u'捌':8, u'玖':9,
        u'拾':10, u'佰':100, u'仟':10 ** 3, u'萬':10 ** 4,
        u'亿':10 ** 8, u'億':10 ** 8, u'幺': 1,
        u'０':0, u'１':1, u'２':2, u'３':3, u'４':4,
        u'５':5, u'６':6, u'７':7, u'８':8, u'９':9}

def convertChineseDigitsToArabic (chinese_digits, encoding="utf-8"):
    if isinstance (chinese_digits, str):
        chinese_digits = chinese_digits.decode (encoding)

    result  = 0
    tmp     = 0
    hnd_mln = 0
    for count in range(len(chinese_digits)):
        curr_char  = chinese_digits[count]
        curr_digit = chs_arabic_map.get(curr_char, None)
        # meet 「亿」 or 「億」
        if curr_digit == 10 ** 8:
            result  = result + tmp
            result  = result * curr_digit
            # get result before 「亿」 and store it into hnd_mln
            # reset `result`
            hnd_mln = hnd_mln * 10 ** 8 + result
            result  = 0
            tmp     = 0
        # meet 「万」 or 「萬」
        elif curr_digit == 10 ** 4:
            result = result + tmp
            result = result * curr_digit
            tmp    = 0
        # meet 「十」, 「百」, 「千」 or their traditional version
        elif curr_digit >= 10:
            tmp    = 1 if tmp == 0 else tmp
            result = result + curr_digit * tmp
            tmp    = 0
        # meet single digit
        elif curr_digit is not None:
            tmp = tmp * 10 + curr_digit
        else:
            return result
    result = result + tmp
    result = result + hnd_mln
    return result
```

完整版见：[GitHub Repo](https://github.com/Liam0205/py-tools/blob/master/convertChineseDigitsToArabic.py)

测试用例来自：[fayaa](http://fayaa.com/code/view/37/)