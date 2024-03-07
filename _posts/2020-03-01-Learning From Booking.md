---
title: Learning From Booking 
date: 2020-03-01 17:30:09
categories:
- System Design
---

## Question

设计酒店预定/电影预定/机票预定系统

## Functional & Non-functional requirement

* 酒店主页
* 指定酒店的房间详情
* 预定房间
* 管理员系统(上架酒店)

* 高并发: 避免一间房价被重复预定
* 高可用
* easily scalable

流量预估:
* 5000 hotels/ 1M room
* 每天的预定量 1M * 0.7 /3 = 240000
* 每秒的预订量 240000/10^5 = 3

倒推: 订房 3 qps -> 下单 30 qps -> 浏览 300 qps

* Read heavy system
* Need ACID for avoiding double charge/double booking
* Easily set up model for entity

## Data Model

注意点: 对每一个实体建模: hotel, room, order(reservation)

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Booking/20240307130426/img.png)

## API Design

动词(GET POST PUT DELETE) + 名词(hotel)

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Booking/20240307130426/img_1.png)

## High level design

注意点:
* CDN 为了静态资源加速和JS
* Gateway(frontend) 保证request dispatch 和 解决一些公共的问题 auth, rate limitation...
* 每个数据库实体都有一个service

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Booking/20240307130426/img_2.png)

## 优化点

### 并发问题

* 同一个用户click twice
* 多个用户竞争

第一个场景： 

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Booking/20240307130426/img_3.png)

* 在前一个步骤，创建订单中，服务端创建了unique id, reservation id
* 后面的check out步骤都想尝试下单，但是依赖数据库只能插入一个primary key

第二个场景：

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/Booking/20240307130426/img_4.png)

* 悲观锁
  * 悲观锁直接锁行，事务2要等待事务1先完成
    * 简单实现
    * 可能出现死锁，可能性能会下降很多
  * 乐观锁
    * 增加一个版本号字段（如version）或者时间戳字段来完成的
    * 如果事务的update 操作失败了，这意味有其他的事务完成了更新
    * 因此就rollback
    * 优点
      * 无锁操作，性能更好
    * 缺点
      * 高并发下多次重试
