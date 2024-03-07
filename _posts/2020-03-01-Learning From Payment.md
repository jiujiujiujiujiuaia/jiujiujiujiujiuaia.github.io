---
title: Learning From Payment System
date: 2020-03-01 17:30:09
categories:
- System Design
---

## 问题

设计一个支付交易系统。

Question: 
* 我们这个交易系统是收谁的钱，客户是谁？（电商，外卖，酒店）
* 支持什么样的付款方式，信用卡，第三方，银行卡
* 一笔订单可以是多个不同的商家提供的货物吗？
* 每天产生多少比交易？
* 我们是不是不能产生对通过用户的多次charge?
* 客户付钱后，钱是打给平台，平台等待交易完成后，再给商家打款，对吗？
* 全球部署？流量来自全球？
* 我们这个系统需要提供对账服务吗？（我们收了用户多少钱，我们给商家打了多少钱）

## Requirement & keypoint

* 收款: 用户下单，平台替商家扣款，钱打入商家的账户
  * 和第三方支付平台的交互(paypal)
  * 使用信用卡 -> 使用stripe扣款
* 付款: 平台定期把钱给商家（除去平台费用）
  * 记账

这个应用场景下，对一致性要求非常高:
* 用户重复下单，多个请求产生，平台不能重复扣款
* 平台定期要分钱给商家，因此不能有记账错误
* 一致性的要求大于可用性，可以提示client，当前有问题

## Data Model & API Design

在CAP theory, 我们只能选择CP和AP，在我们前面的分析中：
* 系统对一致性的要求特别高
* 我们需要事务来保证
  * 不会出现用户重复扣款
  * 用户扣款成功了，但是商品余额没改变的情况

因此，我们会选择SQL来解决这个应用场景。

### Data Model

用户下单事件 table:
* payment id (PK)
* user id
* order info (List)
* payment way(credit card)
* seller info
* is_payment_done bool

订单 table:
* order id (PK)
* price
* amount
* product name
* is_done(payment status)
* ledger_updated
* payment id(FK)

值得一提的是:
* 一笔payment包含了多个order(订单), 只有所有订单都完成了，这个payment才算完成

### API Design

REST API

下单:
POST /v1/payments

获取订单状态

GET /v1/payments/{:paymentid}

内部系统，和order系统的交互，我们可以采取RPC，更加轻量，高效，不需要http的header


## High level design

根据需求和表设计，我们可以划分成这么几块：
* 用户下单付款, 付款系统
* 一笔付款包含多比订单，请求到订单系统
* 订单系统向外部payment system例如paypal charge
* 最终，告诉用户失败还是成功
* 以及记账

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/payment/20240306152819/img_1.png)

## 优化

### 外部系统延时过高怎么办?

两个场景导致异常发生:
* PSP 认为付款请求风险较高，需要人工审核。
* 信用卡需要额外的保护, 银行也有fraud detection

解决方法:
* 用户发起支付请求，validation无误后，立即返回响应，用户需要等待结果。然后有callback机制，PSP成功或者失败，异步通知。
* APP/Web 上提供用户实时的进度更新

### 内部系统同步和异步模型

同步: 简单，小规模系统效果很好，大规模下问题就会逐渐出现:
* tight couple, sender知道谁来recipient，随着业务的发展，可能有更多的功能需要订阅同一个消息/事件，例如下单成功，我们可能需要邮件/短信通知
* low performance: 任何一个组件性能不行，就会导致整个业务的performance下降
* 难扩展

使用消息队列，讲同步模型转变成异步模型：

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/payment/20240306152819/img_2.png)

* decoupling: 多个业务系统可以消费同一个events
* 容易扩展
* 缓冲层

### 容错

* 重试队列：可重试的错误（例如暂时性错误）被路由到重试队列。
* 死信队列：如果一条消息反复失败，它最终会进入死信队列。死信队列对于调试和隔离有问题的消息非常有用，以便检查以确定它们未成功处理的原因。

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/payment/20240306152819/img_3.png)

### 重复收费场景

支付系统可能遇到的最严重的问题之一是向客户重复收费。(booking这种系统是不是也忌讳一个房间被重复消费?)

因此，我们要保证收费这个事情，exactly once!:
* at least once(至少成功一次)
* at most once(最多也只能成功一次)

第一，我们使用retry机制，一旦我们发生网络错误或者timeout，保证用户的请求可以到达payment系统（重试的策略有固定重试，指数退让，立即重试等等）

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/payment/20240306152819/img_4.png)

那如果用户重复支付怎么办？我们只能让用户成功一次:
* 场景1 ：支付系统使用托管支付页面与 PSP 集成，客户单击支付按钮两次。(向PSP支付两次)
* 场景2 ：PSP **成功**处理付款，但由于网络错误，**响应**无法到达我们的支付系统。用户再次点击“支付”按钮或客户端重试支付。

对于场景一，我们需要一个幂等的UUID，如果客户端对同一笔订单点击多次，请求带着同一个UUID（UUID 的目的是允许多个系统中的数据在没有中央协调机构的情况下独立生成，而不会发生冲突）
* payment system 查询数据库，发现这个UUID对应着一个token已经在数据库中
* 立马返回
* 如果是并发写入场景，可以把主键设置为幂等键，这样数据库插入会失败

对于场景二, PSP应该对于同一个UUID 有着PSP这边的token，因此当扣费成功时，哪怕第二个请求带着相同的token来了，也不能扣款。
* 请求是psp和payment service之间未能成功，因此payment system这边压根就没有token的记录
* 因此，payment system会带着同样的UUID，访问psp
* psp会发现针对这个UUID发放了token，直接返回结果

总结，场景一和场景二，分别代表了，
* #1 payment system已经有成功了记录，如何避免重复扣费 
* #2 payment system db没有记录，但是PSP有，如何避免重复扣费

## Reference

https://newsletter.pragmaticengineer.com/p/designing-a-payment-system?s=r
