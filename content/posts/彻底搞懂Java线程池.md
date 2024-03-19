---
title: 彻底搞懂Java线程池
date: 2023-06-18 19:52:32
tags:
- Java并发
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 线程池概述
线程池（Thread Pool）是一种基于池化思想管理线程的工具，经常出现在多线程服务器中，如MySQL。
线程过多会带来额外的开销，其中包括创建销毁线程的开销、调度线程的开销等等，同时也降低了计算机的整体性能。线程池维护多个线程，等待监督管理者分配可并发执行的任务。这种做法，一方面避免了处理任务时创建销毁线程开销的代价，另一方面避免了线程数量膨胀导致的过分调度问题，保证了对内核的充分利用。
线程池解决的核心问题就是资源管理问题。在并发环境下，系统不能够确定在任意时刻中，有多少任务需要执行，有多少资源需要投入。这种不确定性将带来以下若干问题：

1. 频繁申请/销毁资源和调度资源，将带来额外的消耗，可能会非常巨大。
2. 对资源无限申请缺少抑制手段，易引发系统资源耗尽的风险。
3. 系统无法合理管理内部的资源分布，会降低系统的稳定性。
## 使用场景

1. 需要频繁使用线程做一些并发的工作（创建异步线程做一些异步的工作）
2. 线程的创建成本高 （数据库连接池）
## 线程池核心原理
对于一些初始化比较麻烦且耗时的工作，通过池化技术维护一些状态是一种比较常用的手段。减少创建步骤，可以提高重复利用率，让程序运行更高效。大致的流程如下图所示。
![thread-pool-simple.png](https://cdn.nlark.com/yuque/0/2023/png/21760570/1695287674571-0f4d1cf7-fbc7-4dbe-9d55-877559cbf0d8.png#averageHue=%23fbf7f7&clientId=u6b20e3a0-79f1-4&from=paste&height=292&id=u2715bf31&originHeight=292&originWidth=587&originalType=binary&ratio=1&rotation=0&showTitle=false&size=68964&status=done&style=none&taskId=u8a4b6901-5d0a-4f98-8d16-c0d594597fb&title=&width=587)

## 源码分析
理解源码的最好的方式，是自己去实现一下核心流程，才能体会到作者在写代码时候的思考有多细致，代码写的有多优雅。不然你是感受不出来的。
### 核心流程

1. 状态管理
2. 任务处理
3. 任务执行
#### 状态管理
八股文开始，线程池有几种状态（RUNNING，SHUTDOWN，STOP， TIDYING，TERMINATED），他们的之间的状态是怎么扭转的？
![](https://cdn.nlark.com/yuque/0/2023/jpeg/21760570/1695558634578-6184adbd-45c3-4ecf-a2f5-e6baf766a759.jpeg)
> 问问自己：
> 1. shutdown和stop有什么区别？
> 2. shutdown或者shutdownNow之后，正在工作的线程，队列中剩余任务怎么处理的？
> 3. shutdown过程中怎么保证并发？
> 4. TIDYING是什么状态，什么情况会变成这种状态？
> 5. TIDYING和 TERMINATED 状态有什么区别？

##### 状态解读

- RUNNING：运行状态，接受新的任务并且处理队列中的任务。
- SHUTDOWN：关闭状态(调用了shutdown方法)。不接受新任务，,但是要处理队列中的任务。
- STOP：停止状态(调用了shutdownNow方法)。不接受新任务，也不处理队列中的任务，并且要中断正在处理的任务。
- TIDYING：所有的任务都已终止了，workerCount为0，线程池进入该状态后会调 terminated() 方法进入TERMINATED 状态。
- TERMINATED：终止状态，terminated() 方法调用结束后的状态。
#### 
在状态的值的设计上，Doug Lea也很细节。欣赏一下。
```java
// 通过一个原子变量保存状态和工作线程数
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
private static final int COUNT_BITS = Integer.SIZE - 3;
// int的后29位来作为工作线程数的最大容量
private static final int CAPACITY   = (1 << COUNT_BITS) - 1;
/**
* 前3位表示状态。
* 这几个状态设计就很巧妙。
* RUNING 111刚好是个负数
* 其他值是正数，而且刚好是递增的，
* 下面通过位运算来判断和更改线程状态和线程数非常高效。
* 太细节了呀。
*/
// runState is stored in the high-order bits
private static final int RUNNING    = -1 << COUNT_BITS;
private static final int SHUTDOWN   =  0 << COUNT_BITS;
private static final int STOP       =  1 << COUNT_BITS;
private static final int TIDYING    =  2 << COUNT_BITS;
private static final int TERMINATED =  3 << COUNT_BITS;

// Packing and unpacking ctl
private static int runStateOf(int c)     { return c & ~CAPACITY; }
private static int workerCountOf(int c)  { return c & CAPACITY; }
private static int ctlOf(int rs, int wc) { return rs | wc; }

/*
 * Bit field accessors that don't require unpacking ctl.
 * These depend on the bit layout and on workerCount being never negative.
 */

private static boolean runStateLessThan(int c, int s) {
    return c < s;
}

private static boolean runStateAtLeast(int c, int s) {
    return c >= s;
}

private static boolean isRunning(int c) {
    return c < SHUTDOWN;
}
```

#### 任务处理
脱离状态管理和并发处理，任务的处理其实很简单。用一个小小的流程图来帮助理解一下。
![](https://cdn.nlark.com/yuque/__puml/8129d73ee483332045d085a8bfe29369.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOuaJp-ihjOS7u-WKoTtcblxuaWYgKOe6v-eoi-axoOS4reeahOe6v-eoi-aYr-WQpuWwj-S6juaguOW_g-e6v-eoi-aVsCkgdGhlbiAodHJ1ZSlcbiAgOuWIm-W7uldvcmtlcue6v-eoi-aUvuWFpeaxoOS4rTtcbiAgOuWQr-WKqFdvcmtlcue6v-eoi-aJp-ihjOS7u-WKoTtcbmVsc2UgKGZhbHNlKVxuICA65bCG5Lu75Yqh5pS-5YWl6Zi75aGe6Zif5YiX77yM562J5b6F57q_56iL5omn6KGMO1xuXHRpZiAo6Zif5YiX5ruh5LqG5L2G5rGg5Lit57q_56iL5pWw5bCP5LqO5pyA5aSn57q_56iL5pWwKSB0aGVuICh0cnVlKVxuXHRcdDrliJvlu7rpnZ7moLjlv4Pnur_nqIvmiafooYzku7vliqE7XG5cdGVsc2UgKGZhbHNlKVxuXHRcdDrmi5Lnu53nrZbnlaU7XG5cdGVuZGlmXG5cbmVuZGlmXG5cbnN0b3BcblxuQGVuZHVtbCIsInVybCI6Imh0dHBzOi8vY2RuLm5sYXJrLmNvbS95dXF1ZS9fX3B1bWwvODEyOWQ3M2VlNDgzMzMyMDQ1ZDA4NWE4YmZlMjkzNjkuc3ZnIiwiaWQiOiJjVWhDbCIsIm1hcmdpbiI6eyJ0b3AiOnRydWUsImJvdHRvbSI6dHJ1ZX0sImNhcmQiOiJkaWFncmFtIn0=)
但如果加上状态处理和并发处理的逻辑，就变得很复杂很多了。
> 但是我们可以思考一下，上面那些过程会出现并发问题？

##### void execute(Runnable command)

![](https://cdn.nlark.com/yuque/__puml/5069056708363b2aaccc59b338ad18d5.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOuaJp-ihjOS7u-WKoTtcblxuaWYgKOe6v-eoi-axoOS4reeahOe6v-eoi-aYr-WQpuWwj-S6juaguOW_g-e6v-eoi-aVsCkgdGhlbiAodHJ1ZSlcbiAgaWYgKOWIm-W7undvcmtlcue6v-eoiykgdGhlbiAo5oiQ5YqfKVxuXHRcdDpXb3JrZXLnur_nqIvmlL7lhaXmsaDkuK07XG5cdFx0ZW5kXG5cdGVuZGlmXG5lbmRpZlxuaWYgKOe6v-eoi-axoOeKtuaAgeS4uui_kOihjCAmJiDmt7vliqDpmJ_liJfmiJDlip8pIHRoZW4gKHRydWUpXG5cdDrph43mlrDmo4Dmn6Xnur_nqIvmsaDnirbmgIE7XG5cdFx0Oue6v-eoi-axoOeKtuaAgemdnui_kOihjO-8jOWwneivleenu-mZpOWImua3u-WKoOeahOWFg-e0oDtcblx0XHQ656e76Zmk5oiQ5Yqf5ZCO77yM6Kem5Y-R5ouS57ud562W55WlO1xuXHRpZiAo5Lu75Yqh5o-Q5Lqk5ZCO77yM57q_56iL5rGg5rKh5pyJ57q_56iL5aSE55CGKSB0aGVuICh0cnVlKVxuXHRcdDrmt7vliqBXb3JrZXLnur_nqIvmlL7lhaXmsaDkuK07XG5cdGVuZGlmXG5lbmRpZlxuXG5zdG9wXG5cbkBlbmR1bWwiLCJ1cmwiOiJodHRwczovL2Nkbi5ubGFyay5jb20veXVxdWUvX19wdW1sLzUwNjkwNTY3MDgzNjNiMmFhY2NjNTliMzM4YWQxOGQ1LnN2ZyIsImlkIjoicXVocW4iLCJtYXJnaW4iOnsidG9wIjp0cnVlLCJib3R0b20iOnRydWV9LCJjYXJkIjoiZGlhZ3JhbSJ9)

咋一看也还好，不就一些判断吗？

任务处理分为两个关键方法：

1. execute
2. addWorker

上面只是execute方法
##### boolean addWorker(Runnable firstTask, boolean core)
![](https://cdn.nlark.com/yuque/__puml/ea7fbd9e88b249f83a013ce5196a8b48.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOua3u-WKoOS7u-WKoTtcbjog6Ieq5peLQ0FTIOiOt-WPluWIm-W7uue6v-eoi-eahOacuuS8mjtcbjrliJvlu7p3b3JrZXLnur_nqIs7XG465Yqg6ZSB5bCGd29ya2Vy5re75Yqg5Yiwc2V05LitO1xuaWYgKOe6v-eoi-axoOeKtuaAgeS4uui_kOihjCAmJiDku7vliqHkuI3mmK9udWxsKSB0aGVuICh0cnVlKVxuXHQ65aaC5p6c57q_56iL5bey57uP5ZCv5Yqo5LqG77yM5oql6ZSZO1x0XG5cdDrlsIbliJvlu7rnmoR3b3JrZXLmt7vliqDliLBzZXTkuK07XG5cdDrlpoLmnpzliqDlhaXmiJDlip_kuobvvIzlkK_liqjnur_nqIs7XG5cdDrlpoLmnpzlkK_liqjlpLHotKXkuobvvIzku45zZXTkuK3np7vpmaTvvIxDQVPlh4_lsJHnur_nqIvmlbDph487XG5lbmRpZlxuXG5zdG9wXG5cbkBlbmR1bWwiLCJ1cmwiOiJodHRwczovL2Nkbi5ubGFyay5jb20veXVxdWUvX19wdW1sL2VhN2ZiZDllODhiMjQ5ZjgzYTAxM2NlNTE5NmE4YjQ4LnN2ZyIsImlkIjoiVXBUa3IiLCJtYXJnaW4iOnsidG9wIjp0cnVlLCJib3R0b20iOnRydWV9LCJjYXJkIjoiZGlhZ3JhbSJ9)

每次添加都有可能面临并发，从而导致失败，那如何保证添加的原子性，正常来讲，加锁嘛。但是加锁会不会有点太重了。每次都要触发系统调用。Doug Lea大神用的是自旋的CAS，来欣赏一下源码。
```java
retry:
for (;;) {
    int c = ctl.get();
    //线程状态
    int rs = runStateOf(c);

    // Check if queue empty only if necessary.
    if (rs >= SHUTDOWN &&
        ! (rs == SHUTDOWN &&
           firstTask == null &&
           ! workQueue.isEmpty()))
        return false;

    for (;;) {
        int wc = workerCountOf(c);
        if (wc >= CAPACITY ||
            wc >= (core ? corePoolSize : maximumPoolSize))
            //工作线程数超过了最大值
            return false;
        if (compareAndIncrementWorkerCount(c))
            //CAS成功了，可以去下面创建线程了
            break retry;
        c = ctl.get();  // Re-read ctl
        if (runStateOf(c) != rs)
            // 线程池状态发生了改变，从头开始
            continue retry;
        // else CAS failed due to workerCount change; retry inner loop
    }
}
```
#### 任务执行
![](https://cdn.nlark.com/yuque/__puml/2a282557d9f1176a0ea103a6dd8ecbce.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOuW3peS9nOe6v-eoi-WQr-WKqDtcbnJlcGVhdFxuXHQ65bel5L2c57q_56iL5Yqg6ZSBO1xuXHRpZiAo57q_56iL5rGg54q25oCB5piv5ZCmc3RvcCkgdGhlbiAodHJ1ZSlcblx0XHQ65Lit5patO1xuXHRlbHNlXG5cdFx0OuaJp-ihjOS7u-WKoeWJjee9ruWkhOeQhjtcblx0XHRmbG9hdGluZyBub3RlIHJpZ2h0OiDmianlsZVcblx0XHQ65omn6KGM5Lu75YqhJuW8guW4uOWkhOeQhjtcblx0XHQ65omn6KGM5Lu75Yqh5ZCO572u5aSE55CGO1xuXHRcdGZsb2F0aW5nIG5vdGUgcmlnaHQ6IOaJqeWxlVxuXHRcdDrlt6XkvZznur_nqIvop6PplIE7XG5cdFx0OuWkhOeQhuW3peS9nOe6v-eoi-mAgOWHujtcblx0XHRmbG9hdGluZyBub3RlIHJpZ2h0OiDmm7TmlLnnur_nqIvmsaDlt6XkvZznur_nqIvmlbDph49cblx0ZW5kaWZcbnJlcGVhdCB3aGlsZSAo6Ieq6Lqr5Lu75Yqh5LiN5Li656m6IHx8IOS7jumYn-WIl-S4reiOt-WPluWIsOS7u-WKoSlcblxuc3RvcFxuXG5AZW5kdW1sIiwidXJsIjoiaHR0cHM6Ly9jZG4ubmxhcmsuY29tL3l1cXVlL19fcHVtbC8yYTI4MjU1N2Q5ZjExNzZhMGVhMTAzYTZkZDhlY2JjZS5zdmciLCJpZCI6ImsyUENyIiwibWFyZ2luIjp7InRvcCI6dHJ1ZSwiYm90dG9tIjp0cnVlfSwiY2FyZCI6ImRpYWdyYW0ifQ==)
### 注意
比较需要注意的，什么时候需要处理并发场景。这个是需要小心翼翼思考的问题。

1. 添加任务，核心线程接近满了或者队列接近满了 【execute方法】
2. 添加过程中，线程池状态变了【addWorker方法】
3. cas增加线程数成功了，但是添加任务的时候失败了（可能是线程池状态变更了）【addWorkerFailed�方法】
4. 添加线程成功了，但是启动失败了，需要回滚状态【addWorkerFailed�】
5. 工作线程执行完了，或者执行失败了，应该怎么处理【runWorker方法】
## 总结
线程池的核心还是体现在ThreadPoolExecutor�这个类，主要体现在这几个流程

1. 状态管理
2. 任务处理（execute , addWorker方法）
3. 任务执行 （runWorker , getTask方法）

在状态管理上，作者用了大量的自旋CAS操作来管理状态和线程数的变更。在任务添加和执行过程中甚至也用到了一下recheck的方式。
整体的逻辑，刚开始看可能会比较手足无措，但是当你尝试自己去写的时候，你会发现作者的实现思路可能不一致，你就会去想作者为什么这样写。然后追着主流程慢慢捋，你才能慢慢感受到作者的思考的细致，以及借鉴一些思路，这才是你的学习与成长。享受这个过程！