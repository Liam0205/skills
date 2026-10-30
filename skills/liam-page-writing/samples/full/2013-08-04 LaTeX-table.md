---
title: "【LaTeX Tips】各种表格的绘制"
url: https://liam.page/2013/08/04/LaTeX-table/
date: 2013-08-04
categories: ["LaTeX"]
tags: ["Table"]
---

听说 LaTeX 中有一只表格君欠调教，于是有了以下调教指南【雾。。】

且看表格君是如何在我的手里变得面目狰狞丧心病狂无法直视的【弥天大雾。。】

## 最初的表格君

### 初生的娃娃

```tex
% 我是代码 01 号
\documentclass[UTF8]{ctexart}
\begin{document}
\begin{tabular}{cc}
我是& 一只\\
表格君& 咿呀咿呀哟
\end{tabular}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=3202142247&uk=1728178661)。

### 给娃娃摆个造型

你可以通过调整 tabular 环境的选项，来掰掰这个小婴儿的手脚，然后咔嚓拍一张照片。比如我希望表格的第一列居左，而希望表格的第二列居右，可以这样

```tex
% 我是代码 02 号
\documentclass[UTF8]{ctexart}
\begin{document}
\begin{tabular}{lr}
我是& 一只\\
表格君& 咿呀咿呀哟
\end{tabular}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=3253087186&uk=1728178661)。

你会发现文字呈现一个弧形，就好像娃娃咧嘴笑的样子【好吧我想多了**禁止吐槽！！！**；我一定很萌对吧！**快回答我很萌不然我不继续写了！！**】

### 给娃娃穿件衣服

看到这么可爱的娃娃，你们一定不会希望他**赤♂身果♀体**（请想歪）到处乱跑。通常我们会希望给表格画一些线来分割各个 cell. LaTeX 提供的最基本方法，是用 \hline 命令画横线，在表格选项处加 | 以添加竖线。

```tex
% 我是代码 03 号
\documentclass[UTF8]{ctexart}
\begin{document}
\begin{tabular}{|l|r|}
\hline
我是& 一只\\
\hline
表格君& 咿呀咿呀哟\\
\hline
\end{tabular}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=3636059235&uk=1728178661)。

需要注意的是，\hline 命令必须接在换行符 \\ 的后面，或者在表头。

## 三线表

### 最基本的三线表

科技论文写作中，更常见的可能是三线表，比如这样

```tex
% 我是代码 04 号
\documentclass[UTF8]{ctexart}
\begin{document}
\begin{tabular}{ccc}
\hline
姓名& 学号& 性别\\
\hline
Ch'en Meng& 001& Male\\
Sarah Brightman& 002& Female\\
\hline
\end{tabular}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=3664755361&uk=1728178661)。

### 让它变得更漂亮

通常来说，我们会希望表格的第一根线和最后一根线比表格中的横线更粗一些。booktabs 宏包为我们提供了这个功能，加载 booktabs 宏包之后我们可以使用 \toprule 和 \bottomrule 命令分别画出表格头和表格底的粗横线，而用 \midrule 画出表格中的横线。比如这样

```tex
% 我是代码 05 号
\documentclass[UTF8]{ctexart}
\usepackage{booktabs}
\begin{document}
\begin{tabular}{ccc}
\toprule
姓名& 学号& 性别\\
\midrule
Ch'en Meng& 001& Male\\
Sarah Brightman& 002& Female\\
\bottomrule
\end{tabular}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=3688384551&uk=1728178661).

## table 环境

LaTeX 的排版的一个特点就是编号和位置浮动的自动化。为了让表格能够自动编号并尽可能美观的浮动，LaTeX 提供了 table 环境。基本用法如下

```tex
% 我是代码 06 号
\documentclass[UTF8]{ctexart}
\usepackage{booktabs}
\begin{document}
\begin{table}[!htbp]
\centering
\caption{这是一张奇怪的表格}\label{tab:aStrangeTable}
\begin{tabular}{ccc}
\toprule
姓名& 学号& 性别\\
\midrule
Ch'en Meng& 001& Male\\
Sarah Brightman& 002& Female\\
\bottomrule
\end{tabular}
\end{table}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=3735767101&uk=1728178661).

