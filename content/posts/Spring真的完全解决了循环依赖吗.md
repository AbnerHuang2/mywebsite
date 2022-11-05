---
title: Spring真的完全解决了循环依赖吗
date: 2022-06-20 17:51:15
description: Spring循环依赖竟然还有坑
tags: 
- Spring
- 问题排查
categories:
- Spring
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

感觉好久没写过博客了，刚好最近遇到一个还挺有意思的问题，就记录一下吧。
# 现象
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1655356733646-073b8a94-2149-4b23-aee0-cf52bfee4f33.png#clientId=uf5832294-d1ff-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=164&id=u0978593f&margin=%5Bobject%20Object%5D&name=image.png&originHeight=328&originWidth=2658&originalType=binary&ratio=1&rotation=0&showTitle=false&size=137850&status=done&style=none&taskId=u4686c31e-51cd-42b0-9b7d-583fcc47d30&title=&width=1329)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1655356770032-1a67d61a-25c2-4ee5-b3cd-5fe4f5762d7f.png#clientId=uf5832294-d1ff-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=355&id=u3199fdc2&margin=%5Bobject%20Object%5D&name=image.png&originHeight=710&originWidth=1104&originalType=binary&ratio=1&rotation=0&showTitle=false&size=129014&status=done&style=none&taskId=ua38aa6b4-a57f-423f-8028-8ea5d08c7a4&title=&width=552)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1655356803893-522894d9-b177-40df-99b5-5c09844d356d.png#clientId=uf5832294-d1ff-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=168&id=uabdf2325&margin=%5Bobject%20Object%5D&name=image.png&originHeight=336&originWidth=1070&originalType=binary&ratio=1&rotation=0&showTitle=false&size=65515&status=done&style=none&taskId=u239d0500-9b89-4159-aeef-27b06a3c65d&title=&width=535)

??? Spring不是通过三级缓存解决了循环依赖问题吗？
这不就是A依赖B，然后B依赖A吗？怎么也报循环依赖啊。

# 问题排查
### 排查思路
1. 难道这个版本的Spring没解决？写个Demo验证一下（简单写个TestService1和TestService2相互依赖就行）。启动很成功啊。【不过这里还有一个比较好玩的现象，就是在TestService1的方法上加上@Async注解，就会报循环依赖了，这个google上有很多答案，其实就是TestService1被代理了，引用变了，然后TestService2还保留的是原始的引用】
1. 把相关依赖去掉试试（把ConnectServiceImpl和UserServiceImpl中的其他依赖去掉试试看了），还是报错循环依赖。

### 源码分析
what's the hell? 只能捋捋源码了。
看看Spring解决循环依赖的过程
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1655717886881-61b7e403-bc8f-4ba0-9d6e-4a2c05a15e83.jpeg)

当我发现初始化前后，这个ConnectService的引用不一样时，问题就已经浮出水面了。这个情况应该跟@Async的情况是一样的，就是UserService中注入了ConnectService的引用，然后后续ConnectService初始化的时候，被包装了，引用变了，然后ConnectService初始化会判断新的引用和旧的是否相同，如果不相同，会去找ConnectService实际上依赖的bean(userService)是否创建了，如果创建了就添加到依赖列表中，如果依赖列表不为空，就报错循环依赖。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1655690682070-19445d07-de7e-46f7-aca9-7d31680bf5dd.png#clientId=uf5832294-d1ff-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=255&id=u20f89496&margin=%5Bobject%20Object%5D&name=image.png&originHeight=255&originWidth=1757&originalType=binary&ratio=1&rotation=0&showTitle=false&size=97476&status=done&style=none&taskId=ufc72dc1b-7b37-4199-bbd9-069507b32a0&title=&width=1757)
**那么问题来了**，实例化的时候包装了ConnectService，引用变成新的了，但是正常来讲，不应该包装啊。 Test1和Test2相互引用也没有被包装啊。
那就来看看源码吧
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1655704728621-34a05b4a-b350-4f36-bf31-2230501ba70b.png#clientId=uf5832294-d1ff-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=654&id=u1ff9b18e&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1308&originWidth=2778&originalType=binary&ratio=1&rotation=0&showTitle=false&size=432468&status=done&style=none&taskId=u5507bbe9-324b-4f22-9c64-0d274080290&title=&width=1389)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1655704836889-f9fdc2a7-d41d-45d7-a87b-d714f27436d0.png#clientId=uf5832294-d1ff-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=673&id=u95c9f560&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1346&originWidth=2718&originalType=binary&ratio=1&rotation=0&showTitle=false&size=476852&status=done&style=none&taskId=ua786477a-e213-4b7a-a13f-b282049c757&title=&width=1359)

可以看到，在初始化这个ConnectService类的时候，会调用一个applyBeanPostProcessorsAfterInitialization方法，这个方法的会应用所有的beanPostProcessor，其中有一个方法参数校验的beanPostProcessor会代理这个类。所以导致引用变了。
那罪魁祸首就出来了呀，就是这个MethodValidationPostProcessor会代理这个bean，然后修改引用。那为啥会被这个MethodValidationPostProcessor代理呢。当然是这个AOP啦。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1655714772658-7318e28a-cb36-47ae-87d8-b979b3678d6d.png#clientId=uf5832294-d1ff-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=266&id=u81ab7db7&margin=%5Bobject%20Object%5D&name=image.png&originHeight=266&originWidth=543&originalType=binary&ratio=1&rotation=0&showTitle=false&size=30652&status=done&style=none&taskId=u658bc219-d0e1-4412-bed3-0f6e6e80cb6&title=&width=543)

# 解决
### 两种方案
1. 去除@Validated校验。
1. 注入UserService时加上@Lazy注解

方案一得加好多校验代码，选择方案二吧。

# 总结
### 循环依赖处理失效的场景
1. **初始化过程生成了新的代理对象**（一般应该是初始化过程中使用了一些前后置处理器）
1. 使用@DependOn产生循环依赖 
1. 非单例产生循环依赖

虽然2，3在本案例中并没有提到，但是应该也是可以明白的

# 参考
[https://zhuanlan.zhihu.com/p/344624139](https://zhuanlan.zhihu.com/p/344624139) （三级缓存分析的还比较清晰）