---
title: "使用 TRANSFORM 在 Hive 中调用用户自定义的脚本"
url: https://liam.page/2020/05/11/TRANSFORM-in-Hive/
date: 2020-05-11
categories: ["Big Data and Machine Learning"]
tags: ["Hive"]
---

在实际工作一个典型的机器学习任务中，我们在线上和线下都要对特征数据进行处理。线上处理的目的是为了推理预测，线下处理的目的则是为了准备训练数据。显然，因为处理区分线上线下，数据一致性就会成为非常关键的问题。

然而，数据一致性是挺烫手的山芋。因为，如果尝试在线上线下先后两次实现同样的功能，不论如何小心，都有出错的可能。更不用说，如果使用不同语言，那对于数据处理上的些微不同最终都可能破坏数据一致性。

因此，保证数据一致性最好的办法就是用一份代码在两个地方干同样的事情。我们线上服务是用 C++ 编写的，因此我们可以将特征 ETL 抽象成单独的模块，分别链接到线上服务以及离线特征处理程序中。这样，二者对于特征的 ETL 的行为就完全一致了。

剩下的问题就是：离线数据通过 Kafka 落在 Hive 表当中，我们需要在 Hive 处理数据的过程中，嵌入我们自己编写的特征处理程序。

经过简单的检索，我发现 Hive SQL 的 TRANSFORM 语法可以很方便地完成这一工作。

首先，我们需要使用 ADD FILE 将可执行程序以及可能的其他资源文件加入 Hive 豪华套餐。

```sql
ADD FILE hdfs://path/to/feature_etl;
ADD FILE hdfs://path/to/feature_etl.cfg;
```

而后，我们就可以将 TRANSFORM 语句嵌入在 SELECT 子句当中了：

```sql
SELECT
  TRANSFORM (column1, column2)
    USING './feature_etl --config_file=./feature_etl.cfg'
    AS (out_column1 STRING, out_column2 BIGINT)
FROM
  db_name.tb_name
WHERE
  conds;
```

这里：

- column1 和 column2 是原始表 db_name.tb_name 中的列名字。

- TRANSFORM 子句表示 Hive 会将 column1 和 column2 以制表符 \t 分割拼成一个字符串传给用户指定的程序。
注意，如果 column1 或者 column2 当中包含制表符，则用户需要自行处理，Hive 对此不负责。

- USING 子句指示使用什么命令来处理输入。这里我们用 ./feature_etl --config_file=./feature_etl.cfg。
注意，使用 ADD FILE 导入的文件就在「当前目录」中。
另外，Hive 会像 Hadoop Streaming 任务那样，将数据通过标准输入传给用户指定的程序，并从标准输出读取输出。

- AS 子句指示用户程序的输出都有哪些列。
注意，用户程序的输出也应当是以制表符 \t 分割拼成的字符串；如果输出字符串中包含换行符，则会被 Hive 视作是输出了多条数据（一行变多行）。
另外，AS 子句当中可以指定列数据的类型，若不指定则默认都是字符串。Hive 会和往常一样去解析数据类型。

另外，Hive 也提供了 MAP 和 REDUCE 子句，同样可以使用用户自定程序处理数据。但是 MAP 和 REDUCE 其实只是 TRANSFORM 的别称，使用 MAP 并不一定会在 MapReduce 的 Map 阶段进行处理，使用 REDUCE 也是一样。因此，使用这两个子句难免有误导之嫌，不如不用，统一转向 TRANSFORM。

TRANSFORM 子句还有其他一些细节，可参考 [Apache 的 wiki 页](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Transform)。