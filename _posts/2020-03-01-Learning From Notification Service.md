---
title: Learning From Notification Service
date: 2020-03-01 17:30:09
categories:
- System Design
---

## 

## Requirement

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/notification/20240307095211/img.png)

## Frontend service

什么时候需要这种service(MFE就是这个架构，chat service肯定需要这种)

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/notification/20240307095211/img_1.png)

## Metadata service

为什么需要metadata service? 什么时候需要? => mysql 如何快速找到一个user id在哪个数据库? 通过zookeeper(metadata service)

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/notification/20240307095211/img_2.png)
