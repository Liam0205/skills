---
title: "在 Python 中使用 wbdata 库获取世界银行的数据"
url: https://liam.page/2017/04/04/get-data-from-World-Bank-in-Python-within-the-wbdata-module/
date: 2017-04-04
categories: ["Algorithm and Computer Science"]
tags: ["Python", "Matplotlib", "World Bank", "wbdata", "Pandas"]
---

世界银行（英语：World Bank）是为发展中国家资本项目提供贷款的联合国系统国际金融机构。它是世界银行集团的组成机构之一，同时也是联合国发展集团（UNDP）的成员。世界银行的官方目标为消除贫困。根据其有关协定规定（修订并于1989年2月16日生效），其所有决定都必须旨在推动外商直接投资和国际贸易，以及为资本投资提供便利。

为了方便世界各国的研究人员，世界银行免费公开了世界各国的发展数据。应当说，这是一份详实而权威的数据。

此篇介绍如何在 Python 中使用 wbdata 库获取世界银行的数据。

## 安装

对于 Python，我们假设你已经安装好。不过，这里还是要多嘴一句，对于科学研究特别是数据科学的研究者，我们推荐使用 [Anaconda](/2015/11/21/Python-distribution-Anaconda/) 作为你的发行版。

若安装好了 Python，那么只需要在系统命令行执行下列命令，即可安装所需的 wbdata 库。

```bash
pip install wbdata
```

## 数据库介绍

