---
title: OrderBy踩坑之路
description: OrderBy并不是你想象的这么简单
date: 2022-02-10 20:13:06
tags:
- 问题排查
categories:
- Mysql
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# 先看一条社死SQL
> **SELECT*****FROM** t_device_online **where** device_id=8788 **orderby** start_time **desc limit **1;

其中 device_id 没有索引， start_time有索引。表中数据量大概200w。这条语句执行平均耗时3s多。同时十几条这个请求。直接占住了数据库链接。导致后续请求调用都超时了。
200w数据查一条数据要花这么久吗？device_id 没有索引，全表扫描可能需要是吧。
但是我们通过执行计划分析，发现它走了start_time的联合索引。
好，我们去掉 **orderby** start_time **desc** 试试，结果只花了600ms。？ 索引比全表扫描还慢？
去掉 **where** device_id=8788 试试，也就 不到 10ms。 ？
这里涉及到两个知识点，一是索引，二是排序。
# 索引排序详解
### 索引的存储方式
主键索引
![image.png](https://cdn.nlark.com/yuque/0/2021/png/21760570/1640936474883-61cb4d73-c389-4594-89cb-4a14206dc3f7.png#clientId=u59529091-3b42-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=147&id=u82d37e53&margin=%5Bobject%20Object%5D&name=image.png&originHeight=147&originWidth=354&originalType=binary&ratio=1&rotation=0&showTitle=false&size=6339&status=done&style=none&taskId=u46f7b41f-446e-43b4-be8d-c181006d446&title=&width=354)
联合索引
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641391457565-51184cb0-bb21-4d18-a2ce-22d80d6626d0.png#clientId=u32680ef7-dac2-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=331&id=u82d961fa&margin=%5Bobject%20Object%5D&name=image.png&originHeight=662&originWidth=821&originalType=binary&ratio=1&rotation=0&showTitle=false&size=286633&status=done&style=none&taskId=u3444be28-f0e2-4a15-bdc4-c743785dd80&title=&width=410.5)
### 索引排序查询执行过程分析
一次查询最多只会用到一个索引，所以可能存在下面几种情况

1. where走索引
1. order by 走索引
1. where和order by都走索引
1. where和order by都不走索引
#### 表结构
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641350356024-e686092a-4f2b-4839-86e7-76279c056aaa.png#clientId=ucfe51a14-d7a8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=184&id=u334558af&margin=%5Bobject%20Object%5D&name=image.png&originHeight=184&originWidth=562&originalType=binary&ratio=1&rotation=0&showTitle=false&size=23314&status=done&style=none&taskId=ub784c7c7-78e2-48d9-9cd2-b319335832d&title=&width=562)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641350388019-c5df714f-a78f-4d27-b3ee-52803649bcfb.png#clientId=ucfe51a14-d7a8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=295&id=u9fb0fdb4&margin=%5Bobject%20Object%5D&name=image.png&originHeight=295&originWidth=1039&originalType=binary&ratio=1&rotation=0&showTitle=false&size=34447&status=done&style=none&taskId=ue8aa8218-778b-46e0-b77e-a5f5c1a588b&title=&width=1039)
#### where走索引案例
**SELECT** * **FROM **test_online **where **start_time > 1609842103 **order by **device_id  **desc**; 【索引值start_time】
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641350307226-6c2f01a6-bb56-4954-a410-c01f95eee9a6.png#clientId=ucfe51a14-d7a8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=295&id=uf9d74344&margin=%5Bobject%20Object%5D&name=image.png&originHeight=295&originWidth=1042&originalType=binary&ratio=1&rotation=0&showTitle=false&size=46997&status=done&style=none&taskId=u8863e4fc-21d0-4e19-aefe-7e880c8844c&title=&width=1042)
执行过程：

1. 走索引过程找出 start_time > 1609842103 的 rowid（默认是主键id）
1. 将符合条件的rowid和排序字段（device_id）放入到排序缓存区中排序。
1. 然后在根据排序好的rowid去查询row记录。



#### order by走索引案例
> order by走索引的情况特别坑，如果走错了索引，效率比全表扫描还慢的多，而且，加上limit还会帮你加上索引。这里就能解释上面的社死SQL问题了。

**SELECT** * **FROM **test_online **where **device_id=10060 **order by **start_time **desc **;
**SELECT** * **FROM **test_online **where **device_id=10060 **order by **start_time **desc limit** 0,20;
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641298798315-e0ebaf93-37ab-4ed1-9d6c-86361c3f0917.png#clientId=u2cf24bf6-ebca-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=267&id=u2372b142&margin=%5Bobject%20Object%5D&name=image.png&originHeight=267&originWidth=1048&originalType=binary&ratio=1&rotation=0&showTitle=false&size=43638&status=done&style=none&taskId=u6d05b52a-804f-4976-8e6b-308279251e6&title=&width=1048)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641298878764-07c44d9b-a640-4e50-810d-f78df27b05e9.png#clientId=u2cf24bf6-ebca-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=100&id=u412b29a4&margin=%5Bobject%20Object%5D&name=image.png&originHeight=100&originWidth=711&originalType=binary&ratio=1&rotation=0&showTitle=false&size=16748&status=done&style=none&taskId=u64fa963d-e263-43c7-9636-0cd7f224f25&title=&width=711)


执行过程(不加limit)：

1. 全部扫描找到 device_id=10060 的 rowid（全表顺序扫描）。
1. 将符合条件的rowid和排序字段（start_time）放入到排序缓存区中排序
1. 然后在根据排序好的rowid去查询row记录（回表查）

执行过程（加上limit）：

1. 先根据order by的索引去查询符合where条件的数据；（相当于是走一个无效的索引去查找值，就是随机查找了，效率自然慢）
1. 将符合条件的rowid和排序字段（start_time）放入到排序缓存区中排序
1. 然后在根据排序好的rowid去查询row记录

![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641344175886-63f4be2a-c38a-4a4d-b312-96981b04429c.png#clientId=u96a7a8cc-ca77-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=57&id=u20adb565&margin=%5Bobject%20Object%5D&name=image.png&originHeight=57&originWidth=916&originalType=binary&ratio=1&rotation=0&showTitle=false&size=9574&status=done&style=none&taskId=u8011232e-f09c-4510-82cd-a7cb31ef99e&title=&width=916)
> 有些博客讲这个慢在第三步，但是我想不通，
> 1.通过主键id回表应该也不至于很慢，而且mysql也有优化，数据量小的情况下，就会将所有的数据在排序缓存区中处理，不需要二次回表。
> 2.无法解释上面的情况，两次查询数据都为null，但是耗时差距却这么大。

​

​

#### where和order by都走索引
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641430639579-afd72ac0-7b42-41d2-98b9-2e41fe7fd94b.png#clientId=u21c5884e-59d6-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=338&id=u8a6cb280&margin=%5Bobject%20Object%5D&name=image.png&originHeight=338&originWidth=1014&originalType=binary&ratio=1&rotation=0&showTitle=false&size=50951&status=done&style=none&taskId=ubb5d1f7d-2ab5-4fed-87ef-acbd0b7468c&title=&width=1014)
执行过程：

1. 通过索引去过滤where条件的数据
1. 将符合条件的rowid和排序字段放入到排序缓存区中排序
1. 根据排序好的rowid查询row记录

​

#### where和order by都不走索引
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1641430719394-81da8131-9083-481c-af24-e48d7cf54759.png#clientId=u21c5884e-59d6-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=341&id=u46755490&margin=%5Bobject%20Object%5D&name=image.png&originHeight=341&originWidth=1029&originalType=binary&ratio=1&rotation=0&showTitle=false&size=50745&status=done&style=none&taskId=uf47167cc-ba41-42c2-ad6a-37cdbb8e795&title=&width=1029)
执行过程：

1. 全表扫描where条件的数据
1. 将符合条件的rowid和排序字段放入到排序缓存区中排序
1. 根据排序好的rowid查询row记录
### filesort
我们注意到order by走索引不加limit和加limit的两种情况下，他们的explain最后一列，走全表扫描的有use filesort，另一个没有。
在我们的认知中，使用文件排序肯定比没有使用文件排序要快对吧，比较磁盘IO肯定更耗时嘛。
但是这里却相反了。当然现在我们知道了，是因为它走错了索引，导致了非常多无效的随机IO。
但是我们也可以了解一下这个filesort。
filesort不一定就会在文件中排序，
> _filesort is not always bad and it does not mean that a file is saved on disk. If the size of the data is small, it is performed in memory._

按排序方式分为：

1. 数据量小时，在内存中快排
1. 数据量大时，在内存中分块快排，再在磁盘上将各个块做归并

上面在分析排序过程时，排序完都会回表查询row记录，但是这个不一定是这样，也可以直接将行记录全查询出来在去排序，所以排序按回表次数又可以分为：

1. 两次传输排序（只将rowid和排序字段放入排序缓存区，然后在回表查询）
1. 单次传输排序（直接将要查询的行数据放入排序缓存区排序，排序完直接返回，避免二次随机回表查询）

我们知道随机回表的效率肯定比顺序IO慢，所以在mysql4.1之后的版本中，mysql优化了这个排序，
MySQL做了以下限制：

- 所有需要的列或**ORDER BY**的列只要是**BLOB**或者**TEXT**类型，则使用**两次传输排序**。
- 所有需要的列和**ORDER BY**的列总大小超过**max_length_for_sort_data**字节，则使**用两次传输排序**。



# 总结
1. 走索引不一定比全表扫描快，还得看你索引用的对不对，order by用索引where不用索引就是血淋淋的教训。
1. mysql会帮你优化查询，但是优化不一定是最好的，比如本来查询走全表扫描才几百ms，但这个limit觉得才查几条数据，走索引肯定更快，结果这个索引反而更慢了。
1. use filesort不一定就是使用文件排序，得看数据量大不大。也不一定会两次回表，看你列的数据多不多。

# 参考
[https://segmentfault.com/a/1190000015987895](https://segmentfault.com/a/1190000015987895) 
[https://petrunia.net/2007/08/29/how-mysql-executes-order-by/](https://petrunia.net/2007/08/29/how-mysql-executes-order-by/) (order by 执行过程详解)
[https://dev.mysql.com/doc/refman/5.7/en/order-by-optimization.html#order-by-optimizer-control](https://dev.mysql.com/doc/refman/5.7/en/order-by-optimization.html#order-by-optimizer-control) (mysql order by)
[https://dev.mysql.com/doc/refman/5.7/en/limit-optimization.html](https://dev.mysql.com/doc/refman/5.7/en/limit-optimization.html) (mysql limit)