---
title: "谈谈期望最大算法"
url: https://liam.page/2018/11/08/Expectation-Maximization-Algorithm/
date: 2018-11-08
categories: ["Big Data and Machine Learning"]
tags: ["EM"]
---

本篇讨论期望最大算法算法（Expecation Maximization Algorithm，EM 算法）。

## 从极大似然估计到 EM 算法

EM 算法和极大似然有着很深的联系。因此在讨论 EM 算法之前，我们首先通过一个例子来回顾极大似然算法。

### 极大似然

#### 问题描述

假设有一枚硬币 A；投掷硬币 A 后结果为正面的概率记为 $p$。我们将投掷硬币结果为正面的实验记作 $1$，反面的实验记作 $0$。独立重复 $n = 10$ 次实验，观测结果如下：

$$1, 1, 0, 1, 0, 0, 1, 0, 1, 1.$$

现在的问题是要估计投掷硬币 A 后结果为正面的概率 $p$。

#### 整理似然函数和对数似然函数

显而易见，投掷硬币 A 后的结果应当服从二项分布。于是我们可以整理似然函数：

$$L(\theta) = L(x_1, x_2, \ldots, x_{10} \mid \theta) = \prod_{i = 1}^{10} p(x_i\mid \theta) = p^{6}(1 - p)^{4}.$$

由于连乘不方便分析和优化，因此我们对似然函数取对数，构造对数似然函数，将连乘转换为连加。

$$H(\theta) = \ln L(\theta) = \sum_{i = 1}^{10}\ln p(x_i \mid \theta) = (\ln p)^{6}\cdot\bigl(\ln (1 - p)\bigr)^{4}.$$

#### 求解极大化问题

根据似然函数或者对数似然函数，构造极大化问题。此处以似然函数为例：

$$\hat \theta = \underset{\theta}{\arg,\max} L(\theta).$$

对于这类简单的似然函数，我们可以对它求导，令导数为 $0$，而后得到参数值；对于复杂的似然函数极大化问题，我们可以用牛顿法、拟牛顿法、梯度上升法等方法求解。此处

$$\frac{\mathop{}\!\mathrm{d}L(\theta)}{\mathop{}\!\mathrm{d}\theta} = \frac{\mathop{}\!\mathrm{d}L}{\mathop{}\!\mathrm{d}p} = 2p^{5}(1 - p)^{3}(3 - 5p).$$

令导函数为 $0$，得到似然方程

$$2p^{5}(1 - p)^{3}(3 - 5p) = 0$$

对似然方程的三个不重复解代入原函数依次验证，可知当 $p = \frac{3}{5}$ 时原函数取得极大值。此即为所求。

#### 总结

极大似然估计的一般方法可以记录如下：

- 极大似然估计，估计的目标是随机变量服从分布的参数；因此在使用极大似然估计法之前，必须假定数据服从的分布。

- 根据分布和实验结果，列出似然函数或者对数似然函数；

- 求解似然函数或者对数似然函数的极大化问题；

- 对于不同的（对数）似然函数，采取不同的求解方法——例如可以采用牛顿法、拟牛顿法、梯度上升法等方法，也可以求导直接求解。

### EM 算法

#### 问题描述

我们考虑一个复杂一些的问题。

现在假设我们有 A, B, C 三枚硬币；三枚硬币投掷后结果为正面的概率分别记为 $\pi$, $p$, $q$。现在我们规定这样一种实验：先抛 A 硬币，若 A 硬币为正面，则继续抛 B 硬币并记录结果；若 A 硬币为反面，则继续抛 C 硬币并记录结果。独立重复 $n = 10$ 次实验，观测结果如下：

$$1, 1, 0, 1, 0, 0, 1, 0, 1, 1.$$

现在的问题是要估计三枚硬币投掷后结果为正面的概率 $\pi$, $p$, $q$。

#### 问题分析、生成模型与似然函数

参考上一节关于极大似然估计法的讨论。如果我们能知道 10 次独立重复实验中，哪一些是由 B 硬币确定的最终结果，哪一些是由 C 硬币确定的最终结果；那么我们就可以对他们分别采用极大似然估计，确定 B、C 两枚硬币的二项分布参数。但是由于硬币 A 的分布参数不确定，反过来我们又必须先知道 B、C 两枚硬币取得正面的分布参数，才能说某一个结果更可能来自 B 硬币还是 C 硬币。

