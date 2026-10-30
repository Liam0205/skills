---
title: "谈谈逻辑回归模型"
url: https://liam.page/2018/10/10/logistic-regression/
date: 2018-10-10
categories: ["Big Data and Machine Learning"]
tags: ["Logistic Regression", "Classification", "Likelihood"]
---

逻辑回归（Logistic Regression）是最简单的分类算法之一，但是在很多领域中都被广泛应用。对于大多数人来说，逻辑回归（Logistic Regression）大概是入门机器学习时学习的第一个算法。然而，并不是每个人都能讲清这个算法。这便是本文的缘由。

## Logistic 函数

### 原函数

Sigmoid 函数是所有函数图像为 S-形的函数的统称。Logistic 函数是形如下式定义的函数

$$\sigma(x;\alpha) = \frac{1}{1 + \exp(-\alpha\cdot x)}.$$

此处 $\alpha$ 是函数的参数，它调整函数曲线的形状。当参数 $\alpha = 1$ 时，它的函数曲线如下图所示，因而它是一个 Sigmoid 函数。

![](/uploads/images/MachineLearning/logistic_curve.png)

当 $\alpha$ 增大时，函数曲线在 $x$ 轴方向压缩，函数曲线越接近阶梯函数。反之，当 $\alpha$ 减小时，函数曲线在 $x$ 轴方向拉伸。通常，我们可以直接使用 $\alpha = 1$ 的 Logistic 函数，即：

$$\sigma(x) = \frac{1}{1 +\exp(-x)}.$$

### 导函数

Logistic 函数的导函数具有很好的形式，具体来说：

$$\begin{aligned}    \sigma'(x) ={}& \biggl(\frac{1}{1 +\exp(-x)}\biggr)' \\               ={}& -\frac{1}{\bigl(1 +\exp(-x)\bigr)^2}\cdot\exp(-x)\cdot(-1) \\               ={}& \frac{1}{1 +\exp(-x)}\cdot\frac{\exp(-x)}{1 +\exp(-x)} \\               ={}& \sigma(x)\bigl(1 - \sigma(x)\bigr)\end{aligned}$$

### 模拟概率

由于 Logistic 函数的值域是 $(0, 1)$ 且便于求导，它在机器学习领域经常被用来模拟概率。

具体来说，假设二分类模型有判别函数 $z = f(\vec x;\vec  w)$。其表意为：当输出值 $z$ 越大，则 $\vec x$ 代表的样本为正例的概率越大；当输出值 $z$ 越小，则 $\vec x$ 代表大样本为负例的概率越大。此时，考虑到 Logistic 函数的值域，我们可以用 $P(\vec x) = \sigma\Bigl(f(\vec x;\vec  w)\Bigr)$ 来表示 $\vec x$ 代表的样本为正例的概率。同时，由于 Logistic 函数便于求导，只要我们选用了合适的损失函数（例如交叉熵损失函数），我们就可以方便地将梯度下降法运用在求解参数向量 $\vec w$ 之上。

## 二分类的逻辑回归模型

### 线性判别函数

在上一节讨论使用 Logistic 函数模拟概率时，我们没有限制判别函数 $f(\vec x;\vec w)$ 的形式。考虑到判别函数的形式取决于模型的结构，这也就是说，我们没有限制模型的结构。事实上，对于分类问题，我们可以用任意结构的模型得到的判别函数，代入 Logistic 函数得到对概率的模拟，再引入交叉熵损失函数进行优化求解。

在讨论逻辑回归模型时，我们一般假定模型是线性的，也就是判别函数是线性函数：

$$f(\vec x;\vec w) = -\vec w\cdot\vec x.$$

### 定义条件概率

于是，我们可以定义条件概率：

$$\begin{aligned}    P(Y = 1\mid X = \vec x) ={}& \sigma(-\vec w\cdot\vec x), \\    P(Y = 0\mid X = \vec x) ={}& 1 - \sigma(-\vec w\cdot\vec x).\end{aligned}$$

考虑正负例定义的对称性，我们也可以反过来将条件概率定义为：

$$\begin{aligned}    \pi(\vec x) \overset{\text{def}}{=} P(Y = 1\mid X = \vec x) ={}& 1 - \sigma(-\vec w\cdot\vec x) = \frac{\exp(\vec w\cdot\vec x)}{1 + \exp(\vec w\cdot\vec x)}, \\    P(Y = 0\mid X = \vec x) ={}& \sigma(-\vec w\cdot\vec x) = \frac{1}{1 + \exp(\vec w\cdot\vec x)}.\end{aligned}$$

这即是经典的逻辑回归模型中条件概率的定义。

### 几率与对数几率

事件的几率（odds）是该事件发生的概率与不发生的概率的比值。即，若假设事件发生的概率为 $p$，则其几率为

$$\text{odds} \overset{\text{def}}{=} \frac{p}{1 - p}.$$

