---
title: Java连接Mysql字符集设置过程详解
description: utf8mb4设置无效引发的java-mysql字符集设置探索
date: 2022-02-13 11:08:37
tags:
- utf8mb4

categories:
- Mysql
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

### 现象
生产数据库设置了数据库的字符集为utf8mb4。数据库层面可以正常插入表情。但是在java程序中设置表情却不生效。
测试数据库也设置了数据库的字符集为utf8mb4。数据库层面可以正常插入表情。但是在java程序中也可以正常插入表情。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644722332307-797c071b-32f4-4d59-8513-95fed07ffc3b.png#clientId=uc18636e8-2b8f-4&crop=0&crop=0&crop=1&crop=1&from=paste&height=305&id=ubb297f7d&margin=%5Bobject%20Object%5D&name=image.png&originHeight=610&originWidth=610&originalType=binary&ratio=1&rotation=0&showTitle=false&size=172833&status=done&style=none&taskId=ud023eee6-4b58-4ba8-a347-447daf466bd&title=&width=305)
测试和生产环境的区别是：测试环境数据库重启过。生产没有==。
但是生产环境重启数据库影响太大，不太现实。
**有没有什么其他的解决方案呢？请往下看。**
### 先说结论，三种解决方案

1. 重启数据库（character-set-server 这个配置只在数据库启动时生效）
1. 修改连接配置，指定连接的字符集 （数据库连接后面加上  com.mysql.jdbc.faultInjection.serverCharsetIndex=45）
1. 升级 mysql连接驱动到5.1.47之后的版本（因为这个版本之后设置encoding=utf8会自动映射成utf8mb4）



