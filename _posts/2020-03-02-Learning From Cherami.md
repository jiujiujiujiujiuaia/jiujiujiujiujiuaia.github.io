---
title: Learning From Cherami
date: 2020-03-02 17:30:09
categories:
- System Design
---

## 1.故障恢复和复制

### 数据持久化

仅当“所有storage主机”都确认收到相同消息时，input主机才会向生产者确认。最后的确认意味着该消息已持久存储在所有副本中。

下图中，1，2，3被持久化成功了。

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img.png)

### Fail handle and recover

收到“所有storage主机”的ACK，才意味着存储在所有副本。如果某个默认时间收不到ACK，意味着故障发生。

input主机因为没有收到来自该失败storage主机的确认，无法确定该消息是否在所有副本中都被成功存储，因此导致这个范围（partition）不再可追加新消息，但是任然可以读。

如何recover呢？

* 密封这个partition，可以读但是不能写
* 通过websocket，向client端通知（producer)，创建了一个新的partition

好处：
* 简单的恢复机制：如果没能出现ACK，那么创建一个新的partition并通知client，保证可用性

坏处：
* 消息的重复：
    * 生产者在未收到确认时可能会重试发送消息，导致新范围中出现重复的消息。
    * 脏读：有些消息可能没有被所有副本确认，这些消息在读取路径中仍会被处理。

### 读和写可用

硬件故障是经常发生的。当磁盘发生故障时，多个replica可以保证读可用。

“写”如何保持可用呢？

每个队列，都由多个partition构成(文中称为extent), 在创建partition的时候，会由元数据数据库(zookeeper?)分配不可变的input主机和 3个storage主机。

client端（producer）连接到input主机，然后发送消息，input主机负责维护和storage主机的连接（ack）以及replica message。

* 就像上面说的，如果任意一个storage host发生故障，那么其他的storage host任然可读，但是不可以写了。
* 会分配新的input和3个storage主机。
* 通知客户端。


### Append only

好处：
* 降低复杂性：数据一旦写入，就不涉及update和delete，这样简化了系统，降低了多个replica之间复制的复杂性（因为update和delete也要在多个副本之间维护）
* 无锁操作，增大吞吐量: 它避免了修改和删除操作可能引起的数据竞争条件。由于所有写入操作都是追加到日志文件的末尾，因此可以无需复杂的锁机制，避免了并发写入时的数据冲突。

坏处：
* 数据膨胀很快
* 读取效率问题，有大量旧数据

## 2.scaling of write

### scale up

每个input 主机都会监控吞吐量，一旦吞吐量超过threshold，那么就会自动创建新的input和storage host。

新的input接收部分写入负载，从而减轻现有盘区的负载。

Before scaling:
![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_1.png)

After scaling:
![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_2.png)

### scale down

随着负载的减少，Cherami 会密封某些范围，而不用新的范围替换它们。

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_3.png)

这样的好处：
* 分散到多个partition，避免单个partition过载。
* 扩展性强，方便横向扩展

缺点：
* 随着extent的数量增加，需要维护更多的元数据来追踪每个消息存储的位置，这可能导致管理复杂性增加
* 客户端可能需要从多个extent中检索数据，这可能导致读取操作比集中存储的情况更复杂，影响读取性能

因此，
* 需要高效的索引来快速定位数据（比如记录数据id到extent id的索引关系（index relationship）)
* 同时需要定期的后台任务来合并和压缩extent
* 缓存热点数据，减少对分散extent的直接访问，从而改善读取性能


## 3. Consumption handling

一条queue可以被consumer group处理，不同的消费组有不同的逻辑。消息可以被重复读取，这个很好理解。

但是会有一些问题：
* 某个消费者处理消息超时（客户端超时）
* 消息没能成功发送给消费者
* 不同消费者的处理速度不一样
* 管理已读未读状态的复杂性

因此，Cherami是这样设计的：
* 每个消费组有自己的定时器，超时会重传
* 每个消费组记录自己的offset
* Cherami有一个output主机，维护了read offset和consumed offset
* 如果达到重传限制，消息将被发送到死信队列（Dead Letter Queue，DLQ），并将该消息标记为已确认，以便确认偏移量可以前进。

