---
title: "利用 Protobuf 中 oneof 的特性生成 has_xxx 接口"
url: https://liam.page/2020/05/05/using-oneof-to-generate-has-xxx-in-pb3/
date: 2020-05-05
categories: ["Algorithm and Computer Science"]
tags: ["Protobuf", "Protobuf 3"]
---

Protobuf（全称 Protocal Buffer，简称 pb）是 Google 开源的序列化/反序列化工具，在工业界相当流行。pb3 相比 pb2 的一个显著变化，就是在 pb3 当中不再区分 required 和 optional 字段。与此同时，在 pb2 中针对 optional 基本类型字段设计的 [default = foobar] 的默认值功能和 has_xxx() 的接口也随之消失。这样引出来一个问题，即：

- 在多数场景下，「未设置」和「取值为 0/0.0/""/false」等价；但是

- 在某些场景下，「未设置」和上述取值不等价。

特别地，在序列化 - 反序列化之后，如果拿到一个零值，你无法得知这个值是确实为零值，还是说因为没有显示设置而得到的零值。本文在 C++ 场景下来解决这个问题。

## oneof

Protobuf 提供了 oneof 功能（见[文档](https://developers.google.com/protocol-buffers/docs/reference/cpp-generated#oneof)）。其本意是想实现 C/C++ 当中 union 的功能，即多个不同类型共享存储空间，但同一时间只有一个类型有实际值。但在实现的过程中，Protobuf 做了一些妥协。例如，对于下面这样定义的 message 来说，

```proto
message FooMessage {
  string id = 1;
  oneof oneof_name {
    int32 bar = 2;
    int64 baz = 3;
  }
}
```

在生成的类当中，会有一个名为 OneofNameCase 的枚举类型来标记 oneof_name 字段的设置状态——你可以用 oneof_name_case() 接口来获取该状态。若状态取 ONEOF_NAME_NOT_SET 说明 oneof_name 未设置，若状态取 kBar/kBaz 其意义不言自明。

```cpp
enum OneofNameCase {
  kBar = 2,
  kBaz = 3,
  ONEOF_NAME_NOT_SET = 0
}
```

## 文档未注明的特性

对比开发文档和 pb3 的源码，我们发现 pb3 会为 oneof 字段生成一个 has_xxx() 的接口，其实现正是内联了 return xxx_case() != XXX_NOT_SET;。

注意到其命名策略，我们只需定义一个**只含有一个字段的同名 oneof**就能方便地判断了。例如：

```proto
message FooMessage {
  string id = 1;
  oneof bar {
    int32 bar = 2;
  }
}
```

此时，Protobuf 会生成 has_bar() 这个接口。于是，利用这一特性，我们就可以在反序列化之后来判断字段是否有设置过了。