这是一个鸡生蛋蛋生鸡的问题，看起来不好解决。脑壳疼啊脑壳疼。以下我们用概率的语言来表述这个问题。

我们引入两个随机变量 $y$ 和 $z$。此处 $y$ 表示一次投币实验的结果，而 $z$ 表示一次投币实验中间硬币 A 的结果。于是，三硬币问题的生成模型是

$$\begin{aligned}     p(y \mid \theta) = {}& \sum_{z} p(y, z\mid \theta) \\                      = {}& \sum_{z} p(z \mid \theta)p(y \mid z, \theta) \\                      = {}& \pi p^{y} (1 - p)^{1 - y} + (1 - \pi)q^{y}(1 - q)^{1 - y}. \end{aligned}\tag{*}\label{star}$$

如此有似然函数

$$\begin{aligned}     L(\theta) = {}& p(Y\mid\theta) \\               = {}& \prod_{i = 1}^{n} \pi p^{y_i} (1 - p)^{1 - y_i} + (1 - \pi)q^{y_i}(1 - q)^{1 - y_i}. \end{aligned}$$

考虑求模型参数 $\theta = (\pi, p, q)$ 的极大似然估计

$$\hat \theta = \underset{\theta}{\arg\,\max} \ln L(\theta).$$

这种「鸡生蛋蛋生鸡」的问题，$(\pi, p, q)$ 参数之间互相制约，因此这个优化问题很难求得解析解。因此，针对极大似然估计法的常用解法在这里都会失效，而只能用迭代的方式求解。EM 算法是其中一种迭代算法。

#### EM 迭代

我们刚才说，如果能确定三硬币模型的参数，那么我们就能知道观测数据 $y_i$ 来自硬币 B 或 C 的概率。知道了这个概率，我们又可以反过来去推算三硬币模型的参数。这种鸡生蛋蛋生鸡的问题，总得有个头啊。因此，在 EM 算法迭代过程中，我们需要为模型参数设置一个初始值，而后不断循环迭代。以下是以三硬币模型为例，表述 EM 算法的迭代过程。

- 选取参数的初始值，记为 $\theta^{(0)} = (\pi^{(0)}, p^{(0)}, q^{(0)})$；

- 迭代至参数值变化不大为止
E 步，根据第 $i - 1$ 轮的参数，计算隐变量 $z$ 的概率 $\mu^{(i)}_j = p\bigl(z_j\mid \theta^{(i - 1)}\bigr)$（即 $y_{j}$ 来自硬币 B 的概率）；
M 步，根据隐变量的概率，计算模型参数新的估计值 $$\begin{aligned}  \pi^{(i)} = {}& \frac{1}{n} \sum_{j = 1}^{n}\mu_j^{(i)}; \\  p^{(i)}   = {}& \frac{\sum_{j = 1}^{n}\mu_j^{(i)}y_j}{\sum_{j = 1}^{n}\mu_j^{(i)}}; \\  q^{(i)}   = {}& \frac{\sum_{j = 1}^{n}\bigl(1 - \mu_j^{(i)}\bigr)y_j}{\sum_{j = 1}^{n}\bigl(1 - \mu_j^{(i)}\bigr)}.  \end{aligned}$$

#### 实际计算看看

我们假定初值 $\theta^{(0)} = (\pi^{(0)} = 0.5, p^{(0)} = 0.5, q^{(0)} = 0.5)$。

第一轮迭代：

- E 步：$\mu^{(1)_j} = p\bigl(z_j\mid \theta^{(0)}\bigr) = \frac{\pi^{(0)} \bigl(p^{(0)}\bigr)^{y_j}\bigl(1-p^{(0)}\bigr)^{1 - y_j}}{\pi^{(0)}\bigl(p^{(0)}\bigr)^{y_j}\bigl(1 - p^{(0)}\bigr)^{1 - y_j} + \bigl(1 - \pi^{(0)}\bigr)\bigl(q^{(0)}\bigr)^{y_j}\bigl(1 - q^{(0)}\bigr)^{1 - y_j}} = 0.5$

