---
title: Learning From Slack Messaging
date: 2020-03-01 17:30:09
categories:
- System Design
---

## 问题

请设计一个即时通讯的系统，就像slack那样

## Functional Requirement

* 1-1 私聊
* group chat
* 是否正在typing
* 用户状态
* 群添加或者删除人
* 是否需要推送功能?
* Slack/Teams 不像wechat，不需要添加好友的功能

## Non-function requirement

* QPS有多大? DAU MAU有多大?
* 多少是读，多少是写? 估算读写比例
* 估算每条消息的大小，然后计算需要多大的存储去存
* 流量的规律, P95 latency是多少
* 用户是否来自全球？

## 需求总结

* 我们需要一个分布式的系统服务全球的用户
* Write heavy
* 我们需要存储10TB的数据，并且在不断增长，我们需要能够horizontally and easily scalable db系统

## Data Model

**仅仅只是把数据分表，而不说我们用什么数据库** 

User profile:
* id int
* name string
* email string
* displayName string

解释为什么这里要分表，而不是用type类型来区分? 
* 假设私聊比群聊的量级大得多
* 1.私聊和群聊消息在业务逻辑和数据访问模式上存在差异。私聊消息通常是一对一的交流，而群聊消息则涉及到一对多的通信。
  * 通过将这两种消息类型分开存储，可以更容易地对每种消息类型实施特定的优化策略，如索引策略、查询优化等。
* 2.如果将这两种消息存储在同一张表中，高频的私聊消息操作可能会影响到群聊消息的查询和存储性能。
  * 分表操作有助于减轻单一表的读写压力，从而提高数据库的响应速度和整体性能。
* 3.这里是一种解耦的操作（万金油答案) 以后业务发展不同了，增加了不同的property，不会互相影响。

Chat 1-1 message:
* chatId int
* User id Send
* User id Received
* timestamp 
* Chat content(先不要考虑太复杂，比如传文件，图片等等)

Chat group message:
* Group id
* Message id
* timestamp
* message content
* sender user id

User membership
* group id
* user id

## API Design

### 1-1 私聊
   发送私聊消息

POST /api/messages/private
请求体包含：senderId, receiverId, content
获取与特定用户的私聊历史

GET /api/messages/private/{userId}/{otherUserId}
其中userId是请求者的用户ID，otherUserId是对方用户的ID


### 群聊
   创建群聊

POST /api/groups
请求体包含：creatorId, name, members（成员ID列表）
发送群消息

POST /api/messages/group/{groupId}
请求体包含：senderId, content
获取群聊历史

GET /api/messages/group/{groupId}

### 群添加或者删除人
   向群里添加人

POST /api/groups/{groupId}/members
请求体包含：成员的userId列表
从群里删除人

DELETE /api/groups/{groupId}/members/{userId}

## High Level Design

这里说明，我会给一个basic的design，仅仅是围绕需求
* Replay： 重新过一遍每个需求，为每个需求添加一个服务 
* Merge： 归并相同的服务

我们需要:
* 1-1 service
* group service
* membership management service
* presence service
* notification service

#1 和 #2可以合并称chat service

然后画图，把这些service 和 DB 和Gateway(LB)连在一起

用whiteboard画了一个最搓的，尝试一下功能，大概就是这个效果和样子。
![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/messaging/20240305103150/img.png)

* 线头处加上字和API
* 组件和组件之间可以加上消息队列/缓存进行优化

### 稍微优化一些的design

在完成了一个最简单的架构之后，我们可以回头看一下non-functional requirement(一开始写non-functional requirement，就是为了这里作铺垫)

* 比如说我们写了，我们需要一个scalable和超大数据规模的数据库，因此我们需要做sharding
* 一开始我们写了我们需要低时延，我们需要redis，数据库索引优化，做load testing压测看看系统瓶颈
* 一开始我们写了要高可用，所以就要有replica，kafka...

我们的non-functional requirement。

* 我们需要redis缓存热点数据
* 我们需要消息队列解耦消息推送，从而有更大的吞吐量
* 这个时候再设计一下DB的sharding? (或者引导面试官来到sharding)

## 优化点，其他的细节

### 1.每秒大量请求

* rate limitation
* 需要消息队列当作缓冲区，控制速率
* 实现缓存算法，累计一批消息，然后再发送，比如等50ms-100ms

### 2.广播消息（群聊）

* pull: 客户端主动从服务器拉取数据，一条消息，N个客户端主动拉取，这是读放大，对数据库读取压力很大
* push: 服务端主动推送到客户端，这是写入放大，一消息推送到N个客户端。

那么解法就是推拉结合，如果group规模大，我们宁愿读放大（pull），因为我们可以加storage，减少带宽压力。如果group 规模小，那么我们就push

为什么宁可增大读压力，也不增大写压力？
* 写操作通常比读操作更耗资源
* 数据一致性和持久性要求
* 读有读缓存的办法

### 3.批量写入

在我们的系统中，用户的写操作是直接到达数据库的，那么我们可能面对峰值X QPS造成风险，因此我们加入消息队列

在队列的另外一端，专用的批量写入器可以帮助我们讲消息削峰填谷。

但是，风险是有可能队列会比较慢，因此我们可以接受最终一致性，那么可以采用这种。

## Reference

https://towardsdatascience.com/ace-the-system-interview-design-a-chat-application-3f34fd5b85d0
