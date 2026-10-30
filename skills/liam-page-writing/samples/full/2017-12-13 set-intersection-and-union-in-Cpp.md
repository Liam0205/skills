---
title: "谈谈 C++ 中集合的交集和并集"
url: https://liam.page/2017/12/13/set-intersection-and-union-in-Cpp/
date: 2017-12-13
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Set", "Intersection", "Union"]
---

在数学中，集合是最基本的概念之一。编程时，我们不可避免地会涉及到集合及其相关操作。在 C++ 中，标准模板库（STL）提供了 std::set/std::unordered_set 两种传统意义上的集合（除此之外，还有 std::multiset 和 std::unordered_multiset）。其中，std::set（和 std::multiset）定义在头文件 set 当中，从 C++98 起就有支持；而 std::unordered_set（和 std::unordered_multiset）则定义在头文件 unordered_set 当中，从 C++11 开始支持。

此篇我们讨论如何在 C++ 中进行集合的交集和并集操作。

## std::set 和 std::unordered_set 简介

在 C++ 标准中，std::set 是基于平衡二叉树的（经典的 SGI STL 以红黑树实现），因而是有序的。以恰当的方式，比如以 std::set 的迭代器，遍历，可以得到有序的结果。在 C++ 标准中，std::unordered_set 则是基于哈希表的。因此，遍历 std::unordered_set 得到的顺序是不被保证的。std::unordered_set 的插入、查找、计数等操作的时间复杂度是 $O(1)$。

如果你更喜欢 hash_set 这个名字，你也可以借助 C++11 的 using 关键字的新功能，将 hash_set 作为 unordered_set 的别名。

```cpp
#include <unordered_set>
namespace std {
template <typename Key,
          typename Hash = std::hash<Key>,
          typename KeyEqual = std::equal_to<Key>,
          typename Allocator = std::allocator<Key>>
using hash_set = unordered_set<Key, Hash, KeyEqual, Allocator>;
}  // namespace std
```

之后，就能像使用 std::unordered_set 那样使用 std::hash_set 了。

因为 std::set 和 std::unordered_set 底层使用了不同的数据结构，它们对外表现出来的性能也不相同。std::set 的插入、查找、计数等操作的时间复杂度是 $O(\log n)$。std::unordered_set 的插入、查找、计数等操作的时间复杂度是 $O(1)$。因此，在集合中元素的顺序很重要时，可以考虑使用 set::set 来保存元素；当顺序相对不重要，但会反复进行插入、查找等操作时，则应考虑使用 set::unordered_set。

我们用下面这段代码来演示 std::set 和 std::unordered_set 的用法。

```cpp
#include <iostream>
#include <string>

#ifdef HASH_        // 1.
#include <unordered_set>
#else  // HASH_
#include <set>
#endif

namespace test {
#ifdef HASH_        // 1.
template <typename Key,
          typename Hash = std::hash<Key>,
          typename KeyEqual = std::equal_to<Key>,
          typename Allocator = std::allocator<Key>>
using set = std::unordered_set<Key, Hash, KeyEqual, Allocator>;
#else  // HASH_
template <typename Key,
          typename Compare = std::less<Key>,
          typename Allocator = std::allocator<Key>>
using set = std::set<Key, Compare, Allocator>;
#endif  // HASH_
}  // namespace test

int main() {
    test::set<std::string> set{"Hello", "world", "!"};           // 2.
    set.insert("hello");                                         // 3.
    set.insert("world");                                         // 4.

    for (const auto& i : set) {
        std::cout << i;                                          // 5.
        if ((set.count(i) > 0) == (set.find(i) != set.end())) {  // 6.
            std::cout << "\tYES!\n";
        }
    }

    return 0;
}
```

(1) 利用预处理器，在 HASH_ 有定义时，加载 unordered_set 头文件，并将 test::set 作为 std::unordered_set 的等价类型；否则，加载 set 头文件，并将 test::set 作为 std::set 的等价类型。(2) 声明并定义了名为 set 的变量，其中包含 "Hello"/"world"/"!" 三个元素。注意，这里的 set 不带名字空间前缀，因而不会与 std::set 或者 test::set 冲突。(3) 和 (4) 处分别将 "hello" 和 "world" 插入 set。(5) 在按迭代器顺序遍历集合。(6) 则给出了查询元素是否属于集合的两种等价方式。

