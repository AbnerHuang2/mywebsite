---
title: kotlin1.2升级1.3踩坑
date: 2023-01-19
tags:
- 字节码
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

# 现象
在对项目的kotlin版本从1.2升级到1.3的时候，有一个很奇怪的现象。我觉得值得一提。当然，也不得不感谢大佬的博客让我受益匪浅。
现象是这样的，项目的kotlin版本从1.2升级到1.3之后，在idea中debug启动是正常启动的。但是当我用jar包启动时，就会报错 Ambiguous mapping. 然后，代码是没有改动的，就仅仅改动到一些pom文件。
tips：  . 大概意思就是mapping重复了。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1664192486346-d53dd8c3-f9e9-4a0d-99a8-ad17499a9540.png#averageHue=%23171717&clientId=uf27f46b6-9d35-4&from=paste&height=820&id=u4faed016&originHeight=820&originWidth=1665&originalType=binary&ratio=1&rotation=0&showTitle=false&size=332285&status=done&style=none&taskId=u2e2b6337-c1e3-499d-a1e4-7f6f38c6d79&title=&width=1665)
# 分析
1.2能正常工作，1.3就报错。不会是字节码在搞鬼吧。
看看这个报错的类生成的字节码。
kotlin1.2
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1663922958131-f8b3c59d-5a03-4211-8b87-0d9a73f29a75.png#averageHue=%23060606&clientId=u98f6ad55-aaa9-4&from=paste&height=461&id=u0a3d051b&originHeight=461&originWidth=1725&originalType=binary&ratio=1&rotation=0&showTitle=false&size=116696&status=done&style=none&taskId=uc5870d4a-a7cd-44e8-a240-eea19de0dac&title=&width=1725)

kotlin1.3
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1663922437180-8b9b1d5c-591f-4d71-a0fc-b8837b0b5d32.png#averageHue=%23080706&clientId=u98f6ad55-aaa9-4&from=paste&height=456&id=u07ad138b&originHeight=456&originWidth=1659&originalType=binary&ratio=1&rotation=0&showTitle=false&size=134684&status=done&style=none&taskId=u2eff7dde-f457-4afd-9d49-c0e68c1a93b&title=&width=1659)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1663922880786-209e1c5d-c67e-4c9f-866b-52f007981eb9.png#averageHue=%2329353b&clientId=u98f6ad55-aaa9-4&from=paste&height=811&id=u1ca2e8cd&originHeight=811&originWidth=803&originalType=binary&ratio=1&rotation=0&showTitle=false&size=84247&status=done&style=none&taskId=u9cab9975-5c39-415a-a37e-f43b7bf7cf1&title=&width=803)

