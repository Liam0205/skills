---
title: "Hive SQL 中的 LATERAL VIEW"
url: https://liam.page/2020/03/09/LATERAL-VIEW-in-Hive-SQL/
date: 2020-03-09
categories: ["Big Data and Machine Learning"]
tags: ["Hive", "SQL"]
---

这些天使用 Hive 的过程中遇到了新的知识点，于是将 LATERAL VIEW 的使用方法记录下来。

## UDTF

UDTF 是 User-Defined Table-Generating Functions 的缩写，即用户定义的表生成函数。UDTF 用来解决从原始表中的一行生成多行数据的问题。典型的 UDTF 有 EXPLODE 函数，它能将 array 或者 map 展开。例如：

考虑以下名为 pageAds 的原始表，它有两列：pageid（网页名称）和 adid_list（网页上显示的广告数组）：

名称
类型

pageid
STRING

adid_list
Array<int>

假设其中有以下两行：

pageid
adid_list

contact_page
[3, 4, 5]

front_page
[1, 2, 3]

使用 EXPLODE 函数可以展开 adid_list 这一列，也就是说，SQL 语句的结果如下所示：

```sql
SELECT
  EXPLODE(adid_list)
FROM
  pageAds;

-- possible result:
-- 1
-- 2
-- 3
-- 3
-- 4
-- 5
```

不过，UDTF 有一个限制，它出现在 SELECT 子句中的时候，不能与其它列共同出现。也就是说下列 SQL 语句会报语法错误：

```sql
SELECT
  pageid, EXPLODE(adid_list) AS adid
FROM
  pageAds;
```

为了解决这个问题，我们就需要引入 LATERAL VIEW。

## LATERAL VIEW

LATERAL VIEW 的语法如下：

```sql
-- lateralView:
LATERAL VIEW udtf(expression) tableAlias AS columnAlias (',' columnAlias)*
--fromClause:
FROM baseTable (lateralView)*  -- 允许联用多个 LATERAL VIEW 子句
```

这里，udtf(expression) 表示诸如 EXPLODE 之类的 UDTF 的表达式。LATERAL VIEW 对遇到的每一行，首先会按 UDTF 表达式进行处理，展开成若干行（可能是零行），然后将这些输出行与输入行 INNER JOIN。如果要保留输出为零的行，则需使用 LATERAL VIEW OUTER 执行 OUTER JOIN。

继续以上述名为 pageAds 的原始表为例，为了同时 SELECT 出 pageid 和 adid，我们需要使用 LATERAL VIEW：

```sql
SELECT
  pageid, adid
FROM
  pageAds
  LATERAL VIEW
    EXPLODE(adid_list) tmp AS adid;

-- possible result:
-- front_page	1
-- front_page	2
-- front_page	3
-- contact_page	3
-- contact_page	4
-- contact_page	5
```