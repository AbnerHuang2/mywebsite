---
title: Mysql插入删除死锁问题排查
description: 搞懂Mysql插入删除是如何加锁的
date: 2022-02-10 19:58:16
tags:
- 问题排查
categories:
- Mysql
---
<meta name="referrer" content="no-referrer" />
<!-- more -->


## 查看业务日志
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642074072500-6db92ae1-eaff-462f-af20-9f0fb579d2c0.png#clientId=u1d0a973d-d39c-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=207&id=uc5138bc1&margin=%5Bobject%20Object%5D&name=image.png&originHeight=207&originWidth=961&originalType=binary&ratio=1&rotation=0&showTitle=false&size=81604&status=done&style=none&taskId=u9feaf1b7-3944-4bda-b069-fb48f7151cd&title=&width=961)
## 查看死锁日志
show engine innodb status; （查询语句）
```c
------------------------
LATEST DETECTED DEADLOCK
------------------------
2022-01-12 08:24:23 0x7f5a5cf75700
*** (1) TRANSACTION:
//事务A
TRANSACTION 9400396, ACTIVE 0 sec inserting
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 1136, 2 row lock(s), undo log entries 10
MySQL thread id 2138935, OS thread handle 140026474653440, query id 58338774 10.21.17.247 liuchuangzhao update
insert into t_device_online (device_id, start_time, end_time,online_times) values

            (133, 1641975738, 1641975861,1)
         ,
            (137, 1641975727, 1641975861,1)
         ,
            (138, 1641975743, null,1)
         ,
            (144, 1641975726, null,1)
         ,
            (146, 1641975742, null,1)
         ,
            (147, 1641975728, 1641975862,1)
         ,
            (150, 1641975724, null,1)
         ,
            (152, 1641975746, 1641975861,1)
         ,
            (154, 1641975744, null,1)
         ,
            (28, 1641975737, 1641975861,1)
         ,
            (158, 1641975744, null,1)
         ,
            (32, 1641975736, 1641975862,1)
         ,
            (162, 1641975733, null,1)
         ,
            (36, 1641975736, 1641975861,1)
         ,
            (168, 1641975729, null,1)
         ,
            (40, 1641975732, n
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 61 page no 30559 n bits 824 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 9400396 lock_mode X locks gap before rec insert intention waiting
*** (2) TRANSACTION:
//事务B
TRANSACTION 9400297, ACTIVE 1 sec fetching rows
mysql tables in use 1, locked 1
72 lock struct(s), heap size 24784, 1748 row lock(s), undo log entries 5
MySQL thread id 2138649, OS thread handle 140026083497728, query id 58338328 10.21.17.247 liuchuangzhao updating
delete from t_device_online where end_time is null
            and device_id in
             (
                133
             ,
                137
             ,
                138
             ,
                144
             ,
                146
             ,
                147
             ,
                150
             ,
                152
             ,
                154
             ,
                28
             ,
                158
             ,
                32
             ,
                162
             ,
                36
             ,
                168
             ,
                40
             ,
                10536
             ,
                169
             ,
                170
             ,
                42
             ,
                10411
             ,
                171
             ,
                172

*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 61 page no 30559 n bits 824 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 9400297 lock_mode X locks gap before rec
*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 61 page no 30545 n bits 672 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 9400297 lock_mode X waiting
*** WE ROLL BACK TRANSACTION (1)
```
| 事务A（insert） | 事务B（delete） |
| --- | --- |
|  | ​
 |
|  | 持有行锁 824 index（X锁） |
| 等行锁 824 index（X锁） |  |
|  | 等行锁 672 index（X锁） |
| 回滚 |  |

