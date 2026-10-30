---
title: "在 C++ 中解包 std::vector 作为函数参数"
url: https://liam.page/2019/07/04/unpack-vector-as-parameters-for-functions/
date: 2019-07-04
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Function", "std::vector", "unpack"]
---

昨天 jsteward 问我，有一个接受若干个同类型参数的函数 template <typename U, typename T> U func(T a, T b, T c)，现在有一个 std::vector<T> args，希望将 std::vector<T> 当中的元素作为函数参数传进去，要怎么办。

这篇来解决这个问题。

首先，待执行的函数的参数个数，在编译时就能知道；比如这里是 3 个。于是，很自然地，我们最终肯定需要类似这样的代码：

```cpp
func(args[0], args[1], args[2]);
```

现在的问题是，我们希望这种调用代码能够自动生成，而不是手动去写。因为 func 的参数，在实际情况下，可能不止 3 个。C++ 11 引入了参数包（parameter pack）的概念，能够将若干个模板参数，打包在一起，然后再用 ... 的方式展开。参数包可以是类型参数包，比如 template <typename... Args>，这样 (*Args)... 就是各个类型的指针；参数包也可以是变量参数包，比如 size_t... I，这样 args[I]... 就是 args[0], args[1], args[2] 这样的展开。后者正是我们要的。

于是，为了利用参数包，我们首先需要根据函数 func 的参数数量，构建一个参数包，作为索引。

```cpp
namespace util {
template <size_t... Indices>
struct indices {
  using next = indices<Indices..., sizeof...(Indices)>;
};
template <size_t N>
struct build_indices {
  using type = typename build_indices<N - 1>::type::next;
};
template <>
struct build_indices<0> {
  using type = indices<>;
};
template <size_t N>
using BuildIndices = typename build_indices<N>::type;
}  // namespace util
```

这里用到了[前作](/2019/02/19/recursive-like-function-template-calling/)提到过的技巧。我们看：

- BuildIndices<0> 是 build_indices<0>::type 也就是全特化的 indices<>；

- BuildIndices<1> 是 build_indices<1>::type 也就是 build_indices<0>::type::next 也就是 indices<>::next 也就是 indices<0>；

- 同理，BuildIndices<2> 是 build_indices<2>::type 也就是 build_indices<1>::type::next 也就是 build_indices<0>::type::next::next 也就是 indices<0>::next 也就是 indices<0, 1>；

- 以此类推 BuildIndices<N> 是 indices<0, 1, ..., N - 1>。

于是我们很容易构建出 caller 如下：

```cpp
template <typename Func, typename T, size_t... I>
void call(Func& func, std::vector<T>& args, indices<I...>) {
  f(args[I]...)
}
```

使用时只需要这样既可：

```cpp
call(func, args, BuildIndices<num_args>());
```

我们将整个封装起来，写成一个完整的例子如下：

```cpp
#include <iostream>
#include <utility>
#include <vector>

namespace util {
template <size_t... Indices>
struct indices {
  using next = indices<Indices..., sizeof...(Indices)>;
};
template <size_t N>
struct build_indices {
  using type = typename build_indices<N-1>::type::next;
};
template <>
struct build_indices<0> {
  using type = indices<>;
};
template <size_t N>
using BuildIndices = typename build_indices<N>::type;

template <typename returnT, typename valueT, size_t num_args>
struct unpack_caller {
 private:
  template <typename FuncType, size_t... I>
  returnT call(FuncType& f, std::vector<valueT>& args, indices<I...>) {
    return f(args[I]...);
  }

 public:
  template <typename FuncType>
  returnT operator()(FuncType& f, std::vector<valueT>& args) {
    return call(f, args, BuildIndices<num_args>());
  }
};
}  // namespace util

int func(int a, int b, int c) {
  return a + b + c;
}

int main() {
  std::vector<int> args = {1, 2, 3};
  int i = util::unpack_caller<int, int, 3>()(func, args);
  std::cout << i << std::endl;

  return 0;
}
```

