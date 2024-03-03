---
title: Learning From Pinterest(Shard)
date: 2020-03-01 17:30:09
categories:
- System Design
---

## Why Sharding

* 更高的扩展性：单机的存储是有上限的， 分sharding能够存储下更多的数据
* 更好的性能：把请求分散到多个DB/服务器，限制了每个服务器的负载，性能得到了提升
* 更简单：比较Cluster的方案，sharding之间通常不需要复杂的算法同步和意识到其他sharding的存在，一般是由中间层分配请求和决定存储和读取
* 高可用：如何部分分片发生故障，只会影响这个分片上的数据，其他分片依旧可以正常工作。

## How Pinterest Sharding

* 多master（好处和坏处）
* 如何知道任意的user id store在哪个shard(db)?
  * Option1: 把User id -> DB Url的关系映射起来，然后存在某个metedata数据库中，提供lookup service
  * Option2: 设计合理的ID structure，直接从id读到look up的信息（优点：避免额外的开销，查询lookup service）

### ID Structure设计

* 64位的ID被分为三个部分：Shard ID、Type和Local ID。
* Shard ID确定数据存储在哪个分片上, 通过这个shardId可以直接拼接出来sharding db的地址。
* Type用于表示对象类型，例如：User, Photo comments。
* Local ID在分片内部用于唯一识别对象。这是一个由mysql 提供的自增id。

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/pinterest/20240303130331/img.png)

### 写入场景

对于任意的新数据，例如新用户，新评论

* 应用层服务从默认范围内，随机选择一个shard id
* 插入数据库，得到一个local id，通过自增字段来实现的
* 然后就得到了一个完成的用户id shardid-type-localId

### 读取场景

* 用户请求: 用户在应用中发起请求时（比如登陆），应用知道用户的完整64位ID，因为这是在用户注册时生成并分配给用户的，通常也会被用作系统内部表示用户身份的一部分。
* 解析ID: 应用或中间件层会解析这个64位ID，提取Shard ID、Type和Local ID。
* 定位数据: 通过Shard ID，应用或中间件可以查询查找结构来确定数据存储在哪个物理服务器上。这个查找结构就像一个路由表，它告诉系统每个Shard ID对应的数据库服务器。
* 读取操作: 一旦确定了物理服务器，应用会连接到该服务器的数据库实例，并使用Local ID作为查询参数来检索用户信息。

### 总结

* 新用户和新数据会倍随机的分布在不同的shards中
  * 好处: 1.避免某个分片过载 2.简单的扩展
  * 坏处： 1. 由于是随机分配，可能某个分片的用户恰好非常的活跃，导致负载失衡 2.跨分片的操作复杂和低效（follow up: 让用户的数据和用户在一起是一个手段）
* 对于该用户后续的数据，会尽量分配在同一个shard中，尽量减少跨shard的读取
* Local id依靠mysql的自增机制完成
  * 好处 1.简单高效，比其他负责的ID generate算法简单 2.递进顺序，可以优化索引和方便数据检索
  * 坏处 1.写入高峰时性能会下降
* Shard id space可以很大，我们一开始可以是先在初始范围，例如0-4000，一旦这个范围基本上满了，我们就开辟新的range，例如4001-8000选取。（好处是什么？）

### Bottle Neck?

1.用户规模增大了X倍，如何扩展？

通过开辟新的shard的range来解决

2.单个shard的负载变得很大，如何解决性能问题？

* 多个shard复制分摊读取的压力
* 把一个DB sharding拆分称多个DB shard，可以分担写入的压力
* 加入监控，实时的监控分片的容量和性能

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/pinterest/20240303130331/img_1.png)

3.高可用

* 分片副本: 对每个分片保持一个或多个副本，以便在主分片出现故障时快速故障转移。
* 定期备份和恢复策略: 确保可以从数据丢失中恢复，减少意外发生时的影响。

### 主页的渲染

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/pinterest/20240303130331/img_2.png)

在我们前面的id structure的设计中，shardid-type-localId，type就是分表了，对于不同的数据用不同的表处理: 
* type = user, user表
* type = board, board表
* 因此一个用户的数据可以这样表示
  * 001-user-001
  * 001-board-001
  * 两个自增id在不同的table，因此可以相同

假设我们有两张表:

Table: User Row: User id, User name, email,...
Table: Board: board id, board name, board video...

* 我们可以通过主键和外键之间的关系，通过join，把不同的数据关联起来
* 也可以通过mapping table，避免join操作
  * Local ID(user id) -> MySQL blob(user information)
  * Local Id(user id) -> Local Id(board id)

需要的查询语句就类似下面：
```sql
SELECT body FROM users WHERE id=<local_user_id>
SELECT board_id FROM user_has_boards WHERE user_id=<user_id>
SELECT body FROM boards WHERE id IN (<board_ids>)
```

总结：
* 使用PK（主键）或者index 查找比join更快更简单
  * 好处： 1.join性能很慢，变成join一旦复杂了，写起来难以维护 
  * 坏处： 2.维护额外的冗余表，增加复杂性和负担

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/pinterest/20240303130331/img_3.png)


## Reference

* 1.https://www.youtube.com/watch?v=dSk-SWLJ2g0
