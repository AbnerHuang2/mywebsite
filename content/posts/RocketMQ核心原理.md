---
title: RocketMQ核心原理
description: RocketMQ核心原理
date: 2022-02-02 10:53:49

categories:
- RocketMQ

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 整体架构图
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1658284536555-ae0e6412-d9cc-4fcf-8614-74c8215aefd3.jpeg)
NameServer : Topic注册中心，支持Broker的动态注册与发现；Broker管理；路由信息管理
Broker : 消息中转角色，负责存储消息、转发消息。代理服务器在RocketMQ系统中负责接收从生产者发送来的消息并存储、同时为消费者的拉取请求作准备。代理服务器也存储消息相关的元数据，包括消费者组、消费进度偏移和主题和队列消息等
![image.png](https://cdn.nlark.com/yuque/0/2024/png/21760570/1709196863879-7645b97e-b472-45b4-8ed8-c4c015d67be9.png#averageHue=%23f6f6f6&clientId=u1e803081-543e-4&from=paste&height=429&id=u7b26f77f&originHeight=858&originWidth=2062&originalType=binary&ratio=2&rotation=0&showTitle=false&size=233827&status=done&style=none&taskId=u16b3534a-9259-4639-bc15-850ceccb741&title=&width=1031)
### 工作流程

1. 启动NameServer，NameServer起来后监听端口，等待Broker、Producer、Consumer连上来，相当于一个路由控制中心。
2. Broker启动，跟所有的NameServer保持长连接，定时发送心跳包。心跳包中包含当前Broker信息(IP+端口等)以及存储所有Topic信息。注册成功后，NameServer集群中就有Topic跟Broker的映射关系。
3. 收发消息前，先创建Topic，创建Topic时需要指定该Topic要存储在哪些Broker上，也可以在发送消息时自动创建Topic。
4. Producer发送消息，启动时先跟NameServer集群中的其中一台建立长连接，并从NameServer中获取当前发送的Topic存在哪些Broker上，轮询从队列列表中选择一个队列，然后与队列所在的Broker建立长连接从而向Broker发消息。
5. Consumer跟Producer类似，跟其中一台NameServer建立长连接，获取当前订阅Topic存在哪些Broker上，然后直接跟Broker建立连接通道，开始消费消息。
## Broker
从上面的设计可以看出，rocketmq大部分工作都是在broker上进行的
### 核心模块
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1658197008752-cc1da69c-9368-4905-9728-d213802412cf.png#averageHue=%23f6f6f5&clientId=u4fe640e3-80aa-4&from=paste&height=453&id=ube0c70ae&originHeight=453&originWidth=845&originalType=binary&ratio=1&rotation=0&showTitle=false&size=92751&status=done&style=none&taskId=udc01857a-b27e-4973-bff5-7fe1e602f1d&title=&width=845)
### 内部结构
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1658286549086-79367c20-406d-4145-bc20-be432ae5dce2.png#averageHue=%23f3b3a5&clientId=u02892b1e-f95b-4&from=paste&height=677&id=u88315092&originHeight=677&originWidth=989&originalType=binary&ratio=1&rotation=0&showTitle=false&size=355295&status=done&style=none&taskId=u95ad648c-acea-4e57-ac3e-8ec8fae623f&title=&width=989)
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1658810974010-42458dcb-eb13-4277-bd71-da5b6d44db9f.jpeg)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1658811356787-e69f4e63-5b46-4935-9a5c-84d267dcc015.png#averageHue=%2329363d&clientId=uc15cad4f-3b11-4&from=paste&height=255&id=u9be3407e&originHeight=510&originWidth=1358&originalType=binary&ratio=1&rotation=0&showTitle=false&size=100400&status=done&style=none&taskId=u5bc894bc-7fb8-42b7-b1d1-98794d4d82f&title=&width=679)
```sql
<!-- https://mvnrepository.com/artifact/org.apache.rocketmq/rocketmq-spring-boot-starter -->
<dependency>
    <groupId>org.apache.rocketmq</groupId>
    <artifactId>rocketmq-spring-boot-starter</artifactId>
    <version>2.0.4</version>
</dependency>
```
一个topic在一个broker中应该只有一个消息队列？欢迎大佬评论区留言解答
对，但是一个topic可以存储在多个broker上，这样每个broker都有一个队列。
每次producer都只能和一个broker进行建连。

### 消息刷盘
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1658287151589-f8fcd661-3d75-4070-a98b-7059fd90b918.png#averageHue=%23c1ed9c&clientId=u02892b1e-f95b-4&from=paste&height=664&id=ua389b834&originHeight=664&originWidth=694&originalType=binary&ratio=1&rotation=0&showTitle=false&size=181442&status=done&style=none&taskId=u3c2cf654-0f54-4e30-9185-27e49846441&title=&width=694)
## 问题
### Broker和其中一个NameServer注册失败了，怎么处理？
不确定rocketmq有没有什么重试机制。
### 怎么保证消息的顺序性？
#### 顺序投递
RocketMQ可以保证发送到同一个mqQueue的消息是有序的。业务方可以通过重写mqQueueSelector(消息队列选择器)来实现消息的有序性。
RocketMQ有两种发送方式，一种是直接发送。这种方式默认是随机选择一个可用的broker进行发送。
另一种是指定mqQueue发送。
[https://blog.51cto.com/u_12132623/3065791](https://blog.51cto.com/u_12132623/3065791) （分析发送消息源码）
#### 消息存储
存在同一个队列的消息才能保证有序
#### 顺序消费
消费者消费消息有两种模式，一种是并发消费，一种是顺序消费。
只要设置顺序消费就可以保证消费的顺序了。
### 怎么保证消息不丢失？
从broker的实现逻辑可以看到，rocketmq支持两种持久化模式，同步刷盘和异步刷盘。同步刷盘就可以保证消息不丢失.
### 消息重复
消息重复的场景如下：

- **发送时消息重复**

当一条消息已被成功发送到服务端并完成持久化，此时出现了网络闪断或者客户端宕机，导致服务端对客户端应答失败。 如果此时生产者意识到消息发送失败并尝试再次发送消息，消费者后续会收到两条内容相同但Message ID不同的消息。

- **投递时消息重复**

消息消费的场景下，消息已投递到消费者并完成业务处理，当客户端给服务端反馈应答的时候网络闪断。为了保证消息至少被消费一次，消息队列RocketMQ版的服务端将在网络恢复后再次尝试投递之前已被处理过的消息，消费者后续会收到两条内容相同并且Message ID也相同的消息。

- **负载均衡时消息重复**（包括但不限于网络抖动、Broker重启以及消费者应用重启）

当消息队列RocketMQ版的Broker或客户端重启、扩容或缩容时，会触发Rebalance，此时消费者可能会收到少量重复消息。
#### 处理方法
因为不同的Message ID对应的消息内容可能相同，有可能出现冲突（重复）的情况，所以真正安全的幂等处理，不建议以Message ID作为处理依据。最好的方式是以业务唯一标识作为幂等处理的关键依据，而业务的唯一标识可以通过消息Key设置。
### 消息堆积&消息延迟
消息处理流程中，如果客户端的消费速度跟不上服务端的发送速度，未处理的消息会越来越多，这部分消息就被称为堆积消息。消息出现堆积进而会造成消息消费延迟。以下场景需要重点关注消息堆积和延迟的问题：

- 业务系统上下游能力不匹配造成的持续堆积，且无法自行恢复。
- 业务系统对消息的消费实时性要求较高，即使是短暂的堆积造成的消息延迟也无法接受
