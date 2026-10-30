---
title: "利用位运算验证数独正确性"
url: https://liam.page/2017/12/17/validating-sudoku-in-a-efficient-way/
date: 2017-12-17
categories: ["Algorithm and Computer Science"]
tags: ["C++", "Sudoku", "Bitwise"]
---

[数独](https://zh.wikipedia.org/wiki/%E6%95%B8%E7%8D%A8)是一种益智解谜游戏。初始状态，在 $9\times 9$ 的盘面上，零星分布着一些 1 -- 9 的整数。规则要求玩家在初始状态的基础上，填入 1 -- 9 的数字，使得 $9\times 9$ 的盘面上，每个横行、纵列、$3\times 3$ 宫都有完整且不重复的 1 -- 9 组合。

现在的问题是，给定一个数独答案，如何用代码验证这个答案的正确性。本文使用 C++ 来实现该目标。

## 分析

根据规则，验证程序必然要验证 9 个横行、9 个纵列、9 个宫分别的正确性。在这个层面上，没有投机取巧的余地。因为，哪怕只省略了一个横行、纵列或是宫，都有可能造成误判——程序认为数独答案正确，但实际错误。反过来，只要程序发现有一个横行、纵列或是宫有异常，就可断定答案错误。

在行列宫的角度，数独验证的方法简单明了。但验证横行、纵列和宫中的数字组合的细节，却藏着魔鬼。

按照规则，正确的数独每一个行列宫，其中的数字组合都应当是完整且不重复的 1 -- 9 的组合。这样，似乎只需验证行列宫中数字之和为 $45 = \sum_{i = 1}^{9} i$ 即可。我们称之为求和验证法。然而，这藏着一个魔鬼——求和验证法暗藏了一个假设，而这个假设不总是成立：每一个行列宫中的数字只能是 1 -- 9 中的整数，并且若这一行列宫的数字组合有误，则只能是有一个数字重复一次。于是，至少有两种特殊情形能够轻易地推翻这一假设，从而推翻求和验证法。其一，数字组合 $[1, 2, 3, 4, 6, 6, 6, 8, 9]$ 中 $6$ 重复了 3 次，但整个组合的和为 45。其二，数字组合 $[0, 2, 3, 4, 5, 6, 7, 8, 10]$ 中，出现了 1 -- 9 之外的数字，但整个组合的和为 45。考虑第二种情况是有意义的，因为，尽管规则要求仅使用 1 -- 9 之间的整数，但是却无法保证数独答案中只有这些数字——不能对用户输入做任何假设，完全有可能出现规则之外的输入。

在讨论求和验证法时，本文指出了其暗含的假设。通过指出假设的不合理处，推翻了求和验证法。事实上，这一假设只是表象，还可以深入挖掘。

主张求和验证法的人，事实上受到了某种欺骗。数独及其要求人们以 1 -- 9 的整数填充宫格的规则，看似是一个数字问题；但实际上，数独规则的核心不在「数」而在「独」。若把 1 -- 9 换成任意其它 9 个符号，比如字母 A -- I，不难发现也能套入数独的规则。因此，在数独中，数字仅仅是一个符号，代表不同的个体，没有运算上的价值。这也就是说，任何假定数独中数字可以运算的验证方法，都是不正确的。

考虑到数独中的数字仅仅是符号，代表不同的个体，验证程序只能从集合相等的角度进行验证。也就是说，在 C++ 中，程序要将每一个行列宫中的数字纳入一个集合，与正确的集合进行比对。若比对不符，则说明数独答案错误；否则，若所有行列宫均比对成功，则说明数独答案正确。

## 集合

说到集合，C++ 的标准模板库提供了 std::set 和 std::unordered_set 两种容器模板。按[前文](/2017/12/13/set-intersection-and-union-in-Cpp/)介绍，std::set 以平衡二叉树实现，而 std::unordered_set 以哈希表实现。因此，一个可行的方案，是以 std::set 或 std::unordered_set 为容器，保存每一个行列宫中的数字组合，然后与正确的集合比对。考虑到此处数字的顺序不重要，使用 std::unordered_set 更为妥当。因此，正确的集合应是：

```cpp
stataic const constexpr
std::unordered_set<const uint8_t> kCorrectSet{1, 2, 3, 4, 5, 6, 7, 8, 9};
```

标准模板库提供了高效的容器，程序需要的集合这一数据结构已经有了着落。但标准模板库是为一般情形设计的，在绝大多数情况下，其中的设施都可堪使用，但并不一定是最优选择。在数独验证任务中，程序所需的集合总是非常小的——不超过 9 个元素（对于 9 宫格的数独来说）。在这样的数据规模下，频繁对集合进行建立、插入、比对、销毁的成本是很高的。

事实上，在数独验证这一有严格限定的问题下，集合这一数据结构的实现有更优的方案。当然，选用任何方案都会有一定的代价；而选用这一方案的代价即是：需要预先假定一种对应关系。

这一方案相关的假设如下：

- 首先，以一个整型变量代替标准模板库中的设施，作为集合容器。

- 其次，假定整型变量中的二进制位（bit）代表对应元素在集合中是否存在。例如若 1 在集合中，则该整型变量的倒数第 1 位（最低位）置 1，否则置 0。又例如若 4 在集合中，则该整型变量的倒数第 4 位置 1，否则置 0。

在这样的假设下，集合的操作有：

操作
方法

建立
int16_t flag = 0x0

插入（x）
flag or_eq (1 << (x - 1))

比较
if (kFlag == flag)

显而易见，对单个整型变量的操作，比对标准模板库的容器的操作要快至少一个数量级。

这一方案受到了 [Milo Yip 的知乎答案](https://www.zhihu.com/question/264114285/answer/276796444)中提到的 [Optimizing software in C++](http://www.agner.org/optimize/optimizing_cpp.pdf) 中关于布尔变量优化（7.5 节）的启发。

## 实现

首先，本文给出测试文件。测试文件的第一行是一个整数，表示测试文件中有多少个数独答案。而后则是每个数独答案的具体内容。

```cpp
3
7 2 6 4 9 3 8 1 5
3 1 5 7 2 8 9 4 6
4 8 9 6 5 1 2 3 7
8 5 2 1 4 7 6 9 3
6 7 3 9 8 5 1 2 4
9 4 1 3 6 2 7 5 8
1 9 4 8 3 6 5 7 2
5 6 7 2 1 4 3 8 9
2 3 8 5 7 9 4 6 1
7 2 6 4 9 3 8 1 5
3 1 5 7 2 8 9 4 6
4 8 9 6 5 1 2 7 3
8 5 2 1 4 7 6 9 3
6 7 3 9 8 5 1 2 4
9 4 1 3 6 2 7 5 8
1 9 4 8 3 6 5 7 2
5 6 7 2 1 4 3 8 9
2 3 8 5 7 9 4 6 1
9 3 1 4 7 6 5 2 8
4 8 6 1 2 5 7 3 9
7 2 5 8 9 3 1 4 6
5 7 4 2 3 9 8 6 1
1 6 8 7 5 4 2 9 3
3 9 2 6 1 8 4 5 7
2 4 3 9 8 7 6 1 5
8 1 9 5 6 2 3 7 4
6 5 7 3 4 1 9 8 2
```

接下来，本文给出具体实现。实现中，通过替换 std::cin 的缓冲区，可在定义 DEBUG_ 宏的情况下从测试文件中读取内容。其他逻辑，可于上文参考。

```cpp
#include <iostream>
#include <cmath>
#include <cstdint>
#ifdef DEBUG_
#include <fstream>
namespace std {
ifstream fin{"./sudoku.test.txt"};
streambuf* cin_buf = cin.rdbuf(fin.rdbuf());
}  // namespace std
#endif

class Sudoku {
 private:
    const size_t size_       = 9;
    const size_t total_      = size_ * size_;
    const size_t block_size_ = static_cast<const size_t>(std::sqrt(size_));
    const int64_t flag_      = 0x1FF;
    int*         matrix_     = nullptr;

 public:
    Sudoku() : Sudoku(9) {}
    explicit Sudoku(size_t size) :
        size_{size},
        total_{size_ * size_},
        block_size_{CalculateBlockSize(size_)},
        flag_{CalculateFlag(size_)},
        matrix_{ConstructMatrix(size_)} {}
    ~Sudoku() {
        DestroyMatrix(matrix_);
    }

 private:
    Sudoku(const Sudoku&) = delete;
    Sudoku(Sudoku&&) = delete;
    Sudoku& operator=(const Sudoku&) = delete;
    Sudoku& operator=(Sudoku&&) = delete;

 private:
    const size_t CalculateBlockSize(const size_t range) {
        const size_t res = static_cast<const size_t>(std::sqrt(range));
        if (not(range == res * res)) {
            std::terminate();
        }
        return res;
    }
    const int64_t CalculateFlag(const size_t range) {
        if (not(range <= 64)) {
            std::terminate();
        }
        int64_t res = 0;
        for (size_t i = 0; i != range; ++i) {
            res |= 1 << i;
        }
        return res;
    }
    int* ConstructMatrix(const size_t total) {
        return new int[total];
    }
    void DestroyMatrix(int*& matrix) noexcept {
        if (nullptr != matrix) {
            delete[] matrix;
            matrix = nullptr;
        }
        return;
    }

 public:
    bool ReadFromStream(std::istream& is) {
        int* const m = const_cast<int* const>(this->matrix_);
        if (is and m) {
            for (size_t i = 0; i != total_; ++i) {
                if (is) {
                    is >> m[i];
                } else {
                    return false;
                }
            }
            return true;
        } else {
            return false;
        }
    }
    bool Validate() const {
        const int* const m = const_cast<const int* const>(this->matrix_);
        for (size_t i = 0; i != size_; ++i) {  // validate rows
            int64_t flag = 0x0;
            for (size_t j = 0; j != size_; ++j) {
                flag |= (1 << (m[i * size_ + j] - 1));
            }
            if (flag_ != flag) {
                return false;
            }
        }
        for (size_t j = 0; j != size_; ++j) {  // validate columns
            int64_t flag = 0x0;
            for (size_t i = 0; i != size_; ++i) {
                flag |= (1 << (m[i * size_ + j] - 1));
            }
            if (flag_ != flag) {
                return false;
            }
        }
        for (size_t i = 0; i != block_size_; ++i) {  // validate blocks
            for (size_t j = 0; j != block_size_; ++j) {
                int64_t flag = 0x0;
                for (size_t ii = 0; ii != block_size_; ++ii) {
                    for (size_t jj = 0; jj != block_size_; ++jj) {
                        flag |= (1 << (m[(i * block_size_ + ii) * size_ + j * block_size_ + jj] - 1));
                    }
                }
                if (flag_ != flag) {
                    return false;
                }
            }
        }
        return true;
    }
};

int main() {
    size_t case_num;
    std::cin >> case_num;
    Sudoku sudoku(9);
    for (size_t i = 0; i != case_num; ++i) {
        if (sudoku.ReadFromStream(std::cin)) {
            std::cout << ((sudoku.Validate()) ? "YES" : "NO") << '\n';
        }
    }
    return 0;
}
```