从死锁日志上，可以，事务A并没有持有事务B所需要的资源啊，但是从现象上来看，事务A应该是持有了672的行锁。那我们就必须先了解insert的加锁过程。
## insert加锁
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642377267905-4e7f60c8-004b-4c62-9313-7e4a6d6738c5.png#clientId=ub48be365-8441-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=293&id=u060c8838&margin=%5Bobject%20Object%5D&name=image.png&originHeight=586&originWidth=1910&originalType=binary&ratio=1&rotation=0&showTitle=false&size=181462&status=done&style=none&taskId=u5f6f6851-c0a1-4849-a00b-ee7576e4bdb&title=&width=955)
#### insert加锁过程
1. 先加插入意向Gap锁(insert intention gap lock)【如果别的事务已经有了这个间隙的锁Gap Lock，就无法加insert intention gap lock】
1. 然后对插入的记录加索引记录锁（index-record lock）不会加gap锁，不影响其他insert的执行，除非他们插入的记录的索引值相同。
1. 如果插入的记录索引值相同，则会出现duplicate-key error，就会对改索引加一个共享锁（shared lock）。但是如果有多个请求同时插入同一个索引值，这种情况可能会出现死锁。

举个例子：

| 事务A | 事务B | 事务C |
| --- | --- | --- |
| START TRANSACTION; | ​
 | ​
 |
| INSERT INTO t1 VALUES(1); | START TRANSACTION; | START TRANSACTION; |
| 获取到index-record lock(也是这个行记录的排查锁) | INSERT INTO t1 VALUES(1); | INSERT INTO t1 VALUES(1); |
| 增加shared lock | 遇到duplicate-key error | 遇到duplicate-key error |
| ​
 | 等待shared lock | 等待shared lock |
| ROLLBACK; | ​
 | ​
 |
| 释放shared lock | 获取到shared lock | 获取到shared lock |
| 释放排查锁 | 等待排查锁 | 等待排查锁 |
|  | 死锁 | 死锁 |

事务B和C都获取到了shared lock，都在等待排他锁，但是排他锁和shared lock互斥，所以事务B和C都获取不到排他锁。（想要获取排他锁必须等对方释放shared lock，但是这是不可能的）
**还有一种情况也会产生死锁**

| 事务A | 事务B | 事务C |
| --- | --- | --- |
| START TRANSACTION; | ​
 | ​
 |
| delete from t1 where id = 1; | START TRANSACTION; | START TRANSACTION; |
| 获取到index-record lock(也是这个行记录的排查锁) | INSERT INTO t1 VALUES(1); | INSERT INTO t1 VALUES(1); |
| 增加shared lock | 遇到duplicate-key error | 遇到duplicate-key error |
| ​
 | 等待shared lock | 等待shared lock |
| commit; | ​
 | ​
 |
| 释放shared lock | 获取到shared lock | 获取到shared lock |
| 释放排查锁 | 等待排查锁 | 等待排查锁 |
|  | 死锁 | 死锁 |

#### 结论

**三个以上的并发插入，如果一个回滚了，可能会存在死锁（原因是出现**duplicate-key error，其他事务都获取不到排他锁**）**
**一个删除，两个并发插入，删除提交后也会造成死锁。**
​

## Delete加锁
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642516633446-beceaa9f-6468-424d-b493-0dcf38284708.png#clientId=u56f5bcdf-874a-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=65&id=u9e1f885a&margin=%5Bobject%20Object%5D&name=image.png&originHeight=130&originWidth=1896&originalType=binary&ratio=1&rotation=0&showTitle=false&size=38765&status=done&style=none&taskId=u443b9767-dbf8-4aaf-9327-418f0eb25c4&title=&width=948)
delete加锁过程

1. 设置一个next-key的排他锁在每个搜索的行记录。（意味着除了占住行锁，还会占住间隙锁）
1. 对于使用唯一索引搜索的情况只会对搜索的行加索引记录锁



## 复现