注意到 table 环境后面跟了一些由方括号包括起来的可选参数 [!htbp]. 其中 h 代表 here, 意思是将表格排在当前文字的位置； t 表示将表格放在下一页的 top (页首)； b 表示将表格放在当前页的 bottom (底部)；p 表示表格单独放在一个浮动页中；最前面的 ! 表示忽略美观因素，尽可能按照参数指定的方式来处理表格浮动位置。因此这五个参数放在一起就表示「尽可能将表格放在这里，不行就放在下一页的页首，再不行就放在这一页的底部，如果实在不行就单独成页吧」。

应当说明的是，浮动环境会根据行文的状况来调整表格的位置。几乎每个 LaTeX user 都会遇到表格位置不符合自己心中所想的情况。最佳的处理办法，是「随它去」，因为本来就应该这样去处理。如果一定要表格固定在所需位置，可以不用 table 环境，取消浮动。

\centering 命令的意义是将 tabular 环境绘制的表格居中放置。你可以去掉这个命令编译看看效果，进行对比。

\caption 命令输出表格的标题，并按照预定义的样式为表格编号。

\label 命令的作用，是在此处做一个「标记」，可以与 \ref 命令共同使用实现「交叉引用」的效果。**注意为了得到正确的交叉引用结果，\label 命令必须放在 \caption 命令之后**。该命令并不影响**表格本身**的样式，但是设置不当会使得交叉引用失效。交叉引用的具体细节不在本文的讨论范围之内，请自行阅读相关文献。

## 跨行和跨列的表格

有时我们需要进行类似 MS Office Excel 中的「合并单元格」的操作。

### 横向合并

在 tabular 中，可以用 \multicolumn{cols}{pos}{text} 来使得 text 占据 cols 个 cells, 并遵照 pos 中指示的位置。其中 pos 中支持竖线 | 的使用，以在合并后的 cells 两侧绘制竖线。

```tex
% 我是代码 07 号
\documentclass[UTF8]{ctexart}
\begin{document}
\begin{table}[!htbp]
\centering
\caption{这是一张奇怪的表格}\label{tab:aStrangeTable}
\begin{tabular}{|c|c|c|}
\hline
\multicolumn{3}{|c|}{学生信息}\\
\hline
姓名& 学号& 性别\\
\hline
Ch'en Meng& 001& Male\\
Sarah Brightman& 002& Female\\
\hline
\end{tabular}
\end{table}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=493435385&uk=1728178661).

注意如果横向合并 cells 之后，改行的列数会相应增加。亦即在上述例子中，第一行的 cell 占据了 3 列的空间，如果在其后添加 & 符号（表示希望将接下来的内容添加在下一列），则会提示列数过多。

### 纵向合并

纵向合并 cells 需要 multirow 宏包的支持。该宏包提供的 \multirow{rows}{width}{text} 命令能够实现我们的需求。其中若 width 参数中填入 *, 则占据的宽度会根据需要自动增减。

```tex
% 我是代码 08 号
\documentclass[UTF8]{ctexart}
\usepackage{multirow}
\begin{document}
\begin{table}[!htbp]
\centering
\caption{这是一张奇怪的表格}\label{tab:aStrangeTable}
\begin{tabular}{|c|c|c|c|}
\hline
\multicolumn{4}{|c|}{学生信息}\\
\hline
班级& 姓名& 学号& 性别\\
\hline
\multirow{2}*{1 班}& Ch'en Meng& 001& Male\\
& Sarah Brightman& 002& Female\\
\hline
\end{tabular}
\end{table}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=541954644&uk=1728178661).

注意该命令仅仅是将目标位置的 text 扩展到了包括目标位置所在的 rows 行。因此，在其下的若干行，必须用 & 符号空出相应的位置，不然就会导致文字重叠。例如编译下面的代码

```tex
% 我是一个错误演示
\documentclass[UTF8]{ctexart}
\usepackage{multirow}
\begin{document}
\begin{table}[!htbp]
\centering
\caption{这是一张奇怪的表格}\label{tab:aStrangeTable}
\begin{tabular}{|c|c|c|c|}
\hline
\multicolumn{4}{|c|}{学生信息}\\
\hline
班级& 姓名& 学号& 性别\\
\hline
\multirow{2}*{1 班}& Ch'en Meng& 001& Male\\
Sarah Brightman& 002& Female\\
\hline
\end{tabular}
\end{table}
\end{document}
```

