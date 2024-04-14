---
title: JVM
date: 2023-02-19
tags:
- JVM
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# 思维导图
![](https://cdn.nlark.com/yuque/0/2024/jpeg/21760570/1710334193469-4a2cc41a-c559-41cf-9fde-6a350b4f3ef6.jpeg)
# 常用命令
```bash
# dump堆内存
jmap -dump:format=b,file=<filePath> <pid>
jmap -dump:format=b,file=app.hprof 45

#查看GC情况
jstat -gcutil <pid> 1s #每1秒打印gc基本信息
jstat -gc 45 250 10 #每250毫秒打印Java进程45的gc详细信息，一共打印10次
jstat -class 45 #查看类加载信息
```
# JVM必备调优参数
```bash
-XX:+UseConcMarkSweepGC  #设置垃圾回收器为CMS（Java8默认新生代为PS，老年代为SerialOld）

-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/heapdump.hprof #设置oom时自动dump堆

# 打印gc log
-XX:+PrintGCDetails -Xloggc:/Users/abner/Downloads/jvm-gc.log

-Xmx1g -Xms1g #稳定堆大小，避免启动时触发过程fullGC

-XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m #稳定元空间大小，避免启动时触发过程fullGC（默认才几十M）

##配置gc日志详情
-XX:+PrintGCDetails 
## 配置引用gc耗时
-XX:+PrintReferenceGC

## 中文释义：尽可能启用并行引用处理
## 使用方法：通过-XX:+ParallelRefProcEnabled开启，或者-XX:-ParallelRefProcEnabled关闭
```
# JVM内存结构
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1654764952513-d650d288-e03a-46c4-b4eb-5fb5da2a6b21.png#averageHue=%23c6cea8&clientId=uc1ae992b-911b-4&from=paste&height=199&id=u056f1f8a&originHeight=398&originWidth=475&originalType=binary&ratio=1&rotation=0&showTitle=false&size=114407&status=done&style=none&taskId=u2637fd05-8176-46f0-898c-adb740cb405&title=&width=237.5)
# 参考
[https://tech.meituan.com/2020/11/12/java-9-cms-gc.html](https://tech.meituan.com/2020/11/12/java-9-cms-gc.html) （常见oom问题分析）
https://www.cnblogs.com/jmcui/p/12051328.html (参数使用手册)