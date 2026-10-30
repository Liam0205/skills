---
title: "Scala 中下划线的一些魔法"
url: https://liam.page/2019/10/24/underscore-magic-in-Scala/
date: 2019-10-24
categories: ["Algorithm and Computer Science"]
tags: ["Scala", "Underscore"]
---

这段时间开始学习使用 Scala。和大多数初学者一样，面对 Scala 的各种符号，我也是一脸懵哔。尤其是 Scala 中的下划线 _ 在不同场合有不同含义，简直慌。适应一段时间之后，这里总结记录一下我遇见的下划线的含义。

## 导入模块包

在 Scala 导入模块包时，_ 的作用类似于 Java 导入模块包时的 *。

```scala
// 引入 matching 包中的所有类
import scala.util.matching._
// 引入对象 Fun 中的所有成员（相当于 Java 中的 static import）
import com.test.Fun._
// 引入对象 Fun 中的所有成员，但将 `Foo` 改名为 `Bar`（相当于 Python 中的 `import Foo from com.test.Fun as Bar`）
import com.test.Fun.{ Foo => Bar , _ }
// imports all the members except Foo. To exclude a member rename it to _
// 引入对象 Fun 中的所有成员，但通过将 `Foo` 改名为 `_` 而忽略。
import com.test.Fun.{ Foo => _ , _ }
```

## 模式匹配

[Scala 中的模式匹配](https://docs.scala-lang.org/tour/pattern-matching.html)和 C/C++ 或者 Java 中的 switch - case 语句类似。在 Scala 中的模式匹配中，下划线 _ 是匹配任意内容的通配符。最基本的用法时，_ 相当于 C/C++ 中的 default。

```scala
import scala.util.Random

val x: Int = Random.nextInt(10)

x match {
  case 0 => "zero"
  case 1 => "one"
  case 2 => "two"
  case _ => "other"
}
```

更高阶的用法中，_ 可以嵌套使用，这时候就远超出 default case 的作用了。

```scala
expr match {
  case List(1, _, _) => " a list with three element and the first element is 1 "
  case List(_*)  => " a list with zero or more elements "
  case Map[_, _] => " matches a map with any key type and any value type "
  case _ => " others "
}
```

## 匿名函数的参数

Scala 和 Python、C++ 等语言一样，也有匿名函数的设定。下划线 _ 可用作是匿名函数的参数的占位符，但对于每一个参数，只能用下划线占位一次。例如，在 Scala 中 2 * _ 相当于 Python 中的 lambda x: 2 * x 或者 C++ 中的 [](auto x) { return 2 * x; }；但对于 Python 中的 lambda x: x * x 不能写成 Scala 中的 _ * _——因为在 Scala 中，_ * _ 表示匿名函数接受 2 个参数，函数返回值是两个参数的乘积。又例如，下列 Scala 代码中的 print(_) 相当于 x => print(x)：

```scala
List(1, 2, 3, 4, 5).foreach(print(_))
```

下列 Scala 代码中的 _ + _ 相当于 (x, y) => x + y：

```scala
List(1, 2, 3, 4, 5).reduceLeft(_ + _)
```

## 阻止函数意外调用

众所周知，Scala 是函数式语言。在 Scala 中，函数是一等公民，和普通变量一样可以赋值。但由于在 Scala 中函数调用时可省略括号，如果你打算将一个函数赋值给一个新的变量，则函数可能会被意外地调用而后将函数的返回值赋值。这种时候，我们需要在函数名之后加上 _ 来阻止函数调用——类似 TeX 中的 \relax 阻止继续执行的作用。

```scala
class Test {
  def foo = {
    // some code
  }
  val bar = foo _
}
```

## 区分 getter 和 setter

在 Scala 中，对象中的非私有成员会自动生成一对 getter 和 setter。对于私有成员，程序员也可以自己实现 getter 和 setter。这时候，我们需要在 setter 后加上下划线 _ 来实现类似 C++ 中函数重载的效果。

```scala
class Test {
  private var a = 0
  def age = a
  def age_ = (n:Int) = {
    require(n > 0)
    a = n
  }
}

val t = new Test
t.age = 5
println(t.age)
```

相当于 C++ 代码：

```cpp
class Test {
 private:
  int a = 0;

 public:
  int age(void) const {
    return a;
  }
  void age(const int a_) {
    a = a_;
    return;
  }
};

Test t;
t.age(5);
std::cout << t.age() << std::endl;
```