- M 步：$$\begin{aligned}   \pi^{(1)} = {}& \frac{1}{n} \sum_{j = 1}^{n}\mu_j^{(1)} = 0.5; \\   p^{(1)}   = {}& \frac{\sum_{j = 1}^{n}\mu_j^{(1)}y_j}{\sum_{j = 1}^{n}\mu_j^{(1)}} = 0.6; \\   q^{(1)}   = {}& \frac{\sum_{j = 1}^{n}\bigl(1 - \mu_j^{(1)}\bigr)y_j}{\sum_{j = 1}^{n}\bigl(1 - \mu_j^{(1)}\bigr)} = 0.6. \end{aligned}$$

第二轮迭代：

- E 步：$\mu^{(2)_j} = p\bigl(z_j\mid \theta^{(1)}\bigr) = \frac{\pi^{(1)} \bigl(p^{(1)}\bigr)^{y_j}\bigl(1-p^{(1)}\bigr)^{1 - y_j}}{\pi^{(1)}\bigl(p^{(1)}\bigr)^{y_j}\bigl(1 - p^{(1)}\bigr)^{1 - y_j} + \bigl(1 - \pi^{(1)}\bigr)\bigl(q^{(1)}\bigr)^{y_j}\bigl(1 - q^{(1)}\bigr)^{1 - y_j}} = 0.5$

- M 步：$$\begin{aligned}   \pi^{(2)} = {}& \frac{1}{n} \sum_{j = 1}^{n}\mu_j^{(2)} = 0.5; \\   p^{(2)}   = {}& \frac{\sum_{j = 1}^{n}\mu_j^{(2)}y_j}{\sum_{j = 1}^{n}\mu_j^{(2)}} = 0.6; \\   q^{(2)}   = {}& \frac{\sum_{j = 1}^{n}\bigl(1 - \mu_j^{(2)}\bigr)y_j}{\sum_{j = 1}^{n}\bigl(1 - \mu_j^{(2)}\bigr)} = 0.6. \end{aligned}$$

考虑到 $\theta^{(1)} = \theta^{(2)} = (\pi = 0.5, p = 0.6, q = 0.6)$，参数已趋于稳定，故而迭代结束。

注意，EM 算法迭代的结果是对初值敏感的。例如，对于三硬币模型，若初值取 $\theta^{(0)} = (\pi^{(0)} = 0.4, p^{(0)} = 0.6, q^{(0)} = 0.7)$，则迭代结果为 $\hat\theta = \bigl(\hat{\pi}=0.4064, \hat{p}=0.5368, \hat{q} = 0.6432\bigr)$。

## EM 算法的理论推导

### 数学工具

#### 凸函数

定义在实数域上的一元函数 $f(x)$，若对于定义域内的任意自变量都成立不等式 $f''(x) \geqslant 0$，则称该函数是凸函数；若严格成立不等式 $f''(x) > 0$，则称该函数是严格凸函数。

定义在实数域上的多元函数 $f(x_1, x_2, \ldots, x_n)$，若对于定义域内的任意自变量其海森矩阵是半正定的，则称该函数是凸函数；若海森矩阵是正定的，则称该函数是严格凸函数。

#### 期望

对于连续随机变量 $X$，若其概率密度函数为 $f(x)$，则其期望定义为

$$E[X] = \int_{-\infty}^{+\infty} x\cdot f(x)\mathop{}\!\mathrm{d}x.$$

设随机变量 $Y = g(X)$，则其期望是

$$E[Y] = \int_{-\infty}^{+\infty} g(x)\cdot f(x)\mathop{}\!\mathrm{d}x.$$

#### 琴生（Jensen）不等式

假设 $\mu$ 是集合 $\Omega$ 的正测度，并且 $\mu(\Omega) = 1$。又设 $g$ 是勒贝格（Lebesgue）可积的实值函数，而 $\varphi$ 是定义在 $\mathbb{R}$ 上的凸函数，则成立琴生不等式

$$\varphi\Bigl(\int_{\Omega} g\mathop{}\!\mathrm{d}\mu\Bigr) \leqslant \int_{\Omega}\varphi\circ g\mathop{}\!\mathrm{d}\mu.$$