复现方式1
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642595958486-9b6c7bd9-d820-4732-88de-07943b535904.png#clientId=u8b19cdb6-bf92-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=348&id=u90cbff8d&margin=%5Bobject%20Object%5D&name=image.png&originHeight=348&originWidth=881&originalType=binary&ratio=1&rotation=0&showTitle=false&size=57322&status=done&style=none&taskId=ua0cb8125-6d19-43f7-b468-58cae125d82&title=&width=881)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642595985011-eea742e4-e772-4304-9191-370751e251c0.png#clientId=u8b19cdb6-bf92-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=171&id=u59c09004&margin=%5Bobject%20Object%5D&name=image.png&originHeight=171&originWidth=560&originalType=binary&ratio=1&rotation=0&showTitle=false&size=16731&status=done&style=none&taskId=u8ec56e12-27bd-4d24-b07f-767c578af60&title=&width=560)
执行步骤：

| 事务A | 事务B |
| --- | --- |
| 开始事务 |  |
|  | 开始事务 |
| 插入133 |  |
|  | 删除137 |
| 插入137 |  |
|  | 提交 |
| 死锁 |  |

死锁日志
```c
------------------------
LATEST DETECTED DEADLOCK
------------------------
2022-01-19 12:38:16 0x7f59772d9700
*** (1) TRANSACTION:
//事务A
TRANSACTION 10649448, ACTIVE 136 sec inserting
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 1136, 2 row lock(s), undo log entries 2
MySQL thread id 2419529, OS thread handle 140026471950080, query id 66144333 10.21.17.247 liuchuangzhao update
/* ApplicationName=DBeaver 21.0.0 - SQLEditor <dev_with_high_pri.sql> */ insert into t_device_online (device_id, start_time, end_time,online_times) values(137, 1641975727, 1641975861,1)
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 61 page no 30554 n bits 824 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 10649448 lock_mode X locks gap before rec insert intention waiting
*** (2) TRANSACTION:
//事务B
TRANSACTION 10649665, ACTIVE 28 sec fetching rows
mysql tables in use 1, locked 1
35 lock struct(s), heap size 8400, 203 row lock(s), undo log entries 100
MySQL thread id 2419581, OS thread handle 140022228293376, query id 66144549 10.21.17.247 liuchuangzhao updating
/* ApplicationName=DBeaver 21.0.0 - SQLEditor <Script-4.sql> */ delete from t_device_online where device_id in (133)
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 61 page no 30554 n bits 824 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 10649665 lock_mode X locks gap before rec
*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 61 page no 30545 n bits 712 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 10649665 lock_mode X waiting
*** WE ROLL BACK TRANSACTION (1)
```

---

复现方式2
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642599276279-94f84360-1e7f-4148-8f2f-ae77161bb0b6.png#clientId=u23a50d9c-b0fd-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=112&id=ubb856f14&margin=%5Bobject%20Object%5D&name=image.png&originHeight=224&originWidth=1460&originalType=binary&ratio=1&rotation=0&showTitle=false&size=145102&status=done&style=none&taskId=ud9cda12f-cdd1-41cf-aff1-c5099cc89ce&title=&width=730)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642599253891-c90bea14-e1f4-459d-9090-b4996782ea4a.png#clientId=u23a50d9c-b0fd-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=170&id=u2e2ac32f&margin=%5Bobject%20Object%5D&name=image.png&originHeight=340&originWidth=1342&originalType=binary&ratio=1&rotation=0&showTitle=false&size=113383&status=done&style=none&taskId=ucf365b65-f865-4d54-bc6d-ed21d32a4df&title=&width=671)
执行过程

| 事务A | 事务B |
| --- | --- |
| 开始事务 |  |
|  | 开始事务 |
| 插入137 |  |
|  | 删除137,133 |
| 插入133 |  |
| 死锁 | ​
 |
| ​
 |  |