[世界银行的公开数据库](http://data.worldbank.org.cn/)，允许用户从几个维度进行浏览：

- 国家（contry）：世界银行的各个成员体，并不严格限于「国家」的概念，还包括各种经济体。

- 指标（indicator）：世界银行提供了国家发展层面的各个指标。

- 专题（topic）：世界银行将数据库分成了几个专题（比如：农业、经济与增长、贸易……）。

- 来源（source）：世界银行将数据库从来源分类（比如：非洲发展指标、世界范围内的统治指标……）。

wbdata 库在以上四个层面，提供了 get 函数，用以列出世行提供的所有条目；同时在国家和指标层面，提供了 search 函数，用以检索所需的国家和指标。

## 一个典型的交互过程

从这里开始，我们将在 Python 的交互模式下做实验。我们推荐使用 iPython 作为交互模式，并假设你已经 import 了相关的 Python 库（wbdata, pandas, datetime 等等）。

如前所述，我们可以使用几个 get 函数查看世行提供的数据类别。默认情况下，这些函数会直接将结果打印在标准输出上。如果希望将返回的数据储存在一个数据结构里，我们可以传入 display = False 参数。

```python
In [13]: wbdata.get_source()
11  Africa Development Indicators
36  Statistical Capacity Indicators
31  Country Policy and Institutional Assessment (CPIA)
41  Country Partnership Strategy for India
26  Corporate Scorecard
1   Doing Business
...
43  Wealth accounting
2   World Development Indicators
3   Worldwide Governance Indicators

In [14]: wbdata.get_country()
...
UZB Uzbekistan
VCT St. Vincent and the Grenadines
VEN Venezuela, RB
VGB British Virgin Islands
VIR Virgin Islands (U.S.)
VNM Vietnam
VUT Vanuatu
WLD World
WSM Samoa
XKX Kosovo
XZN Sub-Saharan Africa excluding South Africa and Nigeria
YEM Yemen, Rep.
ZAF South Africa
ZMB Zambia
ZWE Zimbabwe

In [20]: topics = wbdata.get_topic(display = False)

In [21]: type(topics)
Out[21]: list

In [22]: type(topics[0])
Out[22]: dict

In [23]: print topics[0]
{u'id': u'1', u'value': u'Agriculture & Rural Development', u'sourceNote': u"For the 70 percent of the world's poor who live in rural areas, agriculture is the main source of income and employment. But depletion and degradation of land and water pose serious challenges to producing enough food and other agricultural products to sustain livelihoods here and meet the needs of urban populations. Data presented here include measures of agricultural inputs, outputs, and productivity compiled by the UN's Food and Agriculture Organization."}
```

这些代码，展现了世行数据库的冰山一角，但已足见世行数据库的强大了。

接下来，我们看看 serach 函数如何使用。比如我们想检索和中国以及美国相关的数据，特别关注的是人均 GDP。首先我们试着检索中国和美国在世行数据库里的缩写。

```python
In [27]: wbdata.search_countries('china')
CHN China
HKG Hong Kong SAR, China
MAC Macao SAR, China
TWN Taiwan, China

In [28]: wbdata.search_countries('united')
ARE United Arab Emirates
GBR United Kingdom
USA United States
```

通过 search_countries 函数，我们很容易地就能找到中国和美国对应的缩写分别为 CHN 和 USA。如果你希望查询其他国家的数据，在这里也可以很简单地检索到。

接下来，我们希望查询人均 GDP 的相关情况。我们知道人均 GDP 的英文写法是 GDP per capita（如果你不知道，那么你应该补补课了），我们试着在世行的数据库里检索和人均 GDP 相关的指标。

```python
In [29]: wbdata.search_indicators('GDP per capita')
GDPPCKD                     GDP per Capita, constant US$, millions
GDPPCKN                     Real GDP per Capita (real local currency units, various base years)
NV.AGR.PCAP.KD.ZG           Real agricultural GDP per capita growth rate (%)
NY.GDP.PCAP.CD              GDP per capita (current US$)
NY.GDP.PCAP.KD              GDP per capita (constant 2000 US$)
NY.GDP.PCAP.KD.ZG           GDP per capita growth (annual %)
NY.GDP.PCAP.KN              GDP per capita (constant LCU)
NY.GDP.PCAP.PP.CD           GDP per capita, PPP (current international $)
NY.GDP.PCAP.PP.KD           GDP per capita, PPP (constant 2005 international $)
NY.GDP.PCAP.PP.KD.ZG        GDP per capita, PPP annual growth (%)
SE.XPD.PRIM.PC.ZS           Expenditure per student, primary (% of GDP per capita)
SE.XPD.SECO.PC.ZS           Expenditure per student, secondary (% of GDP per capita)
SE.XPD.TERT.PC.ZS           Expenditure per student, tertiary (% of GDP per capita)
```

我们注意到，其中有一个名为 NY.GDP.PCAP.PP.CD 的指标。它的含义是：人均 GDP 占比按实际购买力折算之后以美元计价的值。听起来是一个高大上的指标，不是吗？我们试着以它为例，获取所需的数据。

wbdata 提供了 get_data 函数，用以获取数据。

```python
In [50]: res = wbdata.get_data('NY.GDP.PCAP.PP.CD', country = ['CHN', 'USA'])

In [51]: type(res)
Out[51]: list

In [52]: type(res[0])
Out[52]: dict

In [53]: print res[0]
{u'date': u'2016', u'country': {u'id': u'CN', u'value': u'China'}, u'indicator': {u'id': u'NY.GDP.PCAP.PP.CD', u'value': u'GDP per capita, PPP (current international $)'}, u'decimal': u'1', u'value': None}
```

Pandas 是 Python 里处理数据表格常用的库，wbdata 提供了对 Pandas 良好的支持。

```python
In [56]: countries = ['CHN', 'USA']
    ...: indicators = {'NY.GDP.PCAP.PP.CD' : 'GDP per capita, PPP (current international $)'}
    ...: dt = (datetime.datetime(2000, 1, 1), datetime.datetime(2017, 1, 1))
    ...: df = wbdata.get_dataframe(indicators, country = countries, convert_date = False, data_date = dt)
    ...:

In [57]: df
Out[57]:
                    GDP per capita, PPP (current international $)
country       date
China         2016                                            NaN
              2015                                   14450.174744
              2014                                   13439.907642
              2013                                   12367.965864
              2012                                   11351.062843
              2011                                   10384.367317
              2010                                    9333.124882
              2009                                    8374.432850
              2008                                    7635.073139
              2007                                    6863.982229
              2006                                    5883.719784
              2005                                    5092.560189
              2004                                    4455.205330
              2003                                    3961.274167
              2002                                    3551.663897
              2001                                    3226.848680
              2000                                    2933.315020
United States 2016                                            NaN
              2015                                   56115.718426
              2014                                   54539.665575
              2013                                   52749.911240
              2012                                   51433.047090
              2011                                   49781.800656
              2010                                   48374.086793
              2009                                   47001.555350
              2008                                   48401.427340
              2007                                   48061.537661
              2006                                   46437.067117
              2005                                   44307.920585
              2004                                   41921.809762
              2003                                   39677.198348
              2002                                   38166.037841
              2001                                   37273.618103
              2000                                   36449.855116
```

接下来，我们可以使用 [matplotlib](/2014/09/11/matplotlib-tutorial-zh-cn/) 将中美两国的指标绘制出来。

```python
In [63]: dfu = df.unstack(level = 0)
    ...: dfu.plot()
    ...: plt.legend(loc = 'best')
    ...: plt.title('GDP per capita, PPP (current international $)')
    ...: plt.xlabel('Year')
    ...: plt.ylabel('GDP per capita, PPP (current international $)')
    ...: plt.show()
    ...:
```

如此我们得到图像。

![](/uploads/images/python/gdp_per_captia_ppp_usd.png)

## 小结

上一节中，我们介绍了人们使用 wbdata 与世行数据库交互的典型步骤。据此，你应该能获取到大多数你想要的数据。

关于 wbdata 更多的介绍，你可以参考它的[官方文档](http://wbdata.readthedocs.io/en/latest/wbdata.html)。

关于 matplotlib，你可以在[前作](/2014/09/11/matplotlib-tutorial-zh-cn/)中找到相关用法的介绍。