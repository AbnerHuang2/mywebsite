---
title: "Go高性能编程Workshop"
description: "完整翻译Dave Cheney的High Performance Go Workshop，系统学习Go性能优化"
date: 2024-11-17
---

<meta name="referrer" content="no-referrer" />

## 概述

本workshop的目标是为你提供诊断和修复Go应用程序性能问题所需的工具。

在这一天中，我们将从小处着手——学习如何编写基准测试，然后剖析一小段代码。接着扩展到讨论执行追踪器、垃圾回收器以及追踪运行中的应用程序。最后将有时间让你提问、实验你自己的代码。

> 本系列完整翻译自 Dave Cheney 的 [High Performance Go Workshop (dotGo Paris)](https://dave.cheney.net/high-performance-go-workshop/dotgo-paris.html)

## 日程安排

这是（大致的）一天的日程：

| 时间 | 内容 |
|-----|------|
| 09:00 | 欢迎和介绍 |
| 09:30 | 基准测试 |
| 10:45 | 休息（15分钟）|
| 11:00 | 性能测量和剖析 |
| 12:00 | 午餐（90分钟）|
| 13:30 | 编译器优化 |
| 14:30 | 执行追踪器 |
| 15:30 | 休息（15分钟）|
| 15:45 | 内存和垃圾回收器 |
| 16:15 | 技巧与陷阱 |
| 16:30 | 练习 |
| 16:45 | 最后的问题和总结 |
| 17:00 | 结束 |

## 欢迎

你好，欢迎！🎉

本workshop的目标是为你提供诊断和修复Go应用程序性能问题所需的工具。

在这一天中，我们将从小处着手——学习如何编写基准测试，然后剖析一小段代码。接着扩展到讨论执行追踪器、垃圾回收器以及追踪运行中的应用程序。最后将有时间让你提问、实验你自己的代码。

### 讲师

* Dave Cheney dave@cheney.net

### 许可证和材料

本workshop是David Cheney和Francesc Campoy的合作成果。

本演示文稿根据Creative Commons Attribution-ShareAlike 4.0 International许可证授权。

### 先决条件

今天你需要以下软件：

#### Workshop代码仓库

从以下地址下载本文档的源码和代码示例：<https://github.com/davecheney/high-performance-go-workshop>

#### Go 1.12

workshop材料面向Go 1.12。

下载 [Go 1.12](https://golang.org/dl/)

> 如果你已经升级到Go 1.13也没关系。在Go的小版本之间总会有一些优化选择的小变化，我会在讲解过程中指出这些差异。

#### Graphviz

pprof章节需要`dot`程序，它随`graphviz`工具套件一起提供。

* Linux: `[sudo] apt-get install graphviz`
* OSX:
  * MacPorts: `sudo port install graphviz`
  * Homebrew: `brew install graphviz`
* Windows（未测试）

#### Google Chrome

执行追踪器章节需要Google Chrome。它不能在Safari、Edge、Firefox或IE 4.01上工作。请告诉你的电池我很抱歉。

下载 [Google Chrome](https://www.google.com/chrome/)

#### 你自己的代码用于剖析和优化

当天的最后一部分将是一个开放环节，你可以用学到的工具进行实验。

### 还有一件事...

这不是一场讲座，而是一次对话。我们会有很多休息时间来提问。

如果你不理解某些内容，或者认为你听到的内容不正确，请提问。

## 章节目录

### [第1章：微处理器性能的过去、现在与未来](/series/go-performance/01-microprocessor-performance/)

理解硬件演进历史，为什么单核性能停滞，以及这对编写高性能代码意味着什么。

**核心内容：**
- Mechanical Sympathy（机械同理心）
- 六个数量级的性能提升
- 计算机还在变快吗？
- 时钟频率
- 热量问题
- Dennard scaling的终结
- 更多核心
- Amdahl定律
- 现代CPU针对批量操作优化
- 现代处理器受限于内存延迟而非内存容量
- 缓存规则一切
- 免费的午餐结束了

### [第2章：基准测试](/series/go-performance/02-benchmarking/)

学习如何正确地编写和运行基准测试，避免常见陷阱。

**核心内容：**
- 基准测试的基本规则
- 使用testing包进行基准测试
- 使用benchstat比较基准测试
- 避免基准测试的启动成本
- 基准测试内存分配
- 注意编译器优化
- 基准测试常见错误
- 从基准测试进行剖析

### 第3章：性能测量和剖析 🚧

使用pprof工具深入分析程序性能。

### 第4章：编译器优化 🚧

理解Go编译器的优化技术。

### 第5章：执行追踪器 🚧

使用execution tracer可视化程序执行。

### 第6章：内存和垃圾回收器 🚧

深入理解Go的GC和内存管理。

### 第7章：技巧与陷阱 🚧

实用的性能优化建议和需要避免的陷阱。

---

## 关于翻译

本系列文章是对Dave Cheney的High Performance Go Workshop的忠实翻译，使用专业术语但力求让Go初级开发者也能理解。

所有代码示例、图片和结构都保持与原文一致。

## 参考资料

- [High Performance Go Workshop 原文](https://dave.cheney.net/high-performance-go-workshop/dotgo-paris.html)
- [Workshop GitHub仓库](https://github.com/davecheney/high-performance-go-workshop)
