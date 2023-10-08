---
title: Redis分布式锁
date: 2022-04-27 09:30:31
description: 回顾一下之前写的分布式锁的实现逻辑
tags: 
- 分布式锁
categories:
- Redis
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# 认识分布式锁
Distributed locks are a very useful primitive in many environments where different processes must operate with shared resources in a mutually exclusive way.
分布式锁是在分布式环境中保证不同的进程以相互独立的方式操作共享资源的一种实现方式。（说白了，分布式锁就是在分布式环境下实现进程同步操作共享资源的方式）
和本地锁（synchronized,reentrantlock）相比，分布式锁有什么不一样的地方呢？
场景不同，分布式场景。

# 分布式锁特性
1. 安全性：相互独立，任何情况下，只能有一个客户端持有锁
1. 死锁释放：即使持有锁的客户端宕机了，其他客户端最终总能获取锁。
1. 容错性：只要大多数的Redis节点无故障，客户端总能获取锁和释放锁。

# 分布式锁的实现原理
锁主要需要解决的问题
1. 互斥访问
1. 死锁问题
1. 可重入
1. 阻塞等待

Redis分布式锁是怎么做的呢？
其实就一条语句
SET resource_name my_random_value NX PX 30000
当客户端需要获取锁时，就往redis发送上面的语句，如果resource_name这个key已经存在了，就无法插入到redis中，也就无法获取锁。
如果没有，就将 resource_name -> my_random_value 设置到redis中。当其他客户端也想访问该资源时，就不能访问了，这就解决了互斥访问问题。
那客户端在处理业务的情况下宕机了怎么办，由于redis自带的失效时间处理，就很好的解决了死锁问题。
那客户端获取到了锁，在执行业务的时候，又有个地方要获取该资源的锁，怎么办呢？我们可以看看redission是怎么处理的。
那如果客户端没获取到锁，想一直等待锁呢？

可能遇到的问题
1.执行过程中，锁的失效时间到期了怎么办？redission设置了一个定时器，每到失效时间的1/3，如果业务还没执行完，就刷新失效时间。
2.为什么要设置唯一的value？防止别人误解锁。设置唯一的value，只有加锁的人才能解锁。
3.设置过程中master节点宕机了怎么办？
# Redisson实现分布式锁源码分析
redission分布式锁的使用
1.引入依赖
<dependency><groupId>org.redisson</groupId> <artifactId>redisson</artifactId> <version>3.13.5</version> </dependency>
2.配置
单机配置
config.useSingleServers().addAdress("redis://127.0.0.1:6379");
集群配置
config.useClusterServers().addAdress("redis://127.0.0.1:6379").addAdress("redis://127.0.0.1:6380");
3.使用
RLock lock = redissionClient.getLock(random_key);
lock.lock();
lock.unLock();

过程分析
加锁
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1650869288591-477858f4-5170-45c4-a427-709cf505fa5d.png#clientId=ue8d70bce-cde0-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=738&id=u500182bc&margin=%5Bobject%20Object%5D&name=image.png&originHeight=738&originWidth=1545&originalType=binary&ratio=1&rotation=0&showTitle=false&size=283038&status=done&style=none&taskId=ucec26631-0c24-48f1-883c-2d9ed6d6575&title=&width=1545)

解锁

