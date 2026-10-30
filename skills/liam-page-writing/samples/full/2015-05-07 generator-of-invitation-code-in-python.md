---
title: "用 Python 生成随机的邀请码"
url: https://liam.page/2015/05/07/generator-of-invitation-code-in-python/
date: 2015-05-07
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Invitation Code"]
---

在很多场合，我们都需要生成一系列固定长度的字符串，分发给用户，作为邀请码或者兑换码。

关于邀请码，最容易想到的特征有二：一是足够长，二是不具有规律性。这两个特征主要是为了防止用户伪造邀请码，简单来说，就是让用户「猜对」正确邀请码的可能性足够小。不过，作为邀请码来说，仅有这两个特征还不够。

邀请码并不是发放给用户就结束了，还涉及到验证的过程。用户在收到邀请码之后，将邀请码提交给系统。系统在收到提交之后，要在数据库里查询是否有匹配的记录。所以生成邀请码时除了要防止用户伪造，还要方便后期的校验。这就要求我们能够从邀请码中，经过简单的变换，提取出「主键」。

这篇文章我们讨论一下如何用 Python 生成随机的邀请码。

## 产生随机数

Python 有自带的随机库，其名为 random。random 库中的 randint(inf, sup) 函数可以在指定的范围内产生一个随机整数；choice(sequence) 可以在一个有序的类型中（比如 list、tuple 或 string）随机选取一个元素。

这里我们需要产生一个 15 位的随机串，可以包含数字和大小写字母。

```python
# import random, string

poolOfChars  = string.ascii_letters + string.digits
random_codes = lambda x, y: ''.join([random.choice(x) for i in range(y)])

print random_codes(poolOfChars, 15)
```

## 填充空位

为了方便统计，主键通常是一个递增的整数序列。如果主键的值从 1 增加到 1000，那么主键的「（十进制）位数」就会从 1 增加到 4。对于邀请码来说，我们需要固定其总长度。反应到主键上，我们就需要固定主键的长度。最简单的办法，就是用 0 填充（pad）空位。

```python
class LengthError(ValueError):
   def __init__(self, arg):
      self.args = arg

def pad_zero_to_left(inputNumString, totalLength):
    '''
    takes inputNumString as input,
    pads zero to its left, and make it has the length totalLength
    1. calculates the length of inputNumString
    2. compares the length and totalLength
        2.1 if length > totalLength, raise an error
        2.2 if length == totalLength, return directly
        2.3 if length < totalLength, pads zeros to its left
    '''
    lengthOfInput = len(inputNumString)
    if lengthOfInput > totalLength:
        raise LengthError("The length of input is greater than the total\ length.")
    else:
        return '0' * (totalLength - lengthOfInput) + inputNumString
```

## 拼接

至此，我们已经得到了主键和随机序列产生的方法，剩下的问题就是要拼接起来。拼接两个字符串很容易，但是我们在拼接完成之后，还要保证能够很容易地找到主键的部分。

为了达成这个目的，我们只需要在主键和随机串之间加上一个固定的字母，比如 L，作为标识符。

```
bGH49U63p5zy3ULL0123

```

这样我们就知道，整个邀请码子串最后一个 L 之后，就是主键部分。我们有代码：

```python
def invitation_code_generator(quantity, lengthOfRandom, LengthOfKey):
    '''
    generate `quantity` invitation codes
    '''
    placeHoldChar = "L"
    for index in range(quantity):
        tempString = ""
        try:
            yield random_codes(poolOfChars, lengthOfRandom) + placeHoldChar + \
                pad_zero_to_left(str(index), LengthOfKey)
        except LengthError:
            print "Index exceeds the length of master key."

for invitationCode in invitation_code_generator(200, 15, 4):
    print invitationCode
```

这样，我们就生成了 200 个邀请码。其中随机串长度为 15，主键长度为 4，分隔符为字母 L。