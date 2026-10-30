---
title: "编写 iOS 越狱插件：速览 Objective-C"
url: https://liam.page/2023/01/21/Build-an-iOS-Jailbreak-Tweak-Objective-C-the-quick-start/
date: 2023-01-21
categories: ["Jailbreak and Reverse Engineering"]
tags: ["Language", "Objective-C"]
---

Objective-C 在很长时间内都是 iOS 上的主流编程语言。2014 年 Apple 发布 Swift 之后，这一情况才逐渐改变。但是，在开发 Tweak 时，用得更多的依旧是 Objective-C。因此有必要对 Objective-C 有一个快速的了解。

这里假定你对 C-like 语言有一个较为全面的了解。若你是 C/C++ 的熟练使用者则更好。

## 简介

Objective-C 是 C 语言的严格超集。即是说，在 C 编译器下能够编译的代码，应当可以不加修改地使用 Objective-C 的编译器来编译。（尽管可能行为不完全相同）另一方面，在 Objective-C 当中，可以混合使用 C 风格的代码。

## 文件扩展名

头文件
实现文件

C
.h
.c

C++
.h/.hpp
.cc/.cpp/.cxx

Objective-C
.h
.m

Objective-C++
.h
.mm

为了兼容 C，我们依然可以使用预处理器指令 #include 来包含头文件。但是 Objective-C 提供了另一选项 #import。它与 #include 的作用几乎完全相同，但可以保证在一个编译单元中每个头文件都只被引入一次。即是说，它起到了传统 C/C++ 变成中 #pragma once 或是 Guard Macro 的作用。

## 基本类型

Objective-C/C++ 中的基本类型和 C/C++ 中的差不多。几种基本类型在 Objective-C/C++ 中的长度分别是：

- char: 1B

- int: 4B

- float: 4B

- double: 8B

此外，Objective-C/C++ 中也有 short/long/long long/signed/unsigned 之类的修饰。含义也和 C/C++ 中的相同。

## 字符串

Objective-C 支持 C-style 字符串，并且也遵循 C 语言当中对引号使用的约定。亦即，使用单引号表示字符（例 'c'），使用双引号表示字符串（null termination）。但在 Objective-C 中也有实现 NSString 类（类似 C++ 中的 std::string 但更强大）。它更常用。

```objectivec
'c';  // 字符类型字面量
"hello world";  // C-style string
@"hello world";  // Objective-C NSString
```

此外，NSString 也支持 printf 风格的字符串构造方法，以及支持从 C-style 字符串中构造。

```objectivec
// construct a NSString object from literal
NSString* myString = @"My String\n";

// construct a NSString object from printf formatter
NSString* anotherString = [NSString stringWithFormat: @"%d %s", 1, @"String"];

// construct a NSString object from C-style string
NSString*  fromCString = [NSString stringWithCString: "A C string" encoding: NSASCIIStringEncoding];
```

## 逻辑控制

### if

Objective-C 中的 if 语句和 C/C++ 中的基本一致。唯独，在 Objective-C 中以 0 表示 false，而以其他值表示 true。例如说，其他任何数值，或是任何字符串，在 Objective-C 中都会被认为是 true。

### for/while

Objective-C 中的 for/while 和 C 中的完全一致。

## 函数调用

名称
代码风格

C/C++
对象成员函数调用
obj.method(args)

Objective-C/C++
向对象传递消息
[obj method: args]

在 C++/Java 中，类中定义有成员函数/成员方法。我们可以通过类似 obj.method(args) 的方式调用 obj 对象的 method 成员函数。如果 method 在 obj 所属的类中没有定义，则在编译期就会报错。

Objective-C 则继承了 Smalltalk 的消息传递模型。在这一模型中，调用成员函数被视作是向对象发送一个消息。例如，obj.method(args) 式的调用会被写作是 [obj method: args]。这种写法的意思是，向 obj 这个对象发送名为 method 的消息，args 则是消息附带的参数。与 C++/Java 风格的调用不同，obj 所属的类即便没有定义名为 method 的成员函数，我们在代码中依旧可以向 obj 发送这一消息。Objective-C 的编译器不会为此报错，但在程序执行时则会抛出一个异常。

对比下来，消息传递模型中类和成员函数的关系较为松散，这种调用方式总是在运行期动态绑定。于是，它不需要 C++ 当中的 virtual/override 关键字。当然，这种做法也存在一定额外开销。（显然）

空对象（nil）接受消息后默认不做任何事情。因此向 nil 传递消息是安全的。

## 类的声明与数据成员

在 C++ 中，我们称之为「声明一个类」。在 Objective-C/C++ 中，我们说「定义类的接口（interface）」。

在 C++ 中，定义一个空的类形如

