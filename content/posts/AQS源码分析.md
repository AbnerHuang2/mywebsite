---
title: AQS源码分析
description: AQS源码分析
date: 2023-05-25 21:32:32
tags:
  - Java并发
categories:
  - Java

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 概述
AbstractQueueSynchronized抽象队列同步器，Java的并发框架中核心实现。
思考一个问题：如果让你去实现并发控制，你会怎么做？再去对比别人是怎么做的。可以借鉴synchronized的实现。
## 核心原理
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1668955192723-6550f2ad-d9d0-4334-b574-95abd46899a9.png#averageHue=%23fcfbfb&clientId=u9107a52e-a5ae-4&from=paste&height=358&id=u4ef39cda&originHeight=716&originWidth=1552&originalType=binary&ratio=1&rotation=0&showTitle=false&size=82390&status=done&style=none&taskId=u5c63bd90-5f9d-4baf-b78f-9f10c37087f&title=&width=776)
CLH (Craig, Landin and Hagersten) , 是一种基于链表的可扩展，高性能，公平的自旋锁。
![image.png](https://cdn.nlark.com/yuque/0/2023/png/21760570/1693837090656-ad00a4ff-1bfa-4b75-885c-4965384e18bc.png#averageHue=%2325353d&clientId=u06f3cd98-fac1-4&from=paste&height=687&id=ue46ea392&originHeight=1374&originWidth=1276&originalType=binary&ratio=2&rotation=0&showTitle=false&size=317508&status=done&style=none&taskId=u28f893f7-ae97-4583-a437-b792bf14184&title=&width=638)
本质上就是维护了一个state变量和FIFO的线程队列。然后通过CAS的操作去获取state的值，获取到state值就可以执行相关原子操作。
然后封装了一些模版方法，比如说getState, setState, compareAndSet.
然后juc上很多框架，像ReentryLock，Semaphore, CountDownLatch.ReadWriteLock底层都是基于AQS实现的。
## 两种模式
### 独占(acquire)
实现子类：ReentrantLock的公平锁和非公平锁
### 共享(acuqireShared)
实现子类：Semaphore/CountDownLatch。Semaphore、CountDownLatch、 CyclicBarrier、ReadWriteLock
## 源码解析
### 核心方法

1. accquire （获取独占锁）
2. acquireShared（获取共享锁）
3. release (先尝试释放锁，然后通知队列第一个节点)
4. releaseShared (释放共享锁)
### 特性方法

1. acquireInterruptibly 可中断的方式获取锁
2. tryAcquireNanos 可超时获取锁
### 模版方法

1. tryAcquire （需要子类实现具体的获取独占锁的逻辑）
2. tryRealse （需要子类实现具体的释放独占锁的逻辑）
3. tryAcquireShard（需要子类实现具体的获取共享锁的逻辑）
4. tryRequireShard（需要子类实现具体的释放共享锁的逻辑）
### acquire方法
acquire的整体逻辑还是比较清晰的

1. 想尝试获取，能获取就直接成功了
2. 获取失败了，就封装成一个waiter节点，加入到队列中
3. 从队列中获取节点
#### 整体流程
![](https://cdn.nlark.com/yuque/__puml/25668d727a972fe4e1d61475af18bd86.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOmFjcXVpcmXojrflj5bni6zljaDplIE7XG5cbmlmICjlsJ3or5Xnm7TmjqXojrflj5YpIHRoZW4gKOiOt-WPluaIkOWKnylcbiAgOuebtOaOpeWwseaIkOWKn-S6hjtcbmVsc2UgKOiOt-WPluWksei0pSlcbiAgOuWwgeijheaIkHdhaXRlcuiKgueCue-8jOWwneivleebtOaOpeWKoOWFpemYn-WIl-WwvumDqDtcblx0OuWKoOWFpeWksei0pe-8jOiHquaXi-WKoOWFpeWwvumDqDtcbmdyb3VwIOS7jumYn-WIl-WktOmDqOiOt-WPlumUgVxuXHRpZijlvZPliY3oioLngrnmmK9oZWFk6IqC54K55LiU6I635Y-W5Yiw6ZSBKSB0aGVuKHllcylcblx0XHQ66I635Y-W6ZSB5oiQ5Yqf77yM5bCx5oqK6Ieq5bex5LuO6Zif5YiX5Lit56e76ZmkO1xuXHRlbHNlIChubylcblx0XHQ655yL55yL5YmN5LiA5Liq6IqC54K55piv5ZCm6I635Y-W5Yiw6ZSBO1xuXHRcdDog5aaC5p6c6I635Y-W5Yiw5LqG77yM5bCx5oqK6Ieq5bex55qE562J5b6F54q25oCB5pS55Li6U0lHTkFM77yM5bCx5Y-v5Lul6LCD55SocGFya-mYu-WhnuiHquW3seS6hjtcbm5vdGUgcmlnaHRcdFxuXHTlj6rmnInlvZPliY3kuIDkuKroioLngrnojrflj5bliLDplIHvvIzlsLHlj6_ku6XpmLvloZ7vvIxcbiDnrYnlvoXliY3kuIDkuKrkuIrkuIDkuKrnur_nqIvmiafooYzlrozllKTphpLoh6rlt7FcbmVuZCBub3RlXG5cdGVuZGlmXG5lbmQgZ3JvdXBcbmVuZGlmXG5cbnN0b3BcblxuQGVuZHVtbCIsInVybCI6Imh0dHBzOi8vY2RuLm5sYXJrLmNvbS95dXF1ZS9fX3B1bWwvMjU2NjhkNzI3YTk3MmZlNGUxZDYxNDc1YWYxOGJkODYuc3ZnIiwiaWQiOiJiNTBDcCIsIm1hcmdpbiI6eyJ0b3AiOnRydWUsImJvdHRvbSI6dHJ1ZX0sImNhcmQiOiJkaWFncmFtIn0=)
#### 源码分析
```java
public final void acquire(int arg) {
    //先获取一把，如果失败了，就新增节点，添加到队列中，然后自我中断
    if (!tryAcquire(arg) &&
        acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
        selfInterrupt();
}
```
```java
private Node addWaiter(Node mode) {
    //新增节点
    Node node = new Node(Thread.currentThread(), mode);
    // 尝试快速入队 Try the fast path of enq; backup to full enq on failure
    Node pred = tail;
    if (pred != null) {
        node.prev = pred;
        if (compareAndSetTail(pred, node)) {
            pred.next = node;
            return node;
        }
    }
    //通过标准的方式入队
    enq(node);
    return node;
}
```
```java
final boolean acquireQueued(final Node node, int arg) {
    boolean failed = true;
    try {
        boolean interrupted = false;
        for (;;) {
            final Node p = node.predecessor();
            //如果是head节点，并且获取锁成功，就执行成功了，把自己从队列中移除
            if (p == head && tryAcquire(arg)) {
                setHead(node);
                p.next = null; // help GC
                failed = false;
                return interrupted;
            }
            //非head节点或者获取锁失败
            if (shouldParkAfterFailedAcquire(p, node) &&
                parkAndCheckInterrupt())
                interrupted = true;
        }
    } finally {
        if (failed)
            cancelAcquire(node);
    }
}
```

### release方法
#### 整体流程
![](https://cdn.nlark.com/yuque/__puml/2d2d6823f11f359dab135a65df728be5.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOnJlbGVhc2Xop6PplIE7XG5cbmlmICh0cnlSZWxlYXNl6Kej6ZSB5oiQ5YqfKSB0aGVuICh0cnVlKVxuICA65pu05pawaGVhZOiKgueCueeahOetieW-heeKtuaAgTtcblx0OuWUpOmGkuWkhOS6juiiq-WUpOmGkueKtuaAgeeahOiKgueCuTtcbm5vdGUgcmlnaHQ65LiA6Iis5piv5LiL5LiA5Liq6IqC54K577yM5Lmf5Y-v6IO95Lya5Y-W5raI5LqG77yM5bCx57un57ut5b6A5LiL5om-O1xuZWxzZSAoZmFsc2UpXG4gIDrop6PplIHlpLHotKU7XG4gIGVuZFxuZW5kaWZcblxuc3RvcFxuXG5AZW5kdW1sIiwidXJsIjoiaHR0cHM6Ly9jZG4ubmxhcmsuY29tL3l1cXVlL19fcHVtbC8yZDJkNjgyM2YxMWYzNTlkYWIxMzVhNjVkZjcyOGJlNS5zdmciLCJpZCI6InFUdFRyIiwibWFyZ2luIjp7InRvcCI6dHJ1ZSwiYm90dG9tIjp0cnVlfSwiY2FyZCI6ImRpYWdyYW0ifQ==)
#### 源码分析
```java
@ReservedStackAccess
public final boolean release(int arg) {
    if (tryRelease(arg)) {
        Node h = head;
        if (h != null && h.waitStatus != 0)
            unparkSuccessor(h);
        return true;
    }
    return false;
}
```
```java
private void unparkSuccessor(Node node) {
        /*
         * If status is negative (i.e., possibly needing signal) try
         * to clear in anticipation of signalling.  It is OK if this
         * fails or if status is changed by waiting thread.
         */
        int ws = node.waitStatus;
        if (ws < 0)
            compareAndSetWaitStatus(node, ws, 0);

        /*
         * Thread to unpark is held in successor, which is normally
         * just the next node.  But if cancelled or apparently null,
         * traverse backwards from tail to find the actual
         * non-cancelled successor.
         */
        //唤醒下一个节点
        Node s = node.next;
        if (s == null || s.waitStatus > 0) {
            s = null;
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)	//节点处于被唤醒的状态
                    s = t;
        }
        if (s != null)
            LockSupport.unpark(s.thread);
    }
```

---

## 插曲
看源码的时候，不小心看到了java17的版本，发现和一些博客的说法不一样，我就很奇怪，原来是 Doug Lea在后续的版本中又对aqs做了优化，把共享，独占的一些获取逻辑合并到一起去了，看起来更复杂了。
### acquire（java17的实现）
java17中，aqs的多种方式被合并成了一个核心实现，都在acquire方法中。 不管是用独占，共享，还是指定等待时间，最终我们都会走到accquire方法上来，因为这里是核心的处理逻辑，会根据是否共享模式，是否超时等方式去实现最终的逻辑。
```java
final int acquire(Node node, int arg, boolean shared,
                      boolean interruptible, boolean timed, long time) {
        Thread current = Thread.currentThread();
        byte spins = 0, postSpins = 0;   // retries upon unpark of first thread
        boolean interrupted = false, first = false;
        Node pred = null;                // predecessor of node when enqueued

        /*
         * Repeatedly:
         *  Check if node now first
         *    if so, ensure head stable, else ensure valid predecessor
         *  if node is first or not yet enqueued, try acquiring
         *  else if node not yet created, create it
         *  else if not yet enqueued, try once to enqueue
         *  else if woken from park, retry (up to postSpins times)
         *  else if WAITING status not set, set and retry
         *  else park and clear WAITING status, and check cancellation
         */

        for (;;) {
            //不满足第一个的条件，循环等待
            if (!first && (pred = (node == null) ? null : node.prev) != null &&
                !(first = (head == pred))) {
                //如果前一个节点取消了，就清理队列，然后继续
                if (pred.status < 0) {
                    cleanQueue();           // predecessor cancelled
                    continue;
                } else if (pred.prev == null) {
                    //前一个节点要执行了，当前线程要进入准备状态了
                    Thread.onSpinWait();    // ensure serialization
                    continue;
                }
            }
            //终于轮到我为第一个节点了
            if (first || pred == null) {
                boolean acquired;
                try {
                    //如果是共享的模式，就通过共享模式获取
                    if (shared)
                        acquired = (tryAcquireShared(arg) >= 0);
                    else
                        //否则就通过正常模式获取
                        acquired = tryAcquire(arg);
                } catch (Throwable ex) {
                    //如果出现了异常，就取消获取
                    cancelAcquire(node, interrupted, false);
                    throw ex;
                }
                //如果获取到了，就出队列
                if (acquired) {
                    if (first) {
                        node.prev = null;
                        head = node;
                        pred.next = null;
                        node.waiter = null;
                        if (shared)
                            //如果是共享模式，唤醒一下其他节点
                            signalNextIfShared(node);
                        if (interrupted)
                            current.interrupt();
                    }
                    return 1;
                }
            }
            //当前节点处理完了
            if (node == null) {                 // allocate; retry before enqueue
                if (shared)
                    node = new SharedNode();
                else
                    node = new ExclusiveNode();
            } else if (pred == null) {          // try to enqueue
                //不为空，尝试入队
                node.waiter = current;
                Node t = tail;
                node.setPrevRelaxed(t);         // avoid unnecessary fence
                if (t == null)
                    tryInitializeHead();
                else if (!casTail(t, node))
                    node.setPrevRelaxed(null);  // back out
                else
                    t.next = node;
            } else if (first && spins != 0) {
                --spins;                        // reduce unfairness on rewaits
                Thread.onSpinWait();
            } else if (node.status == 0) {
                node.status = WAITING;          // enable signal and recheck
            } else {
                long nanos;
                spins = postSpins = (byte)((postSpins << 1) | 1);
                if (!timed)
                    LockSupport.park(this);
                else if ((nanos = time - System.nanoTime()) > 0L)
                    LockSupport.parkNanos(this, nanos);
                else
                    break;
                node.clearStatus();
                if ((interrupted |= Thread.interrupted()) && interruptible)
                    break;
            }
        }
        return cancelAcquire(node, interrupted, interruptible);
    }
```
##### 流程图
![](https://cdn.nlark.com/yuque/__puml/c2f76568535f8e23a7804e220185c453.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcbnRpdGxlIGFjY3F1aXJl5a6e546w6YC76L6RKOebuOWvueadpeiusuavlOi-g-Wkjeadgu-8jOWFiOS6huino-S4quWkp-amgua1geeoiylcbnN0YXJ0XG5cbjroh6rml4s7XG5pZiAo5b2T5YmN6IqC54K55LiN5piv56ys5LiA5LiqKSB0aGVuICh0cnVlKVxuICA65aaC5p6c5YmN5LiA5Liq6IqC54K56LaF5pe25LqG77yM5bCx5riF55CG6Zif5YiXO1xuXHQ66Ieq5peLO1xuZWxzZSAoZmFsc2UpXG4gIDrlpoLmnpzmmK_nrKzkuIDkuKroioLngrk7XG5cdDrojrflj5bplIE7XG5cdDrku47pmJ_liJfkuK3lsIboh6rlt7Hnp7vpmaQ7XG5ub3RlIHJpZ2h0OuS5n-WPr-iDveS4jeWcqOmYn-WIl-S4re-8jOS4jeWcqOWwseS4jeeUqOenu-mZpOS6hlxuICBlbmRcbmVuZGlmXG5cbnN0b3BcblxuQGVuZHVtbCIsInVybCI6Imh0dHBzOi8vY2RuLm5sYXJrLmNvbS95dXF1ZS9fX3B1bWwvYzJmNzY1Njg1MzVmOGUyM2E3ODA0ZTIyMDE4NWM0NTMuc3ZnIiwiaWQiOiJnRnJwUCIsIm1hcmdpbiI6eyJ0b3AiOnRydWUsImJvdHRvbSI6dHJ1ZX0sImNhcmQiOiJkaWFncmFtIn0=)accquire的的实现逻辑考虑了两个模式，独占和共享模式，以及考虑是否需要超时中断。大致的处理逻辑如下

1. 判断自己是否为第一个节点，如果是的话，直接去获取资源，如果获取失败，就取消获取。
2. 如果自己不是第一个节点，看看自己是否在队列中，如果不在队列中，就添加到队列中。
3. 如果以及在队列中，就看看上一个节点有没有超时，有超时就清理队列，否则就继续自旋

## 总结
今天的aqs分析就到此结束了。主要分析了核心的独占锁的方式，acquire方法和release方法。让我们对aqs的线程并发的管理有了更近一步的认识。
#### 回顾一下
acquire

1. 尝试获取一下
2. 获取不到，把自己封装成node节点，先快速加入一把到队尾，失败了就cas加入
3. 然后从队列中获取锁
    1. 如果自己是第一个节点，就获取一把，获取成功了就成功了。
    2. 如果上一个节点是否在执行了，如果是，就阻塞自己等待上一个执行完唤醒自己。

release

1. 直接释放
2. 释放成功了，更新自己的等待状态，唤醒下一个节点