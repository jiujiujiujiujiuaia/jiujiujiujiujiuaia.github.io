---
title: Learning From Rate Limiting
date: 2020-03-01 17:30:09
categories:
- System Design
---

## What?

* 系统上游突然有了spike traffic
* 出了事故（bug) or unsafe change

导致本系统received到了超出limitation的流量

## Requirement

problem: 如何解决过量的请求?

clarify:
* 可以用autoscaling增加更多的instance吗?
  * 不行，因为这个太慢了，scale instance需要时间
* 可以在LB层设置max connection吗？
  * 不行，因为每一种请求的cost和operation不一样，如果想针对不同的client和不同operation做rate limit 应该如何做呢？
* ok 现在确认了，是在application level做rate limitation

## Basic design

基本的单机流程如下：
* 1.识别是哪个client
* 2.不同的client有不同的rule和配置，这个可以写在config中，也可以写在db中
  * config更简单，但是写在config中如果要修改要重新部署
  * db中更加的灵活，但是有额外负担
* 3.对于reject的请求，可以直接丢掉，也可以放在队列中

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/ratelimitation/20240303194456/img_4.png)

然后会有好几个方向，看面试官的兴趣

## Buket token Algorithm

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/ratelimitation/20240303194456/img.png)

## Object oriented design

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/ratelimitation/20240303194456/img_1.png)

## Distributed environment

### Communication 

分析每一种communication 是什么? Pros & Cons 

Gossip
Distributed cache + watchdog(像call recorder)
Raft 选举leader（复杂，需要构建coordination service）

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/ratelimitation/20240303194456/img_2.png)

### Communication protocol

TCP有序（准确，但是慢一些）
UDP快但是不保证有序（性能更好，不需要那么准）

### 如何集成到应用中

Inter-process vs daemon mode

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/ratelimitation/20240303194456/img_3.png)


## Final Design

* Daemon side模式，额外一层，但是业务侵入式小，修改起来更加灵活，修改起来更加方便
* 提供Rule UI，方便Oncall，SRE修改Rule和monitor rule

![img_5.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/ratelimitation/20240303194456/img_5.png)
