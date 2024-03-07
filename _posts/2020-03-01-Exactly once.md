---
title: Exactly Once
date: 2020-03-01 17:30:09
categories:
- System Design
---

## 业务场景中的 最多一次/至少一次/恰好一次

在业务场景中，这里的消息除开消息队列中的消息，还可能是请求（比如金融场景中重复扣费的场景）

### 𝐀𝐭-𝐦𝐨𝐬𝐭 O𝐧𝐜𝐞

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/once/20240307111406/img.png)

顾名思义，最多一次意味着消息不会被传递超过一次。消息可能会丢失，但不会重新传送。

**这个是最低要求，没有任何额外的机制去保证消息是否丢失**。

使用案例：它适用于监控指标等可以接受少量数据丢失的使用案例。

### 𝐀𝐭-𝐥𝐞𝐚𝐬𝐭 O𝐧𝐜𝐞

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/once/20240307111406/img_1.png)

在这个语境下，多次传递消息是可以接受的，但不应丢失任何消息。

也就是说，生产者一旦没有收到ACK，会通过重试机制，来保证消息的写入。

使用场景：消息重复不是大问题的业务场景。
* 消费者可以通过唯一键，来确认消息是否被插入到数据库
* kafka可以通过offset机制，保证消费者至少消费一次（可能涉及到重复消费）

### Exactly Once

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/once/20240307111406/img_2.png)

Exactly Once 是最难实现的交付语义。消息只被处理一次。

用例：与金融相关的用例（支付、交易、会计等），重复扣费是不可以接受的。
* 如何解决呢？
* 唯一的UUID
* 途径的每一个系统都记录UUID和token的关系
* 并发写入的场景依赖唯一主键
  * 好处: 简单，一致性
  * 坏处: 性能受拖累，因为要加锁嘛

## Kafka

### 𝐀𝐭-𝐦𝐨𝐬𝐭 O𝐧𝐜𝐞

在这种语义中，Kafka 不提供消息传递的保证。
* 一旦生产者向 Kafka topic发送消息，无论消息是否实际到达消费者，该消息都被视为已送达。
* 不涉及重试或确认机制，如果发生任何故障，消息可能会丢失。

### 𝐀𝐭-𝐥𝐞𝐚𝐬𝐭 O𝐧𝐜𝐞

此语义确保消息不会丢失并至少传递给消费者一次。
* 生产者向 Kafka 发送消息，Kafka 确认收到消息。
* 如果消费者失败或遇到任何问题，它可以从上次提交的偏移量开始重新消费来自 Kafka 的消息。
* 因此 消息可以重复消费但不会丢失。

### Exactly Once

精确一次语义保证每条消息仅被消费者处理一次，即使存在失败或重试也是如此。
* 生产者以幂等的方式发送消息（解决重试场景下多次produce message)
* 配置事务，配置transaction id
* 消费者配置read_commissed(只读取已提交的消息并忽略任何中止或重复的消息)
* 记录消费者偏移是指消费者已经成功处理的消息的位置。

## Reference
* https://blog.bytebytego.com/p/at-most-once-at-least-once-exactly
* https://medium.com/@aviksaha2007/exactly-once-processing-with-apache-kafka-4ae243ced107
