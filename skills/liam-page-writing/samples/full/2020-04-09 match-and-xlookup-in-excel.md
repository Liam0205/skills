---
title: "利用 Excel 当中的 MATCH 和 XLOOKUP 函数实现集合与字典（映射）访问"
url: https://liam.page/2020/04/09/match-and-xlookup-in-excel/
date: 2020-04-09
categories: ["Computer Skills"]
tags: ["Excel", "MATCH", "XLOOKUP"]
---

集合与字典（映射）是程序设计当中常见的两种容器类型。在 C++ 的标准模板库中，它们的实现分别是 std::set/std::multiset 与 std::map/std::multimap。（分别还有利用哈希表实现的 unordered 版本）其中，字典（映射）的键（Keys）可视作组成一个相应类型的集合。

对于集合或字典的读取，经典操作有两个：判断目标元素是否在集合当中、根据目标键获取相应值。

这篇文章讲讲在 Excel 中如何实现这两个功能。

## MATCH 函数

Excel 中的 MATCH 函数原型是 MATCH(lookup_value, lookup_array, [match_type])。函数可接受 3 个参数，其中前两个为必选参数，第三个为可选参数。第一个参数表示要被查找的值，第二个参数表示要在哪个范围查找，第三个参数表示如何匹配（0 表示相等，-1 表示小于，1 表示大于）。如果匹配成功，则函数返回目标值在范围内的索引，否则报错。

假设有下图所示的 namebook 表。

![](/uploads/images/Excel/namebook.jpg)

现在我们要看看下列人物是否登记在册。

![](/uploads/images/Excel/register-question.jpg)

对于 B2 单元格，我们可以用这样的函数 =NOT(ISERROR(MATCH(A2,namebook!$A$2:$A$4,0)))。这里核心是刚才介绍的 MATCH 函数。我们利用 ISERROR 函数判断 MATCH 函数是否报错——若报错说明查无此人，否则说明登记在册。最后，再用 NOT 函数反转上述真值。如此则有如下图所示的结果。

![](/uploads/images/Excel/register-answer.jpg)

如此，我们就利用 MATCH 函数（搭配 ISERROR 和 NOT 两个函数）实现了判断目标元素是否在集合当中的功能。

## XLOOKUP 函数

Excel 中的 XLOOKUP 函数原型是 XLOOKUP(lookup_value, lookup_array, return_array, [if_not_found], [match_mode], [search_mode])。函数可接受 6 个参数，其中前 3 个为必选参数，后 3 个为可选参数。第一个参数表示要被查找的值，第二个参数表示要在哪个范围（数组）查找，第三个参数表示返回的值在哪个范围（数组），第四个参数表示若未找到返回什么。最后两个参数是高级功能，参见[微软的文档](https://support.office.com/en-us/article/xlookup-function-b7fd680e-6d10-43e6-84f9-88eae8bf5929)。如果匹配成功，假设目标值在待查数组中的索引为 i，则函数返回返回值数组下标 i 的单元格内容，否则报错或填入 if_not_found 内容。

还是看刚才的 namebook 表。

![](/uploads/images/Excel/namebook.jpg)

现在我们要看看下列人物是否登记在册，若登记在册的话登记身高是多少。对于 B2 单元格，我们可以用这样的函数 =XLOOKUP(A2,namebook!$A$2:$A$4,namebook!$B$2:$B$4,"未登记在册")。

![](/uploads/images/Excel/height-solution.png)