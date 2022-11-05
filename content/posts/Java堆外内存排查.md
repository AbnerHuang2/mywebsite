---
title: Java堆外内存排查
date: 2022-02-19 19:52:32
tags:
- Java
- JVM
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# 启动参数
> java -XX:NativeMemoryTracking=detail -XX:MetaspaceSize=256M -XX:MaxMetaspaceSize=256M -XX:+AlwaysPreTouch -XX:ReservedCodeCacheSize=128m -XX:InitialCodeCacheSize=128m -Xss512k -Xmx1g -Xms1g -XX:+UseG1GC -XX:G1HeapRegionSize=4M -jar lib/helfy-1.0-SNAPSHOT.jar

# 现象
程序启动一段时间，就会被自动kill掉。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642827852635-6811ba84-1bc6-45c1-a2cb-29ac69e21438.png#clientId=u8a31b6cc-a918-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=29&id=ucc172fe5&margin=%5Bobject%20Object%5D&name=image.png&originHeight=29&originWidth=113&originalType=binary&ratio=1&rotation=0&showTitle=false&size=2239&status=done&style=none&taskId=ud0035b56-0fee-458a-9bfc-05ba8b1ef43&title=&width=113)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642828201933-ba8b0306-9faf-45f0-a94f-bf22fdaf4cff.png#clientId=u8a31b6cc-a918-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=682&id=ubeabec97&margin=%5Bobject%20Object%5D&name=image.png&originHeight=682&originWidth=671&originalType=binary&ratio=1&rotation=0&showTitle=false&size=121957&status=done&style=none&taskId=u5552601d-8cb0-40da-865c-d20933a96a1&title=&width=671)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642828352885-5f8dada5-a939-4832-bd19-fd540e6410fd.png#clientId=u8a31b6cc-a918-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=466&id=u2410ff95&margin=%5Bobject%20Object%5D&name=image.png&originHeight=466&originWidth=657&originalType=binary&ratio=1&rotation=0&showTitle=false&size=89919&status=done&style=none&taskId=u656ab374-bb55-4139-878d-1a45f4c6f8a&title=&width=657)