### 既跨行又跨列

显见，实现这样的需求需要将上述两个命令结合起来使用。但是只能用 \multicolumn{cols}{pos}{\multirow{rows}{width}{text}} 这样的形式，而不能反过来嵌套。具体原因不明。

以下是一个示例代码

```tex
% 我是代码 09 号
\documentclass{standalone}
\usepackage{multirow}
\begin{document}
\begin{tabular}{|*{10}{r|}}
\hline
\multicolumn{2}{|c|}{\multirow{2}*{Blank}}
& \multicolumn{2}{|c|}{CG} & \multicolumn{2}{|c|}{IS}
& \multicolumn{2}{|c|}{MG} & \multicolumn{2}{|c|}{LU}\\\cline{3-10}
\multicolumn{2}{|c|}{}  & 2   & 4 & 2 & 4 & 2 & 4 & 2 & 4\\\hline
\multirow{2}*{Run Time(s)}
& IA32 & 24.37   & 16.18 & 19.62 & 8.98 & 31.98 & 18.71 & 622.76 & 266.16\\
& IA64 & 54.41   & 30.29 & 25.54 & 15.72 & 164.16 & 84.73 & 3226.60 & 1723.11\\\hline
\multirow{2}*{Sync Time(ms)}
& IA32 & 7.156   & 25.607 & 189.793 & 70.336 & 286.354 & 86.888 & 6.446 & 18.434\\
& IA64 & 5.960   & 7.043 & 21.980 & 10.078 & 2.780 & 13.793& 2.922 & 5.385\\\hline
\end{tabular}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=583335008&uk=1728178661).

## 体型「不正常」的表格

### 「肥胖」表格

你可能已经注意到，在代码 09 中，我使用了 standalone 文档类，而不是之前一直在使用的 ctexart 文档类。standalone 这个文档类，会根据需要，设定恰好的纸张大小，特别适合生成 pdf 格式的图档。事实上，在代码 09 中的表格，就是一个「肥胖」的表格。如果你把上面这段代码放在普通的 article 文档类中，或是像之前一样放在 ctexart 中，因为表格过于宽，会超过页面跑到异次元去。比如你可以编译下面的代码试试看

```tex
% 我是一个错误演示
\documentclass{article}
\usepackage{multirow}
\begin{document}
\begin{tabular}{|*{10}{r|}}
\hline
\multicolumn{2}{|c|}{\multirow{2}*{Blank}}
& \multicolumn{2}{|c|}{CG} & \multicolumn{2}{|c|}{IS}
& \multicolumn{2}{|c|}{MG} & \multicolumn{2}{|c|}{LU}\\\cline{3-10}
\multicolumn{2}{|c|}{}  & 2   & 4 & 2 & 4 & 2 & 4 & 2 & 4\\\hline
\multirow{2}*{Run Time(s)}
& IA32 & 24.37   & 16.18 & 19.62 & 8.98 & 31.98 & 18.71 & 622.76 & 266.16\\
& IA64 & 54.41   & 30.29 & 25.54 & 15.72 & 164.16 & 84.73 & 3226.60 & 1723.11\\\hline
\multirow{2}*{Sync Time(ms)}
& IA32 & 7.156   & 25.607 & 189.793 & 70.336 & 286.354 & 86.888 & 6.446 & 18.434\\
& IA64 & 5.960   & 7.043 & 21.980 & 10.078 & 2.780 & 13.793& 2.922 & 5.385\\\hline
\end{tabular}
\end{document}
```

为了解决这个问题，同时尽可能让示例简单明了，我们将会在下面这个表格的基础上进行修改

```tex
% 我是一个肥胖儿童
\documentclass[UTF8]{ctexart}
\begin{document}
\begin{table}[!htbp]
\begin{tabular}{|*{5}{c|}}
\hline
第一列第一列& 第二列第二列& 第三列第三列& 第四列第四列& 第五列第五列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列& 第四列第四列& 第五列第五列\\
\hline
\end{tabular}
\end{table}
\end{document}
```

它的编译结果在[这里](http://pan.baidu.com/share/link?shareid=657593804&uk=1728178661).

#### 压缩

一个显然的想法，是横纵各压缩相同的比例，使得表格足够「苗条」。

graphicx 宏包提供的 \resizebox{h-length}{v-length}{text} 命令可以满足要求。这个命令可以将 text 中的内容拉伸至 h-length 和 v-length 指定的长度。同时如果将 ! 填入 v-length 的话，将会按照 h-length 的比例拉伸 text 中的内容。

参考以下代码

```tex
% 我是代码 10 号
\documentclass[UTF8]{ctexart}
\usepackage{graphicx}
\begin{document}
\begin{table}[!htbp]
\resizebox{\textwidth}{!}{
\begin{tabular}{|*{5}{c|}}
\hline
第一列第一列& 第二列第二列& 第三列第三列& 第四列第四列& 第五列第五列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列& 第四列第四列& 第五列第五列\\
\hline
\end{tabular}
}
\end{table}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=698669715&uk=1728178661).

