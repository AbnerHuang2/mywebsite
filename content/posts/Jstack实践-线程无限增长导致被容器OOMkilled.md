---
title: Jstack实践-线程无限增长导致被容器OOMkilled
description: 千万不要随意创建线程池
date: 2022-04-19 16:30:09
tags:
- Java
- JVM
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# 现象
容器每隔一段时候就会自动重启，大概一周左右。理由是OOMkilled。
查看jstack日志，发现里面竟有3319个线程在运行。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649205811746-7ad8d374-0284-435e-a7c1-e843d46aaa7a.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=113&id=u9445deab&margin=%5Bobject%20Object%5D&name=image.png&originHeight=113&originWidth=1011&originalType=binary&ratio=1&rotation=0&showTitle=false&size=44683&status=done&style=none&taskId=uda40d6d1-58de-4de9-9749-364045f5308&title=&width=1011)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649205954100-cf131c0a-a5bc-4797-a064-37f6881e32d5.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=805&id=ue60269a7&margin=%5Bobject%20Object%5D&name=image.png&originHeight=805&originWidth=1328&originalType=binary&ratio=1&rotation=0&showTitle=false&size=370605&status=done&style=none&taskId=u184c7bea-822f-4bba-9255-e0ce06106e1&title=&width=1328)
# 分析
看看这些线程都在做什么？（图表来源于fastthread.io）
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649206157121-b31738e8-05b2-4a76-bd9b-2c8bdcff848b.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=521&id=ud1783b3f&margin=%5Bobject%20Object%5D&name=image.png&originHeight=521&originWidth=1428&originalType=binary&ratio=1&rotation=0&showTitle=false&size=268355&status=done&style=none&taskId=ub89f1a99-b4fe-4965-9781-e33923ebc38&title=&width=1428)
可以看到有1578个pool，和1485个消费线程。而这里就占了90%。所以肯定有点问题。
于是就可以详细看pool和这个消费线程在做啥。
pool基本都是两个两个一组双数增长。而且也看不到什么业务代码。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649206379665-a70f65e8-bf11-4228-b0cf-dad6a5d8574f.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=1080&id=ud85ece79&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1080&originWidth=1675&originalType=binary&ratio=1&rotation=0&showTitle=false&size=791564&status=done&style=none&taskId=u44e5fb49-8bae-4a57-b175-7b747d3d436&title=&width=1675)
消费线程也是两个两个的，一个上行，一个下行。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649206476389-3cb15253-346c-4ea8-a9f5-2c63ea106adf.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=763&id=u2fd9197c&margin=%5Bobject%20Object%5D&name=image.png&originHeight=763&originWidth=1618&originalType=binary&ratio=1&rotation=0&showTitle=false&size=200790&status=done&style=none&taskId=uaaf5ddb7-bccc-426b-bb36-feae077d9a4&title=&width=1618)
那只能从业务代码出发了。
从代码中搜索下行回复消息，找到了
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649207075937-9b03976b-cfbd-474a-81cb-cdb20faccb3f.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=390&id=uabbb1300&margin=%5Bobject%20Object%5D&name=image.png&originHeight=390&originWidth=1199&originalType=binary&ratio=1&rotation=0&showTitle=false&size=70732&status=done&style=none&taskId=ueb4738b5-2777-4f54-bb74-f43af10f22c&title=&width=1199)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649207107360-092179a2-41f2-4a33-b44d-d492666cb281.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=412&id=u1e6fe115&margin=%5Bobject%20Object%5D&name=image.png&originHeight=412&originWidth=1104&originalType=binary&ratio=1&rotation=0&showTitle=false&size=140435&status=done&style=none&taskId=u6a2e757f-4121-4764-8c75-451e4b6f8e1&title=&width=1104)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649207161877-0bb45e80-d382-4ce3-9013-72a7b7635965.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=420&id=ua67faa85&margin=%5Bobject%20Object%5D&name=image.png&originHeight=420&originWidth=1018&originalType=binary&ratio=1&rotation=0&showTitle=false&size=79128&status=done&style=none&taskId=ua2fc14db-f5d4-4b7b-92d4-9a165b8283f&title=&width=1018)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649207181956-b50cc494-339f-4a4a-a601-d23f9869ec56.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=164&id=uea6c0053&margin=%5Bobject%20Object%5D&name=image.png&originHeight=164&originWidth=1028&originalType=binary&ratio=1&rotation=0&showTitle=false&size=30231&status=done&style=none&taskId=u5a0912ef-bccc-4e38-92e6-3a544f16b54&title=&width=1028)
# 根因
大致逻辑是，有个设备上下线的接口。

1. 每隔7分钟调用设备上线接口
1. 触发iotClient的start(),里面会new IotMqttService()
1. 然后触发线程池的创建，以及上下行消息的提交
1. 触发两个监听两个阻塞队列读取上下行消息。