看起来就只有一个差异了，1.2多了一个bridge。 不会是这个原因吧。
到这里好像也并没有什么思路，我怎么知道这个bridge究竟是怎么影响到mapping处理的呢。所以还是得看看mapping的处理过程。
# SpringMVC处理Mapping
接下来应该去看看springmvc是怎么处理Mapping的。这一个咋一看，好像没什么思路，只有google。也没什么答案。但是呢，作为一个程序员，解决问题不能全靠google吧。还是要学会正向解决问题。记得之前梳理过spring的启动过程。
![](https://cdn.nlark.com/yuque/__puml/274abd6d374e5f4a48e8ecdde0d96b88.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcbjrku6PnkIblupTnlKg7XG5wYXJ0aXRpb24g5Yid5aeL5YyWe1xuICA65Yid5aeL5YyW5a655Zmo5ZCv5Yqo55uR5ZCs5ZmoO1xuICBub3RlIHJpZ2h0OiDmj5Dkvpvoh6rlrprkuYnnm5HlkKzlmajnmoTmianlsZU7XG4gIDrlh4blpIfnjq_looM7XG4gIDrlh4blpIfkuIrkuIvmloc7XG59XG5wYXJ0aXRpb24g5bCG57G75Yqg6L295Yiw5a655Zmo6YeMIHtcbiAgOuWIneWni-WMluexu-WKoOi9veebkeWQrOWZqDtcbiAgbm90ZSByaWdodDog5o-Q5L6b6Ieq5a6a5LmJ55uR5ZCs5Zmo55qE5omp5bGVO1xuICA66K-G5Yir57G75a6a5LmJO1xuICBmb3JrXG4gICAgOuazqOino-mFjee9rjtcblx0bm90ZSByaWdodDog55Sa6Iez5Y-v5Lul6Ieq5Yqo5YyWO1xuICBmb3JrIGFnYWluXG4gICAgOnhtbOmFjee9rjtcbiAgZW5kIGZvcms7XG4gIG5vdGUgcmlnaHQ6IOaJqeWxlTFcbiAgOuW3peWOguaooeW8j-WKoOi9veexu-WumuS5iTtcbiAgI2RhcmtjeWFuOuaPkOS-m-S_ruaUueexu-WumuS5ieeahOWbnuiwg-aOpeWPoztcbiAgZmxvYXRpbmcgbm90ZSByaWdodDog5omp5bGVMlxuICA65a6e5L6L5YyW57G7O1xuICA65aGr5YWF57G75a2X5q615bGe5oCnO1xuICAjZGFya2N5YW465o-Q5L6b5L-u5pS557G75L-h5oGv55qE5Zue6LCD5o6l5Y-jOyBcbiAgZmxvYXRpbmcgbm90ZSByaWdodDog5omp5bGVM1xuICAjZGFya2N5YW465o-Q5L6b5Yid5aeL5YyW57G75LmL5YmN55qE5aSE55CG5Zue6LCD5o6l5Y-jOyBcbiAgZmxvYXRpbmcgbm90ZSByaWdodDog5omp5bGVNFxuICA65Yid5aeL5YyW57G7O1xuICAjZGFya2N5YW465o-Q5L6b5Yid5aeL5YyW57G75LmL5ZCO55qE5aSE55CG5Zue6LCD5o6l5Y-jOyBcbiAgZmxvYXRpbmcgbm90ZSByaWdodDog5omp5bGVNVxufVxucGFydGl0aW9uIOS9v-eUqOexuyB7XG4gICAgOuS7juWuueWZqOS4reiOt-WPlumcgOimgeeahOexuztcbn1cblxuc3RvcFxuXG5AZW5kdW1sIiwidXJsIjoiaHR0cHM6Ly9jZG4ubmxhcmsuY29tL3l1cXVlL19fcHVtbC8yNzRhYmQ2ZDM3NGU1ZjRhNDhlOGVjZGRlMGQ5NmI4OC5zdmciLCJpZCI6Ikg1cHU0IiwibWFyZ2luIjp7InRvcCI6dHJ1ZSwiYm90dG9tIjp0cnVlfSwiY2FyZCI6ImRpYWdyYW0ifQ==)从实现思路来看，应该会在初始化类之后，解析对应的mapping放入到一个map中。这个从报错日志也能发现端倪。

```java
at org.springframework.web.servlet.handler.AbstractHandlerMethodMapping$MappingRegistry.assertUniqueMethodMapping(AbstractHandlerMethodMapping.java:576) ~[spring-webmvc-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.web.servlet.handler.AbstractHandlerMethodMapping$MappingRegistry.register(AbstractHandlerMethodMapping.java:540) ~[spring-webmvc-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.web.servlet.handler.AbstractHandlerMethodMapping.registerHandlerMethod(AbstractHandlerMethodMapping.java:264) ~[spring-webmvc-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.web.servlet.handler.AbstractHandlerMethodMapping.detectHandlerMethods(AbstractHandlerMethodMapping.java:250) ~[spring-webmvc-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.web.servlet.handler.AbstractHandlerMethodMapping.initHandlerMethods(AbstractHandlerMethodMapping.java:214) ~[spring-webmvc-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.web.servlet.handler.AbstractHandlerMethodMapping.afterPropertiesSet(AbstractHandlerMethodMapping.java:184) ~[spring-webmvc-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping.afterPropertiesSet(RequestMappingHandlerMapping.java:127) ~[spring-webmvc-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.invokeInitMethods(AbstractAutowireCapableBeanFactory.java:1687) ~[spring-beans-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.initializeBean(AbstractAutowireCapableBeanFactory.java:1624) ~[spring-beans-4.3.9.RELEASE.jar!/:4.3.9.RELEASE]
	... 24 more
```
![](https://cdn.nlark.com/yuque/__puml/6d3efeb9022ac837e341e152aeb8f711.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOuWIneWni-WMlmJlYW7vvIhBYnN0cmFjdEF1dG93aXJlQ2FwYWJsZUJlYW5GYWN0b3J5LmluaXRpYWxpemVCZWFu77yJO1xuOuiwg-eUqOWIneWni-WMluaWueazle-8iEFic3RyYWN0QXV0b3dpcmVDYXBhYmxlQmVhbkZhY3RvcnkuaW52b2tlSW5pdE1ldGhvZHPvvIk7XG466LCD55So5bGe5oCn6K6-572u5ZCO57ut5aSE55CG5pa55rOV77yIUmVxdWVzdE1hcHBpbmdIYW5kbGVyTWFwcGluZy5hZnRlclByb3BlcnRpZXNTZXTvvIk7XG466LCD55SoaW5pdEhhbmRsZXJtZXRob2Tmlrnms5XvvIhBYnN0cmFjdEhhbmRsZXJNZXRob2RNYXBwaW5nLmluaXRIYW5kbGVyTWV0aG9kc--8iTtcbjrosIPnlKhkZXRlY3RIYW5kbGVyTWV0aG9kc-aWueazle-8iEFic3RyYWN0SGFuZGxlck1ldGhvZE1hcHBpbmcuZGV0ZWN0SGFuZGxlck1ldGhvZHPvvIk7XG466LCD55So5rOo5YaMbWFwcGluZ-eahOaWueazle-8iEFic3RyYWN0SGFuZGxlck1ldGhvZE1hcHBpbmcucmVnaXN0ZXJIYW5kbGVyTWV0aG9k77yJO1xuXG5zdG9wXG5cbkBlbmR1bWwiLCJ1cmwiOiJodHRwczovL2Nkbi5ubGFyay5jb20veXVxdWUvX19wdW1sLzZkM2VmZWI5MDIyYWM4MzdlMzQxZTE1MmFlYjhmNzExLnN2ZyIsImlkIjoic0hnZEEiLCJtYXJnaW4iOnsidG9wIjp0cnVlLCJib3R0b20iOnRydWV9LCJjYXJkIjoiZGlhZ3JhbSJ9)
从这个流程来看的话，大概率是检测handlerMethods会不一致，导致有bridge标志符的会被过滤掉，我们就来细看这个detectHandlerMethods方法。
果然，detectHandlerMethods内部有个MethodIntrospector.selectMethods调用，这个内部用了ReflectionUtils.USER_DECLARED_METHODS。 里面就是判断哪些方法需要进入mapping map的。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1664256734768-58b9d7c1-ee01-408d-8fb3-ee6255e8a6e4.png#averageHue=%232a3439&clientId=u76489489-ca5c-4&from=paste&height=176&id=u19860a72&originHeight=352&originWidth=1422&originalType=binary&ratio=1&rotation=0&showTitle=false&size=74541&status=done&style=none&taskId=u8fb7eb90-02be-43d8-bd10-ed92ddff3a9&title=&width=711)
到这里，我们就能知道，为啥kotlin1.2版本没有这个问题，而kotlin1.3编译的字节码会存在这个问题了。
# 那怎么解决呢？
按这个逻辑来讲，kotlin1.3和spring-webmvc.4.3.11不是水火不容吗？
这样的话，应该有两种解决方式，要么spring解决非桥接方法问题，要么kotlin解决mapping问题。总不能我重写spring的类吧
## Spring解决方式
让我们来看看spring5.x的ReflectionUtils.USER_DECLARED_METHODS。多了一个isSynthetic，刚好kotlin1.3也有这个AccessFlag.
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1664271342532-23313fff-f0b6-4e23-8fd2-31d6af6ce586.png#averageHue=%23211d1c&clientId=u76bb36de-83cd-4&from=paste&height=106&id=u2529423b&originHeight=106&originWidth=943&originalType=binary&ratio=1&rotation=0&showTitle=false&size=25558&status=done&style=none&taskId=u105b67fd-00cf-427a-b1ef-68cb91ae35e&title=&width=943)
## Kotlin解决方式
kotlin升级到1.4.21也能解决，原因是getQuestionList$default没有mapping了
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1664272577189-f15f778f-eef0-4df8-b9bd-acceb178c032.png#averageHue=%23080706&clientId=u76bb36de-83cd-4&from=paste&height=420&id=uf62aee2a&originHeight=420&originWidth=1708&originalType=binary&ratio=1&rotation=0&showTitle=false&size=123836&status=done&style=none&taskId=uf16430fc-8174-467c-a8f7-55911482aee&title=&width=1708)
# 总结

1. Idea可能会骗人，字节码永远不会
2. 不熟悉流程时，调用链非常关键。结合处理流程和调用链报错，反猜问题根因是一个不错的方式。

# 参考
[https://juejin.cn/post/7083666557313744932](https://juejin.cn/post/7083666557313744932) 