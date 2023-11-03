---
title: IHosted Service碰到的问题
date: 2023-10-30 17:30:09
categories:
- Dotnet
- Debug
---

## 1.前言
应用程序通常需要在后台执行任务而不中断主要用户体验。这种任务我们通常称之为后台背景任务。在Dotnet中，提供了一个IHostedService接口来方便的实现启动和停止后台服务。
而我碰到了一个issue是关于，执行本地代码，后台任务是可以正常启动得，但是现在环境却始终获取不到相关的日志。

## 2.问题描述

这种问题，很让人头疼，因为本地无法复现，不得不走CICD pipeline去线上看，一旦有了一个想要尝试的方向，又要等一轮CI/CD。并且由于是线上问题，因此肯定是没有本地IDEA排查起来的方便。

言归正传，这个问题简单说就是本地能够看到我的`WorkerService`的log，但是把相关code部署到线上后，完全看不到一点相关的log。

## 3.思路

一开始是无头苍蝇，觉得很匪夷所思，检查了本地和线上都是一个版本的code后，觉得更加奇怪了，怎么会这样呢？

冷静下来后，有这么几个可能的方向:

* 1.实际是打印出来,但是日志上传到Grafana失败了。（跳板到线上环境检查，实际docker也没有日志）
* 2.分别在构造器和`StartAsync`方法中打印`HelloWorld`日志，确定`WorkService`有没有依赖注入成功

做了简单尝试后，顺着#2的思路，有了线索，构造器内打印了日志，但是`StartAsync`method没有日志。这说明DI成功了，但是`StartAysnc`没有被调用

## 4.解决方法


## Reference

* 1.[The Good, The Bad and The Ugly IHostedService](https://medium.com/@iamprovidence/the-good-the-bad-and-the-ugly-ihostedservice-8be82d063584)