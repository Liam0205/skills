---
title: "删除 Hive SQL 查询结果中的重复内容"
url: https://liam.page/2020/05/14/remove-duplicate-entries-in-Hive-SQL/
date: 2020-05-14
categories: ["Big Data and Machine Learning"]
tags: ["Hive", "SQL"]
---

最近用 Hive 实在太频繁了，此篇继续讲 Hive。

此篇遇到的问题是要以某几列为 key，对 Hive SQL SELECT 出来的数据进行去重。以下逐步讨论。

## DISTINCT

说到要去重，自然会想到 DISTINCT。但是在 Hive SQL 里，它有两个问题。

- DISTINCT 会以 SELECT 出的全部列作为 key 进行去重。也就是说，只要有一列的数据不同，DISTINCT 就认为是不同数据而保留。

- DISTINCT 会将全部数据打到一个 reducer 上执行，造成严重的数据倾斜，耗时巨大。

## ROW_NUMBER() OVER

DISTINCT 的两个问题，用 ROW_NUMBER() OVER 可解。比如，如果我们要按 key1 和 key2 两列为 key 去重，就会写出这样的代码：

```sql
WITH temp_table AS (
  SELECT
    key1,
    key2,
    [columns]...,
    ROW_NUMBER() OVER (
      PARTITION BY key1, key2
      ORDER BY column ASC
    ) AS rn
  FROM
    table
)

SELECT
  key1,
  key2,
  [columns]...
FROM
  temp_table
WHERE
  rn = 1;
```

这样，Hive 会按 key1 和 key2 为 key，将数据打到不同的 mapper 上，然后对 key1 和 key2 都相同的一组数据，按 column 升序排列，并最终在每组中保留排列后的第一条数据。借此就完成了按 key1 和 key2 两列为 key 的去重任务。

注意 PARTITION BY 在此起到的作用：一是按 key1 和 key2 打散数据，解决上述问题 (2)；二是与 ORDER BY 和 rn = 1 的条件结合，按 key1 和 key2 对数据进行分组去重，解决上述问题 (1)。

但显然，这样做十分不优雅（not-elegant），并且不难想见其效率比较低。

## GROUP BY 和 COLLECT_SET/COLLECT_LIST

ROW_NUMBER() OVER 的解法的一个核心是利用 PARTITION BY 对数据按 key 分组，同样的功能用 GROUP BY 也可以实现。但是，GROUP BY 需要与聚合函数搭配使用。ORDER BY 和 rn = 1 的条件结合起来实现了「保留第一条」的功能。我们需要考虑，什么样的聚合函数能实现或者间接实现这样的功能呢？不难想到有 COLLECT_SET 和 COLLECT_LIST。

于是有这样的代码：

```sql
SELECT
  key1,
  key2,
  [COLLECT_LIST(column)[1] AS column]...
FROM
  temp_table
GROUP BY
  key1, key2
```

对于 key1 和 key2 以外的列，我们用 COLLECT_LIST 将他们收集起来，然后输出第一个收集进来的结果。这里使用 COLLECT_LIST 而非 COLLECT_SET 的原因在于 SET 内是无序的，因此你无法保证输出的 columns 都来自同一条数据。若对于此没有要求或限制，则可以使用 COLLECT_SET，它会更节省资源。

相比前一种办法，由于省略了排序和（可能的）落盘动作，所以效率会高不少。但是因为（可能）不落盘，所以 COLLECT_LIST 中的数据都会缓存在内存当中。如果重复数量特别大，这种方法可能会触发 OOM。此时应考虑将数据进一步打散，然后再合并；或者干脆换用前一种办法。