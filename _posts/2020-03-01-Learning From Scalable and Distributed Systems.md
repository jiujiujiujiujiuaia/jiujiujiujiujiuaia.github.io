---
title: Learning From Scalable and Distributed Systems
date: 2020-03-01 17:30:09
categories:
- System Design
---

## Introduction 

读后感关于Kate Matsudaira写的这篇https://aosabook.org/en/v2/distsys.html

## 设计原则

我们应该设计怎么样的系统?

* High availability - replication
* Low latency - routing/redis/data index/split table/sharding
* Easily scalability - db partition/ service SRP - micro-service/keep stateless
* Reliability: 一开始对这个和availability没能区别开，才知道这个指的是数据的一致性，没有脏读等等

## 需求

想象一个系统，用户可以将图像上传到中央服务器，并且可以通过网络链接或 API 请求图像。了简单起见，我们假设该应用程序有两个关键部分：
* 将图像上传（写入）到服务器的能力
* 查询图像的能力

对应到上面的原则，这个系统就需要这些能力:
* 如果用户上传图像，该图像应该始终存在(HA)
* 图像下载/请求需要低延迟(Low latency)
* 存储的图像数量非常大，需要考虑扩展(Easily scalability)

## V1 版本

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img.png)

## 优化

V1版本已经可以满足functional的需求了，但是我们要考虑那些non-functional的需求应该如何满足?

### 1.服务读写扩展

* 读和写的qps不一样 (大部分系统read heavy not write heavy)
* 读和写的资源需求不一样
* 读和写的latency也不一样，读有很多优化，而写由于一致性的要求，有锁

因此，我们需要把服务进行拆分，把“image request handler service”拆分成一个负责读，另外一个负责写:
* image write service
* image retrieval service

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_1.png)

这样做的好处是:
* 读写频率，资源需求不一样，因此为了资源最大利用率，服务可以各自扩展以应对不同业务需求(比如写请求spike，可以单独扩展write)
* 不同的业务服务有着不同的bottle neck，拆分了更容易解决和improve

### 2.数据库读写扩展

中间的服务只是数据流转的中点，而不是终点。因此，背后的数据库也要考虑到读写扩展。我们有两种做法:
* Mysql master and slave mode
* Nosql partition mode

在SD中，我们更倾向第二种，nosql的partition更容易也更简单。我们只需要对每一张照片，随机分配到一个sharding db中，然后再去这个sharding db中进行读取。

这样，相当于我们把巨大的QPS请求，给拆分成了10，100，1000个sharding db的请求，每个sharding db可以通过load testing压测出来它的压力上限，我们就可以合理分配sharding的数量。

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_2.png)

用sharding的问题是:
* 带来分布式系统下，跨多个partition join的问题
* 部分partition的存放的数据过热问题
* 复杂事务如何处理?
* 数据一致性

可以参考我自己写的这个!(Learning-From-Pinterest)[https://jiujiujiujiujiuaia.github.io/system%20design/2020/03/01/Learning-From-Pinterest/]是如何解决带来的这个问题

### 3.更快的Access到Data(networking&cache)

#### Cache

如下图所示，我们肯定不想用户直接touch database，这样db的压力过大，同时disk 比memory慢了好几个量级。因此，我们需要加缓存。

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_3.png)

#1. Local cache

最简单的，我们在access level(应用服务器)上加cache。每次向服务发出请求时，节点都会快速返回本地缓存的数据（如果存在）。如果缓存中没有，则请求节点会从磁盘中查询数据。

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_4.png)

问题很快就出现了，由于我们的系统会不断的水平扩展以及使用Load balancer技术分摊qps的压力，这导致每次请求都会随机load到任意的机器上。

相同的请求将发送到不同的节点，从而增加缓存未命中率和DB的压力。

![img_5.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_5.png)

#2.Global cache

全局缓存顾名思义：所有节点都使用相同的单个缓存空间。当在缓存中找不到缓存的响应时，缓存本身将负责从底层存储中检索丢失的数据。

![img_6.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_6.png)

问题同样也很快出现了：
* 随着数据规模的不断扩大，global cache需要更多的capacity，如何方便的增加节点？
* global cache处理请求的能力是有限的，如何分担读取的QPS?

#3.Distribute cache

在分布式缓存中（图 1.12），每个节点都拥有部分缓存数据。不同于#1 local cache的是，应用层节点在查找某条数据的时候，就已经知道要去那个cache node查找（hash算法）

![img_7.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_7.png)

然而，把一块中心化的cache切分成一块块（类似于sharding和partition了），所带来的坏处同样是：
* 如何方便的上线和下线cache节点？(一致性hash算法)[https://jiujiujiujiujiuaia.github.io/redis/cache/2020/03/02/Cache-And-Redis/]
* 如何解决部分cache节点过热问题？

#### Indexes

不可能在任何合理的时间内在一个大数据集中迭代那么多数据。因此索引是必要的（然而索引需要在增加存储开销和降低写入速度（因为您必须同时写入数据和更新索引））。

如下图所示，如何你想找到B-Part2，你不必要从头开始遍历整个table，而是可以通过索引知道，如果想找B，请从Location-1开始。

![img_8.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_8.png)

甚至还有多级索引，当找到了B之后，如何快速知道part2在哪里呢？

![img_9.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_9.png)

#### Gateway(LB) 加快网络访问

* ATM/Akamai
  * 地理位置有限访问
  * 权重访问
  * 优先级访问
* Gateway TLS termination加速
* Gateway可以针对header和path进行路由

#### 队列

队列可以把同步操作改成异步操作，让客户端不会傻等。

![img_10.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_10.png)

![img_11.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/article/20240305212051/img_11.png)

## Pinterest感想

Pinterest感想:
* 1.把用户的数据分离到不同的sharding中
* 2.同一个用户不同的数据，尽量分布在同一个sharding中

## Reference

* 1.https://acodersjourney.com/system-design-interview-consistent-hashing/