这就造成了线程数不断增长。最终导致超出容器分配的内存而被OOMkilled。
# 修复
**初始思路**
设备下线时，触发线程池的关闭。梳理下线逻辑，在内部的一个clear方法，将线程池关掉。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649207662952-2d813e4b-0dd8-49ab-82f1-1254bc2c8f25.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=270&id=u93fae7b0&margin=%5Bobject%20Object%5D&name=image.png&originHeight=270&originWidth=336&originalType=binary&ratio=1&rotation=0&showTitle=false&size=17557&status=done&style=none&taskId=u6462f0c1-60c2-4b9b-b2c3-4abb843dbf5&title=&width=336)
但是写完，测试的时候发现线程数依旧在涨（这里在测试环境模拟了线上环境，然后通过脚本一直在跑请求），而且我明明都shutdownNow了，还是依旧会有消息线程的增长。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649207910862-93d26010-c80d-4389-823f-d5d0def9837d.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=790&id=u4349bf0d&margin=%5Bobject%20Object%5D&name=image.png&originHeight=790&originWidth=862&originalType=binary&ratio=1&rotation=0&showTitle=false&size=231790&status=done&style=none&taskId=ub3b9b3fb-f5ed-42cb-83c2-ffb6ed6fd13&title=&width=862)
于是我在while(true)内部增加了中断处理。
但是神奇的是，线程数还是在涨。

于是我在线程池关闭之后，通过一个异步线程打印当前程序的线程数依旧线程名称。发现消息线程确实会被处理掉，但是还是有这个pool-thread。那这个pool-thread是在哪里开启的呢？
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649208188461-2596e561-eda2-4f59-a1c9-064c406810de.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=553&id=ub7b3366f&margin=%5Bobject%20Object%5D&name=image.png&originHeight=553&originWidth=1282&originalType=binary&ratio=1&rotation=0&showTitle=false&size=349119&status=done&style=none&taskId=u08233f99-455b-47f0-af9f-fd4f33c4aaf&title=&width=1282)
�回到fastthread.io,看到这个pool-thread是通过ScheduledThreadPoo触发的。同样的，代码中大概率是通过newScheduledThreadPool创建的线程池，就搜一下，果然发现了这个。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649208307525-a40303c6-42aa-4502-9883-2623358f5291.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=75&id=u5b75f912&margin=%5Bobject%20Object%5D&name=image.png&originHeight=75&originWidth=938&originalType=binary&ratio=1&rotation=0&showTitle=false&size=15354&status=done&style=none&taskId=u7363a734-8a5a-4a2c-8323-bc3fe60921f&title=&width=938)
不啰嗦了，这个的原因是：创建这个IotMqttService的时候也会初始化一个日志打印的线程池，也会有两个线程在做日志打印的工作。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649208567300-d552c053-336f-4aa5-bf13-4e2b47c1027d.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=358&id=ue016f51d&margin=%5Bobject%20Object%5D&name=image.png&originHeight=358&originWidth=916&originalType=binary&ratio=1&rotation=0&showTitle=false&size=42771&status=done&style=none&taskId=uf5ce3248-1763-45fa-8a1c-1b47ac76525&title=&width=916)
于是我把这个改成了单例模式。
到这里，基本上才算清晰，
为啥线程池的shutdownNow不生效？(没有做break处理，shutdownNow只会将正在执行的线程进行中断，而业务上的线程在死循环等待，中断之后又进入了循环)
为啥pool-thread总是双数增长？（消费线程也是个线程池，之后业务设置了名称为消费线程，不然也是pool）
# 最终成效
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649208625902-d481df6e-2b2c-4dcd-b8b1-01615367f1e8.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=525&id=u50683071&margin=%5Bobject%20Object%5D&name=image.png&originHeight=525&originWidth=780&originalType=binary&ratio=1&rotation=0&showTitle=false&size=183986&status=done&style=none&taskId=u0f318335-beb0-4a7b-a1e0-3cb0ca5d472&title=&width=780)
异步打印程序的线程结果
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1649208636585-d00e35dd-b168-4c77-8884-dc4f51713234.png#clientId=ud58f7856-850e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=526&id=u07e5c1a8&margin=%5Bobject%20Object%5D&name=image.png&originHeight=526&originWidth=1685&originalType=binary&ratio=1&rotation=0&showTitle=false&size=148796&status=done&style=none&taskId=u699a3675-063d-4074-bf2f-d1b89d82d2e&title=&width=1685)
开了一个watch命令，没20s跑一次请求，跑了一下午，线程数基本都是稳定在105.
# 总结
**线程不断增长问题排查过程总结**

1. top -Hp <pid> 查看cpu情况和线程情况
1. jstack <pid> >> jstack.log 分析jstack日志（通过fastthread.io分析）
1. 通过fastthread.io的线程分组查看线程详情。
1. 通过关键词定位业务逻辑。
1. 分析业务逻辑，复现&解决问题



**注意⚠️**
线程池使用还是要谨慎啊，千万要注意关闭的问题。

#### 遗留待处理问题
一个线程占用多少内存？【1.9g的容器内存，大概可以开启9900多个线程，加上堆内存之类的，一个线程大概几百kb】【csdn上有个人说大概100k，看起来还算可信。[https://blog.csdn.net/spytian/article/details/113637759](https://blog.csdn.net/spytian/article/details/113637759)】
如果操作系统内存足够，一个Java程序可以无限增加线程吗？【应该会受JVM堆外内存限制，但是具体堆外内存是多少，怎么设置，我也还不太清楚】