对于逻辑回归的条件概率 $P(Y = 1\mid X = \vec x)$ 来说，它的几率是

$$\text{odds}(Y = 1\mid X = \vec x) = \exp(\vec w\cdot\vec x).$$

于是它的对数几率（logit）是

$$\text{logit}(Y = 1\mid X = \vec x) \overset{\text{def}}{=} \ln \text{odds}(Y = 1\mid X = \vec x) = \vec w\cdot \vec x = -f(\vec x).$$

这就是说，在逻辑回归模型中，线性判别函数 $f$ 实际上是事件发生几率的相反数。

### 似然与对数似然

条件概率确定之后，即可求模型在训练集上的似然。显然，这是一个二项分布的问题：

$$L(\vec w) \overset{\text{def}}{=} \prod_i\bigl[\pi(\vec x_i)\bigr]^{y_i}\bigl[1 - \pi(\vec x_i)\bigr]^{1 - y_i}.$$

对连乘进行最优化求解往往是困难的，因此我们可以在其上加上对数变换，将似然函数中的连乘转换为连加来求解。考虑到对数变换是单调的，它不会影响最优化求解结果的正确性。

$$\begin{aligned}    \ln L(\vec w) \overset{\text{def}}{=}{}& \sum_i y_i\ln\pi(\vec x_i) + (1 - y_i)\ln\bigl(1 - \pi(\vec x_i)\bigr), \\        ={}& \sum_i y_i\ln\frac{\pi(\vec x_i)}{1 - \pi(\vec x_i)} + \ln\bigl(1 - \pi(\vec x_i)\bigr), \\        ={}& \sum_i y_i\cdot\vec w\cdot\vec x_i - \ln\bigl(1 + \exp(\vec w\cdot\vec x_i)\bigr).\end{aligned}$$

于是，逻辑回归模型的最优化问题就化归为：

$$\vec{ w^{*}} = \underset{\vec w}{\arg,\max} \ln L(\vec w).$$

此处应用的是极大似然估计。极大似然估计法使用的前提是要知道或者假设数据总体的分布。此处显然数据服从二项分布。

### 最大似然与最小损失

最大似然是站在统计学的角度求解模型。站在机器学习的角度，则应当用最小损失的办法求解优化问题。

考虑对样本 $(\vec x, y)$ 的交叉熵损失函数：

$$\begin{aligned}    \ell(\vec w) \overset{\text{def}}{=}{}& -y\ln P(Y = y\mid X = \vec x) - (1 - y)\ln\bigl[1 - P(Y = y\mid X = \vec x)\bigr], \\        ={}& -y\ln \pi(\vec x) - (1 - y)\ln\bigl[1 - \pi(\vec x)\bigr]\end{aligned}$$

于是有在全部训练集上的损失：

$$\begin{aligned}    J(\vec w) \overset{\text{def}}{=}{}& \sum_i -y_i\ln \pi(\vec x_i) - (1 - y_i)\ln\bigl[1 - \pi(\vec x_i)\bigr], \\    ={}& \sum_i \ln\bigl(1 + \exp(\vec w\cdot\vec x_i)\bigr) - y_i\cdot\vec w\cdot\vec x_i, \\    ={}& -\ln L(\vec w).\end{aligned}$$

这也就是说，对于逻辑回归模型来说，最小化损失函数与最大化（对数）似然是等价的。

### 梯度下降求解

至此，我们可以用梯度下降法求解模型。基本步骤如下：

- 求解梯度，选择下降方向 $\nabla J(\vec w_{(i - 1)})$；

- 线性搜索，选择步长 $\rho^*_{(i)} = \underset{\rho}{\arg\,\min} J\bigl(\vec w_{(i - 1)} - \rho\cdot\nabla J(\vec w_{(i - 1)})\bigr)$；

- 更新参数，使用学习率收缩步长 $\vec w_{(i)} = \vec w_{(i - 1)} - \eta\rho^{*}_{(i)}\cdot\nabla J(\vec w_{(i - 1)})$。

### 正则化

当模型的参数很多时，往往需要加入正则项以防止过拟合。我们可以使用[前文](/2017/03/30/L1-and-L2-regularizer/)中提到的 $L_p$-正则项，于是我们有目标函数：

$$ \text{Obj}(\vec w) \overset{\text{def}}{=} J(\vec w) + \lambda_p\cdot\lVert\vec w\rVert_p. $$

## 多分类的逻辑回归模型

将上述二分类的逻辑回归模型推广到多分类时，即得到所谓的 Softmax 模型。它将二分类的 Logistic 函数升级为 Softmax 函数。也就是说，条件概率的形式如下：

$$ P(Y = i\mid X = x, \vec w) \overset{\text{def}}{=} \frac{\exp(\vec w_i\cdot \vec x)}{\sum_j^K \exp(\vec w_j\cdot \vec x)}. $$

而后我们可以类似地得到损失函数，并套用梯度下降等方法求解。此处略去。