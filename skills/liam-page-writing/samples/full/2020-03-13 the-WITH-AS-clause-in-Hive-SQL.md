---
title: "使用 WITH ... AS ... 语句增强 SQL 查询的可读性"
url: https://liam.page/2020/03/13/the-WITH-AS-clause-in-Hive-SQL/
date: 2020-03-13
categories: ["Big Data and Machine Learning"]
tags: ["Hive", "SQL"]
---

最近在读各种 Hive SQL，发现一个可读性问题，让我很无奈。这里记录一下，希望看到的读者能够写出可读性更好的代码。

因为业务比较复杂，所以大家经常会用到各种子查询（sub-query）。于是会写成类似这样：

```sql
SELECT
  t1.foo,
  t2.bar,
  t3.baz
FROM (
    SELECT
      foo,
      bar
    FROM
      tb1
    WHERE
      <conds>
  ) AS t1 INNER JOIN (
    SELECT
      baz
    FROM
      tb2
    WHERE
      <conds>
  ) AS t2 ON <conds>
WHERE
  <conds>;
```

这样写子查询会有两个问题。一是子查询的结果如果要在多个不同地方用到，那么就要复制粘贴多次，实际执行的时候也可能执行多次。二是当子查询或/和 JOIN 特别多的时候，整个查询就会变得无比复杂，可读性极差。为解决问题，可用视图（VIEW）解决，也可用 WITH ... AS ... 子句来解决。

WITH <temprary_table_name> AS (SELECT ... FROM <table_name> WHERE <conds>)  和视图类似，可以创建一个临时表，供之后使用。按上述例子，改用 WITH ... AS ... 子句可以写成这样：

```sql
WITH t1 AS (
  SELECT
    foo,
    bar
  FROM
    tb1
  WHERE
    <conds>
),
t2 AS (
  SELECT
    baz
  FROM
    tb2
  WHERE
    <conds>
)

SELECT
  t1.foo,
  t2.bar,
  t3.baz
FROM
  t1 INNER JOIN t2 ON <conds>
WHERE
  <conds>;
```

很明显，这样写起来可读性会强很多。