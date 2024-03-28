---
title: Canal核心原理
description: Canal核心原理
date: 2022-03-12 09:53:49

tags:
- Canal

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

Canal是一个C/S架构模式，服务端复制拉取，解析，存储Mysql的binlog。客户端负责从服务器轮询获取binlog信息。
Canal服务端有一个核心功能，就是模拟mysql的slave节点去向master节点获取binlog。所以我们先要理解Mysql是怎么做主备复制的
## MySQL主备复制原理
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657766934821-2d98f2a1-0d82-44eb-80e7-0d53a1fa2be3.png#averageHue=%23f3f2f2&clientId=ub198369d-0d06-4&from=paste&height=372&id=u9eb5d405&originHeight=372&originWidth=520&originalType=binary&ratio=1&rotation=0&showTitle=false&size=111151&status=done&style=none&taskId=ufa66b3b3-f5d3-49a7-9d00-5fbc1cdc9aa&title=&width=520)
## Server架构图
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1657775182776-a42d1b77-8342-476a-8f82-ca7f04b7a63b.jpeg)
### 名词解释
CanalServerWithEmbeded：负责拉取和解析mysql binlog。

## Server处理流程图
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657775440954-a8145ab0-c5d7-4f2f-98dc-1c53ed2ba80e.png#averageHue=%23f8faf8&clientId=ub198369d-0d06-4&from=paste&height=432&id=u96f8bc9b&originHeight=864&originWidth=1564&originalType=binary&ratio=1&rotation=0&showTitle=false&size=355847&status=done&style=none&taskId=u64703b0b-ec60-45a3-a48c-660b9a12231&title=&width=782)

1. 从 Log Position 管理器中获取上一次解析的日志位点。
2. 向 [Mysql](https://cloud.tencent.com/product/cdb?from=10680) Master 节点发送 BINLOG_DUMP 请求。
3. Mysql Master 节点从 Slave 端传入的日志位点开始向从节点推送 binlog 日志。
4. Slave 接收 binlog 日志，调用 BinlogParser 解析 binlog日志。
5. 将解析后的结构化数据传入到 EventSink 组件。
6. 定时记录解析 binlog 的日志，以便重启后继续进行增量订阅。

如果Mysql Master宕机了，Canal是不是不可用了？
上图中还罗列一个HA 特性，即需要同步的 Master 如果宕机，可以从它的其他从节点继续同步 binlog 日志，避免单点故障。


![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657775304181-f6f38f76-8d34-46e4-9ece-fa0b69755db5.png#averageHue=%23f0f0ef&clientId=ub198369d-0d06-4&from=paste&height=295&id=ub4bbf6bf&originHeight=590&originWidth=1516&originalType=binary&ratio=1&rotation=0&showTitle=false&size=129435&status=done&style=none&taskId=uacf9d7bb-8162-41eb-a97d-48772e66905&title=&width=758)


## Client-Server时序图
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657768761616-41666a96-a0cf-40a4-b537-3fbb92a49002.png#averageHue=%23f6f6f5&clientId=ub198369d-0d06-4&from=paste&height=826&id=ua78d0ff7&originHeight=826&originWidth=605&originalType=binary&ratio=1&rotation=0&showTitle=false&size=373996&status=done&style=none&taskId=ue19451ca-a25b-4fe8-8342-76b3e4a4e7c&title=&width=605)
左边Client，右边Server
## Canal高可用架构（HA）
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1657955588768-4f20aac4-87d0-4c4d-88a8-2f0d7205c958.jpeg)
### 疑问

1. 这个方式看起来可以做到Server的高可用架构。但是对于client，如果一个应用对应多个节点，就会对应多个client，怎么协调不同的client的数据拉取？
2. 对于Server，多个instance拉同一个Mysql的binlog，怎么协调？

**通过具体的实现流程来解答上面两个问题**
**canal server实现流程如下：**

1. canal server 要启动某个 canal instance 时都先向 zookeeper 进行一次尝试启动判断 (实现：创建 EPHEMERAL 节点，谁创建成功就允许谁启动）；
2. 创建 zookeeper 节点成功后，对应的 canal server 就启动对应的 canal instance，没有创建成功的 canal instance 就会处于 standby 状态；
3. 一旦 zookeeper 发现 canal server A 创建的节点消失后，立即通知其他的 canal server 再次进行步骤1的操作，重新选出一个 canal server 启动instance；
4. canal client 每次进行connect时，会首先向 zookeeper 询问当前是谁启动了canal instance，然后和其建立链接，一旦链接不可用，会重新尝试connect。

**「PS」**: 为了减少对mysql dump的请求，不同server上的instance要求同一时间只能有一个处于running，其他的处于standby状态。
**canal client实现流程**

1. canal client 的方式和 canal server 方式类似，也是利用 zookeeper 的抢占EPHEMERAL 节点的方式进行控制
2. 为了保证有序性，一份 instance 同一时间只能由一个 canal client 进行get/ack/rollback操作，否则客户端接收无法保证有序。

## 生产问题

1. 消息堆积？本质上是client的消费能力跟不上
2. canal重复拉取binlog （[https://kb.cvte.com/pages/viewpage.action?pageId=209960949](https://kb.cvte.com/pages/viewpage.action?pageId=209960949)）
3. canal更新es的document失败（[https://kb.cvte.com/pages/viewpage.action?pageId=154110064](https://kb.cvte.com/pages/viewpage.action?pageId=154110064)）
## 参考
[https://docs.google.com/presentation/d/1FDrfVEoNV7AlPOrgXYKo2L_70NDizhwrMpfCG0vztf8/edit#slide=id.gb0d10616_5_255](https://docs.google.com/presentation/d/1FDrfVEoNV7AlPOrgXYKo2L_70NDizhwrMpfCG0vztf8/edit#slide=id.gb0d10616_5_255) （otter设计ppt）
[https://github.com/alibaba/canal](https://github.com/alibaba/canal) （官方）
[https://www.bookstack.cn/read/canal-v1.1.4/cd6a5ac129e1edb7.md](https://www.bookstack.cn/read/canal-v1.1.4/cd6a5ac129e1edb7.md) （中文文档）
[https://www.modb.pro/db/79040](https://www.modb.pro/db/79040) （canal原理详解）
[https://cloud.tencent.com/developer/article/1805726](https://cloud.tencent.com/developer/article/1805726) (canal高可用架构)
[https://cloud.tencent.com/developer/article/1658839](https://cloud.tencent.com/developer/article/1658839) （EventParser详解）