当定义 HASH_ 时，可能的输出为：

```bash
$ g++ -std=c++11 foo.cpp -DHASH_
$ ./a.out
hello   YES!
!       YES!
world   YES!
Hello   YES!
```

当不定义 HASH_ 时，输出应为：

```bash
$ g++ -std=c++11 foo.cpp
$ ./a.out
!       YES!
Hello   YES!
hello   YES!
world   YES!
```

不难发现，不论是使用 std::set 还是 std::unordered_set，重复插入的 "hello" 在集合中都只存在一份；此外，std::set 是有序的，而 std::unordered_set 是无序的。另一方面，我们发现，使用 set.count(i) > 0 和 set.find(i) != set.end() 判断集合中是否存在元素 i 是等价的。

## 标准库提供的 std::set_intersection 和 std::set_union

标准库提供了 [std::set_intersection](http://en.cppreference.com/w/cpp/algorithm/set_intersection) 和 [std::set_union](http://en.cppreference.com/w/cpp/algorithm/set_union) 两个函数，用于对容器内的元素进行集合求交、求并，而后将得到的结果保存在 OutputIt 对应的容器当中。这两个函数定义在头文件 algorithm 当中。

不过，这两个函数都要求原始集合是排序的。因此，我们无法将这两个函数直接运用在 std::unordered_set 上。

我们用下面这段代码演示这两个函数的用法。

```cpp
#include <iostream>
#include <iterator>
#include <algorithm>

#ifdef HASH_
#include <unordered_set>
#else  // HASH_
#include <set>
#endif

namespace test {
#ifdef HASH_
template <typename Key,
          typename Hash = std::hash<Key>,
          typename KeyEqual = std::equal_to<Key>,
          typename Allocator = std::allocator<Key>>
using set = std::unordered_set<Key, Hash, KeyEqual, Allocator>;
#else  // HASH_
template <typename Key,
          typename Compare = std::less<Key>,
          typename Allocator = std::allocator<Key>>
using set = std::set<Key, Compare, Allocator>;
#endif  // HASH_
}  // namespace test

int main() {
    test::set<int> lhs{1, 2, 3, 4};                             // 1.
    test::set<int> rhs{3, 4, 5, 6};                             // 2.

    test::set<int> result;

    std::set_intersection(lhs.begin(), lhs.end(),               // 3.
                          rhs.begin(), rhs.end(),               // 4.
                          std::inserter(result, result.end())); // 5.
    for (const auto& i : result) {
        std::cout << i << ' ';
    }
    std::cout << '\n';

    result.clear();
    std::set_union(lhs.begin(), lhs.end(),                      // 6.
                   rhs.begin(), rhs.end(),                      // 7.
                   std::inserter(result, result.end()));        // 8.
    for (const auto& i : result) {
        std::cout << i << ' ';
    }
    std::cout << '\n';

    return 0;
}
```

(1) 和 (2) 声明并定义了两个 test::set<int> 类的对象：lhs 和 rhs。在 (3) 处，我们向 std::set_intersection 传入了 lhs 的首末位置迭代器；在 (4) 处，我们向函数传入了 rhs 的首末位置迭代器；在 (5) 处，我们向函数传入了 result 的输出迭代器。随后，我们在 (6)(7)(8) 处做了类似的事情，不过是把函数 std::set_intersection 替换成了 std::set_union。

如此一来，我们应有可能的输出：

```bash
$ g++ -std=c++11 foo.cpp -DHASH_
$ ./a.out

5 6 1 2 3 4
$ g++ -std=c++11 foo.cpp
$ ./a.out
3 4
1 2 3 4 5 6
```

不难发现，当使用 std::unordered_set 时，函数 std::set_intersection 工作不正常（std::set_union 恰好看起来正常，实际也不正常）。当使用 std::set 时，由于基于平衡二叉树的集合是有序的，因此两个函数工作正常。

由于 std::set_intersection 和 std::set_union 接受的输入是迭代器；事实上，这两个函数不光能对集合求交集和并集，还能接收任意有序的序列的迭代器并求交集和并集。可见，虽然名字是「集合交集」和「集合并集」，但这两个函数的行为与我们默认的交集和并集的概念并不一致。更有甚者，由于这两个函数要求容器有序，所以不能作用在 std::unoredered_set 类型的对象上。因此，我们可以考虑定义自己的求交、求并函数。

## 定义自己的求交、求并函数

我们以下面的例子呈现我们自己定义的求交、求并函数。

```cpp
#include <iostream>

#ifdef HASH_
#include <unordered_set>
#else  // HASH_
#include <set>
#endif

namespace test {
#ifdef HASH_
template <typename Key,
          typename Hash = std::hash<Key>,
          typename KeyEqual = std::equal_to<Key>,
          typename Allocator = std::allocator<Key>>
using set = std::unordered_set<Key, Hash, KeyEqual, Allocator>;
#else  // HASH_
template <typename Key,
          typename Compare = std::less<Key>,
          typename Allocator = std::allocator<Key>>
using set = std::set<Key, Compare, Allocator>;
#endif  // HASH_
}  // namespace test

namespace setop {
template <typename Set>                                             // 1.
static inline Set
set_union(const Set& lhs, const Set& rhs) {
    Set uset{lhs};                                                  // 2.
    uset.insert(rhs.begin(), rhs.end());                            // 3.
    return std::move(uset);                                         // 4.
}

template <typename Set, typename Key = typename Set::value_type>    // 5.
static inline Set
set_intersection(const Set& lhs, const Set& rhs) {
    if (lhs.size() <= rhs.size()) {                                 // 6.
        Set iset;
        for (const Key& key : lhs) {
            if (rhs.count(key) > 0) {                               // 7.
                iset.insert(key);
            }
        }
        return std::move(iset);
    } else {
        return set_intersection(rhs, lhs);
    }
}
}  // namespace setop

int main() {
    test::set<int> lhs{1, 2, 3, 4};
    test::set<int> rhs{3, 4, 5, 6};

    const auto iset = setop::set_intersection(lhs, rhs);            // 8.
    const auto uset = setop::set_union(lhs, rhs);                   // 9.

    for (const auto& i : iset) {
        std::cout << i << ' ';
    }
    std::cout << '\n';

    for (const auto& i : uset) {
        std::cout << i << ' ';
    }
    std::cout << '\n';
    return 0;
}
```

(1) 和 (5) 表明，setop::set_union 和 setop::set_intersection 都是函数模板，可以接受任何符合要求的容器。其中，在 (5) 的模板声明中，我们使用了 typename Set::value_type 这样的语法。这是因为，对于编译器来说，它并不知道 Set::value_type 是一个类型还是 Set 这个名字空间地下的名为 value_type；此处我们明确地告诉编译器，它应当是一个类型名。

在 (2) 处，我们通过 Set 的拷贝构造函数，将 lhs 中的元素全都拷贝到 uset 当中。这样一来，uset 当中就包含了 lhs 中的所有元素。在 (3) 处，我们通过 insert 函数，将 rhs 的全部元素依次插入到 uset 当中。这样一来，uset 当中也包含了 rhs 中的所有元素。因此，此时它是 lhs 和 rhs 的并集；我们在 (4) 处将 uset 返回。值得一提的是，为了避免可能的额外拷贝（返回值拷贝），我们明确使用了 std::move 将 uset 作为右值返回。不过，即使不这么写，现代编译器也会优化这一拷贝过程。

(6) 比较了 lhs 和 rhs 的大小。这里使用 <= 而不使用 <，是为了避免两个集合元素个数相同时无限递归。(7) 处使用了 rhs.count(key) > 0 的方式，验证 key 是否在 rhs 这一集合当中。显然，它比使用 find 然后与 rhs.end() 进行比较来得自然。

如此一来，我们有可能的输出：

```bash
$ g++ -std=c++11 foo.cpp -DHASH_
$ ./a.out
3 4
5 6 1 2 3 4
$ g++ -std=c++11 foo.cpp
$ ./a.out
3 4
1 2 3 4 5 6
```

不难发现，两个函数工作良好。