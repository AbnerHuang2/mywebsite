---
title: ES核心原理
description: ES核心原理
date: 2022-03-02 09:53:49

categories:
- ElasticSearch

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 核心思想
Query then Fetch （先查找数据所在位置，再获取数据内容）
## 内部存储结构
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1657874852844-a053a682-5259-4539-bb7a-87b03fdff08f.jpeg)
Node : es集群中的节点
Shard: 分片（相当于master节点，主要负责写）
Replica : 副本（相当于slave节点，主要负责读）
Lucene : es数据写入，存储，查询的内核
Index : 应该可以理解为一个数据库

## 数据写入过程
[https://www.elastic.co/guide/cn/elasticsearch/guide/current/distrib-write.html](https://www.elastic.co/guide/cn/elasticsearch/guide/current/distrib-write.html)
### 整体写入流程

![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657852744444-905da9a9-2129-4dd6-aa3b-6b56d9e4237f.png#averageHue=%23eef3e9&clientId=u705aa42f-361a-4&from=paste&height=674&id=u92656088&originHeight=674&originWidth=766&originalType=binary&ratio=1&rotation=0&showTitle=false&size=300590&status=done&style=none&taskId=u6be6d4cd-722b-4768-b2b1-6ccbc4fb4ce&title=&width=766)
### Shard写入流程
通过上述流程，我们大概清晰了一个写请求，到ES之后，ES是如何处理的。那数据又是怎么真正落盘的呢？
#### 先写translog还是先写buffer
官方给点说法是先写buffer，然后追加translog。
[https://www.elastic.co/guide/cn/elasticsearch/guide/2.x/translog.html](https://www.elastic.co/guide/cn/elasticsearch/guide/2.x/translog.html)
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1657953212420-deca01b4-9a55-4383-a49d-0c441f6bcbc0.jpeg)

1. shard收到写入请求时，将数据写入到缓存区中
2. 数据写入成功之后，再记录translog
3. 缓存区每秒将数据写入到Lucene Index的segment文件中。同时es维护了一个定时服务，将小的segment合并成大的segment，避免segment文件过多。
4. 记录输入最后落盘的数据位置到commit point中
5. 删除translog中commit point之前的日志记录

### 问题

1. 如果在数据同步到副本的时候，有个副本所在的node宕机了，怎么处理？ 如果过一会这个node又恢复了呢？
2. 如果数据写入到了segment，但是没来的急记录到commit point中，下次重启，这条数据好像又会重新执行一遍？ 应该可以跳过
3. 先写内存，在追加translog是不是会导致数据丢失？ 如果再写完translog才返回成功应就不会。

**问题1解答**
es在数据写入的时候，默认是需要所有副本都写入成功才算成功。这样可以保证数据的一致性。但是这也同时导致可用性降低，只要一个节点宕机了，可能数据写入就失败了。
当然也可以通过配置最多成功的个数来避免有一个节点宕机从而导致写入失败。提升可用性。那这种情况下，会不会导致脏读呢？写入了一个数据，下一个读取请求被负载均衡到写入失败的节点，那不就造成脏读了吗？
不会的。当数据写入失败时，Primary Shard会有重试机制，如果重试失败了，就会将对应的Replica移除。

Lucene在写segment的时候，也会先写内存，在落盘，所以也可能存在还没有落盘的之前，服务器宕机了，数据丢失了。
## 数据读取过程
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657852931891-3af21c69-21f1-459f-b173-f7f4a3a4633d.png#averageHue=%23fcfcfc&clientId=u705aa42f-361a-4&from=paste&height=578&id=ucb9632d8&originHeight=578&originWidth=784&originalType=binary&ratio=1&rotation=0&showTitle=false&size=101278&status=done&style=none&taskId=u44b2b56c-9015-4b14-bf21-124c9f7d241&title=&width=784)



## 参考文档
[https://xie.infoq.cn/article/73c7bc776a8ab2a0d7a173472](https://xie.infoq.cn/article/73c7bc776a8ab2a0d7a173472) (ES写入流程)
[https://zhuanlan.zhihu.com/p/139762008](https://zhuanlan.zhihu.com/p/139762008) 
[https://www.elastic.co/guide/cn/elasticsearch/guide/current/distrib-write.html](https://www.elastic.co/guide/cn/elasticsearch/guide/current/distrib-write.html) （官方文档过程）