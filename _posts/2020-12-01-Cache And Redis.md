---
title: Cache
date: 2020-12-23 17:30:09
categories:
- Redis
- Cache
---

## 为什么需要缓存?

* 1.需要经常访问的数据，例如热点数据，推特的top10 topic, 根据28定律，少量数据负责大量请求。
* 2.成本高昂的数据库操作: 从数据库检索数据需要复杂的查询或联接多个表，这些操作通常会消耗更多的CPU和内存资源。通过background-job不断的写入这些结果到缓存中。
* 3.不轻易修改的数据
* 4.与DB系统不同地是，缓存不是为了数据长期持久性设计的，是为了提高性能和吞吐量。不适合长期存储的场景

总结: 对于数据不经常更改、多次访问相同数据、重复产生相同输出或耗时查询或计算的结果值得缓存的场景. 减少对数据库的访问次数。

## 使用缓存的例子

* L1,2,3: 现代计算机利用多级缓存（包括 L1、L2 和 L3 缓存）来为 CPU 提供对常用数据的快速访问。
* MMU: 内存管理单元（MMU）负责将虚拟内存地址映射到物理内存地址。
* Page cache: 操作系统在主内存中使用page cache来增强整体系统性能。
* Browser cache: 浏览器使用缓存来存储经常访问的网站图像、数据和文档，从而实现更快的加载时间和更流畅的浏览体验。
* CDN: CDN 是另一种形式的缓存，用于交付静态资源，例如图像、视频、CSS 文件和其他多媒体内容。

## 缓存为什么快

数据保存在内存中。内存中的数据读写通常比磁盘读写快 1,000 倍 - 10,000 倍。详细信息请参见下图。

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/redis/20231229135150/img_1.png)

## 分布式缓存分片的策略

单个机器的redis或者本地缓存，无法提供无限的存储空间，因此需要分布式的缓存。

缓存数据分布在多个节点上，每个节点仅存储一部分缓存数据。那么当客户端请求数据时，应该从那个节点返回数据呢？写入数据的时候又应该写入哪个节点呢？

### 模数分片(Modulus)

最直白的，对每个key进行hash计算，然后根据分片的数量取模。

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/redis/20231229135150/img_2.png)

缺点：当分片数量增加或减少时，可能会导致许多缓存未命中，大多数键将重新分配到不同的分片。

### 基于范围的分片(Range)

对于基于地理位置的数据或与特定客户群相关的数据。

这种非常有用，特别适合key的种类比较明确，且不大会改变。例如地理位置的region，大洲的数据就不容易改变

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/redis/20231229135150/img_3.png)

缺点：同样，这种方法也可能难以扩展，因为分片的数量是预定义的并且无法轻易更改。更改分片数量需要重新定义键范围并重新映射数据。

### Consistent hashing

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/redis/20231229135150/img_4.png)

通过举一个例子来理解一致性hash

* 假设我们有一个分布式缓存系统，开始时有3个节点（Node A、Node B、Node C）。
* 使用一致性哈希环来分配数据，哈希环的范围是0到1000。
* 每个节点在哈希环上的位置是通过对节点名称进行哈希计算得到的。
* 假设哈希函数返回以下位置：Node A（哈希值200）、Node B（哈希值400）、Node C（哈希值600）。

对于写入和读取的场景:

写入：
* 假设Key1的哈希值是350。
* 在环上顺时针找到第一个节点是Node B（位置400），所以Key1存储在Node B。

读取：
* 计算Key1的哈希值（350）。
* 顺时针在哈希环上找到Node B，从Node B读取Key1。

增加slot:
* 现在我们增加一个新的节点Node D，假设其哈希值是500。
* Node D插入到Node C（600）和Node A（200）之间。 
* 原本存储在Node C上哈希值介于500和600之间的数据项现在需要迁移到Node D。
* 当增加或删除节点时，只有一部分数据需要迁移，而不是所有数据。这样可以极大地减少重新分配数据时的网络流量和处理负担，提高了系统的扩展性和稳定性。

## 缓存和数据库的一致性

Refere 系统设计常见问题

## TODO 缓存的挑战

https://blog.bytebytego.com/p/a-crash-course-in-caching-final-part

## Reference

* https://blog.bytebytego.com/p/a-crash-course-in-caching-part-1
* https://blog.bytebytego.com/p/a-crash-course-in-caching-part-2
* https://blog.bytebytego.com/p/a-crash-course-in-caching-final-part
* https://blog.bytebytego.com/p/a-crash-course-in-redis