上个链接吧，完美解决。
[https://blog.arstercz.com/mysql-connector-java-%E6%8F%92%E5%85%A5-utf8mb4-%E5%AD%97%E7%AC%A6%E5%A4%B1%E8%B4%A5%E9%97%AE%E9%A2%98%E5%A4%84%E7%90%86%E5%88%86%E6%9E%90/](https://blog.arstercz.com/mysql-connector-java-%E6%8F%92%E5%85%A5-utf8mb4-%E5%AD%97%E7%AC%A6%E5%A4%B1%E8%B4%A5%E9%97%AE%E9%A2%98%E5%A4%84%E7%90%86%E5%88%86%E6%9E%90/)
作者的思路很清晰。


对于修改连接配置这一点，有点奇怪的是，
我在本地连接数据库测试的时候，默认设置的字符集就是utf8mb4。
但是在预发环境抓连接mysql的包是，发现设置的字符集却是utf8。
上图！
![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927264-76c34c17-ff19-4edd-82de-eb0f162cf63f.png#crop=0&crop=0&crop=1&crop=1&id=z9IGe&originHeight=1006&originWidth=2854&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927397-767941f4-11c8-4469-8d5c-7c7d7db46adc.png#crop=0&crop=0&crop=1&crop=1&id=UnY3o&originHeight=1040&originWidth=2828&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)
但是代码一样的呀！没有理由会有不同啊。
于是开始了下面的探索，嘿嘿嘿。
### java-mysql-connector和mysql建立连接的过程


![](https://cdn.nlark.com/yuque/__puml/215108b658172281aaa6b00b3c0ff2ea.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWwgXG5KYXZh56iL5bqPIC0-IG15c3Fs5pyN5Yqh5ZmoOiBUQ1DlsYLmj6HmiYsgXG5teXNxbOacjeWKoeWZqCAtLT4gSmF2Yeeoi-W6jzogVENQ56Gu6K6kQUNLIFxubXlzcWzmnI3liqHlmaggLS0-IEphdmHnqIvluo86IE1ZU1FM6Zeu5YCZ5a6i5oi356uvIFxuSmF2Yeeoi-W6jyAtPiBteXNxbOacjeWKoeWZqDog5bim55So5oi35ZCN5a-G56CB55m75b2V5oyH5a6a5pWw5o2u5bqTIFxubXlzcWzmnI3liqHlmaggLS0-IEphdmHnqIvluo86IOi_lOWbnk1ZU1FM5o-h5omL5YyFIFxuSmF2Yeeoi-W6jyAtPiBteXNxbOacjeWKoeWZqDog5bim6L-e5o6l5Zmo54mI5pys6I635Y-W5pyN5Yqh5Zmo55qE5LiA5Lqb5L-h5oGv77yIYXV0b19pbmNyZW1lbnQsdGltZXpvbmUsY2hhcnNldO-8iSBcbm15c3Fs5pyN5Yqh5ZmoIC0tPiBKYXZh56iL5bqPOiDov5Tlm57nm7jlhbPkv6Hmga8gXG5KYXZh56iL5bqPIC0-IG15c3Fs5pyN5Yqh5ZmoOiDorr7nva7ov57mjqXnmoTlrZfnrKbpm4bkuYvnsbvnmoTkv6Hmga8gXG5AZW5kdW1sIiwidXJsIjoiaHR0cHM6Ly9jZG4ubmxhcmsuY29tL3l1cXVlL19fcHVtbC8yMTUxMDhiNjU4MTcyMjgxYWFhNmIwMGIzYzBmZjJlYS5zdmciLCJpZCI6IlpyVTFzIiwibWFyZ2luIjp7InRvcCI6dHJ1ZSwiYm90dG9tIjp0cnVlfSwiY2FyZCI6ImRpYWdyYW0ifQ==)

### **Mysql握手协议包**
![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927551-0686ab45-a97c-4d00-9fe1-bccbf4180a18.png#crop=0&crop=0&crop=1&crop=1&id=piDWS&originHeight=300&originWidth=256&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)
### java-mysql-connector设置字符集过程
![](https://cdn.nlark.com/yuque/__puml/0f7c6a105655ff6349ab519fb691bd72.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWwgXG465byA5ZCv572R57uc6L-e5o6lOyBcbjrnmbvlvZVNeXNxbOacjeWKoeWZqDsgXG466I635Y-WTXlzcWzmnI3liqHlmajov5Tlm57mj6HmiYvljIU7IFxuOuino-aekE15c3Fs5pyN5Yqh5Zmo5a2X56ym6ZuGOyBcbmlmICjphY3nva7kuK3orr7nva7orr7nva7kuoblrZfnrKbpm4Y_KSB0aGVuICh5ZXMpICAgXG5cdDrlrZfnrKbpm4bvvIhzZXJ2ZXJDaGFyc2V0SW5kZXjvvIkgPSDphY3nva7kuK3ojrflj5blrZfnrKbpm4borr7nva47IFxuZWxzZSAobm8pICAgXG5cdDrlrZfnrKbpm4bvvIhzZXJ2ZXJDaGFyc2V0SW5kZXjvvIkgPSDmnI3liqHlmajlrZfnrKbpm4Y7IFxuZW5kaWYgXG5cdDrorr7nva7lrqLmiLfnq6_ov57mjqXnmoTlrZfnrKbpm4Yo6YCa6L-H572R57uc5Y-R6YCB57uZbXlzcWzmnI3liqHlmagpOyBcbkBlbmR1bWwiLCJ1cmwiOiJodHRwczovL2Nkbi5ubGFyay5jb20veXVxdWUvX19wdW1sLzBmN2M2YTEwNTY1NWZmNjM0OWFiNTE5ZmI2OTFiZDcyLnN2ZyIsImlkIjoibE0yMmYiLCJtYXJnaW4iOnsidG9wIjp0cnVlLCJib3R0b20iOnRydWV9LCJjYXJkIjoiZGlhZ3JhbSJ9)### 一条SQL从客户端到服务器
![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927642-05a3a361-fb53-4040-8570-47c6799eed80.png#crop=0&crop=0&crop=1&crop=1&id=W4n9Q&originHeight=289&originWidth=612&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)
详情建议阅读《高性能Mysql》第7.9章。


### 顺带又了解一些Mysql的字符集相关内容
1.字符集参数含义
![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927731-6d915569-5094-48e9-8a40-edec9ed8a0c8.png#crop=0&crop=0&crop=1&crop=1&id=YhfqT&originHeight=342&originWidth=785&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)
2.mysql字符集相关sql

| SQL | 含义 |
| --- | --- |
| SET NAMES utf8mb4 | 设置本次连接的字符集为utf8mb4 |
| **SELECT** * **FROM** information_schema.COLLATIONS ; | 查看mysql排序规则 |
| **show** variables **like** '%character%'; | 查看数据库字符集 |
| **show** variables **like** 'collation%'; | 查看数据库排序规则 |
| alter database 库名 default character set utf8mb4; | 修改数据库字符集(character_set_database) |
| set character_set_server=utf8; | 设置服务器编码(character_set_server) |



### java-mysql-connector源码（简单记录一下，方便以后回顾）
主要是从类  **ConnectionImpl** 里面的 方法  **configureClientCharacterSet** 入手去追溯一下过程。
简单贴几个过程吧
![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927814-ee993b88-9c5c-48b1-a7f1-f36bcda25a7a.png#crop=0&crop=0&crop=1&crop=1&id=gvkMG&originHeight=95&originWidth=1032&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)
初始设置字符集，
![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927903-d5afe078-85e1-4d8d-b105-74d2f9ff9fd1.png#crop=0&crop=0&crop=1&crop=1&id=nqtTU&originHeight=151&originWidth=1013&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)
处理utf8和utf8mb4,
![](https://cdn.nlark.com/yuque/0/2022/png/21760570/1644639927993-3f142a55-bb36-44b0-877d-43aa18d4ea1d.png#crop=0&crop=0&crop=1&crop=1&id=Vkn95&originHeight=387&originWidth=1267&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)


### 简单总结一下
mysql连接过程【看上图】
mysql设置字符集过程【看上图】
mysql字符集应该注意的问题

1. 配置生效问题【有些配置可能要重启mysql服务器才能生效】
1. 配置设置问题【java启动参数，环境变量，配置文件】

排查思路

1. 对比现象【代码相同，开发和预发建立连接时，设置的字符集不同】
1. 猜想问题【服务器返回结果不同，导致设置的字符集不同】
1. 分析过程，验证猜想【从抓包分析，设置字符集前，先获取了一波服务器配置，对比分析配置。发现差不多，没什么不同】
1. 根据现象，分析过程【既然是字符集设置不同，就看它字符集设置的过程。最终发现问题】
1. 发现问题，寻找解决方案【修改字符集配置】

