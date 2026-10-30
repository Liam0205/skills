---
title: "在 C++ 中利用反射，动态获取 Protobuf 结构中的字段"
url: https://liam.page/2020/06/29/Dynamic-Get-Fields-in-Protobuf-by-Their-Name-in-Cpp/
date: 2020-06-29
categories: ["Algorithm and Computer Science"]
tags: ["Protobuf", "Reflection"]
---

最近在实际业务中，我遇到了这样一类问题。

首先，我们定义了一个通用类，比如 message Feature。然后，在一个大的特征分组中，我们定义了若干个特征。比如

```proto
message FooGroup {
  Feature foo = 1;
  Feature bar = 2;
  Feature baz = 3;
}
```

但在实际使用中，我们需要根据配置文件，有筛选地选出其中的某几个来使用——比如选择使用 foo 和 baz。为此，我们会传递 "foo" 和 "baz" 给函数 get_feature，并期待它能返回 const Feature&，分别装着 foo 和 baz 的常量引用。

查阅 Protobuf 的文档之后发现，使用描述器（Descriptor）、字段描述器（FieldDescriptor）和反射（Reflection）来实现该功能。

## 函数原型

我们的 get_feature 函数的原型应该形如：

```cpp
const Feature& get_features(const FooGroup& group, const std::string& name);
```

## 描述器

Protobuf 的描述器定义在头文件 [descriptor.h](https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.descriptor)。为了使用描述器，你需要引用相应的头文件：

```cpp
#include <google/protobuf/descriptor.h>
```

Protobuf 的描述器包含了通过 Protobuf 定义的消息类的相关信息。这实际上实现了所谓的「自省」（Introspection）。对于一个具体的消息类对象，可以使用 GetDescriptor() 接口来获取其描述器。例如：

```cpp
const google::protobuf::Descriptor* des = group.GetDescriptor();
```

## 字段描述器

Protobuf 的字段描述器也定义在头文件 [descriptor.h](https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.descriptor) 当中，它包含了对于消息类中某个字段的描述。在概念上，近似于 C++ 中类的成员指针。

由于消息类中某个字段的描述也属于消息类的描述的一部分，因此我们需要通过消息类的描述器来获取其中字段的描述器。

```cpp
const google::protobuf::Descriptor* des = group.GetDescriptor();
const google::protobuf::FieldDescriptor* fdes = des->FindFieldByName("foo");
```

这里，FindFieldByName 接口接受一个 const std::string&，并查找描述器对应的消息类中，是否有相应名称的字段。如果存在，则返回相应的字段描述器。如果不存在，则返回 nullptr。注意，这里的 FindFieldByName 是大小写敏感的。

这样一来，我们就获取了 FooGroup 这个消息类当中字段 foo 的字段描述器（近似理解成 C++ 中的类成员指针）。

## 反射

Protobuf 的反射定义在头文件 [message.h](https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.message) 当中。为了使用它，你需要引用相应的头文件：

```cpp
#include <google/protobuf/message.h>
```

Protobuf 的反射定义了一系列接口，用以在运行时动态地访问、修改消息类中的成员。对于一个具体的消息类对象，可以用 GetReflection() 接口来获取其反射。例如：

```cpp
const google::protobuf::Reflection* ref = group.GetReflection();
```

然后，就可以通过反射提供的一系列接口来访问消息类中的字段了。由于我们需要获取 const Feature&，所以我们需要用到 const Message& GetMessage(const Message & message, const FieldDescriptor * field, MessageFactory * factory = nullptr) const 这个接口。注意到，它返回的是 const Messasge&。这里 Message 是所有 Protobuf 消息类的父类。于是，我们可以在获取到它之后，通过 dynamic_cast<const Feature&> 将 Message 的常量引用动态转换成 Feature 的常量引用。

```cpp
dynamic_cast<const Feature&>(ref->GetMessage(group, fdes));
```

## 完整实现

如此，我们就能给出完整实现了：

```cpp
const Feature& get_feature(const FooGroup& group, const std::string& name) {
  const google::protobuf::Descriptor* des = group.GetDescriptor();
  const google::protobuf::FieldDescriptor* fdes = des->FindFieldByName(name);
  assert(fdes != nullptr);  // in case of typo or something.
  const google::protobuf::Reflection* ref = group.GetReflection();
  return dynamic_cast<const Feature&>(ref->GetMessage(group, fdes));
}
```