---
title: "提升时间机器（Time Machine）的备份速度"
url: https://liam.page/2022/05/07/speed-up-time-machine-backup/
date: 2022-05-07
categories: ["Computer Skills"]
tags: ["Apple", "Time Machine"]
---

时间机器（Time Machine）是苹果针对 macOS 系统的电脑推出的备份方案。自 2014 年接触依赖，它已经数次拯救了我的电脑和数据，可谓功劳甚大。然而，时间机器备份的速度着实令人捉急。

经查，类似时间机器备份或是自 MAS 下载和安装软件的行为，苹果将其优先级调低，并设置有限流（throttle）这一设定。这是为了保证这些优先级较低的行为不会占用过多的系统资源，干扰正常的工作。

这个设定的出发点是好的，但存在一个问题。比如说，对我而言，使用时间机器备份通常发生在无需使用电脑工作的时间段。此时，限流的这个设定就十分让人蛋疼了。为此，我们可以在命令行暂时关闭限流，待备份完成后再重新打开。命令如下：

```bash
# 关闭限流功能，加速备份
sudo sysctl debug.lowpri_throttle_enabled=0
# 备份完成，重新打开限流功能，避免意外的干扰
sudo sysctl debug.lowpri_throttle_enabled=1
```