---
title: Mysql思维导图
description: Mysql思维导图
date: 2023-08-30 10:00:49

categories:
- Mysql

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

![](https://cdn.nlark.com/yuque/0/2024/jpeg/21760570/1710403401941-01fdc882-cb7d-4c66-b65f-9bdcabc15f01.jpeg)
# Mysql服务器逻辑架构图
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1651406584500-ec23a345-2eb4-475f-9b0f-63415aed3379.png#averageHue=%23d9d9d9&clientId=u4b280c50-6229-4&from=paste&height=335&id=u1d043e1c&originHeight=670&originWidth=660&originalType=binary&ratio=1&rotation=0&showTitle=false&size=204500&status=done&style=none&taskId=u2272073e-9447-480e-8913-56325b046de&title=&width=330)
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1651848707862-6b4bb6fc-3b90-454f-9870-db5d98b0e937.png#averageHue=%23d7d7d7&clientId=u52fcd201-72ef-4&from=paste&height=523&id=ue4839a93&originHeight=1046&originWidth=1530&originalType=binary&ratio=1&rotation=0&showTitle=false&size=788213&status=done&style=none&taskId=ua7111ff0-cb50-4e98-b34b-71836dc8c1d&title=&width=765)
InnoDB的io处理模型（高性能mysql第八章）

# 搞懂mysql索引
A列建立1个索引，B列建立1个索引。这两个索引在mysql内存模型上是什么样的?
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1651634763273-77b4e47f-da55-4a29-b22f-bf98f9bef69a.png#averageHue=%23ededed&clientId=u82890459-b209-4&from=paste&height=580&id=ua30149a5&originHeight=1160&originWidth=1204&originalType=binary&ratio=1&rotation=0&showTitle=false&size=445676&status=done&style=none&taskId=u8b72c5d0-b11b-40e4-925f-bcd4a08dfcf&title=&width=602)![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1651634778113-ea353c42-dd82-4309-9b16-4a90cba89e7d.png#averageHue=%23eeeeee&clientId=u82890459-b209-4&from=paste&height=593&id=u4f42a6a5&originHeight=1186&originWidth=1260&originalType=binary&ratio=1&rotation=0&showTitle=false&size=577261&status=done&style=none&taskId=u8b481b14-62df-48a2-abce-3f8ca0a05f1&title=&width=630)
聚簇索引的叶子节点会保存行的所有列，如果一张表的数据上亿行，那内存不是炸了?
应该不会将所有数据加载到内存中，每个叶子节点应该只是存储行数据所在页，查询的时候，把页的数据都加载进来，再去查找。也很方便查找附近的数据，不需要在进行磁盘IO了
索引一般有多少层？为什么？
索引一般3-4层，3层可以存储的数据大概是2千万。
innodb的最小存储单位是页，一页16K。假设一行数据1k。所以一页可以存储16行数据。
![image.png](https://cdn.nlark.com/yuque/0/2022/png/21760570/1651635817644-6079a4bb-a337-41a6-a55d-23efcbc27bda.png#averageHue=%23ededed&clientId=u82890459-b209-4&from=paste&height=225&id=u851d5958&originHeight=450&originWidth=1454&originalType=binary&ratio=1&rotation=0&showTitle=false&size=94009&status=done&style=none&taskId=ucbd67e80-3a49-4ce9-a5d0-06a9fc84ed5&title=&width=727)