以概率论的语言来说，$\mu$ 显然是个概率测度。此时，若 $g$ 表示随机变量 $X$，则在 $\Omega$ 上，随机变量相对概率测度的积分其实是期望。此时，琴生不等式转化为

$$\varphi\bigl(E[X]\bigr) \leqslant E\bigl(\varphi[X]\bigr).$$

### 问题的数学表述

对于 $m$ 个相互独立的样本 $x_1$, $x_2$, ..., $x_m$，有观测数据 $y_1$, $y_2$, ..., $y_m$，以及隐含数据 $z_1$, $z_2$, ..., $z_m$。此时，$(y)$ 为不完全数据，而 $(y, z)$ 是完全数据。

面对不完全数据建立的概率模型（\ref{star} 式）会含有隐变量：

$$\begin{aligned}     H(\theta) = {}& L(\theta) \\               = {}& \ln p(Y \mid \theta) \\               = {}& \ln \sum_{z} p(Y, Z\mid \theta) \\               = {}& \ln \Bigl(\sum_{z} p(Z \mid \theta)p(Y \mid Z, \theta)\Bigr) \end{aligned}$$

因此，极大化问题事实上变成了

$$\hat\theta, \hat z = \underset{\theta, z}{\arg\,\max}H(\theta, z).$$

此时，若以极大似然估计的解法思路，对 $\theta$ 和 $z$ 求导，而后直接求解极大似然方程或者梯度上升，其表达式会非常复杂。因此，很难求得它的解析解。

### 构造似然函数下界

我们的目的是极大化（对数）似然函数 $H(\theta)$。因此对于第 $i + 1$ 轮迭代，我们希望找到新的 $\theta$ 使得 $H\bigl(\theta\bigr) > H\bigl(\theta^{(i)}\bigr)$。

因此，我们考虑（凹函数的）琴生不等式

$$\begin{aligned}     H(\theta) = {}& \ln \Bigl(\sum_{z} p(Z \mid \theta)p(Y \mid Z, \theta)\Bigr) \\               = {}& \ln \biggl(\sum_{z}p(Z\mid Y, \theta^{(i)}) \cdot \frac{p(Z \mid \theta)p(Y \mid Z, \theta)}{p(Z\mid Y, \theta^{(i)})}\biggr) \\               \geqslant {}& \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \biggl(\frac{p(Z \mid \theta)p(Y \mid Z, \theta)}{p(Z\mid Y, \theta^{(i)})}\biggr). \end{aligned}$$

注意到 $\sum_{z} p(Z\mid Y, \theta^{(i)}) = 1$，于是考虑做差

$$\begin{aligned}     H(\theta) - H(\theta^{(i)}) \geqslant {}& \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \biggl(\frac{p(Z \mid \theta)p(Y \mid Z, \theta)}{p(Z\mid Y, \theta^{(i)})}\biggr) - \ln p(Y\mid \theta^{(i)}) \\                                 = {}& \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \biggl(\frac{p(Z \mid \theta)p(Y \mid Z, \theta)}{p(Z\mid Y, \theta^{(i)}) p(Y\mid \theta^{(i)})}\biggr). \end{aligned}$$

于是，令