尽管worker4处理了完了2，发会了ACK，但是consumed offset不会移动。已发送的offset会不断前进。

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_4.png)

只有当前面所有的消息都ACK，consumed offset才会移动。

![img_5.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_5.png)

## 4. Id 唯一性

数据的存储很简单，就是key和value，key是id，那么如何保证id的唯一性呢？

### UUID
UUID（通用唯一标识符）或是依据每个写入实例的特定算法来生成ID，从而避免冲突。

例如，可以结合时间戳、节点标识和序列号来生成唯一的ID，这样即使多个进程同时尝试生成ID，也能保证它们的唯一性。

好处：
* 唯一性：生成全局唯一的ID，避免了冲突。
* 无需协调：不需要跨进程或服务的协调，生成ID的操作可以在本地完成。

坏处：
* 但是这样id就不是有序的，会降低查询效率。
* 可读性差
* 需要更多存储空间

### 分布式一致性算法（如Raft或Paxos）

好处:

* 能够生成自增id
* 强一致性：提供跨多个节点的强一致性保证。
* 容错性：这些算法通常能够容忍部分节点失败而不影响整体系统。

坏处:

* 复杂性高：算法实现复杂，需要深入理解才能正确实施。
* 性能开销：通常需要多轮通信以达成一致，可能导致性能开销。

## 5.整体架构

![img_6.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_6.png)

### Control plane

所有的data plane(DP) 通过gRPC去访问CP，CP

* 使用Cassandra记录和存储元数据
* 它主要确定何时创建范围以及在何处放置（到哪个输入和哪个存储主机）。
* 它还确定哪些输出主机处理消费者组的消费。
* 所有data plane向CP本报告负载信息，CP根据信息做出负载平衡的决策
* CP本身要有高可用，使用一致性hash和leader模式保证一直能够做决策

![img_9.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_9.png)

![img_10.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_10.png)

### 前端

* 提供CRUD API，提供负载均衡，auth健全等等功能
* 帮助producer找到input
* 帮助client找到output

![img_7.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_7.png)

![img_8.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Cherami/20240302165756/img_8.png)


### Cassandra

* Cherami 将元数据存储在 Cassandra 上，Cassandra 是单独部署的。
* 元数据包含有关队列、其所有范围以及所有消费者组信息的信息，例如每个消费者组每个范围的 ACK 偏移量。
* 我们选择 Cassandra 不仅因为 Cassandra 是一个高可用的数据存储系统，还因为它的可调一致性模型。

#### 什么是可调一致性?

* 一致性（Consistency）：每次读取都会返回最新写入的数据。
* 可用性（Availability）：每个请求总能在有限时间内收到响应，无论响应成功或失败。
* 分区容错性（Partition tolerance）：系统即使在某些部分发生网络分区事件时也能继续工作。
  * 在一个分布式数据库中，如果两个数据中心之间的网络连接中断，数据库仍然能够在各自的数据中心内部处理读写请求，这就体现了分区容错性。

Cassandra数据库提供了可调的一致性模型，这意味着开发者可以根据业务需求调整读写操作的一致性级别。例如，可以选择：

* 强一致性（如Quorum）：确保读取总是返回最新的写入数据，但可能会牺牲一些可用性。
* 最终一致性：允许读取不一定立即返回最新写入的数据，但系统最终会达到一致状态，这提高了可用性。

回到我们的情况：

* 这种灵活性使我们能够提供可以容忍分区但不保留顺序的队列（AP 队列），
  * 牺牲一致性，保护可用性
* 或者保留顺序（CP 队列）但在此类分区事件期间在次要分区中不可用的队列。
  * 牺牲可用性，保护一致性
* 两种类型的队列处理上的主要区别在于Extent创建是否需要条件更新操作。

## Reference
* https://web.archive.org/web/20170225055932/https://eng.uber.com/cherami/
