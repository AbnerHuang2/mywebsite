---
title: Mysql主从同步竟然这么多细节
date: 2023-07-27 17:07:07
description: 踩踩Mysql主从同步的坑
tags:
- 主从同步
categories:
- Mysql

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 整体流程
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657979751192-3c6cd1bc-61e8-4cbe-84e4-2c2025b9690b.png#clientId=uff23d712-cab8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=707&id=ub805f8af&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1414&originWidth=2174&originalType=binary&ratio=1&rotation=0&showTitle=false&size=557877&status=done&style=none&taskId=uf7436d59-bb9c-4005-9754-13c7cd0f9e4&title=&width=1087)

1. 主库发生数据变更，将数据写入到binlog文件中
1. 从库I/O线程发起dump请求
1. 主库I/O线程将指定位点的binlog推送到从库
1. 从库I/O线程写入本地的中转日志（relay log）文件（与binlog文件一致）
1. 从库SQL线程读取relay log文件重放

## 传输文件格式
通过上图可以看见，主库会将binlog推送从库。
那么binlog是什么格式？

### binlog的三种格式

1. statement格式： 实际执行的sql语句
1. row格式，所有变更前后的数据（一个Table_map event , 一个 Delete_rows event）
1. mixed格式： 默认选择statement格式，需要的时候该用row格式

### 优缺点

|  | 优点 | 缺点 |
| --- | --- | --- |
| statement | statement传输数据少 | 删除语句带limit可能会存在走错索引，导致主库和从库删除的数据不一致 |
| row（常用） | 可以恢复数据，不会造成数据不一致 | row传输数据可能会很多,比较占空间。 |
| mixed | 继承了statement的优点，屏蔽了row的缺点 | 不能恢复数据 |

**趣味问答**
如果使用now()函数插入数据，通过statement将数据同步到从库，会不会导致时间不一致？
不会，mysql会增加一个set timestamp=xxxxx

如果两个节点互为主备的模式下，会不会产生循环复制？
不会，binlog里面会记录server_id， 如果binlog里的server_id和自己的server_id一致，则不执行。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1657981768550-a2718efe-e195-4cd3-bab8-0fc1a8b47448.png#clientId=uff23d712-cab8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=488&id=uaea0d4cb&margin=%5Bobject%20Object%5D&name=image.png&originHeight=976&originWidth=2062&originalType=binary&ratio=1&rotation=0&showTitle=false&size=325690&status=done&style=none&taskId=u6e16e84d-46d1-4b28-a197-4ce9a762196&title=&width=1031)


## 主从模式下的高可用

### 主从延迟
什么情况下会造成主从延迟？

1. 从库机器性能差
1. 从库读压力大
1. 大事务
1. 大表DDL

主从延迟了会有什么问题？

1. 主库更新了数据，从库查不到

主从延迟了怎么处理？

#### 主从延迟策略

##### 可靠性优先策略
主库发现和从库存在延迟，先关闭写状态，等到延迟为0时，再开启从库写，然后将流量达到从库。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1658027490508-e7ee5120-7e68-4cfb-80ee-c28524cbd330.png#clientId=uff23d712-cab8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=485&id=ud72141fa&margin=%5Bobject%20Object%5D&name=image.png&originHeight=970&originWidth=2036&originalType=binary&ratio=1&rotation=0&showTitle=false&size=294398&status=done&style=none&taskId=u674ce459-c4b4-4c2b-b160-f1c35dba391&title=&width=1018)
备注：图中的SBM，是seconds_behind_master参数的简写。

1. 判断备库B现在的seconds_behind_master，如果小于某个值（比如5秒）继续下一步，否则持续重试这一步；
1. 把主库A改成只读状态，即把readonly设置为true；
1. 判断备库B的seconds_behind_master的值，直到这个值变成0为止；
1. 把备库B改成可读写状态，也就是把readonly 设置为false；
1. 把业务请求切到备库B。

这个切换流程，一般是由专门的HA系统来完成的，我们暂时称之为可靠性优先流程。
##### 可用性优先策略
如果强行把步骤4、5调整到最开始执行，也就是说不等主备数据同步，直接把连接切到备库B，并且让备库B可以读写，那么系统几乎就没有不可用时间了。
我们把这个切换流程，暂时称作可用性优先流程。这个切换流程的代价，就是可能出现数据不一致的情况。
### 从库并行复制
主从延迟的核心问题是从库执行relay log的效率追不上主库写入binlog的效率。那我们提升从库的执行relay log的能力是不是可以解决呢？
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1658028153760-c22e217d-4200-47e6-9d03-b9936a8e7bb3.png#clientId=uff23d712-cab8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=720&id=ua960238a&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1440&originWidth=2004&originalType=binary&ratio=1&rotation=0&showTitle=false&size=300489&status=done&style=none&taskId=u7b7ff6fd-a0e9-48c1-be71-7f1691c9dbb&title=&width=1002)
coordinator就是原来的sql_thread, 不过现在它不再直接更新数据了，只负责读取中转日志和分发事务。真正更新日志的，变成了worker线程。而work线程的个数，就是由参数slave_parallel_workers决定的。根据我的经验，把这个值设置为8~16之间最好（32核物理机的情况），毕竟备库还有可能要提供读查询，不能把CPU都吃光了。
但是对于事务来讲，要怎么分发给不同的线程执行呢？
一个个事务分发？ 可能会导致后分发的事务先执行。
同一个事务发给不同的worker执行？ 先后顺序问题也会造成数据不一致。
#### 分发原则

