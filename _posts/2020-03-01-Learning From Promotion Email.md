---
title: Learning From Promotion Email
date: 2020-03-01 17:30:09
categories:
- System Design
---

## 问题

marketing people经常需要为一些即将举办的活动发送邮件给客户，请设计一个系统，可以根据所给的活动信息和发送目标用户email list信息，填充模板，发送给顾客

例如，圣诞节快到了，有很多campaign，营销人员可以通过这个系统发送给英国的顾客

## Ask Question

* 谁会使用这个系统(营销人员)
* 营销人员多高的频率使用这个系统?
* email list有多大?
* 有多少个模板?模板可以由营销人员自定义吗?
* email内容有多大，我可以假定平均4kb一封邮件吗？
* 有定时功能，对吗？
* 我们需要告诉营销人员，那些email被打开了，多少被阅读了吗？
* 功能: authentication(only for internal employee), web UI for create the email, create email template, on-time send the email，review the email
* user list会被扩充或者减少吗？marketing people是一个个选的？email list怎么来的

每天有多少人使用（创建了多少template+email)
每天需要发多少email
高峰的时候流量是平时的多少倍

## Requirement & Keypoint

* 创建邮件模板
* 创建邮件内容
* 定时发送功能
* 登录功能
* review邮件系统功能(分析)

高吞吐量
nearly real-time

At most once
high availability
store extremely large scale of email data


## Data Model

User Table:
* User id
* User Name
* User Email address

Email Template table:
* Template id
* Creator id
* Title
* Datetime
* Blob string

Object table:
* Object id
* Template id
* Path
* Name

Email Table:
* Email id
* Template id
* placeholder json 
* Content string

## API Design

POST /v1/emails/
* user id list
* email title
* email template
* Picture

Get /v1/template/{id}

## High level design

V1: A service 不断给 B service发请求

在这个版本中，我们有两个独立的进程P1和P2来处理电子邮件工作和短信工作。

好吧，如果你想发送 100~300 封电子邮件，那么看起来不错。但是如果您想发送 20,000 封电子邮件怎么办？那么我们就有问题了。因为只要任何一方新能下降或者出现故障

P1和P2是的连接我们系统的瓶颈。

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/email/20240306202230/img_1.png)

V2: 加入FIFO消息队列，P1和P2被decoupling

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/email/20240306202230/img_2.png)

然而，我们有了更多的问题:
* P1进程崩溃然后重新启动，会不会重复发送邮件? -> 我们需要一个记录发送状态的DB，确保我们不会重复发送邮件
* 用户规模如果有几千甚至上亿，我们当前读表的方式会不会有问题? -> 因此我们应该多个服务，每个服务负责查询一部分user id并且写入队列中
* 我们需要多个worker并行的去发送电子邮件
* 确保我们均匀的访问3rd party的provider，不会把第三方拉爆

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/email/20240306202230/img.png)


## Reference
1.https://medium.com/bsadd/system-design-talk-campaign-management-system-cec31b6a4628
2.https://github.com/jiujiujiujiujiuaia/SDFC/tree/main/system-design/batch-emails