![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1650869302380-d4194ad9-65f8-46b3-a22f-e681c1864645.png#clientId=ue8d70bce-cde0-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=330&id=u79eded21&margin=%5Bobject%20Object%5D&name=image.png&originHeight=330&originWidth=1411&originalType=binary&ratio=1&rotation=0&showTitle=false&size=31509&status=done&style=none&taskId=u739d4845-578e-4dc7-9eff-3eec55ec5af&title=&width=1411)

# Redisson架构
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1650869332933-e9edfae9-9676-4074-a323-94873d536e1f.png#clientId=ue8d70bce-cde0-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=1079&id=ue8a7b0c3&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1079&originWidth=1085&originalType=binary&ratio=1&rotation=0&showTitle=false&size=127331&status=done&style=none&taskId=ub5eca672-9f03-4503-aa2b-1080cb77258&title=&width=1085)
# RedLock算法分析
现在我们大概了解了一下redission的分布式锁实现，那么在集群模式下会不会有什么问题呢？
设想一个场景：
1. 客户端A从master获取到锁
1. 在master将锁同步到slave之前，master宕掉了
1. slave节点被晋级为master节点
1. 客户端B取得了同一个资源被客户端A已经获取到的另外一个锁。**安全失效！**

这个问题如何处理呢？

**RedLock算法**
我们假设有5个Redis master节点，这是一个比较合理的设置，所以我们需要在5台机器上面或者5台虚拟机上面运行这些实例，这样保证他们不会同时都宕掉。
为了取到锁，客户端应该执行以下操作:

1. 获取当前Unix时间，以毫秒为单位。
1. 依次尝试从N个实例，使用相同的key和随机值获取锁。在步骤2，当向Redis设置锁时,客户端应该设置一个网络连接和响应超时时间，这个超时时间应该小于锁的失效时间。例如你的锁自动失效时间为10秒，则超时时间应该在5-50毫秒之间。这样可以避免服务器端Redis已经挂掉的情况下，客户端还在死死地等待响应结果。如果服务器端没有在规定时间内响应，客户端应该尽快尝试另外一个Redis实例。
1. 客户端使用当前时间减去开始获取锁时间（步骤1记录的时间）就得到获取锁使用的时间。当且仅当从大多数（这里是3个节点）的Redis节点都取到锁，并且使用的时间小于锁失效时间时，锁才算获取成功。
1. 如果取到了锁，key的真正有效时间等于有效时间减去获取锁所使用的时间（步骤3计算的结果）。
1. 如果因为某些原因，获取锁失败（_没有_在至少N/2+1个Redis实例取到锁或者取锁时间已经超过了有效时间），客户端应该在所有的Redis实例上进行解锁（即便某些Redis实例根本就没有加锁成功）。

锁真正的有效时间：MIN_VALIDITY = TTL - (T2 - T1) - CLOCK_DRIFT .
TTL：锁的失效时间
T1：第一个获取到锁的时间
T2: 最后一个获取到锁的时间
CLOCK_DRIFT:时钟漂移（每台计算机的时间可能不同，所以集群中不同节点的通信可能会产生时钟漂移),因为基本都是以客户端的时间频率进行前进的，所以时钟漂移基本可以忽略不计。

redission中RedLock实现
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1650869362415-229602ad-ccbb-4bbe-bbe5-5fdbf24169a7.png#clientId=ue8d70bce-cde0-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=406&id=u2e278575&margin=%5Bobject%20Object%5D&name=image.png&originHeight=406&originWidth=491&originalType=binary&ratio=1&rotation=0&showTitle=false&size=61670&status=done&style=none&taskId=u1276c3af-9287-4f42-9fce-d785b8962dd&title=&width=491)
但是有一个问题：这种操作不能保证每个锁都是发送到了不同的实例，如果所有的锁都在一个实例上，一样会遇到问题之前的问题。
于是，Redisson废弃了RedLock。Rlock的一些操作会直接同步到所有的slave节点。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1650869370736-73556b7b-7338-4ea2-9bf5-452ecbb2728c.png#clientId=ue8d70bce-cde0-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=86&id=u263ea20a&margin=%5Bobject%20Object%5D&name=image.png&originHeight=86&originWidth=610&originalType=binary&ratio=1&rotation=0&showTitle=false&size=11991&status=done&style=none&taskId=uc4bc6b5c-4352-44a9-90fb-8450a166c3f&title=&width=610)
然后我就跑去测试了一下，经测试：
RLock操作会发送到每一个slave节点（Redisson只配master节点，slave节点也会收到）。