$$B\bigl(\theta,\theta^{(i)}\bigr) \overset{\text{def}}{=} H(\theta^{(i)} + \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \biggl(\frac{p(Z \mid \theta)p(Y \mid Z, \theta)}{p(Z\mid Y, \theta^{(i)}) p(Y\mid \theta^{(i)})}\biggr),$$

则有 $H(\theta) \geqslant B\bigl(\theta,\theta^{(i)}\bigr)$，并且有 $H\bigl(\theta^{(i)}\bigr) = B\bigl(\theta^{(i)},\theta^{(i)}\bigr)$。因此，实际上我们已经构造了 $H(\theta)$ 的一个下界 $B\bigl(\theta,\theta^{(i)}\bigr)$，即完成了 E 步。接下来，我们要想办法提升这个下界（M 步）。

### 优化目标

考虑到提升 $B\bigl(\theta,\theta^{(i)}\bigr)$ 就能提升 $H(\theta)$。原始的优化问题转化为：

$$\begin{aligned}     \theta^{(i + 1)} = {}& \underset{\theta}{\arg\,\max} B\bigl(\theta,\theta^{(i)}\bigr) \\                      = {}& \underset{\theta}{\arg\,\max} \Biggl[H\bigl(\theta^{(i)}\bigr) + \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \biggl(\frac{p(Z \mid \theta)p(Y \mid Z, \theta)}{p(Z\mid Y, \theta^{(i)}) p(Y\mid \theta^{(i)})}\biggr)\Biggr] \\                      = {}& \underset{\theta}{\arg\,\max} \Biggl[\sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \bigl(p(Z \mid \theta)p(Y \mid Z, \theta)\bigr) + H\bigl(\theta^{(i)}\bigr) - \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \bigl(p(Z\mid Y, \theta^{(i)}) p(Y\mid \theta^{(i)})\bigr)\Biggr] \\                      = {}& \underset{\theta}{\arg\,\max} \Biggl[\sum_{z} p(Z\mid Y, \theta^{(i)}) \ln \bigl(p(Z \mid \theta)p(Y \mid Z, \theta)\bigr) \Biggr] \qquad\text{// 省略相对 $\theta$ 的常数项} \\                      = {}& \underset{\theta}{\arg\,\max} \Biggl[\sum_{z} p(Z\mid Y, \theta^{(i)}) \ln p(Y, Z \mid \theta) \Biggr] \end{aligned}$$

于是，令

$$Q(\theta, \theta^{(i)}) \overset{\text{def}}{=} \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln p(Y, Z \mid \theta).$$

这即是在 M 步我们需要优化的目标。

### EM 迭代算法

- 输入：观测变量数据 $Y$，隐变量数据 $Z$，给定参数 $\theta$ 时观测变量和隐变量的联合分布 $p(Y, Z\mid\theta)$，给定观测变量和参数 $\theta$ 时隐变量 $Z$ 的条件分布 $p(Z\mid Y, \theta)$。

- 输出：模型参数 $\theta$。

- 设置参数初值 $\theta^{(0)}$。

- 开始迭代，直至 $\theta$ 收敛：
E 步，计算 $$Q(\theta, \theta^{(i)}) \overset{\text{def}}{=} \sum_{z} p(Z\mid Y, \theta^{(i)}) \ln p(Y, Z \mid \theta).$$
M 步，解最优化问题 $$\theta^{(i + 1)} = \underset{\theta}{\arg,\max} Q(\theta, \theta^{(i)}).$$

可见，在模型输入中包含联合分布和条件分布。这印证了我们之前说的：「EM 算法同极大似然法一样，需要预先假定分布」。

### EM 算法的收敛性

考虑 EM 算法在迭代过程中产生的参数估计序列 ${\theta^{(i)}}$，以及据此计算的对数似然函数序列 ${H(\theta^{(i)}) = \ln p(Y\mid\theta^{(i)} = B(\theta^{(i)}, \theta^{(i)})}$。

考虑到在 EM 迭代算法中有：

$$B(\theta^{(i + 1)}, \theta^{(i + 1)}) \geqslant B(\theta^{(i + 1)}, \theta^{(i)}) \geqslant B(\theta^{(i)}, \theta^{(i)}).$$

因此，上述对数似然函数序列是单调递增的。又考虑到似然函数是概率，故而上述对数似然函数序列有上界。根据单调有界原理，上述对数似然函数序列必然收敛。不过，这并不意味着参数的估计序列 ${\theta^{(i)}}$ 必然收敛。因此，在实际使用过程中，EM 算法的终止条件除了 $\bigl\lVert\theta^{(i + 1)} - \theta^{(i)}\bigr\rVert < \varepsilon_1$ 之外，还应包含 $\bigl\lVert Q\bigl(\theta^{(i + 1)}, \theta^{(i)}\bigr) - Q\bigl(\theta^{(i)}, \theta^{(i)}\bigr)\bigr\rVert < \varepsilon_2$。

此外，由于 EM 算法对初值敏感。故而，尽管 EM 算法能保证收敛，但不保证一定能收敛到全局最优解。因此，使用 EM 算法时，往往需要设置多个初值，估计多套模型参数。最后再将模型参数代入模型，比较模型的效果，选出其中最好的作为最终结果。