# 分析
从上面的jstat -gcutil 现象来看，应该不是heap OOM，也不是 Metaspace OOM。
那可能是堆外内存OOM，怎么验证呢？
通过top分析Java进程内存占用
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642828527772-0c64e15c-a1d5-497a-8c07-e6da7c5d5205.png#clientId=u8a31b6cc-a918-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=81&id=u0d3b34e2&margin=%5Bobject%20Object%5D&name=image.png&originHeight=81&originWidth=670&originalType=binary&ratio=1&rotation=0&showTitle=false&size=12631&status=done&style=none&taskId=u54e9556f-1c28-4a90-911c-dfa7af4920a&title=&width=670)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1642828550191-42e4e508-3d97-44f0-b832-344558fd1625.png#clientId=u8a31b6cc-a918-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=92&id=uf558c87b&margin=%5Bobject%20Object%5D&name=image.png&originHeight=92&originWidth=649&originalType=binary&ratio=1&rotation=0&showTitle=false&size=9624&status=done&style=none&taskId=u7e398639-8316-45b5-b269-e142192a3ed&title=&width=649)
当这个内存到了3.7g多的时候，程序就会被kill掉。
通过jmap -heap 104139 查看Java堆内存占用
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644927476318-4c8ee2fc-4443-410a-8cf7-3f965452a520.png#clientId=u93d2d44e-1b6e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=370&id=u9fc2d627&margin=%5Bobject%20Object%5D&name=image.png&originHeight=370&originWidth=524&originalType=binary&ratio=1&rotation=0&showTitle=false&size=52913&status=done&style=none&taskId=u74ad6a6e-01d6-4f3f-b768-dae110b52b6&title=&width=524)
我们也可以通过pmap来查看进程的内存占用。
pmap -x 104139 | tail -n 1 
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644927211273-50fd1b6c-d66c-4be7-af23-07e3e2fdc816.png#clientId=u93d2d44e-1b6e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=118&id=u42fb8cab&margin=%5Bobject%20Object%5D&name=image.png&originHeight=118&originWidth=599&originalType=binary&ratio=1&rotation=0&showTitle=false&size=23105&status=done&style=none&taskId=u84b8e90f-d513-43e1-ac72-f4205b55819&title=&width=599)
通过jmap和pmap可以发现，pmap的内存占用比jmap的堆配置总和还多。
而且pmap的RSS也一直在涨。
> 解释一下这个RSS的含义，如下图。一般来讲共享库所占的内存应该不会很多![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644928351558-654bf212-807e-4ebe-b037-7b606848d6c8.png#clientId=u17dc34e6-6de1-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=289&id=ubfaad7bd&margin=%5Bobject%20Object%5D&name=image.png&originHeight=289&originWidth=462&originalType=binary&ratio=1&rotation=0&showTitle=false&size=106819&status=done&style=none&taskId=u4fc87a58-0840-411b-9508-c3a48711e7f&title=&width=462)
> [https://www.jianshu.com/p/3bab26d25d2e](https://www.jianshu.com/p/3bab26d25d2e)

**这里基本就能确定是堆外内存OOM了**

默认来讲，堆外内存大小=设置的堆内存大小-XX:Xmx，但是从top的结果来看，基本上在3.7多就被kill了。
堆内存设置的是1g，然后metaspace设置的好像是256m。那如果堆外内存是1g的话，感觉说不太通。
​

为什么会发生堆外内存OOM呢？看看线程到底在做什么
先top一把
top -H 打印所有线程的使用情况
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644927940329-c771544a-8fd5-4bd0-8cd4-511820aa3dfb.png#clientId=u93d2d44e-1b6e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=135&id=u923b13b9&margin=%5Bobject%20Object%5D&name=image.png&originHeight=135&originWidth=633&originalType=binary&ratio=1&rotation=0&showTitle=false&size=27207&status=done&style=none&taskId=u21e69aaf-99a7-43d0-9249-b8cc923e8aa&title=&width=633)
​

这个 280376一直是用了88%的cpu，稳居榜首。
通过jstack看看它到底在干嘛（这里存在一个十进制转16进制的转换）
jstack 280375 | grep '44738' -A 40
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644928118445-ca02f40c-a09b-453f-bcbd-8fb8bb283004.png#clientId=u93d2d44e-1b6e-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=550&id=uc657fca9&margin=%5Bobject%20Object%5D&name=image.png&originHeight=550&originWidth=921&originalType=binary&ratio=1&rotation=0&showTitle=false&size=145818&status=done&style=none&taskId=udbdc2561-7261-4e1a-ad42-486b226c711&title=&width=921)
从业务代码可以看出，应该是这个one.helfy.SleepyBean里面一直调用springboot的方式去解压jar包。用的是Inflater这个类，一直在申请堆外内存。
# 祖传命令
```c
# 观察GC情况
ps -afx | grep java  | grep -v grep | awk '{print $1}' | xargs -I{} jstat -gcutil {} 1s

# 从JVM角度观察内存
jcmd <pid> VM.native_memory detail

# 观察内存使用情况
pmap -x 1

# 排序一下内存占用
pmap -x 1 | sort -n -k3

# 跟踪系统调用（看谁在分配内存）
strace -f -e 'brk,mmap,munmap' -p <pid>
```
# 总结
**Top + jstack 分析cpu高负载场景**
假设Java进程pid=60

1. top -H 60 ，找到一个pid=280376的高负载线程
1. printf %x 280376 | xargs -I {} sh -C "jstack 60 | grep {}  -A 40"

# 参考
[https://tech.meituan.com/2019/01/03/spring-boot-native-memory-leak.html](https://tech.meituan.com/2019/01/03/spring-boot-native-memory-leak.html) （案例来源）
[https://tech.meituan.com/2020/11/12/java-9-cms-gc.html](https://tech.meituan.com/2020/11/12/java-9-cms-gc.html) （处理思路： 场景九）