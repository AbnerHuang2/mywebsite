---
title: Jstack-抓住摸鱼的线程
description: 详解Jstack
date: 2022-04-19 16:24:35
tags:
- Java
- JVM
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# jstack是啥
jstack是java虚拟机自带的一种堆栈跟踪工具，用于分析java线程的执行情况
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645021418946-2fa22a5b-894c-411b-b44a-c2fc926cc9d9.png#clientId=u36e5c111-c0ef-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=239&id=ue4426d11&margin=%5Bobject%20Object%5D&name=image.png&originHeight=478&originWidth=874&originalType=binary&ratio=1&rotation=0&showTitle=false&size=423792&status=done&style=none&taskId=uc9aa862c-1d35-4134-94db-2950d4f590a&title=&width=437)
# jstack常用实践

1. 死锁分析
1. cpu高负载分析
1. 请求外部资源导致的长时间等待
# jstack常用命令
jstack <pid>
> Options
> -F  强制dump线程堆栈信息. 用于进程hung住， jstack <pid>命令没有响应的情况 
> -m  同时打印java和本地(native)线程栈信息，m是mixed mode的简写 
> -l  打印锁的额外信息

# 如何看懂jstack的dump结果
先来看一份dump结果[abc.log](https://www.yuque.com/attachments/yuque/0/2022/log/21760570/1645021994927-d63c76e0-6257-49c4-bfda-4fb55086a5fc.log?_lake_card=%7B%22src%22%3A%22https%3A%2F%2Fwww.yuque.com%2Fattachments%2Fyuque%2F0%2F2022%2Flog%2F21760570%2F1645021994927-d63c76e0-6257-49c4-bfda-4fb55086a5fc.log%22%2C%22name%22%3A%22abc.log%22%2C%22size%22%3A7206%2C%22type%22%3A%22%22%2C%22ext%22%3A%22log%22%2C%22status%22%3A%22done%22%2C%22taskId%22%3A%22u9a2b7dd6-63bd-4b5d-942e-1d7bc8cd87c%22%2C%22taskType%22%3A%22upload%22%2C%22id%22%3A%22ua794d24e%22%2C%22card%22%3A%22file%22%7D)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645021979672-5fa587b5-d63a-430b-b263-16c1a993e2c9.png#clientId=u7a35ebab-bd98-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=549&id=u6cb45d8a&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1098&originWidth=2064&originalType=binary&ratio=1&rotation=0&showTitle=false&size=1167461&status=done&style=none&taskId=ud2dffc06-a764-4e6e-9fb2-98c0ce43b3a&title=&width=1032)
### 第一行（基本信息）
** main **  表示线程名称
**daemon**  表示线程是否是守护线程
**prio**  表示我们为线程设置的优先级
**os_prio**  表示的对应的操作系统线程的优先级，由于并不是所有的操作系统都支持线程优先级，所以可能会出现都置为0的情况
**tid**  表示java中为这个线程的id
**nid** 表示这个线程对应的操作系统本地线程id的十六进制表示，每一个java线程都有一个对应的操作系统线程
**[id] **线程栈初始地址
### 第二行（线程状态）
第二行一般显示线程当前状态。一个Thread对象可以有多个状态，在java.lang.Thread.State中，总共定义六种状态：
1.NEW
线程刚刚被创建，也就是已经new过了，但是还没有调用start()方法，**jstack命令不会列出处于此状态的线程信息**
2.RUNNABLE
RUNNABLE这个名字很具有欺骗性，很容易让人误以为处于这个状态的线程正在运行。事实上，这个状态只是表示，线程是可运行的。一个单核CPU在同一时刻，只能运行一个线程。
3.BLOCKED
线程处于阻塞状态，正在等待一个monitor lock。通常情况下，是因为本线程与其他线程共用了一个锁。其他在线程正在使用这个锁进入某个synchronized同步方法块或者方法，而本线程进入这个同步代码块也需要这个锁，最终导致本线程处于阻塞状态。
4.**WAITING**
无限期等待另一个线程执行特定操作
调用以下方法可能会导致一个线程处于等待状态：

[Object.wait]() 不指定超时时间 # java.lang.Thread.State: WAITING (on object monitor)

[Thread.join]() with no timeout

[LockSupport.park]() #java.lang.Thread.State: WAITING (parking)

例如：对于wait()方法，一个线程处于等待状态，通常是在等待其他线程完成某个操作。本线程调用某个对象的wait()方法，其他线程处于完成之后，调用同一个对象的notify或者notifyAll()方法。Object.wait()方法只能够在同步代码块中调用。调用了wait()方法后，会释放锁。

**5.TIMED_WAITING**
有限期等待另一个线程执行特定操作
对于以下方法的调用，可能会导致线程处于这个状态：

[Thread.sleep]()#java.lang.Thread.State: TIMED_WAITING (sleeping)``

[Object.wait]() 指定超时时间 #java.lang.Thread.State: TIMED_WAITING (on object monitor)

[Thread.join]() with timeout

[LockSupport.parkNanos]()#java.lang.Thread.State: TIMED_WAITING (parking)``

[LockSupport.parkUntil]()#java.lang.Thread.State: TIMED_WAITING (parking)``

**6.TERMINATED**
线程终止

> 说明，对于** java.lang.Thread.State: WAITING (on object monitor)和java.lang.Thread.State: TIMED_WAITING (on object monitor)**，对于这两个状态，是因为调用了Object的wait方法(前者没有指定超时，后者指定了超时)，由于wait方法肯定要在syncronized代码中编写，因此肯定是如类似以下代码导致：
> synchronized(obj) {
> .........
> obj.wait();
> ........
> }
> 因此通常的堆栈信息中，必然后一个lock标记，如下（来自上图的main线程）：
"main" #1 prio=5 os_prio=0 tid=0x00007f160c009800 nid=0x43db9 **waiting on condition [0x00007f161377a000]]**

#### 不上图怎么理解？
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645969193399-618adbe0-e2f3-4d34-8083-9f56c2b343a8.png#clientId=u6c022a99-1360-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=558&id=u5ad3f333&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1116&originWidth=2296&originalType=binary&ratio=1&rotation=0&showTitle=false&size=2334003&status=done&style=none&taskId=u64c9318a-4c93-429e-a37d-457749057b8&title=&width=1148)
既然讲到线程状态，就不得不提锁了，如果多个线程都都在抢占同一资源，不就会造成死锁了。所以也能通过jstack来分析死锁问题。但是我们先要懂java是怎么上锁的。
#### Monitor监控锁
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1645969287460-f0d387a2-4b9c-4f04-baaa-c998616ad65f.png#clientId=u6c022a99-1360-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=693&id=u704c0ea8&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1386&originWidth=2158&originalType=binary&ratio=1&rotation=0&showTitle=false&size=2509739&status=done&style=none&taskId=ua22d64fc-146b-4ebb-9c24-d732bde6cf5&title=&width=1079)

- 线程想要获取monitor,首先会进入Entry Set队列，它是Waiting Thread，线程状态是Waiting for monitor entry。
- 当某个线程成功获取对象的monitor后,进入Owner区域，它就是Active Thread。
- 如果线程调用了wait()方法，则会进入Wait Set队列，它会释放monitor锁，它也是Waiting Thread，线程状态in Object.wait()
- 如果其他线程调用 notify() / notifyAll() ，会唤醒Wait Set中的某个线程，该线程再次尝试获取monitor锁，成功即进入Owner区域。

For Example , 通过synchronized来举例。
当线程执行到下面的逻辑时，就会进入到Entry Set队列，如果此时没有人占用obj，就会进入到Owner区域，当在synchronized内部调用obj.wait();方法时，就会进入到Wait Set队列，让其他线程获取obj执行相关逻辑。等待其他线程调用obj.notify()或者 notifyAll()时，就有可能会唤醒该线程，然后重新进入到Owner区域。
> synchronized(obj) { 
> .........
>  }


### 第三行（调用堆栈）
反应在dump时刻，线程的状态及调用堆栈。
### 对于jstack做的ThreadDump的栈，可以反映如下信息

1. 如果某个相同的call stack经常出现， 我们有80%的以上的理由确定这个代码存在性能问题（读网络的部分除外）；
1. 如果相同的call stack出现在同一个线程上（tid）上， 我们很很大理由相信， 这段代码可能存在较多的循环或者死循环；
1. 如果某call stack经常出现， 并且里面带有lock，请检查一下这个lock的产生的原因， 可能是全局lock造成了性能问题；
1. 在一个不大压力的群集里（w<2）， 我们是很少拿到带有业务代码的stack的， 并且一般在一个完整stack中， 最多只有1-2业务代码的stack，
1. 如果经常出现， 一定要检查代码， 是否出现性能问题。
1. 如果你怀疑有dead lock问题， 那么请把所有的lock id找出来，看看是不是出现重复的lock id。

# jstack分析工具
在线分析工具
[https://fastthread.io/](https://fastthread.io/)
[http://spotify.github.io/threaddump-analyzer](http://spotify.github.io/threaddump-analyzer/) 