这样还不是很爽。因为在调用 util::unpack_caller 的时候，我们不得不输入函数相关信息。如果有办法能够获取函数的参数类型、参数量、返回值类型，我们就可以避免这个问题了。为此，我们还要定义一套 function_traits。

```cpp
template <typename ReturnType, typename... Args>
struct function_traits_defs {
  static constexpr size_t arity = sizeof...(Args);

  using result_type = ReturnType;

  template <size_t i>
  struct arg {
    using type = typename std::tuple_element<i, std::tuple<Args...>>::type;
  };
};

template <typename T>
struct function_traits_impl;

template <typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(*)(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const volatile>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const volatile&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const volatile&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename T, typename V = void>
struct function_traits
    : function_traits_impl<T> {};

template <typename T>
struct function_traits<T, decltype((void)&T::operator())>
    : function_traits_impl<decltype(&T::operator())> {};
```

这里，function_traits_defs 是 traits 的具体定义，function_traits_impl 则是针对各种情况（函数、函数指针、仿函数的各种 cv 修饰符及引用情况）做的实现，function_traits 则是暴露在外面的接口。如此一来，我们可以对 util::unpack_caller 做一些改进。

```cpp
namespace details {
template <typename FuncType,
          typename VecType,
          size_t... I,
          typename Traits = function_traits<FuncType>,
          typename ReturnT = typename Traits::result_type>
ReturnT do_call(FuncType& func,
                VecType& args,
           indices<I...> ) {
  return func(args[I]...);
}
}  // namespace details

template <typename FuncType,
          typename VecType,
          typename Traits = function_traits<FuncType>,
          typename ReturnT = typename Traits::result_type>
ReturnT unpack_call(FuncType& func,
                VecType& args) {
  return details::do_call(func, args, BuildIndices<Traits::arity>());
}
```

如此一来，完整的示例如下：

```cpp
#include <iostream>
#include <utility>
#include <vector>

namespace util {
template <typename ReturnType, typename... Args>
struct function_traits_defs {
  static constexpr size_t arity = sizeof...(Args);

  using result_type = ReturnType;

  template <size_t i>
  struct arg {
    using type = typename std::tuple_element<i, std::tuple<Args...>>::type;
  };
};

template <typename T>
struct function_traits_impl;

template <typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(*)(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...)>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) volatile&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const volatile>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const volatile&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename ClassType, typename ReturnType, typename... Args>
struct function_traits_impl<ReturnType(ClassType::*)(Args...) const volatile&&>
    : function_traits_defs<ReturnType, Args...> {};

template <typename T, typename V = void>
struct function_traits
    : function_traits_impl<T> {};

template <typename T>
struct function_traits<T, decltype((void)&T::operator())>
    : function_traits_impl<decltype(&T::operator())> {};

template <size_t... Indices>
struct indices {
  using next = indices<Indices..., sizeof...(Indices)>;
};
template <size_t N>
struct build_indices {
  using type = typename build_indices<N - 1>::type::next;
};
template <>
struct build_indices<0> {
  using type = indices<>;
};
template <size_t N>
using BuildIndices = typename build_indices<N>::type;

namespace details {
template <typename FuncType,
          typename VecType,
          size_t... I,
          typename Traits = function_traits<FuncType>,
          typename ReturnT = typename Traits::result_type>
ReturnT do_call(FuncType& func, const VecType& args, indices<I...>) {
  return func(args[I]...);
}
}  // namespace details

template <typename FuncType, typename VecType, typename Traits = function_traits<FuncType>>
auto unpack_caller(FuncType& func, const VecType& args) {
  return details::do_call(func, args, BuildIndices<Traits::arity>());
}
}  // namespace util

int func(int a, int b, int c) {
  return a + b + c;
}

int main() {
  std::vector<int> args = {1, 2, 3};

  int j = util::unpack_caller(func, args);
  std::cout << j << std::endl;

  return 0;
}
```