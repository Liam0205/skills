---
title: "XGBoost 在计算 NDCG 时的特殊处理"
url: https://liam.page/2016/12/21/XGBoost-idealDCG-and-NDCG/
date: 2016-12-21
categories: ["Big Data and Machine Learning"]
tags: ["NDCG", "LambdaMART", "XGBoost", "Gradient Boosting"]
---

XGBoost 是陈天奇（怪）领衔开发的一套 Gradient Boost 算法实现，比如我会用到它做 LambdaMART 的实验。如果要给它一个评价，那应该是：好用、耐操。

不过，也有甜蜜的烦恼。XGBoost 在每轮迭代后，能够贴心地给出模型在数据集上的指标。比如我会关心 NDCG 指标。然而，这里列印出来的指标，会比事后用标准算法计算出来的值要高不少。

最后，经检查（这里包含了血与泪），是 XGBoost 对 idealDCG 为 0 时的默认处理方式与标准算法不同导致的。标准算法，当 idealDCG 为 0 时，当前 NDCG 给 0；而 XGBoost 给 1，于是 XGBoost 计算出的最终 NDCG 要比标准算法计算得到的大不少。这件事情在 XGBoost 的文档里没有说明，所以称其为一个坑。

解决方法也很简单，在传参的时候，修改一下即可。

```python
# before
'eval_metric': 'ndcg@10'
# after
'eval_metric': 'ndcg@10-'
```

没错，只需要加一个减号就行了……

并附链接：

- XGBoost：[https://github.com/dmlc/xgboost](https://github.com/dmlc/xgboost)

- 陈天奇怪：[http://weibo.com/u/2397265244](http://weibo.com/u/2397265244)

- LambdaMART: [LambdaMART 不太简短之介绍](/2016/07/10/a-not-so-simple-introduction-to-lambdamart/)