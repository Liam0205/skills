---
title: "FTRL 不太简短之介绍"
url: https://liam.page/2019/08/31/a-not-so-simple-introduction-to-FTRL/
date: 2019-08-31
categories: ["Big Data and Machine Learning"]
tags: ["Logistic Regression", "FTRL", "Online Optimization"]
---

FTRL 是 Follow The Regularized Leader 的缩写，它是 Google 在 2010 -- 2013 年三年时间内，从理论研究到实际工程化实现的在线优化算法框架。FTRL 在处理带 $L_1$ 正则化的[逻辑回归](/2018/10/10/logistic-regression/)类模型时，效果非常出色：能够得到性能较好的稀疏解。

中文网络上，已有一些关于 FTRL 的介绍。比较详细和出名的是新浪微博的冯扬撰写的「在线最优化求解」。但在我看来，已有的关于 FTRL 的介绍，都或多或少有些值得调整和改进的地方。这促成了这篇文章。

这篇文章讲 FTRL 的理论部分，大致会按照这样的路径来阐述：

- 我们想要解决什么问题？

- FTRL 的前辈们是怎么尝试解决问题的？

- 前辈们之间是什么关系？又留下了哪些尚未解决的问题？FTRL 是如何解决这些遗留问题的？

而后，在下一篇工程部分的文章中，我们会讨论一下 FTRL 的工程实现有哪些值得谈一谈的问题。

## 我们面临的问题

传统的运用机器学习解决实际问题的步骤如下：

- 数据融合，获取数据样本的标签。

- 特征工程及其 ETL，获取每个样本的特征。

- 样本处理，处理正负样本比例、无效或作弊样本等问题，输出用于训练、验证、测试的样本集。

- 构建模型，根据业务特点和数据特点，选取恰当的模型；比如 LR、FM、GBDT、DNN 等。

- 训练模型，在训练集上训练模型，在验证集上调参。

- 模型评估，在测试机上评估模型。

- 在线预测，将有效模型上线，进行在线预测。

这样的流程能够解决很多问题，但存在至少两方面的瓶颈：

- 整套流程在样本维度是「批量」的，在特征高维数据大量的情况下，这导致模型更新周期较长。在工程能力强的团队手上，模型的更新周期最好能做到小时级别；在工程能力差的团队手上，这个周期可能是天级甚至是周级别的。

- 模型的复杂度和线上预测性能之间难以权衡：模型复杂度低，线上预测效果差；模型复杂度高，线上预测效果好，但需要的存储、时间资源也随之升高，无法保证 RT 和 QPS。

为了解决这里的问题 (1)，在线学习（Online Learning）逐渐兴起；为了解决问题 (2)，人们从各种正则、剪枝开始，尝试用各种手段，在保证模型精度的前提下，尽可能获得稀疏的模型。

### 在线学习的兴起

我曾经在多个场合谈到，机器学习模型的三要素是：

- 模型结构；

- 优化目标；

- 求解方法。