```cpp
class Foo {};
```

注意，它不需要继承自一个作为占位符的父类。在 Objective-C/C++ 中，定义一个空类形如

```objectivec
@interface Foo : NSObject
@end
```

注意，和 Python 中所有类都继承自 object 类似，Objective-C 中所有类都继承自 NSObject。

在 C++ 中，定义一个包含有数据成员的类形如

```cpp
class Foo : public Bar {
 protected:
  int data;

 private:
  int private_data;
};
```

类比在 Objective-C/C++ 中则是

```objectivec
@interface Foo : Bar {
  int data;
}
@end

@implementation Foo {
  int private_data;
}
@end
```

Objective-C 的类分为接口（interface）和实现（implementation）。接口部分通常包含了类声明以及其中数据成员的定义，以及相关成员函数的声明。实现部分通常包含了成员函数的实现代码。

注意，C++ 中，class 中的数据成员默认是 private 的；在 Objective-C/C++ 中，@interface 段定义的数据成员默认是 protected 的，@implementation 段定义的数据成员默认是 private 的。为了保持访问控制一致，额外在 C++ 代码中加上了 protected 关键字来指定 data 的访问控制类型。

## 成员函数

在 C++ 中，成员函数的声明形如

```cpp
class Foo : public Bar {
 public:  // 1.
  static void class_method();  // 2.

  void instance_method1();  // 3.a
  void instance_method2(int p1);  // 3.b
  void instance_method3(int p1, int p2);  // 4.
};
```

类比在 Objective-C 中，则是如下形式

```objectivec
@interface Foo: Bar
// 1.
+(void) class_method;  // 2.

-(void) instance_method1;  // 3.a
-(void) instance_method2: (int) p1;  // 3.b
-(void) instance_method3: (int) p1 and: (int) p2;  // 4.
@end
```

首先关注 (1)。在 C++ 中，class 内的访问控制默认是 private。因此，要使声明的成员函数可用，我们需要显式地指明 public。在 Objective-C 中，@interface 段的方法默认是 @public 的。

接下来关注 (2)。在 C++ 中有所谓的 static-成员函数。此类成员函数是属于整个类的，不能修改类的对象内部的数据成员。Objective-C 中也有类似设定，即所谓的类方法（class method）。具体形式是在方法前加上一个 + 记号。

现在关注 (3)。这是典型的成员函数的声明方式。这样的成员函数是与具体的类的对象绑定的，必须要有一个构造好的对象才能执行这些成员函数。在 Objective-C 中，这是所谓的对象方法（instance method），也称为一般方法。

(4) 处也声明了一般意义上的成员函数，但在 Objective-C 这里稍有不同。对 Objective-C 的版本，它的函数全名（签名）是 instance_method3:and:。即是说，在声明时，函数的名称和参数列表交织在一起；每个冒号后面都带有一次参数传递。调用它的时候则类似：[obj instance_method3: 0 and: 1]。这是 Objective-C/C++ 特有的。

## 属性

尽管我们也可以在 Objective-C 中定义数据成员，但实际上更好的方式是使用属性。例如

```objectivec
@interface Foo: NSObject
@property int age;
@end
```

它等价于

```objectivec
@interface Foo: NSObject
@property int age;  // 1.
@end

@implementation Foo
@synthesize age = _age;  // 2.
@end
```

这里，(1) 声明了类 Foo 的一个属性。它的类型是 int，名字是 age。如果没有显式地如 (2) 这样将属性和变量关联起来，则编译器会自动产生一个变量，并做这样的关联。注意，属性的声明应当位于 @interface 段，属性与变量的关联则应放在 @implementation 段。

你也可以使用别的变量与属性进行关联。例如 @synthesize age = internal_age;。这样会将 age 这个属性与 internal_age 这个数据成员进行关联。

声明属性，则编译器会为我们自动生成相应的 setter/getter 方法。例如说，上面的代码，大致相当于会生成这样的代码：

```objectivec
@implementation Foo
-(void) setAge: (int) n {
  self->_age = n;
}

-(int) age {
  return self->_age;
}
@end
```

也就是说，通过属性，我们将类的数据成员封装了起来。外部不能直接操作类的数据成员，而要通过 setter/getter 来操作。此外，Objective-C 还为此提供了类似 C++ 中成员访问运算符（.）的语法糖。我们可以写出类似下面的代码

```objectivec
p.age = 10;  // 1.a
[p setAge: 10];  // 1.b

NSLog(@"age is: %d", p.age);  // 2.a
NSLog(@"age is: %d", [p age]);  // 2.b
```

其中 (1.a) 和 (1.b) 的含义相同，(2.a) 和 (2.b) 的含义也相同。