死锁日志
```c
------------------------
LATEST DETECTED DEADLOCK
------------------------
2022-01-19 12:58:59 0x7f5a74376700
*** (1) TRANSACTION:
//事务A
TRANSACTION 10652218, ACTIVE 4 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 5 lock struct(s), heap size 1136, 5 row lock(s), undo log entries 1
MySQL thread id 2420044, OS thread handle 140022237755136, query id 66160375 10.21.17.247 liuchuangzhao updating
/* ApplicationName=DBeaver 21.0.0 - SQLEditor <Script-4.sql> */ delete from t_device_online where device_id in (137,133)
*** (1) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 61 page no 30554 n bits 824 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 10652218 lock_mode X waiting
*** (2) TRANSACTION:
//事务B
TRANSACTION 10652205, ACTIVE 10 sec inserting
mysql tables in use 1, locked 1
3 lock struct(s), heap size 1136, 2 row lock(s), undo log entries 2
MySQL thread id 2420043, OS thread handle 140026473572096, query id 66160420 10.21.17.247 liuchuangzhao update
/* ApplicationName=DBeaver 21.0.0 - SQLEditor <dev_with_high_pri.sql> */ insert into t_device_online (device_id, start_time, end_time,online_times) values
(133, 1641975727, 1641975861,1)
*** (2) HOLDS THE LOCK(S):
RECORD LOCKS space id 61 page no 30554 n bits 824 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 10652205 lock_mode X locks rec but not gap
*** (2) WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 61 page no 30545 n bits 712 index device_id of table `ifp_remote_platform`.`t_device_online` trx id 10652205 lock_mode X locks gap before rec insert intention waiting
*** WE ROLL BACK TRANSACTION (2)
```

---



## 死锁原因分析
虽然复现方式不一样，但是死锁日志是一样的。

#### 复现1原因分析：
| 事务A | 事务B |
| --- | --- |
| 开始事务 |  |
|  | 开始事务 |
| 插入133（插入index-recode-lock，意向排他锁，是一个隐式排他锁） |  |
|  | 删除137（获取了137的行锁及周围间隙锁） |
| ​
 | 删除133
（发现133有隐式排他锁，就帮他加上记录锁。
等待133的排他锁，也就是133的行锁） |
| 插入137（等待137周围的间隙锁） | ​
 |
| 死锁 |  |

#### 复现2原因分析：
| 事务A | 事务B |
| --- | --- |
| 开始事务 |  |
|  | 开始事务 |
| 插入137（插入index-recode-lock，意向排他锁，是一个隐式排他锁） |  |
|  | 删除137,133 （获取了133的行锁，等待137的行锁）【这里可以说明删除会对in重排序，不然不会造成死锁】 |
| 插入133（等待133的行锁） |  |
| 死锁 | ​
 |
| ​
 |  |

#### 业务死锁分析

1. insert执行流程长，拿到了一些device_id
1. insert执行过程中，delete 对 in 里面的device_id进行排序，然后先于insert拿到后面要执行的device_id，但是需要等待insert已经获取的device_id。
1. insert要等delete已获取的device_id
1. 就死锁了

**待验证**
为什么delete会对in里面的device_id重排序？
我觉得是因为删除语句没有走索引，要全表扫描，mysql为了避免随机IO，就对in的device_id排序了。
为什么insert 不会？
insert默认是通过主键id去查找，然后插入都是很快的，所以不需要重排序。
​

复现1和复现2和最开始的死锁日志一致。
如果复现1还不能说明问题的话，复现2就很能说明问题了。只要insert的够慢，delete 先拿到insert接下来要删除的行锁，就会死锁。
​

## 参考
[https://blog.csdn.net/varyall/article/details/80219459](https://blog.csdn.net/varyall/article/details/80219459) (insert加锁分析)
[https://cloud.tencent.com/developer/article/1900240](https://cloud.tencent.com/developer/article/1900240) (insert加锁分析)
[https://dev.mysql.com/doc/refman/5.7/en/innodb-locks-set.html](https://dev.mysql.com/doc/refman/5.7/en/innodb-locks-set.html) （mysql官网innodb加锁说明）
[https://www.docs4dev.com/docs/zh/mysql/5.7/reference/innodb-locks-set.html](https://www.docs4dev.com/docs/zh/mysql/5.7/reference/innodb-locks-set.html)(中文文档)