1. 不能造成更新覆盖。同一行的两个事务，必须分发到同一个worker中
1. 同一个事务不能拆开，必须放到同一个worker中执行

#### 分发策略
**按表分发策略**
很好理解，但是如果出现热点表就可能退化成了单线程复制了
**按行分发策略**
要解决热点表的并行复制问题，就需要一个按行并行复制的方案。按行复制的核心思路是：如果两个事务没有更新相同的行，它们在备库上可以并行执行。显然，这个模式要求binlog格式必须是row。
**约束条件**
这两个方案其实都有一些约束条件：

1. 要能够从binlog里面解析出表名、主键值和唯一索引的值。也就是说，主库的binlog格式必须是row；
1. 表必须有主键；
1. 不能有外键。表上如果有外键，级联更新的行不会记录在binlog中，这样冲突检测就不准确。

### 主从延迟业务解决方案

- 强制走主库方案；
- sleep方案；
- 判断主备无延迟方案；
- 配合semi-sync方案（等从库ack之后，主库的commit才算成功）；
- 等主库位点方案；
- 等GTID方案。

## 主库宕机，主备切换
先来看看互联网一主多从的玩法
### 一主多从架构
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1658030021982-ac58de62-d724-4f35-bc8b-5ac7fb6d529c.png#clientId=uff23d712-cab8-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=642&id=u12970df7&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1284&originWidth=1872&originalType=binary&ratio=1&rotation=0&showTitle=false&size=394075&status=done&style=none&taskId=ue80ad1de-1677-4017-a872-a6e8d8d49a0&title=&width=936)
图中，虚线箭头表示的是主备关系，也就是A和A’互为主备， 从库B、C、D指向的是主库A。一主多从的设置，一般用于读写分离，主库负责所有的写入和一部分读，其他的读请求则由从库分担。
如果这个时候A宕机了，怎么办？
### 主备切换
#### 基于位点的主备切换
当我们把节点B设置成节点A’的从库的时候，需要执行一条change master命令：
```sql
CHANGE MASTER TO 
MASTER_HOST=$host_name 
MASTER_PORT=$port 
MASTER_USER=$user_name 
MASTER_PASSWORD=$password 
MASTER_LOG_FILE=$master_log_name 
MASTER_LOG_POS=$master_log_pos  
```
这个位点很难精确取到，只能取一个大概位置。为什么这么说呢？
考虑到切换过程中不能丢数据，所以我们找位点的时候，总是要找一个“稍微往前”的，然后再通过判断跳过那些在从库B上已经执行过的事务。
一种取同步位点的方法是这样的：

1. 等待新主库A’把中转日志（relay log）全部同步完成；
1. 在A’上执行show master status命令，得到当前A’上最新的File 和 Position；
1. 取原主库A故障的时刻T；
1. 用mysqlbinlog工具解析A’的File，得到T时刻的位点。

如果A在宕机前把数据推送给了A’和B。那当A'切换成主库时，位点可能是最后一条数据的位点，但是B其实已经执行过了，在执行就会报错。所以需要忽略这些错误。
#### 基于GTID的主备切换
**GTID（Global Transaction Identifier，也就是全局事务ID）**
```sql
GTID=server_uuid:gno
```
其中：

- server_uuid是一个实例第一次启动时自动生成的，是一个全局唯一的值；
- gno是一个整数，初始值是1，每次提交事务的时候分配给这个事务，并加1。

**GTID模式下的切换主库的语法**
```sql
CHANGE MASTER TO 
MASTER_HOST=$host_name 
MASTER_PORT=$port 
MASTER_USER=$user_name 
MASTER_PASSWORD=$password 
master_auto_position=1
```
其中，master_auto_position=1就表示这个主备关系使用的是GTID协议。可以看到，前面让我们头疼不已的MASTER_LOG_FILE和MASTER_LOG_POS参数，已经不需要指定了。
我们把现在这个时刻，实例A’的GTID集合记为set_a，实例B的GTID集合记为set_b。接下来，我们就看看现在的主备切换逻辑。
我们在实例B上执行start slave命令，取binlog的逻辑是这样的：

1. 实例B指定主库A’，基于主备协议建立连接。
1. 实例B把set_b发给主库A’。
1. 实例A’算出set_a与set_b的差集，也就是所有存在于set_a，但是不存在于set_b的GITD的集合，判断A’本地是否包含了这个差集需要的所有binlog事务。
a. 如果不包含，表示A’已经把实例B需要的binlog给删掉了，直接返回错误；
b. 如果确认全部包含，A’从自己的binlog文件里面，找出第一个不在set_b的事务，发给B；
1. 之后就从这个事务开始，往后读文件，按顺序取binlog发给B去执行。

## 总结
本篇主要是剖析Mysql的主从同步。

1. 先从整体流程上看Mysql的同步过程。
1. 然后从具体的数据格式分析。
1. 接着分析主从的高可用，讲了两个核心问题，1是主从延迟，2是主备切换。
1. 主从延迟有两种策略，可靠性和可用性策略。一种并行复制的解决方案
1. 主备切换也有两种策略，位点和GTID
