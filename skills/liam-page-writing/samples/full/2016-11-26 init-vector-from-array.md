---
title: "从硬编码的数组中初始化 vector 容器"
url: https://liam.page/2016/11/26/init-vector-from-array/
date: 2016-11-26
categories: ["Algorithm and Computer Science"]
tags: ["Cpp", "Vector", "Array"]
---

这是一篇简单的记录，因为我总是忘记如何从硬编码的 Array 中初始化得到一个 Vector。

```c++
#include <vector>

using std::vector;

int main () {
    const int arr[] = {16,2,77,29};
    vector<int> vec (arr, arr + sizeof(arr) / sizeof(arr[0]));
    return 0;
}
```