这种方法在「微胖」的时候特别有用，但是如果表格超出页面太多，这样强制压缩会使得表格内的文字太小，「有碍观瞻」。因此我们需要考虑另外的方法。

#### 限制列宽

如果我们用 p{} 选项限制列宽，则能够间接控制整个表格的宽度，从而达到目的。但是 p{} 选项不能同时和 lrc 等位置选项并存，也就是说使用 p{} 选项的时候，我们就无法控制列内的文字位置，这是不科学的。

考虑到这个情况，我们需要对 LaTeX 本身的命令做一些补充，才能够达到我们的目的。array 宏包为我们提供了这样做的可能。下面的代码，定义了 L{} R{} C{} 三个表格列选项，集合了原本的 lrc 的功能以及 p{} 选项限制列宽的功能

```tex
% 我是代码 11 号
\documentclass[UTF8]{ctexart}
\usepackage{array}
\newcolumntype{L}[1]{>{\vspace{0.5em}\begin{minipage}{#1}\raggedright\let\newline\\
\arraybackslash\hspace{0pt}}m{#1}<{\end{minipage}\vspace{0.5em}}}
\newcolumntype{R}[1]{>{\vspace{0.5em}\begin{minipage}{#1}\raggedleft\let\newline\\
\arraybackslash\hspace{0pt}}m{#1}<{\end{minipage}\vspace{0.5em}}}
\newcolumntype{C}[1]{>{\vspace{0.5em}\begin{minipage}{#1}\centering\let\newline\\
\arraybackslash\hspace{0pt}}m{#1}<{\end{minipage}\vspace{0.5em}}}
\begin{document}
\begin{table}[!htbp]
\begin{tabular}{|*{5}{C{.15\textwidth}|}}
\hline
第一列第一列& 第二列第二列& 第三列第三列& 第四列第四列& 第五列第五列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列& 第四列第四列& 第五列第五列\\
\hline
\end{tabular}
\end{table}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=924248527&uk=1728178661).

实际应用中，还可以将这两个方法结合起来，效果拔群。

### 「姚明」表格

LaTeX 将 tabular 环境当做一个 box 来处理，因此用 tabular 环境输出的表格不能跨页。当然你可以使用 \resizebox 命令来缩放表格，不过显然，会有更好的办法。

longtable 宏包提供了 longtable 环境，来生成可以跨页的表格。下面是一个示例

```tex
% 我是代码 12 号
\documentclass[UTF8]{ctexart}
\usepackage{longtable}
\begin{document}
\begin{longtable}{|c|c|c|}
\caption{这是一个很长的表格}\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
第一列第一列& 第二列第二列& 第三列第三列\\
\hline
\end{longtable}
\end{document}
```

编译结果在[这里](http://pan.baidu.com/share/link?shareid=983716071&uk=1728178661).

## 斜线表头

diagbox 宏包可以制作斜线表头。参照下列示例

```tex
% 我是代码 13 号
\documentclass{article}
\usepackage{diagbox}
\begin{document}
\begin{tabular}{|l|ccc|}
\hline
\diagbox{Time}{Room}{Day} & Mon & Tue & Wed \\
\hline
Morning & used & used &\\
Afternoon & & used & used \\
\hline
\end{tabular}
\end{document}
```

编译结果见[这里](http://pan.baidu.com/share/link?shareid=1058016872&uk=1728178661).