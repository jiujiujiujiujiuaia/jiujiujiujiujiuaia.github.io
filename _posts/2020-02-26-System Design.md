---
title: System Design
date: 2020-02-26 17:30:09
categories:
- System Design
---

https://github.com/Interview-Science/interview-english
https://instant.1point3acres.cn/thread/776466

## 关键点

* 不断地主动沟通，和面试官确认，我这样可以吗？我决定先做data model然后API，你可以吗？或者你有什么prefer?
* 注意观察，自己说了超过一分钟，但是没人响应，说明有可能走神了。

Scenario 场景
需要设计哪些功能、到哪个程度
询问： Features / QPS / DAU / Interfaces

Service 服务
将大系统拆分为小服务
拆分、Application、模块化

Storage 存储（比较核心的部分）
数据如何存储与访问
Schema/Data/SQL/NoSQL/File System

Scale 升级
解决缺陷，处理可能遇到的问题
Sharding/ Optimize / Special Case

## 弄清楚意图

关键点:
* 0.对description中的不同实体问问题，建表
* 1.逐字逐字的问题。例如题目是, design for large-scale job scheduler
    * what kinds of job?
    * How large is the scale?
    * Is it the distributed?
    * Who is the user? how does the user use this system? like create job?
    * what amount of data you should process, can the processing be background or it should be realtime, etc.
* 2.弄清楚这是一个读重还是写重的系统
* 3.input 是什么 output是什么 主动带领面试官run一个work flow
* 4.how many requests/timeframe, how much existing data is there

requirements搞清楚你需要什么样的data。
从而进一步推导data的大小、pattern是什么样的，要怎么处理，怎么存，怎么读，怎么保证data integrity等等
来决定合理的处理手段（in-memory vs database, SQL vs NoSQL, CAP strategy etc）
是不是应该问面试官，我们的系统是at least-once at most once exactly once（non-functional requirement）

### Functional Requirement

Are the requirements I listed as core requirement?, do I miss the any core?

* 说不清楚就举例子
* 对description逐字逐字的问，对其中不同的实体建表
* 系统的使用者是谁，是用户，还是其他服务，还是其他系统。(who is the user)
* 如何被使用，是有UI界面，还是定期从哪里拿请求，是提供一个接口。
* 流量是否周期性，是否来自全球?
* 峰值的请求量? 最不希望发生的错误是什么样的
* 是否在意重复数据
* 预估用户量，每个用户的请求数，总数据量，时间跨度
* ** 最终要弄清楚: read heavy or write heavy? exactly once?/ **


### Non-functional Requirement

* How availability the system should be
* How scalable the system should be?
* latency should be low as much as possible
* reliability

## 询问面试官

Are the requirements I listed as core requirement?, do I miss the any core? If not, 
I am used to start from data model and API design, and then give you top-down system.
How do you think about it?

## Data Model
key point:
* 设计表的时候，万变不离其宗的三件套: id, name, timestamp
* 因此，在做data model的时候，先不要说我们是用SQL还是Non-sql存储，根据自己的理解，先把数据的表建立起来。
* 把这些data model对应的“表”写出来，此处你不用强调它是个sql表还是nosql的结构，就只说我们这个data model里有哪些信息。
* 如果是比较经典的事务型关系，比如交易，比如订餐，比如发货，一般是sql，非常看重一致性(CP)
* 如果是重写，更看到可扩展性，对一致性要求没那么高，对可用性要求更高，可以是nonsql(AP)

SQL:
* ACID, 事务
* 读重的系统
* 结构化数据

Nosql:
* 扩展性更好
* 写重的系统
* 更高的可用性

* 不要套，比如酒店业务非得用SQL，而是通过前面的沟通和requirement，“推导”出要用SQL
  * 例如，酒店业务需要加入购物车，下订单，减少库存，这是需要事务的，那么这是SQL的强项
  * 例如聊天系统，是一个重写入的系统，更多时候需要write-heavy，需要在requirement环节对系统进行引导。

## API Design

rest一般是对外，rpc一般是对内，前者有相对严格的围绕资源的定义，后者因为是对内所以协议上灵活一些，类似这种的考量。

## High level Design

* 可以先从同步模型开始，然后走向异步模型(消息队列)
* LB:要画load balancer
* FrontEnt/ Gateway如果有太多service和client做交互的话，可以考虑用Frontend service挡住
  * Common stuff
    * AuthN/AuthZ
    * TLS termination
    * request dispatching
    * rate limitation
* CDN:用于交付静态资源，例如图像、视频、CSS 文件和其他多媒体内容

## 问题和优化

* redis
  * cache avalanche(缓存雪崩)
    * Random TTL
    * Consistent hashing
    * Circuit breakers/rate limitation
  * cache穿透
    * bloom filter(false一定不存在)
* 海量的读写请求怎么办? 
  * 消息队列当作缓冲区,不让我们数据库面临风险
  * 缓存一批数据，然后batch writing/reading
* 单点故障怎么办?
* 通过load testing测试处上限，合理的分配sharding的数量
* 需要一个状态记录的DB，来保证reability

## Reference

https://zhuanlan.zhihu.com/p/103484396