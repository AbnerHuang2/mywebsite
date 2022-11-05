---
title: Redis网络事件模型
date: 2022-02-08 19:31:59
description: Redis的设计中，有一个被大家熟知的概念，就是在6.0之前，Redis是单线程模型，6.0之后才引入的多线程。
tags: 
- Redis
- Cache
categories:
- Redis
---
<meta name="referrer" content="no-referrer" />
<!-- more -->
Redis的设计中，有一个被大家熟知的概念，就是在6.0之前，Redis是单线程模型，6.0之后才引入的多线程。
尽管如此，单线程模型下的redis依旧性能强劲。
所以今天，我们就来好好研究一下redis的线程通信模型。

# 单线程模型
redis是2009推出的，在2019年才引入多线程模型。为什么呢？
单线程

1. 简单可维护
1. 避免线程上下文切换开销
1. 避免同步开销



大体上，Redis的单线程模型是标准的**Reador模式**，基于**I/O多路复用**实现的，一个统一的事件循环处理器去接受事件，然后分派到不同的处理器去处理。
## 服务器启动流程图
![](https://cdn.nlark.com/yuque/__puml/8edd221a204eefb854da24682a8dd270.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOuWQr-WKqOacjeWKoeWZqOWRveS7pDtcbjror7vlj5bmnI3liqHlmajphY3nva47XG465Yid5aeL5YyW5pyN5Yqh5ZmoO1xuOuS7juejgeebmOivu-WPluaVsOaNrjtcbjrlkK_liqjkuovku7blvqrnjq87XG46YmVmb3Jlc2xlZXDlm57osIPvvIjmnIDkuLvopoHnmoTlt6XkvZzlsLHmmK_lsIblvoXlhpnlm57nmoTmlbDmja7lhpnlm57nu5nlrqLmiLfnq6_vvIzlpoLmnpzlhpnkuI3lrozlsLHms6jlhozlhpnlhaXlm57osIPlh73mlbDvvIk7XG466K6h566X5LiL5qyh5pe26Ze05LqL5Lu255qE5pe26Ze0O1xuOuiOt-WPluWGheaguOivu-WGmeS6i-S7tu-8jOWwhuebuOWFs-ivu-WGmeS6i-S7tuaUvuWFpeWIsOWkhOeQhuWIl-ihqOS4rTtcbmlmICjmnInkuovku7blj5HnlJ8pIHRoZW4oeWVzKVxuXHQ65aSE55CG5paH5Lu25LqL5Lu25YiG5Y-RO1xuXHRzcGxpdFxuXHRcdDrlpITnkIbov57mjqXlupTnrZQ7XG5cdHNwbGl0IGFnYWluIFxuXHRcdDrlpITnkIbor7fmsYLlpITnkIbkuovku7Y7XG5cdHNwbGl0IGFnYWluIFxuXHRcdDrlpITnkIblhpnlm57kuovku7Y7XG5cdGVuZCBzcGxpdFxuZWxzZSAobm8pXG5cdDrlpITnkIbml7bpl7Tkuovku7Y7XG5lbmRpZlxuc3RvcFxuXG5AZW5kdW1sIiwidXJsIjoiaHR0cHM6Ly9jZG4ubmxhcmsuY29tL3l1cXVlL19fcHVtbC84ZWRkMjIxYTIwNGVlZmI4NTRkYTI0NjgyYThkZDI3MC5zdmciLCJpZCI6Inh2MUNyIiwibWFyZ2luIjp7InRvcCI6dHJ1ZSwiYm90dG9tIjp0cnVlfSwiY2FyZCI6ImRpYWdyYW0ifQ==)详细图解
![image.png](https://cdn.nlark.com/yuque/0/2021/png/21760570/1636026374931-90221e1e-28be-438c-9e5c-2080e029ad28.png#clientId=u56ea2d30-4eee-4&from=paste&height=1296&id=ucdce5fa8&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1296&originWidth=1240&originalType=binary&ratio=1&size=383452&status=done&style=none&taskId=u5164b8ca-ef62-4aff-9b0f-97970bb423e&width=1240)
## 存在问题
**单线程应该最怕一个问题，就是阻塞。有些操作就是要阻塞进行的，比如删除。**
> 看看作者是怎么想的
> [http://antirez.com/news/93](http://antirez.com/news/93)
只要一个操作非常耗时，就会导致后面的请求都被阻塞住。简单的查询应该不存在这个问题，但如果是删除很多大的key-value。就可能会出现。然后redis在4.0之后引入了多线程异步处理的方式。并增加了一些异步处理命令。
**核心问题就是如何处理大的key-value？最具代表性的就是删除大量的key-value。**

1. 渐进式地延迟删除。【将要删除的key分批写入到队列中，但是单线程怎么触发呢？利用定时器渐进的删除。】
> 队列采用hash table的形式存储。然后利用timer渐进式删除，释放内存。每次删除timer都要知道从哪个地方开始释放内存。然后他采用的是下标的方式记录下次要删除的位置。
> 但是这种方式存在一个问题，就是进行如下操作
> WHILE 1        
>  SADD myset element1 element2 … many many many elements        
>  DEL myset    
> END
> 如果后台删除操作远慢于添加操作，就会导致内存无限增长。【怎么解决，加快删除频率嘛】
> 他做了两个操作来调整定时器解决这个问题。
> 1. 检查内存趋势
> 1. 动态调整定时器的频率
> 
但是这会导致普通的删除还是要走这个逻辑去做删除。导致正常的删除操作速度下降了65%。
> ​


2. lazy-free 用一个异步线程去做内存释放操作。
> 如果有个线程在专门处理内存释放的问题。那么内存释放比内存申请要快得多。
> 但是引入了多线程就必要要考虑一个新的问题，就是共享数据。
> 如果数据只存在一个地方，需要的时候，通过引用的方式去获取，不是既节约了内存又节约了时间。
> 但是还是存在一些问题。举个例子，通过SUNIONSTORE合并两个集合。
> 如果只是引用其他两个集合的引用。但是这样的话，如果修改新的集合的值，旧集合的值也会跟着改变。
> ​

> 最终他是通过拷贝数据的方式去解决。（这种方式可能也会引入一些问题， 但是从他后面的处理结果来看，应该还是这种方式比较合适）。
> ​

> 到这里为止，我们可以看到，在3.2的时候，其实就已经引入了多线程处理。也增加了一个UNLINK命令，就是DEL的异步版本，区别在于，它会先去计算一下删除的开销，开销超过某个值的时候，才用异步的方式进行删除，否则还是用DEL的方式。

​

​

# 多线程模型
Redis在6.0版本之后引入了多线程模型。
一般来讲，从单线程的reactor模式变成多线程，应该是master-workers那种形式。就是主线程只负责解释事件。然后把事件分配给不同的worker去处理。
redis的多线程版本区别与正常的master-workers模式，在于，
主线程将命令请求放入到读队列中，然后分配给子线程去解析。主线程自旋等待子线程解析完。
然后执行命令，然后将请求放入写队列中，然后分配给子线程去写入客户端缓存。主线程自旋等待子线程解析完。最后还是由主线程执行最后的响应操作。
![image.png](https://cdn.nlark.com/yuque/0/2021/png/21760570/1636027604742-e71f6871-7b65-4868-8e43-352138d22d19.png#clientId=u56ea2d30-4eee-4&from=paste&height=1988&id=u1cc811f7&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1988&originWidth=2092&originalType=binary&ratio=1&size=1008800&status=done&style=none&taskId=u061e7484-5d3b-4883-a4fc-8ddba1777ca&width=2092)
​

​

# 参考文档
[https://segmentfault.com/a/1190000039223696](https://segmentfault.com/a/1190000039223696) （一个redis的contributor写的博客）
[http://antirez.com/news/93](http://antirez.com/news/93) （redis作者写的关于延迟删除的思考）
[http://antirez.com/latest/0](http://antirez.com/latest/0) （redis写的文章的列表）
[http://redisbook.com/preview/event/file_event.html](http://redisbook.com/preview/event/file_event.html) （redis设计与实现）
[https://draveness.me/redis-io-multiplexing/](https://draveness.me/redis-io-multiplexing/) 
[https://zhuanlan.zhihu.com/p/144805500](https://zhuanlan.zhihu.com/p/144805500) (redis流程图画的不错)