在这里，模型结构通常会需要根据实际问题的特点进行调整。例如，对于具有稠密特征样本的分类问题，GBDT 类的树模型往往效果良好。又例如，对于具有高维稀疏特征的大规模样本，[逻辑回归](/2018/10/10/logistic-regression/)和[因子分解机](https://liam.page/2019/03/25/Factorization-Machine/)（及其[变体](https://liam.page/2019/06/28/variants-of-FM/)）就会是不错的选择。

优化目标往往会以目标函数这一数学形式来表达。目标函数中的损失函数，则是用来描述「模型对经验数据拟合程度好坏」的方法。目标函数（或损失函数）的选择，通常也是和实际问题的特点相关的。例如对于回归问题和分类问题，通常就会选择不同的损失函数。

对于样本集合 $\mathcal{D}$ 中编号为 $i$ 的样本 $\{\vec x_i, y_i\}$ 来说，在确定好模型结构 $h(\cdot; \vec\omega)$ 的基础上，损失函数记为$$\ell\bigl(h(\vec x_i; \vec\omega), y_i\bigr).$$

求解方法则是解决如何在有限的时间内，求得一个既简单（模型复杂度低，不易过拟合）性能又好（对经验数据拟合程度较高）的模型。在模型结构确定的基础上，机器学习模型的学习，往往会化归为带参数目标函数的最优化求解问题。如何解决这些最优化问题，或者说，采用何种求解方法，往往要根据问题特点、模型结构、目标函数等等各种因素的不同，综合考虑。

#### 批量

在机器学习兴起的早期，由于数据规模较小，计算性能较低与求解复杂度较高的矛盾尚不明显，人们很自然地选择与直觉相符合的批量求解方式来优化模型。具体来说，人们通常会随机给定模型参数 $\vec\omega$ 的初值 $\vec\omega_0$，通过迭代，不断更新来调整 $\vec\omega$ 的取值，使得目标函数在样本集合 $\mathcal{D}$ 上的加和取得或接近最小值：

$$ \begin{aligned}   L(\vec\omega\mid \mathcal{D}) &{} = \sum_{\{\vec x_i, y_i\} \in \mathcal{D}}\ell\bigl(h(\vec x_i; \vec\omega), y_i\bigr) \\   \vec\omega^{*} &{} = \mathop{\arg\,\min}_{\vec\omega} L(\vec\omega\mid \mathcal{D}) \end{aligned} $$

对于这种解法，典型的方式是梯度下降（Gradient Descend）和牛顿法、拟牛顿法等。以梯度下降法为例，其 $t$ 轮迭代的更新如下所示：

$$ \vec\omega^{(t + 1)} \gets \vec\omega^{(t)} - \eta^{(t)}\cdot\nabla_{\vec\omega^{(t)}}L(\vec\omega^{(t)}\mid \mathcal{D}). $$

在这种做法当中，每一次迭代，都需要扫描整个样本集合 $\mathcal{D}$ 以计算全局损失 $L$，而后才能更新参数 $\vec\omega$。对于数据规模较小的情况，这样做的好处是能够准确计算每一次迭代时的梯度，避免「跑偏」。但对于随着数据规模的增大，每一次计算全局梯度的代价变得过高，完成训练的时间就会变得很长。为了解决这个问题，人们引入了随机（小批量）的解法。

#### 随机小批量

我在[强迫症患者也需要随机梯度下降](/2019/06/18/OCD-needs-stochastic-gradient-descent/)一文中介绍了随机（小批量）梯度下降（Stochastic Gradient Descend）的方法和它的好处。按照本文的记号约定，随机梯度下降第 $t$ 轮迭代的更新如下所示：

$$ \vec\omega^{(t + 1)} \gets \vec\omega^{(t)} - \eta^{(t)}\cdot\nabla_{\vec\omega^{(t)}}L(\vec\omega^{(t)}\mid \mathcal{D}^{(t)}). $$

这里描述的是随机小批量梯度下降。其中 $\mathcal{D}^{(t)}$ 是当前轮次的迭代从全部样本集 $\mathcal{D}$ 中随机选取的子集。当子集 $\mathcal{D}^{(t)}$ 当中只有 1 个元素时，算法退化为纯粹的随机梯度下降。

在这种做法当中，每一次迭代，无需扫描整个样本集合 $\mathcal{D}$ 以计算全局损失 $L$。取而代之的是，计算一个随机选取的小集合 $\mathcal{D}^{(t)}$ 中的局部损失，即可更新参数 $\vec\omega$。对于数据规模较大的情况，这样的做法节省了每次迭代的计算量，虽然代价是需要迭代更多轮次，但是总体来说极大地降低了整体的训练时间；与此同时，如[强迫症患者也需要随机梯度下降](/2019/06/18/OCD-needs-stochastic-gradient-descent/)一文中介绍的那样，随机梯度下降还能带来其它一些好处。

#### 在线学习

随机（小批量）的优化方法解决了一部分问题，但做到极限，模型的更新周期也只能缩短到小时级。因此，在线学习逐渐走上了舞台。

和前辈们相比，在线学习最大的特点（或者说需求）有两个：

- 每次只处理少数几个样本，甚至每次只处理一个样本；

- 处理过的样本对于优化过程来说会被「丢弃」，再也看不到了，因此在线学习需要一种「不吃后悔药」的优化方法。

回过头来看随机（小批量）梯度下降，我们发现它恰好能满足在线学习的这两方面需求。对于第一个需求来说，这是显然的。对于第二个需求来说，在线接收的样本某种意义上就可以理解为是一种随机，只要这些随机送到优化器的样本的梯度在统计期望上与总体样本是一致的（而这是在线学习的基本假设），那就适用随机（小批量）梯度下降。

事情看起来很美妙，只需要把随机（小批量）梯度下降整合进在线学习的工程框架当中就可以了。但是事情没有那么美妙，因为这依然无法解决我们面临的第二个问题——对模型稀疏性的追求。

### 对模型稀疏性的追求

#### 模型稀疏的好处

模型稀疏的好处有几个方面。

一是能解决之前提到的「模型复杂度低，线上预测效果差；模型复杂度高，线上预测效果好，但需要的存储、时间资源也随之升高，无法保证 RT 和 QPS」之问题。这是比较显然的。稀疏的模型会大大减少预测时的内存和复杂度。以 LR 为例，若已知输入向量的维度是 $d$ 而 LR 中不为 0 的参数的数量是 $w$，若 $d \gg w$，那么绝大多数特征甚至不需要去采集。这样一来，从特征采集到预测运算整个步骤都能省下很多内存和计算复杂度。

二是模型的稀疏与 $L_1$ 正则化不谋而合（见[谈谈 L1 与 L2-正则项](/2017/03/30/L1-and-L2-regularizer/)一文），这意味着运用 $L_1$ 正则化一方面可以使得模型变得稀疏，另一方面还能够降低模型过拟合的风险。

三是稀疏性较好的模型，相对来说可解释性更好。这对于我们来说，特别是在实际应用当中，是很有好处的。以那个经典的例子来解释，假设你现在需要训练一个模型，解释人的某些特征和罹患某种疾病之间的关系。如果模型稀疏，那么意味着，罹患某种疾病只与少数一些特征有关。这种模型，对于医生来说，是很友好的。因为当医生拿到一个人的指标数据（特征），他就能根据模型，很容易地告诉来访的就医者说：「你的 XX 指标比较高，而 YY 指标比较低，这是罹患 ZZ 疾病的高危因素。因此你需要在日常生活中注意某些方面，同时定期进行身体检查。」

#### 在批量梯度下降中，追求模型稀疏性

我们从最基本的批量梯度下降开始，逐步探寻如何解得一个稀疏的模型。

如[谈谈 L1 与 L2-正则项](/2017/03/30/L1-and-L2-regularizer/)一文所说的那样，我们只需将 $L_1$ 范数引入模型求解过程中的目标函数，即可获得相对稀疏的模型。注意，由于我们的终极目标是「稀疏」，这意味着要有尽可能多的权重项为 0。这样看起来，使用 $L_0$ 范数可能更好（向量 $\vec x$ 的 $L_0$ 范数 $\lVert \vec x\rVert_0$ 是向量 $\vec x$ 各维度中不为 0 的维度的数量）。但由于 $L_0$ 范数是非凸的，在求解优化上比较困难，故而采用 $L_0$ 范数的最紧凸放松，即 $L_1$ 范数作为替代。

这样一来，模型优化时需要最小化的目标函数变更为如下形式：

$$ \text{Obj}(\vec\omega\mid \mathcal{D}) = L(\vec\omega\mid \mathcal{D}) + \lambda_1\frac{\lVert \vec\omega\rVert_1}{n}, \quad\lambda_1 > 0. $$

这里，等式右边的第一项表示模型在训练集 $\mathcal{D}$ 上经验损失，第二项则表示模型的 $L_1$ 正则项。其中 $\lVert \vec\omega\rVert_1$ 表示向量 $\vec\omega$ 的 $L_1$ 范数，$n$ 表示向量 $\vec\omega$ 的维度。

那么为什么加入 $L_1$ 正则项，有助于产出稀疏解呢？

我们假设对于某个 $i \in \{1, 2, \ldots, n\}$ 来说，$\omega_i = 0$。然后，在接下来的迭代中，$\omega_i$ 被更新为 $\omega_i \gets 0 - \eta\frac{\partial \text{Obj}}{\partial \omega_i}$ 而其它参数保持不变。这意味着，对于 $L_1$ 正则项来说，在这一轮迭代中增加了 $\Delta\Omega = \eta\frac{\lambda_1}{n}\Bigl\lvert \frac{\partial \text{Obj}}{\partial \omega_i}\Bigr\rvert$；对于损失函数来说，在这一轮迭代中大约下降了 $\Delta L = \eta\Bigl\lvert \frac{\partial \text{Obj}}{\partial \omega_i}\Bigr\rvert\Bigl\lvert \frac{\partial L}{\partial \omega_i}\Bigr\rvert$。而如果 $\Delta L < \Delta\Omega$，即 $\Bigl\lvert \frac{\partial L}{\partial \omega_i}\Bigr\rvert < \frac{\lambda_1}{n}$，那么目标函数整体是变大了（而不是变小了）。因此，对于这种情况，优化器会拒绝更新 $\omega_i$，也就是拒绝将 $\omega_i$ 更新为非 0 值。由此就得到了相对稀疏的模型。

#### $L_1$ 正则在 SGD 中

注意，在批量梯度下降中，$L_1$ 正则项能有效的原因在于下式的成立：

$$\biggl\lvert \frac{\partial L}{\partial \omega_i}\biggr\rvert < \frac{\lambda_1}{n}.$$

但是，SGD 的假设（随机梯度的期望等于全局梯度）并不能保证在全局梯度满足上式的情况下，随机梯度总能使上式成立。这意味着，在 SGD 的场景中，使用 $L_1$ 正则化有助于提升模型的稀疏性，但并不能很好地保证有在批量梯度下降中的那种稀疏化效果。

那么问题就来了：按之前的说法，在线学习中，我们必然要依赖类似 SGD 的算法；但 $L_1$ 正则化并不能在 SGD 中确保模型是足够稀疏的。于是，**我们迫切需要找到一种能够满足在线学习的需要，同时又能保证模型稀疏性的优化方法**。

## FTRL 的前辈们

前面提到，加入 $L_1$ 正则项，是获得稀疏模型的主要手段；但由于 SGD 的原因，$L_1$ 正则项又很难发挥作用。因此，我们需要新的手段——或者在 $L_1$ 正则化的基础上改进，或者有全新的手段——来解决模型稀疏化的问题。完全创新总是比较困难的。事实上，目前也没有发现完全独立于 $L_1$ 范数同时又十分有效的稀疏化方法。因此，人们的目光还是更多地会聚焦在，如何基于 $L_1$ 正则项进行改进之上。

一个粗暴有简单的想法是：基于 $L_1$ 正则项，对模型参数进行截断。具体是这样做的，以 $k$ 轮迭代为一组：

- 按带 $L_1$ 正则项的 SGD 的方法训练 $k - 1$ 轮

- 在第 $k$ 轮迭代中，先按通常的 SGD 进行更新，得到 $\vec\omega^{(k')}$，然后对所有参数进行考察，以超参数 $\theta$ 进行截断置零：

$$\omega_i^{(k)} \gets \begin{cases} 0 & \text{if $\Bigl\lvert\omega_{i}^{(k')}\Bigr\rvert < \theta$,} \\ \omega_{i}^{(k')} & \text{otherwise.} \end{cases}$$

显然，这种做法太过粗暴，存在很多问题；但它是所有类似方法的祖师爷，反映的是「不等式约束下的凸优化」的思路。在这种思路下，求到的梯度 $g^{(t)} = \frac{\partial \text{Obj}}{\partial \omega_i}$ 被视作是次梯度（subgradient）。根据次梯度更新的结果，可能落在不等式约束的范围之外。此时，就要取该梯度在不等式约束范围内的投影作为真正的迭代结果。

简单截断法采取的投影方式，是直接截断。接下来，我们看看 FTRL 的其他前辈们是怎么做的。

### Truncated Gradient

既然简单地截断过于粗暴，那么我们就让截断温和一点。这就是 09 年提出的截断梯度法。

- 按带 $L_1$ 正则项的 SGD 的方法训练 $k - 1$ 轮

- 在第 $k$ 轮迭代中，先按通常的 SGD 进行更新，得到 $\vec\omega^{(k')}$，然后对所有参数进行考察，以超参数 $\theta$ 和 $\alpha$ 进行截断：

$$\omega_i^{(k)} \gets \begin{cases} 0& \text{if $\Bigl\lvert\omega_{i}^{(k')}\Bigr\rvert \leqslant \alpha$,} \\ \omega_{i}^{(k')} - \alpha\,\text{sgn}\Bigl(\omega_{i}^{(k')}\Bigr) & \text{if $\alpha < \Bigl\lvert\omega_{i}^{(k')}\Bigr\rvert \leqslant \theta$,} \\ \omega_{i}^{(k')} & \text{otherwise.} \end{cases}$$

这里 $\alpha$ 通常取学习率 $\eta^{(k)}$ 的倍数，例如 $\alpha^{(k)} = \eta^{(k)}\lambda$。截断梯度法采用的投影方式，是以分段函数的方式，对参数进行截断。

显然，$\alpha$ 或 $\theta$ 越大，模型越容易求得稀疏解。当 $\alpha = \theta$，TG 退化为简单截断法；当 $\theta = \infty$ 且 $k = 1$，在截断区域之外，TG 继续退化为 SGD-$L_1$，此时 $\omega_i$ 的更新是：

$$\omega_{i}^{(t + 1)} \gets \omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)} - \eta^{(t)}\lambda\,\text{sgn}\Bigl(\omega_{i}^{(t)}\Bigr).$$

### FOBOS (Forward-Backward Splitting)

FOBOS 最开始的名字叫做 Forward Looking Subgradients，简写叫做 FOLOS；后来改名叫做 Forward-Backward Splitting，按说应该简写成 FOBAS。但作者为了减少可能的困扰，就只修改了一个字母，变成了 FOBOS。

吐槽：但实际上，变得更加困惑了好不好……

FOBOS 可以看做是 TG 的改进。

首先，FOBOS 将 $k$ 设置为 1。如此一来，每一轮迭代都一样了：先根据次梯度做梯度下降，再做一步投影操作。

其次，FOBOS 将投影操作改进如下：

$$\vec\omega^{(t + 1)} \gets \mathop{\arg\,\min}_{\vec\omega}\biggl\{\frac{1}{2}\Bigl\lVert\vec\omega - \vec\omega^{t'}\Bigr\rVert^{2} + \eta^{(t')}\Omega(\vec\omega)\biggr\}.$$

这里，优化符号中的第一项保证了投影之后的结果距离梯度下降的结果不太远，第二项是正则项，用于产生稀疏性。我们将它转换为无约束优化的形式：

$$ \begin{aligned} \vec\omega^{(t + 1)} \gets{}& \mathop{\arg\,\min}_{\vec\omega}\biggl\{\frac{1}{2}\Bigl\lVert\vec\omega - \vec\omega^{(t)} + \eta^{(t)}\nabla\text{Obj}(\vec\omega^{(t)})\Bigr\rVert^{2} + \eta^{(t')}\Omega(\vec\omega)\biggr\},  \\ ={}& \vec\omega^{(t)} - \eta^{(t)}\nabla\text{Obj}(\vec\omega^{(t)}) - \eta^{(t')}\nabla\Omega(\vec\omega^{(t + 1)}). \end{aligned} $$

可见，更新结果不仅与上一轮迭代的结果有关（梯度下降），还与迭代之后的状态有关（正则约束），这就是所谓的 Forward-Backword Splitting。

当 $\Omega(\cdot) = \eta^{(t')}\lambda\lVert\cdot\rVert_1 = \tilde\lambda\lVert\cdot\rVert_1$ 时，我们将向量形式再化简到具体某一维度的更新：

$$ \begin{aligned} \omega_{i}^{(t + 1)} \gets{}& \text{sgn}\bigl(\omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)}\bigr)\cdot\max\Bigl\{0, \bigl\lvert \omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)} \bigr\rvert - \tilde\lambda\Bigr\}, \\ ={}& \begin{cases} 0 & \text{if $\lvert\omega_{i}^{(t')}\rvert < \tilde\lambda$,} \\ \omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)} - \tilde\lambda\,\text{sgn}\Bigl(\omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)}\Bigr) & \text{otherwise.} \end{cases} \end{aligned} $$

不难发现，它与 TG 的形式非常接近。当 TG 中的 $\theta = \infty$, $\alpha = \tilde\lambda$, $k = 1$ 时，TG 与 FOBOS 的唯一差别就在于惩罚项上。TG 是惩罚在迭代前的项上，FOBOS 是惩罚在经过次梯度迭代后的项上。

### RDA (Regularized Dual Averaging)

RDA 是微软 10 年发表的研究成果，其权重更新策略如下：

$$\vec\omega^{(t + 1)} \gets \mathop{\arg\,\min}_{\vec\omega}\biggl\{\frac{1}{t}\sum_{r = 1}^{t}\Bigl\langle \nabla\text{Obj}\bigl(\vec\omega^{(r)}\bigr), \vec\omega\Bigr\rangle + \Omega(\vec\omega) + \frac{\beta^{(t)}}{t}h(\vec\omega)\biggr\}.$$

这里，

- $\Bigl\langle \nabla\text{Obj}\bigl(\vec\omega^{(r)}\bigr), \vec\omega\Bigr\rangle$ 表示梯度 $\nabla\text{Obj}\bigl(\vec\omega^{(r)}\bigr)$ 对参数 $\vec\omega$ 的积分中值，即：第 $r$ 轮迭代中的梯度对参数 $\vec\omega$ 产生的变动在所有样本上产生的平均影响。

- $\frac{1}{t}\sum_{r = 1}^{t}\Bigl\langle \nabla\text{Obj}\bigl(\vec\omega^{(r)}\bigr), \vec\omega\Bigr\rangle$ 则是前 $r$ 轮迭代上述平均影响的平均值（Dual Average）。

- $\Omega(\vec\omega)$ 是正则项。

- $\frac{\beta^{(t)}}{t}h(\vec\omega)$ 是额外的正则项。
$\bigl\{\beta^{(t)}\mid t \geqslant 1\bigr\}$ 是一个非负的非降序列。
$h(\vec\omega)$ 是一个严格的凸函数。

除开正则项的变化，和 FOBOS 及之前的截断方法比较，RDA 最大的差别在于丢弃了梯度下降的那一项，换成了梯度的二次平均值。接下来，我们取

- $\Omega(\vec\omega) = \lambda\lVert\vec\omega\rVert_1$，其中 $\lambda > 0$；

- $h(\vec\omega) = \frac{1}{2}\lVert\vec\omega\rVert_2^2$；

- $\beta^{(t)} = \gamma\sqrt{t}$，其中 $\gamma > 0$。

记 $g_i^{(1:t)} = \frac{1}{t}\sum_{r = 1}^{t} g_i^{(r)}$，于是得到第 $i$ 维权重的更新：

$$ \omega_{i}^{(t + 1)} \gets \begin{cases} 0& \text{if $\bigl\lvert g_i^{(1:t)}\bigr\rvert < \lambda$,} \\ -\frac{\sqrt{t}}{\gamma}\Bigl(g_i^{(1:t)} - \lambda\,\text{sgn}\bigl(g_i^{(1:t)}\bigr)\Bigr) & \text{otherwise.} \end{cases} $$

可见，当某一维度参数的二次平均梯度小于阈值 $\lambda$ 时，这一维度被截断，产生稀疏性。

## FTRL (Follow The Regularized Leader)

接下来介绍 FTRL。

### FOBOS 和 RDA 的区别

为便于比较，这里把 FOBOS 和 RDA 在单一维度上的更新策略再次抄录如下。

\begin{equation} \omega_{i}^{(t + 1)} \gets \begin{cases} 0 & \text{if $\lvert\omega_{i}^{(t')}\rvert < \tilde\lambda$,} \\ \omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)} - \tilde\lambda\,\text{sgn}\Bigl(\omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)}\Bigr) & \text{otherwise.} \end{cases} \tag{FOBOS}\label{eq:FOBOS} \end{equation}

\begin{equation} \omega_{i}^{(t + 1)} \gets \begin{cases} 0& \text{if $\bigl\lvert g_i^{(1:t)}\bigr\rvert < \lambda$,} \\ -\frac{\sqrt{t}}{\gamma}\Bigl(g_i^{(1:t)} - \lambda\,\text{sgn}\bigl(g_i^{(1:t)}\bigr)\Bigr) & \text{otherwise.} \end{cases} \tag{RDA}\label{eq:RDA} \end{equation}

首先我们看 FOBOS 和 RDA 的截断部分的差异。

FOBOS 的截断判断取的是单次梯度下降的结果，而 RDA 的截断判断取的是往期所有梯度的二次平均。考虑到我们面临的是「在线学习」，样本在局部抖动的几率比较大。因此 FOBOS 的做法容易因为某些异常、离群样本的出现而错误地截断；RDA 的做法则稳妥许多，参考了过去所有样本的梯度结果。

FOBOS 的截断阈值是 $\tilde\lambda = \eta^{(t')}\lambda$。考虑到学习率 $\eta^{(t')}$ 往往会随着 $t$ 的增加而减小。故而 FOBOS 的截断阈值是不断减小的；与之相对，RDA 的截断阈值是固定的 $\lambda$。这说明，随着训练的进程，FOBOS 对截断的要求越放越松，因而 RDA 相对更容易得到稀疏解。

接下来我们看 FOBOS 和 RDA 截断之外部分的差异。

FOBOS 的取值主体是 $\omega_{i}^{(t)} - \eta^{(t)}g_{i}^{(t)}$，即梯度下降的结果，在此基础上做微调——向 0 的方向微调 $\tilde\lambda$ 步长。按「下山」的比喻，FOBOS 的取值，是在梯度反方向上下山，每次做一定的微调。RDA 的取值，主体是往期所有梯度的二次平均的缩放（$-\frac{\sqrt{t}}{\gamma}$），在此基础上做微调——向 0 的方向微调 $\lambda$。按同样的比喻，RDA 的取值，是在山顶上试探很多步，平均之后只走出一小步。从感性的认知来说，FOBOS 的准确度显然会更高一些。

这也就是说，FOBOS 的精度较高，但解的稀疏性相对较差；RDA 的解的稀疏性好，但精度较差。于是，很自然地，我们会问：**是否有办法，将二者的优点合在一起呢**？

### 统一 FOBOS 和 RDA 的形式

想要取长补短，就要想办法将 FOBOS 和 RDA 的形式统一起来。这样才方便拆墙补墙。

首先看 FOBOS 的无约束优化形式：

$$ \vec\omega^{(t + 1)} \gets \mathop{\arg\,\min}_{\vec\omega}\biggl\{\frac{1}{2}\Bigl\lVert\vec\omega - \vec\omega^{(t)} + \eta^{(t)}\vec g^{(t)}\Bigr\rVert^{2} + \eta^{(t)}\lambda\lVert\vec\omega\rVert_1\biggr\}. $$

注意，这里 $\vec g^{(t)} = \nabla\text{Obj}(\vec\omega^{(t)})$，并且令 $\eta^{(t')} = \eta^{(t)} = \frac{\gamma}{\sqrt{t}}$。我们将之按维度拆开：

$$ \begin{aligned} & \min_{\omega_i\in\mathbb{R}}\biggl\{\frac{1}{2}\Bigl\lVert\omega_i - \omega_i^{(t)} + \eta^{(t)}g_i^{(t)}\Bigr\rVert^{2} + \eta^{(t)}\lambda\lvert\omega_i\rvert\biggr\} \\ ={}& \min_{\omega_i\in\mathbb{R}}\biggl\{\omega_ig_i^{(t)} + \lambda\lvert\omega_i\rvert + \frac{1}{2\eta^{(t)}}\bigl(\omega_i - \omega_i^{(t)}\bigr)_2^2 + \biggl[ \frac{\eta^{(t)}}{2}\bigl(g_i^{(t)}\bigr)_2^2 + \omega_i^{(t)}g_i^{(t)} \biggr]\biggr\} \\ ={}& \min_{\omega_i\in\mathbb{R}}\biggl\{\omega_ig_i^{(t)} + \lambda\lvert\omega_i\rvert + \frac{1}{2\eta^{(t)}}\bigl(\omega_i - \omega_i^{(t)}\bigr)_2^2\biggr\}. \end{aligned} $$

再合并起来有，

$$ \begin{aligned} \vec\omega^{(t + 1)} \gets&{} \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec g^{(t)}\cdot\vec\omega + \lambda\lVert\vec\omega\rVert_1 + \frac{1}{2\eta^{(t)}}\bigl\lVert\vec\omega - \vec\omega^{(t)}\bigr\rVert_2^2\biggr\} \\ =&{} \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec g^{(t)}\cdot\vec\omega + \lambda\lVert\vec\omega\rVert_1 + \frac{1}{2}\sigma^{(1:t)}\bigl\lVert\vec\omega - \vec\omega^{(t)}\bigr\rVert_2^2\biggr\}. \end{aligned} $$

其中 $\sigma^{(t)} = \frac{1}{\eta^{(t)}} - \frac{1}{\eta^{(t - 1)}}$，以及 $\sigma^{(1:t)} = \sum_{r = 1}^{t}\sigma^{(r)} = \frac{1}{\eta^{(t)}}$（注意与 $\vec g^{(1:t)}$ 不同，$\sigma^{(1:t)}$ 在求和符号外没有 $\frac{1}{t}$）。类似地，对于 RDA 有：

$$ \vec\omega^{(t + 1)} \gets \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec G^{(1:t)}\cdot\vec\omega + t\lambda\lVert\vec\omega\rVert_1 + \frac{1}{2}\sigma^{(1:t)}\bigl\lVert\vec\omega - \vec 0\bigr\rVert_2^2\biggr\}. $$

这里 $\vec G^{(t)} = \vec g^{(t)}$，而 $\vec G^{(1:t)} = \sum_{r = 1}^{t}\vec G^{(t)} = t\cdot\vec g^{(1:t)}$。

### 拆墙补墙得到 FTRL

统一了 FOBOS 和 RDA 的形式之后，我们就可以将它们各自的优点拿出来了。

对于 FOBOS，它的优点体现在 $ \frac{1}{2}\sigma^{(1:t)}\bigl\lVert\vec\omega - \vec\omega^{(t)}\bigr\rVert_2^2$ 这一项上；对于 RDA，它的优点体现在 $\vec G^{(1:t)}\cdot\vec\omega$ 这一项上。于是，我们将这两项组合起来，得到的就是标准的 FTRL 了（11 年的论文中的原始版本）：

$$ \vec\omega^{(t + 1)} \gets \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec G^{(1:t)}\cdot\vec\omega + \lambda\lVert\vec\omega\rVert_1 + \frac{1}{2}\sum_{r = 1}^{t}\sigma^{(r)}\bigl\lVert\vec\omega - \vec\omega^{(r)}\bigr\rVert_2^2\biggr\}. $$

注意这里式中第 3 项与 FOBOS 的第三项稍有区别。我们还可以为它加上 $L_2$ 正则项，变成：

\begin{equation} \vec\omega^{(t + 1)} \gets \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec G^{(1:t)}\cdot\vec\omega + \lambda_1\lVert\vec\omega\rVert_1 + \frac{1}{2}\lambda_2\lVert\vec\omega\rVert_2^2 + \frac{1}{2}\sum_{r = 1}^{t}\sigma^{(r)}\bigl\lVert\vec\omega - \vec\omega^{(r)}\bigr\rVert_2^2\biggr\}. \tag{FTRL}\label{eq:FTRL} \end{equation}

### FTRL 更新公式的推导

我们将 \ref{eq:FTRL} 展开，得到

$$ \begin{aligned} \vec\omega^{(t + 1)} \gets{}& \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec G^{(1:t)}\cdot\vec\omega + \lambda_1\lVert\vec\omega\rVert_1 + \frac{1}{2}\lambda_2\lVert\vec\omega\rVert_2^2 + \frac{1}{2}\sum_{r = 1}^{t}\sigma^{(r)}\bigl\lVert\vec\omega - \vec\omega^{(r)}\bigr\rVert_2^2\biggr\} \\ ={}& \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec z^{(1:t)}\vec\omega + \lambda_1\lVert\vec\omega\rVert_1 + \frac{1}{2}\Bigl(\lambda_2 + \sum_{r = 1}^{t}\sigma^{(r)}\Bigr)\lVert\vec\omega\rVert_2^2 + \frac{1}{2}\sum_{r = 1}^{t}\sigma^{(r)}\lVert\vec\omega^{(r)}\rVert_2^2\biggr\} \\ ={}& \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec z^{(1:t)}\vec\omega + \lambda_1\lVert\vec\omega\rVert_1 + \frac{1}{2}\Bigl(\lambda_2 + \sum_{r = 1}^{t}\sigma^{(r)}\Bigr)\lVert\vec\omega\rVert_2^2\biggr\}. \end{aligned} $$

其中 $\vec z^{(t)} = \vec g^{(t)} - \sigma^{(t)}\cdot\vec\omega^{(t)}$，而 $\vec z^{(1:t)} = \sum_{r = 1}^{t}\vec z^{(r)}$。我们将之按维度拆开，有

\begin{equation} \min_{\omega_{i}\in\mathbb{R}}\biggl\{z_i^{(t)}\omega_{i} + \lambda_1\lvert\omega_i\rvert + \frac{1}{2}\Bigl(\lambda_2 + \sigma^{(1:t)}\Bigr)\omega_{i}^{2}\biggr\}. \label{eq:ftrl-one-dim} \end{equation}

式 \ref{eq:ftrl-one-dim} 是一个无约束的非平滑参数优化问题，其中第二项 $\lambda_1\lvert\omega_i\rvert$ 在 $\omega_i = 0$ 处不可导。假设 $\omega_i^*$ 是使式 \ref{eq:ftrl-one-dim} 得到最优解的 $\omega_i$ 的取值；定义 $\xi\in\partial\lvert\omega_i^*\rvert$ 是 $\lvert\omega_i\rvert$ 在 $\omega_i^*$ 处的次导数，于是有

\begin{equation} \partial\lvert\omega_i^*\rvert = \begin{cases} 1  & \text{if $\omega_i^* > 0$}, \\ {-1 < \xi < 1} & \text{if $\omega_i^* = 0$}, \\ -1 & \text{if $\omega_i^* < 0$}. \end{cases} \label{eq:ftrl-subgradient} \end{equation}

根据式 \ref{eq:ftrl-subgradient} 定义的次导数，对式 \ref{eq:ftrl-one-dim} 待优化的部分求导，令其为零，得到方程：

\begin{equation} z_i^{(t)} + \lambda_1\cdot\xi + \bigl(\lambda_2 + \sigma^{(1:t)}\bigr)\omega_{i}^* = 0. \label{eq:ftrl-equation} \end{equation}

式 \ref{eq:ftrl-equation} 中，$\lambda_1 > 0$ 且 $\bigl(\lambda_2 + \sigma^{(1:t)}\bigr) > 0$。对 $z_i^{(t)}$ 的取值进行分类讨论：

- 当 $\bigl\lvert z_i^{(t)}\bigr\rvert < \lambda_1$ 时，有 $\omega_i^{*} = 0$。因为若不然：
当 $\omega_i^{*} < 0$，有 $\xi = -1$。式 \ref{eq:ftrl-equation} 左边有 $z_i^{(t)} - \lambda_1 + \bigl(\lambda_2 + \sigma^{(1:t)}\bigr)\omega_{i}^* < z_i^{(t)} - \lambda_1 < 0$，与式 \ref{eq:ftrl-equation} 矛盾。
当 $\omega_i^{*} > 0$，有 $\xi = 1$。式 \ref{eq:ftrl-equation} 左边有 $z_i^{(t)} + \lambda_1 + \bigl(\lambda_2 + \sigma^{(1:t)}\bigr)\omega_{i}^* > z_i^{(t)} + \lambda_1 > 0$，与式 \ref{eq:ftrl-equation} 矛盾。

- 当 $z_i^{(t)} > \lambda_1$ 时，有 $\omega_i^{*} = -\frac{1}{\lambda_2 + \sigma^{(1:t)}}\bigl(z_i^{(t)} - \lambda_1\bigr) < 0$。因为若不然：
当 $\omega_i^{*} = 0$，由式 \ref{eq:ftrl-equation} 知 $\xi = -\frac{z_i^{(t)}}{\lambda_1} < -1$，与式 \ref{eq:ftrl-subgradient} 矛盾。
当 $\omega_i^{*} > 0$，与 $\bigl\lvert z_i^{(t)}\bigr\rvert < \lambda_1$ 的情况类似，与式 \ref{eq:ftrl-equation} 矛盾。

- 当 $z_i^{(t)} < -\lambda_1$，类似分析，有 $\omega_i^{*} = -\frac{1}{\lambda_2 + \sigma^{(1:t)}}\bigl(z_i^{(t)} + \lambda_1\bigr) > 0$。

如此一来，我们得到 FTRL 的更新公式：

\begin{equation} \omega_i^{(t + 1)} = \begin{cases} 0 & \text{if $\lvert z_i^{(t)}\rvert < \lambda_1$}, \\ -\frac{1}{\lambda_2 + \sigma^{(1:t)}}\bigl(z_i^{(t)} - \text{sgn}(z_i^{(t)})\lambda_1\bigr) & \text{otherwise}. \end{cases} \label{eq:ftrl-updates} \end{equation}

从式 \ref{eq:ftrl-updates} 来看，加入 $L_2$ 正则，没有影响模型的稀疏性，而只是使得参数的取值趋向零。

### FTRL 为什么是有效的

我们引出 FTRL 是按「稀疏性」的路径，从 FOBOS 和 RDA 拆借出来的。从上面的推导，我们能看出 FTRL 能够较好地获得稀疏解。但是，我们仍未能说明，FTRL 能够获得较好的稀疏解。（大家来找茬，笑）这一小节里，我们来说明 FTRL 是有效的。

首先回顾一下 SGD 的更新公式：

\begin{equation} \vec\omega_i^{(t + 1)} \gets \vec\omega_i^{(t)} - \eta^{(t)}\vec g^{(t)}. \label{eq:sgd} \end{equation}

我们丢掉式 \ref{eq:FTRL} 中有关 $L_1$ 和 $L_2$ 正则相关的部分，有

\begin{equation} \vec\omega^{(t + 1)} \gets \mathop{\arg\,\min}_{\vec\omega}\biggl\{\vec G^{(1:t)}\cdot\vec\omega + \frac{1}{2}\sum_{r = 1}^{t}\sigma^{(r)}\bigl\lVert\vec\omega - \vec\omega^{(r)}\bigr\rVert_2^2\biggr\}. \label{eq:ftrl-pure} \end{equation}

记式 \ref{eq:ftrl-pure} 中待优化的部分为 $f(\vec\omega)$。对其求导，有：

\begin{equation} \frac{\partial f(\vec\omega)}{\partial\vec\omega} = \vec G^{(1:t)} + \sum_{r = 1}^{t}\sigma^{(r)}\bigl(\vec\omega - \vec\omega^{(r)}\bigr). \label{eq:ftrl-pure-gradient} \end{equation}

当式 \ref{eq:ftrl-pure-gradient} 为 0 时的 $\vec\omega$，式 \ref{eq:ftrl-pure} 取得极值。此即有

\begin{equation} \begin{aligned} \vec G^{(1:t)} + \sum_{r = 1}^{t}\sigma^{(r)}\bigl(\vec\omega^{(t + 1)} - \vec\omega^{(r)}\bigr) ={}& 0 \\ \sigma^{(1:t)} \vec\omega^{(t + 1)} ={}& \sum_{r = 1}^{t}\sigma^{(r)} \vec\omega^{(r)} - \vec G^{(1:t)} \end{aligned} \label{eq:ftrl-pure-gradient-equation} \end{equation}

在式 \ref{eq:ftrl-pure-gradient-equation} 中，以 $t - 1$ 替换 $t$，得到

\begin{equation} \sigma^{(1:t - 1)} \vec\omega^{(t)} = \sum_{r = 1}^{t - 1}\sigma^{(r)} \vec\omega^{(r)} - \vec G^{(1:t - 1)} \label{eq:ftrl-pure-gradient-equation-minus} \end{equation}

用式 \ref{eq:ftrl-pure-gradient-equation} 减去式 \ref{eq:ftrl-pure-gradient-equation-minus} 得到

\begin{equation} \begin{aligned} \sigma^{(1:t)} \vec\omega^{(t + 1)} - \sigma^{(1:t - 1)} \vec\omega^{(t)} ={}& \sigma^{(t)}\vec\omega^{(t)} - \vec g^{(t)} \\ \sigma^{(1:t)} \vec\omega^{(t + 1)} ={}& \sigma^{(1:t)} \vec\omega^{(t)} - \vec g^{(t)} \end{aligned} \label{eq:ftrl-sgd-equiv} \end{equation}

考虑 $\sigma^{(1:t)} = \frac{1}{\eta^{(t)}}$，化简式 \ref{eq:ftrl-sgd-equiv} 即得到式 \ref{eq:sgd}。这也就是说，FTRL 去掉 $L_1$ 和 $L_2$ 部分后，和 SGD 是等价的。这说明 FTRL 能够较好地获得稀疏解并且能够获得较好的稀疏解。