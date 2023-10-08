---
title: Jstack分析神器
description: fastthread.io帮你分析线上thread
date: 2022-04-19 17:44:18
tags:
- JVM
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# What is fastthread.io?
在线jstack thread dump分析工具。
# Use

1. jstack <pid> > thread.log 
1. 打开网址[https://fastthread.io/](https://fastthread.io/)
1. 将thread.log 上传到fastthread.io
# Menu
## Exception
存在正在抛异常的线程
[https://blog.fastthread.io/2020/06/10/threads-throwing-exception/](https://blog.fastthread.io/2020/06/10/threads-throwing-exception/)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645970464103-6363a5e4-aea8-472d-a67d-93da4d40db07.png#clientId=u61d7cd03-53fd-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=315&id=u2239a8e7&margin=%5Bobject%20Object%5D&name=image.png&originHeight=630&originWidth=2080&originalType=binary&ratio=1&rotation=0&showTitle=false&size=271078&status=done&style=none&taskId=ua3fc2936-6008-4bcf-b312-ff1b515bb9c&title=&width=1040)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645970375887-7426c9f5-75d6-4b79-ac64-174ca628f139.png#clientId=u61d7cd03-53fd-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=279&id=ub1cde824&margin=%5Bobject%20Object%5D&name=image.png&originHeight=558&originWidth=2878&originalType=binary&ratio=1&rotation=0&showTitle=false&size=146030&status=done&style=none&taskId=uc88a11b6-a6b0-4783-b174-f9c541b93b7&title=&width=1439)
## **Identical Stack trace**
**具有相同堆栈跟踪的线程在此处分组。如果许多线程开始表现出相同的堆栈跟踪，这可能是一个问题.**
[https://blog.fastthread.io/2016/02/22/thread-dump-analysis-pattern-repetitive-strain-injury-rsi/](https://blog.fastthread.io/2016/02/22/thread-dump-analysis-pattern-repetitive-strain-injury-rsi/)
当应用程序出现性能瓶颈时，大部分线程将开始在有问题的瓶颈区域累积。这些线程将具有相同的堆栈跟踪。因此，每当大量线程表现出相同/重复的堆栈跟踪时，就应该调查这些堆栈跟踪。这可能表示性能问题
## CPU Thread 
thread dump时刻，真正在使用cpu的thread。jvm的runable状态的线程不一定在消耗cpu。比如有些在进行IO的读写，并不消耗cpu。
## Transitive Graph (传递性图表)
**如果存在这个，说明可能有问题**
Thread-A 可能已经获得了 lock-1，然后永远不会释放它。线程 B 可能已经获得了 lock-2 并等待这个 lock-1。Thread-C 可能正在等待获取 lock-2。这种线程之间的传递块可以使整个应用程序无响应。
[https://blog.fastthread.io/2016/06/23/really-running/](https://blog.fastthread.io/2016/06/23/really-running/) (运动员模式)
## **Complex** DeadLock
循环死锁
[https://blog.fastthread.io/2016/05/18/circular-deadlock/](https://blog.fastthread.io/2016/05/18/circular-deadlock/)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645967455858-5ce63e24-877b-476c-ad89-5f32591689c7.png#clientId=u2f4fc0c2-d2a1-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=436&id=u34d99403&margin=%5Bobject%20Object%5D&name=image.png&originHeight=872&originWidth=1672&originalType=binary&ratio=1&rotation=0&showTitle=false&size=252964&status=done&style=none&taskId=u6dde36cd-335a-4edb-9e78-541f3f26818&title=&width=836)
## DeadLock
死锁
[https://blog.fastthread.io/2016/04/25/deadlock/](https://blog.fastthread.io/2016/04/25/deadlock/)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645967436228-53da0b04-a6c1-451f-af7f-772ea0b211e5.png#clientId=u2f4fc0c2-d2a1-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=402&id=u720b9b9c&margin=%5Bobject%20Object%5D&name=image.png&originHeight=804&originWidth=1166&originalType=binary&ratio=1&rotation=0&showTitle=false&size=141987&status=done&style=none&taskId=u5309f9c5-f53c-45f2-b918-f0a7cee052f&title=&width=583)
## Finalizer Thread
如果 finalizer 线程被 BLOCKED 或 WAITING 很长时间，它可能会导致 OutOfMemoryError。
[https://blog.fastthread.io/2015/11/20/thread-dump-analysis-pattern-leprechaun-trap/](https://blog.fastthread.io/2015/11/20/thread-dump-analysis-pattern-leprechaun-trap/)
具有 finalize() 方法的对象在垃圾收集过程中的处理方式与没有它们的对象不同。在垃圾回收阶段，带有 finalize() 的对象不会立即从内存中逐出。相反，作为第一步，这些对象被添加到 java.lang.ref.Finalizer 对象的内部队列中。有一个名为“ _**Finalizer”**_的低优先级 JVM 线程， 它执行队列中每个对象的 finalize() 方法。只有在 finalize() 方法执行后，对象才有资格进行垃圾回收。由于 finalize() 方法的糟糕实现，如果_Finalizer _线程被阻塞，那么它将对 JVM 产生严重的有害级联影响。
## Flame Graph
火焰图(并不是指一段时间的各个线程占用cpu的时间，而是在线程dump时刻，统计有多少个线程在调用哪些方法，以此来生成的火焰图)
[https://blog.fastthread.io/2018/12/07/benefits-of-a-flame-graph/](https://blog.fastthread.io/2018/12/07/benefits-of-a-flame-graph/)
线程转储文件往往跨越数百行（有时数千行）。由于其冗长，很难构思和吸收线程转储中的所有信息。[fastThread](https://fastthread.io/)工具生成的火焰图将所有信息浓缩成一个单一的紧凑火焰图格式。它有助于您快速识别热代码路径。在本文中，让我们学习如何使用 fastThread 工具生成的火焰图进行有效的调试/故障排除。

# Here comes the question
什么时候该去看thread dump log 呢?
jvm gc？ java进程的cpu占用高？池化资源耗尽（数据库连接池，http调用池，dubbo）？
怎么看哪些线程耗尽了数据库资源？


# So How to grasp troubleshooting  in thread dump
**without thinking**

1. 从exception找线索。
1. 从Identical Stack trace中看看大多数线程都在干嘛。如果都在等外部连接，可能会有一些问题。
1. 从DeadLock列看看有没有死锁。

**for more**，具体情况还是要具体分析。