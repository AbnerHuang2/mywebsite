---
title: Canal实践
description: Canal实践
date: 2022-03-08 10:53:49

tags:
- Canal

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 简介
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642312153729-a7d97f69-08d0-49de-9510-d674434503a6.png#averageHue=%23f3f2f2&clientId=ue28ef31d-a3ea-4&from=paste&height=359&id=u9db2a91f&originHeight=717&originWidth=1361&originalType=binary&ratio=1&rotation=0&showTitle=false&size=137835&status=done&style=none&taskId=uf15ac87c-e23f-4855-a642-1813bf1e579&title=&width=680.5)
**canal [kə'næl]**，译意为水道/管道/沟渠，主要用途是基于 MySQL 数据库增量日志解析，提供增量数据订阅和消费
[https://github.com/alibaba/canal](https://github.com/alibaba/canal)
## 工作原理

- canal 模拟 MySQL slave 的交互协议，伪装自己为 MySQL slave ，向 MySQL master 发送dump 协议
- MySQL master 收到 dump 请求，开始推送 binary log 给 slave (即 canal )
- canal 解析 binary log 对象(原始为 byte 流)
## 业务整合方案
利用canal读取数据库两个数据库的binlog，然后将数据发送到rocketmq，在项目中订阅消息，完成activity和课件数据的写入。
面临问题：

1. canal是否支持多库binlog读取【应该支持，在conf下增加一个example2试试】
2. canal服务器的搭建【如何在鲸云上搭建】
3. 是否存在的性能问题【[https://github.com/alibaba/canal/wiki/Performance](https://github.com/alibaba/canal/wiki/Performance) 从它早期的性能测试数据来看，这个问题应该不大】
4. 对数据库可能会存在一些压力

### 数据库操作
1开启binlog
```c
[mysqld]
log-bin=mysql-bin # 开启 binlog
binlog-format=ROW # 选择 ROW 模式
server_id=1 # 配置 MySQL replaction 需要定义，不要和 canal 的 slaveId 重复
```
> 查看binlog是否开启
> SHOW VARIABLES LIKE 'log_bin';
> 查看binlog
> show binary logs;
> 查看binlog相关设置
> show variables like '%binlog%';

2.创建canal用户
```plsql
CREATE USER canal IDENTIFIED BY 'canal';  
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%';
-- GRANT ALL PRIVILEGES ON *.* TO 'canal'@'%' ;
FLUSH PRIVILEGES;
```
## 服务端部署流程
docker pull canal/canal-server:v1.1.4
下载run.sh，【wget https://raw.githubusercontent.com/alibaba/canal/master/docker/run.sh 】
执行脚本
```c
sh run.sh -e canal.auto.scan=false \
		  -e canal.destinations=test \
		  -e canal.instance.master.address=172.20.218.50:3306  \
		  -e canal.instance.dbUsername=canal  \
		  -e canal.instance.dbPassword=canal  \
		  -e canal.instance.connectionCharset=UTF-8 \
		  -e canal.instance.tsdb.enable=true \
		  -e canal.instance.gtidon=false  \
```
转换后的docker脚本
```c
docker run -d -it -h 172.20.216.202 -e canal.auto.scan=false -e canal.destinations=test -e canal.instance.master.address=172.20.216.202:3306 -e canal.instance.dbUsername=canal -e canal.instance.dbPassword=canal -e canal.instance.connectionCharset=UTF-8 -e canal.instance.tsdb.enable=true -e canal.instance.gtidon=false --name=canal-server -p 11110:11110 -p 11111:11111 -p 11112:11112 -p 9100:9100 -m 4096m canal/canal-server
```
## 本机部署
在官网release下载deployer压缩包。[https://github.com/alibaba/canal/releases/download/canal-1.1.4/canal.deployer-1.1.4.tar.gz](https://github.com/alibaba/canal/releases/download/canal-1.1.4/canal.deployer-1.1.4.tar.gz)
解压，修改配置，启动。按官网教程来就行了。
## 客户端Example
按官网提供的来，也挺简单的。
## 参考
[https://github.com/alibaba/canal](https://github.com/alibaba/canal)
[https://www.bookstack.cn/read/canal-v1.1.4/cd6a5ac129e1edb7.md](https://www.bookstack.cn/read/canal-v1.1.4/cd6a5ac129e1edb7.md)

[https://www.modb.pro/db/79040](https://www.modb.pro/db/79040) （canal原理详解）