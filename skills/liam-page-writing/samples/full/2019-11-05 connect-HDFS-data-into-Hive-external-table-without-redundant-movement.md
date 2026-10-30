---
title: "将 HDFS 上的目录作为 Hive 外表分区同时避免数据拷贝"
url: https://liam.page/2019/11/05/connect-HDFS-data-into-Hive-external-table-without-redundant-movement/
date: 2019-11-05
categories: ["Big Data and Machine Learning"]
tags: ["HDFS", "Hive"]
---

Hive 是个好东西，它能够把 SQL 查询自动转化为一系列 Map-Reduce 任务。但显然，如何将数据引入 Hive 也会是个问题。一个典型的场景是：你通过某种方式，生成了大量结构化的数据，保存在 HDFS 上。现在你希望 Hive 能够基于这些数据，建立数据库，从而能够使用 SQL 语句进行数据库操作。但与此同时，因为数据量十分庞大，你不希望产生数据拷贝、搬移，以免消耗无谓的存储资源和计算资源。

此篇介绍我近期的一个实践方案。

## 数据产出

首先，你需要将数据以特定的格式产出到 HDFS 上。

例如，这里我以 Spark Streaming 任务将制表符分隔的 4 列数据，以 GZip 的格式，输出到 HDFS 位置：hdfs://namenode/path/to/data/<date>/<hour>/<dstreamid>。其中 <date> 是数据产出的日期，<hour> 是数据产出的小时，<dstreamid> 是数据产出时，对应 Spark Streaming 的 Direct Stream 的 ID。于是有类似这样的目录结构：

```shell
hdfs://namenode/path/to/data/2019-11-01/13/123456/_SUCCESS
hdfs://namenode/path/to/data/2019-11-01/13/123456/part-00000.gz
hdfs://namenode/path/to/data/2019-11-01/13/123456/part-00001.gz
hdfs://namenode/path/to/data/2019-11-01/13/123456/part-00002.gz
hdfs://namenode/path/to/data/2019-11-01/13/123456/part-00003.gz
hdfs://namenode/path/to/data/2019-11-01/13/123456/part-00004.gz
hdfs://namenode/path/to/data/2019-11-01/13/123456/part-00005.gz
```

## 建立 Hive 表

有了数据之后，我们需要建立与数据格式相对应的 Hive 表。注意，由于我们不希望对数据进行额外的搬移操作，所以这里需要建立一张外表（EXTERNAL TABLE）。例如，

```sql
CREATE EXTERNAL TABLE `table_name` (
  `field_1` string,
  `field_2` string,
  `field_3` string,
  `field_4` string)
PARTITIONED BY (
  `date` string,
  `hour` string,
  `dstreamid` string)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'field.delim'='\t',
  'serialization.format'='\t')
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'hdfs://namenode/path/to/data/';
```

这里，

- 数据共有 4 个域，名字分别是 field_1 至 field_4（你可以根据实际情况设置恰当的域名字）。

- 分区字段有三个，分别是 date/hour/dstreamid，与数据保存时的子路径名保持一致。

- 域分隔符是 \t，即制表符。

- 输入格式是 org.apache.hadoop.mapred.TextInputFormat，即文本输入。

- 数据位于 hdfs://namenode/path/to/data/，这是我们所有数据的完整路径。

- 表名字是 table_name，你可以根据实际情况设置恰当的表名字。

## 将数据接入 Hive 表

有了数据并创建好 Hive 表之后，我们就可以将数据接入 Hive 表了。这里，我们需要用到 ALTER TABLE 语句。例如：

```sql
ALTER TABLE
  table_name
ADD IF NOT EXISTS PARTITION
  (dt='2019-11-01', hour='13', dstreamid='123456')
LOCATION
  'hdfs://namenode/path/to/data/2019-11-01/13/123456';
```

这个语句表示：

- 更改名为 table_name 的表；

- 具体的动作是 ADD IF NOT EXISTS PARTITION，即当表中不存在相应分区时，添加该分区；

- 添加的数据来自的路径是 hdfs://namenode/path/to/data/2019-11-01/13/123456。

执行成功之后，即可在不进行数据搬移的前提下，将 HDFS 上目录中的数据作为 Hive 外表的分区了。