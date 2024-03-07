---
title: Message queue and service bus
date: 2020-12-23 17:30:09
categories:
- Message Queue
- Serivce Bus
---

## 为什么需要Message Queue

1.解耦, 异步和可扩展

生产的服务和消费的服务**不必相互紧密依赖**，都可以**独立修改和部署**，并且如果哪一块是瓶颈，可以**独立扩展**。

同时，生产的服务和消费的服务谁也不需要等待谁完成，这样可以极大的增加吞吐量。

2.Fan-Out

支付服务将数据发送到三个下游服务以用于不同目的：支付渠道、通知和分析。在这种场景下，由于没有耦合，下游服务想

怎么处理消息队列的数据就怎么处理，用于不同的目的。这是topic的使用场景，多个消费者重复消费同一个数据。

3.消息持久化(Disaster Recovery)

如果上游服务崩了，下游服务依然可以处理

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img.png)

## 两种架构

一种是在线业务模式的场景,又称pub-sub的模式, 消息broker知道消费者或订阅者，并且消息仅发布一次并且永远无法重播。

例如常见的推送系统，订单系统容和支付系统的解耦等等

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img_1.png)

另外一种是Event streaming的模式:

* 消费者不订阅消息代理，而是从流中的任何位置读取事件。订阅者需要提供其阅读位置或偏移量。
* 需要提供消息的长期持久，允许多次读取。类似于DP的业务场景。(Kafka也是这样的)

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img_2.png)

## 适合场景

* 在线执行足够的工作，让用户看到任务已经完成，然后将悬而未决的事情延后执行
  * （在 Twitter 或 Facebook 上发布消息可能会遵循这种模式，更新时间线中的推文/消息，但更新你的关注者' 时间线带外；实时更新 Scobleizer 的所有关注者是不可行的）。
* 在消费者中几乎不执行任何工作（仅安排任务）并通知用户该任务将离线发生，通常使用轮询机制在任务完成后更新界面
  * （例如，在 Slicehost 上配置新的 VM 遵循此图案


## Message queue缺点

* Queue能够同步操作改为异步操作，让客户端不必要一直等待，提高响应性能。
* 代价就是，如果客户端是一个写入操作，然后加入队列，客户端得到一个200。
* 如果恰巧客户端立马查询，实质上数据并没有写入成功（因为数据只是在队列中而没有真正的持久化）
* 最终发生了不一致的事情。
* 总结：如果业务场景可以容忍短时间内的数据不一致（即最终一致性），使用队列是合适的。然而，如果业务流程依赖于即时数据一致性，这种异步处理方式可能就不太适用了。

## Azure Service Bus vs Azure Event Hub

这两种场景的代表分别是ASB和AEH。

* 对于AEH，类似于Kafka，常处理类似于海量的metric和log，例如在线会议中海量的通话，消息等等记录。
* 对于ASB，ASB消息由接收者拉出并且无法再次处理，所以更适用于单次消费的场景，比如订单（订单处理一次），推送（同一个推送不能推送多次嘛）

### Azure Service Bus
更在乎可靠？以及高级功能

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img_3.png)

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img_4.png)

![img_5.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img_5.png)

### Azure Event Hub

Azure 事件中心是一个大数据流平台和摄取服务，适用于产生大量事件的应用程序。它每秒可以接收和处理数百万条记录。

收到数据后，可以使用实时分析提供商或批处理/存储适配器来转换和存储数据。

![img_6.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img_6.png)

接收者被分为消费者组。消费者组代表整个事件中心的视图（状态、位置或偏移量）。它可以被认为是一组同时消费事件的并行应用程序。

消费者组使每个接收者都可以拥有事件流的单独视图。他们按照自己的节奏和自己的偏移量独立阅读流。

Event Hub 使用分区消费者模式；事件分布在各个分区上以允许水平扩展。

### 抉择

https://medium.com/slalom-technology/azure-messaging-when-to-use-what-and-why-post-3-8a914ec74822

![img_7.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/mq/20231223201308/img_7.png)

## Reference
* https://lethain.com/introduction-to-architecting-systems-for-scale/
* https://www.freecodecamp.org/news/a-dummys-guide-to-distributed-queues-2cd358d83780/
* 0.https://blog.bytebytego.com/p/why-do-we-need-a-message-queue
* 1.https://blog.bytebytego.com/p/how-to-choose-a-message-queue-kafka
* 2.https://medium.com/slalom-technology/azure-messaging-when-to-use-what-and-why-post-1-c643e43052ed
* 3.https://medium.com/slalom-technology/azure-messaging-when-to-use-what-and-why-post-2-81d164cc838e
* 4.https://medium.com/slalom-technology/azure-messaging-when-to-use-what-and-why-post-3-8a914ec74822
* 5.https://github.com/Azure/azure-service-bus/tree/master/samples/DotNet/Microsoft.Azure.ServiceBus
