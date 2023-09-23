---
title: Teams Bot 和Azure Web App体验之旅
date: 2023-09-22 21:30:09
categories:
- Azure
- 技术
---

记录一下部署Teams Chat Bot的整个经历。

1.一开始按照教程一步步在本地跑通了，发消息，收到消息，但是回复消息失败了。
2.然后突然发现，回复消息一直是失败的，因为服务消息是有权限控制的
3.问GPT managed identity的权限管理原理是什么？
4.然后部署了一个web app service，解决了所有问题。
5.突然意识到我的需求只是需要收到消息，然后如何把消息抽取出来
而不需要发回去，所以1-3白做了哈哈。

## 在本地部署Bot

### 1.创建Azure bot资源

推荐使用managed identity来无密钥的管理权限。（管理bot能够在specific tenant的teams中发消息的权限，要不然随便一个外部的bot都可以在企业内部发消息）

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img.png)

同时，你就会获得两个资源，一个是Azure bot，另外一个是managed identity。

### 2.下载ngrok

使用ngrok的转发功能，达到内网穿透的效果。

```shell
ngrok http 3978 --host-header="localhost:3978"
```

运行上面命令后，把ngrok的域名复制到Azure bot的资源中去。

例如我的是`https://c9ab74729e32.ngrok.app/api/messages`

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_1.png)

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_2.png)

### 3.Bot code

```shell
git clone https://github.com/OfficeDev/Microsoft-Teams-Samples.git
```

1.修改appsetting.json文件，填入managed identity

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_3.png)

2.找到`TeamsAppManifest`文件夹中`mainfest`文件，填入managed identity和ngrok的域名.

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_4.png)

3.然后打包成zip包，请确保里面没有任何其他的文件夹

![img_5.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_5.png)

4.上传到Teams中

![img_6.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_6.png)

![img_7.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_7.png)

5.请求能够成功的达到本地，但是失败！并且bot不会给你任何回复

![img_8.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_8.png)

![img_12.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_12.png)

## 部署到服务器上

简单在本地进行了debug，发现bot能够收到消息，但是无法发送回Teams，这就是权限问题。

解决的办法也很简单，能够把消息发回Teams的权限是由managed identity提供的，我们需要把服务部署到远程server，然后赋予server相应的权限。

### 1.创建Azure Web App

发布方式请选择Docker，并提供Azure container Registry资源，让其知道去哪里拉镜像

![img_9.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_9.png)

![img_10.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_10.png)

等待资源创建成功后，找到Azure bot的identity，并且绑定给Azure app

![img_11.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_11.png)


### 2.部署

把本地的代码打包到docker image中，并publish到Azure app中。

```shell
docker login xxxx.azurecr.io
docker build -t bot -t xxxx.azurecr.io:0.4 .
docker push xxxx.azurecr.io:0.4
az webapp config container set --resource-group xxx --name xxx --docker-custom-image-name xxx.azurecr.io:0.4

```

修改bot的域名为xxxxx.azurewebsites.net

![img_14.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_14.png)

### 3.结果

可以看到，这一次成功的拿到了我们的echo message!

![img_15.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_15.png)

## 新的问题

我突然发现，尽管我跑通了e2e，但是我的目的是把这部分代码整合到一个线上的服务，

那不就是意味着没有办法本地测试了？本地的环境是没办法绑定Azure identity的。

### 分析

我开始厘清思路，我的目的是为了能够从teams获取聊天文本，而聊天文本之所以会被这个bot接收到，

是因为请求先从teams到Azure bot，Azure bot把消息转发给ngrok到某个server，server 监听3978端口。

因此，我的需求不需要回复teams的消息，我只需要扮演一个server，拿到消息而已，所以我完全不需要任何权限！

**所以我根本不需要web app，也不需要花大量的时间解决权限问题，只是因为我一开始没有分析清楚我的需求！**

**当然也不能开上帝视角，没有上面一步一步的操作，我也没办法如此的熟悉这里面的原理和流程**

### 魔改代码

![img_13.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_13.png)

### 结果

把bot的endpoint重新填写成ngrok的，然后这bot就可以在本地收到任何来自Teams的消息拉~

![img_16.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/bot/img_16.png)


TODO 把code上传到github，两个版本，一个接受message，没有回复的，另外一个是有回复的版本。





