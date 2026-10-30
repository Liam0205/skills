---
title: "100 行代码实现 PageRank 算法"
url: https://liam.page/2017/04/04/Python-100-lines-of-PageRank/
date: 2017-04-04
categories: ["Big Data and Machine Learning"]
tags: ["Python", "Search Engine", "PageRank", "Ranking"]
---

搜索引擎是现代互联网的基础设施之一，而 ranking 则是搜索引擎的需要解决的核心问题。

最早尝试对搜索结果进行 ranking 的应该是 Yahoo 公司，但最终革命性突破的是 Google 公司的 Larry Page 与 Sergey Brin 发明的 PageRank 算法。

## 简介

PageRank 算法的表述很简单，大体上只需要几句话就能表述清楚（不包含一些细微的修正）：

- 将整个互联网，看做一张有向图
网页是图上的点
链接是图上的有向边

- 每个网页都有一个权威性得分，称作 PageRank，可以把它当做是一种「投票权」

- 将每一个超链接作为一次「投票」
每个网页的 PageRank 等于所有具有指向该网页超链接的网页的 PageRank 的加权和
这些权值等于这些网页各自向外链接数目的倒数

PageRank 算法的高明之处，我认为有两点：

- 在表述上清晰明了，所谓简单就是美；

- 将互联网作为一个整体来对待，暗合系统论的观点。

按照《数学之美》（吴军）的说法，PageRank 的算法思想主要来自于 Larry Page，而 Sergey Brin 则将其转化为矩阵的迭代运算并证明其收敛性（解决了鸡生蛋生鸡的悖论）。

## Python 实现

以下是用 Python 实现的 PageRank 算法——当然，没有做任何计算上的优化，仅用于展现算法本身。

原始数据下载：[https://course.ccs.neu.edu/cs6200f14/wt2g_inlinks](https://course.ccs.neu.edu/cs6200f14/wt2g_inlinks)；需要预处理。

```python
class Vertex:
    def __init__(self):
        self.in_degree = 0
        self.out_degree = 0
        self.pagerank = 0.0

class Edge:
    def __init__(self, start, end):
        self.start_id = start
        self.end_id = end

def addVertex(vertex_name, vtx_map):
    '''
    return the id of vertex_name
    if exists in vtx_map, return directly
    if not exists, add it, and then return

    vertex_name: string, the url of a web page
    vtx_map: dict, the map from url to id
    '''
    res_id = 0
    if vertex_name in vtx_map:
        return vtx_map[vertex_name]
    else:
        res_id = len(vtx_map)
        vtx_map[vertex_name] = res_id
    return res_id

def readTable(fname, vtx_map, edge_list):
    '''
    read fname line by line, update the vtx_map and edge_list

    fname: string, the file name of the table
    vtx_map: dict, the map from url to id
    edge_list: list, the list of all edges
    '''
    with open(fname, 'r') as fin:
        for line in fin.readlines():
            tmp = line.strip().split('\t')
            assert(len(tmp) == 2)
            start = addVertex(tmp[0], vtx_map)
            end = addVertex(tmp[1], vtx_map)
            edge_list.append(Edge(start, end))
    return None

def initialize(vtx_map, edge_list, vtx_list):
    '''
    initialize the data structures

    vtx_map: dict, the map from url to id
    edge_list: list, the list of all edges
    vtx_list: list, the list of all vertices
    '''
    vtx_num = len(vtx_map)
    assert(vtx_num > 0)
    vtx_list = [Vertex() for _ in range(vtx_num)]
    for i in range(vtx_num):
        vtx_list[i].pagerank = 1.0 / vtx_num
    for edge in edge_list:
        vtx_list[edge.start_id].out_degree += 1
        vtx_list[edge.end_id].in_degree += 1
    return None

def calcPagerank(alpha, num_iter, vtx_map, edge_list):
    '''
    calc PageRank for all vertices
    return: vtx_list, list, the list of all vertices

    alpha: float, damping factor
    num_iter: int, the upper limitation of calculation
    vtx_map: dict, the map from url to id
    edge_list: list, the list of all edges
    '''
    vtx_list, pr_list = list(), list()
    initialize(vtx_map, edge_list, vtx_list)
    vtx_num = len(vtx_list)
    assert(vtx_num > 0)
    alpha = float(alpha)
    for _ in range(num_iter):
        pr_list = [alpha / vtx_num for _ in range(vtx_num)]
        # calc
        for edge in edge_list:
            pr_list.append((1 - alpha) * vtx_list[edge.start_id].pagerank / \
                        vtx_list[edge.start_id].out_degree)
        # revise
        revise = sum(map(lambda vtx: (1 - alpha) * vtx.pagerank / vtx_num, \
                        filter(lambda vtx:(vtx.out_degree == 0), vtx_list)))
        # update
        for i in range(vtx_num):
            vtx_list[i].pagerank = pr_list[i] + revise
    return vtx_list

def doCalcPageRank(fname = 'wt2g_inlinks.source', alpha = 0.15, num_iter = 30):
    vtx_map = dict()
    edge_list = list()
    readTable(fname, vtx_map, edge_list)
    return calcPagerank(alpha, num_iter, vtx_map, edge_list)

if __name__ == '__main__':
    print doCalcPageRank()
```