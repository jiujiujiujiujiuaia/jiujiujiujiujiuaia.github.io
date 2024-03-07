---
title: Data Model
date: 2020-03-01 17:30:09
categories:
- System Design
---

https://acodersjourney.com/category/all/system-design/

## SQL

SQL选择了CAP中的一致性(C)和分区容忍性(P)

* 需要事务支持的，常见的交易系统，例如电商，payment，银行，反正只要跟下单有关系的
* structure的数据
* 需要schema，因此在业务前期，需求多，需要move fast，就不是优势了
* **多对多**的场景（eg: 多个user对应多个region，用外键关联这两个实体）
* 缺点:水平扩展没有那么好，因为要解决分布式事务，跨server的join等等
  * （Pinterest给出了一个非常好的设计），所以这事不那么绝对
* 缺点:在Write heavy的场景中，没那么合适，因为要维护一致性带来的写性能损失

### Mysql

例如下图的设计，利用primary key和foreign key把不同的数据关联在一起。

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/datamodel/20240304143541/img.png)

## Non-SQL

Non-SQL选择了CAP中的可用性(A)和分区容忍性

* 横向扩展方便，支持海量读写，适合write heavy的场景，例如社交场景
* 更高的可用性，而没有那么在意一致性
  * 比如社交软件不必保证 ACID，因为一条状态的更新对于所有用户读取先后时间有数秒不同并不影响使用。
* No Schema，value非常灵活
* **一对多**的场景(eg: 一个用户有多段工作经历，学校经历，这都是它个人的)

### Cassandra(Wide-Column)

* Partition key
  * Cassandra 会根据这个 key 算一个 hash 值，然后决定整条数据存储在哪个partition
* Sorted key
  * 用户可以指定 Sorted key 按照什么排序, 支持范围查询
  * Sorted key 可以是复合值， 如 timestamp + user_id，这样就可以根据timestamp排序了；
* Value

#### 实际的case: messaging 系统的设计

* No complex relations ops like joined 
* use Cassandra because it scales up easily and is more suitable for write-heavy work
  * Uses LSTM rather than B+ tree

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/datamodel/20240304143541/img_1.png)

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/datamodel/20240304143541/img_2.png)

可以按照上面说的，加入timestamp一起sort


### Mongo DB(Document)

### Redis

## Reference

https://acodersjourney.com/category/all/system-design/
https://aosabook.org/en/v1/nosql.html