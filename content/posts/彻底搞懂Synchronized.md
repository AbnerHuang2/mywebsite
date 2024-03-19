---
title: 彻底搞懂Synchonized
date: 2023-05-22 21:32:32
tags:
- Java并发
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## CPU执行过程
我们都知道Synchonized可以保证原子性，可以保证线程的同步。那么Synchonized是怎么保证的呢。
从CPU说起，
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1657025657089-bd585f3c-da74-4a4d-a51b-e2fdecbd44ec.jpeg)
这是CPU的处理流程图，而线程之间无法同步的本质，就是数据的副本在多个CPU上操作，导致数据的不一致。那么要怎么解决这个问题呢？之前讲过volatile是在总线上通过MESI协议来保证对单个数据的读/写的原子性。但是无法解决i++这种读-改-写的复合操作。那么Synchonized是怎么做的呢？
## 监控锁（原子性保证）
使用Synchonized关键字封装的代码块在编译成汇编语言时，会在这段代码块之前加上monitorenter关键字，之后加上monitorexit关键字。加上这两个关键字怎么就可以保证数据的同步呢？
### 总线锁定
当cpu执行到monitorenter时，会在总线上发出lock信号，其他cpu收到lock信号之后，就不能操作缓存和内存中的值了。所以这个代价挺高的。
### 缓存锁定
总线锁定封锁了缓存和主存数据的读取和修改，为了降低总线锁定的代价，有些cpu把单个值的更新优化成了缓存锁定。对于下图的场景，当CPU1修改了缓存中的值时，CPU2修改时就发现缓存锁定了，无法修改了。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657027629849-34b642db-8547-4556-b037-f7e51c033137.png#averageHue=%23fcfdfa&clientId=uf7a4686d-c9e8-4&from=paste&height=445&id=ubef4febd&originHeight=890&originWidth=972&originalType=binary&ratio=1&rotation=0&showTitle=false&size=304195&status=done&style=none&taskId=u3403d70b-e8fb-4a2f-9681-0b40fa08f6a&title=&width=486)
但是缓存锁定有两个限制：

1. 只能针对单个缓存行的更改【缓存行：缓存的最小单位】
2. 有些处理器不支持
# 锁升级
虽然上诉过程可以在底层保证操作的原子性。但是总线锁定的成本也是很高的。而且JVM团队在实际场景中发现，出现并发的场景其实很少。
于是在JDK1.6版本就优化Synchronized的实现。提出了锁升级的过程。
## 锁状态
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1657027934270-063210cb-dace-4f9d-a10e-587cca2e4cd3.jpeg)
## 锁升级过程
![](https://cdn.nlark.com/yuque/0/2024/jpeg/21760570/1710337738567-aacb719f-d283-48f4-b446-9618da34f5f7.jpeg)
![image.png](https://cdn.nlark.com/yuque/0/2024/png/21760570/1710337312164-0d63d048-629e-4f7f-a6a6-c385f0f2496e.png#averageHue=%2398ab5b&clientId=u1e4897e6-c9d5-4&from=paste&height=451&id=u9ca41cae&originHeight=902&originWidth=1890&originalType=binary&ratio=2&rotation=0&showTitle=false&size=661770&status=done&style=none&taskId=u1ec4a00c-5372-4872-9fda-fd75aa33744&title=&width=945)