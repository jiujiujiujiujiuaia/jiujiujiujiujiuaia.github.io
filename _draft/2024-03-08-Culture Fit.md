---
title: Culture Fit
date: 2024-03-08 17:30:09
categories:
- CPU
---

## 自我介绍

I am Bruce and have the computer science bachelor degree in 2020. Currently, I full-time worked on Microsoft Teams product group and
I have the close to four years experience that focus on building large scalable and flexible distributed meeting system to serve 1 hundred million daily active user.

my skill is about leveraging large distributed middleware component like redis, message queue, nosql db to support our meeting system
like building media platform for decoupling monolithic to microservice, especially different component.

I also build the autoscaling system for recording feature from 0 to 1 to achieve COGS. 

and I had experieced many different area like messaging, routing, big data, migration 

### 你可以给公司带来什么?
gain trust and sposor from stateholder to make team grow(拿人头帮助team增长)
energy, innovation, take initiative to do something.

## 具体讲讲你们的这个平台?

The scenario like this:
* In each meeting ,there is a centralized service to host p2p connection with each client for transfering audio and video
* If we want to build advanced feature,like recording, we need to development a service, like joinning meeting, subscribe the audio/video from the centralized service for business purpose.
* Before the platform I build, there are many monolithic service for advanced feature
    * 从media input -> process media 设计编码解码提高帧率抽帧加滤镜AI降噪 -> media output back to meeting

Talk about what we did:
* you must notice that, there are some duplicated work like how to use the RTP/RTMP protocol to handle input media/output media, how to join meeting
* Hence, we abstract the monolithic to three part, input component, process component, output component.
* Once there are some request, our platform is charged for scheduling component and combine different component to hanlde the request
* The benefit for other partner team once they onboarding us, they can reuse any exsting component, they don't need to care about infra, we provide HA

## 具体讲讲autoscaling是怎么做的?

The scenario like this:
* Before the covid-19，the traffic is smooth we just set up alert and let oncall manually add capacity。
* After covid-19，The demand for online work has surged, so we need autoscaling not manual work.

(high level design)
* We have a Work plane and a Control plane.
* the Work plane is the REST API service, responding to screen recording requests. Once there is a screen recording task,
     it reports the task and heartbeat to Redis.
* The Control plane is responsible for reading the current load situation of all instances
     in this cluster and scaling in or out based on the load situation.

(the detail is like)I am charge of implementing the control plane, there are three part:
* pick up suitable business metric as the triggering signal
* use the suitable storage, I use redis sortedset to store the instance id, and heartbeat timestamp, the detail about how we store it
* define the rule about how to scale up and scale down
    * scale up fast
    * cooldown period
    * don't remove the active instance when scale down

## 指标驱动业务

会议分为无人打开摄像头仅混合音频，多人打开摄像头，摄像头加字幕加混合音频

In one word, I pick up a suitable metric for our recording business, then the metric drive the final design solution.

The scenario like this:
* Before the covid-19，the traffic is smooth we just set up alert and let oncall manually add capacity。
* After covid-19，The demand for online work has surged, so we need autoscaling not manual work.

there are one problem here:
* 1.pick up what kind metric for referring by the autoscaling system,
* 2.once we can finish it, then we can decide what kind of design solution

According to my understanding for recoding business, our recording is divided into different type:
* No one turns on the camera, audio mixing only,
* Multiple people turn on the camera,
* Camera plus subtitles plus audio mixing.

传统的CPU memory不适合我们（trantional cpu memory monitor is not suitable for us why?）
* The computational resources occupied by different types of recording are completely different.
* Everyone turning on the camera plus subtitles is definitely the most resource-intensive.
* If we use CPU, the average CPU usage is very high, It might be caused by outliers, as these are meetings with heavy loads,
  but other nodes in the cluster are idle.

so, we set the slots concept for each recording type, we know each instance can handle how many recording type, we can precisely know the load level of the cluster.


## 如何跨团队的沟通drive一个事情

我认为这里面有几点要点:
* 1.You should have ownership, not just be concerned with technical matters.（许多程序员是优秀的执行者，但是不是优秀的dirver or leader）
* 2.Constantly communicate. we are not english speaker, so we are weak in using english for. design word/message in zoom are our weapon.
    * Activly set up meeting/send message in Zoom. build sync/async communication to sync up the status, what we did, what kind things block us.
* 3.Earn trust from stateholder. we not only complete the task, but also be keen for impact and
    * at the beginning stage, we should move fast and update status frequency,
    * in the middle stage, we should find the metric to prove our project/work are valueable.
    * we also need to actively to think about how to make innovation when we had already completed something
* 4.build connection outside work. If Company support travel, we can bring up some chinese culture stuff, like culture t-shirt, 茶具. we also can invite the partner to China.
  Be honest, deliver impact on time! Don't miss the expectation
* 5.Seek help from manager

Prism项目我是如何drive的

## 如何理解分歧和解决分歧

* 承认Acknowledge that misunderstandings and conflicts are normal; conflicts are just different views on the same issue, not personal. Don't bring emotions to work.
* 总结: Therefore, think from the other person's perspective, aiming for consensus.
* 场景: I wanted to develop a feature on our platform that allows people who can't speak to use Teams. The simplest version would be typing and then converting it to speech to push back to the meeting. My partner thought this scenario didn't exist because people with disabilities are always a minority, and we should develop other projects.
* 行动: We were both right. I was innovating, and he was thinking about prioritizing more urgent matters. Through patient communication, I understood his main disagreement was that he thought Teams' customers are able-bodied, people who can't speak are always a minority, and secondly, typing is too slow.
* 任务: Therefore, I conducted data analysis:
    * There are over 50M people worldwide who cannot speak.
    * Companies like Google, Facebook, and Amazon specifically develop Accessibility projects to help them. Even Microsoft hires disabled people to help develop, not just for an inclusive culture, but also because it's a significant user group that can't be ignored.
    * There are specific gesture algorithms that recognize sign language, eliminating the need for typing in the long run.
* 结果: Our project received a particularly good response, even demoing in front of the VP and winning a second-place prize in the Asia-Pacific region.

* 承认误会和冲突是正常，冲突只是大家对同一个问题不同的看法，不对个人。不要带着emotion去工作。
* 总结:因此站在对方的角度思考问题，目标是达成一致。
* S: 我想要在我们的平台开发一个能让不能发声的人也能用Teams，最简单的版本是打字，然后转语音push back to meeting. 我的同伴认为这个场景不存在，因为障碍人士总是少数，我们应该开发别的项目
* A: 我们都是对，我在innovation，他在想如果投入要优先级更高的事情。通过耐心的沟通，我了解到他不赞成的地方主要是认为Teams的客户是正常人，不能发声的人总是少数，第二个打字太慢了
* T: 因此，我去做了数据分析
    * 全球有超过50M的不能发声人群
    * Google/Facebook/Amazon 专门开发Accessibility project 去帮助他们。Even microsoft会专门雇佣残疾认识帮助开发，除开inclusive culture，这也是不能忽视的用户群
    * 有专门的gesture算法，识别手语，长期不需要打字
* R: 最后我们的项目反响特别好，甚至在VP 面前去demo，拿了亚太地区的二等奖。

## Most challenging/Most proud(最大的挑战和最骄傲的事情)

My initiative, innovative spirit, and sense of ownership helped our project gain good visibility in front of the Media VP. I can give you the example if you would love to.
* The situation: Our next-generation Media development was completed, we declared reuse, rapid integration, without the need to care about infrastructure and failover, 
but there was no internal customer buy-in because migration requires effort, which is tedious work.
* Action: My idea was that we should proactively conduct some feature demos, utilizing our platform to develop from 0 to 1, 
and then prove it really has these benefit.
* Task: Therefore, I took the initiative to collaborate with the AI research team in Beijing, 
asking if they had any AI algorithms related to media that could be used immediately. They gave me some inspiration, 
such as noise reduction, super resolution, and LLM to describe meeting backgrounds.
* Result: Through proactive communication with my boss and the Research team, 
I discovered that Teams lacked features to support people unable to speak, a market that is incredibly vast. 
due to I had the idea and being very familiar with the platform, I used text-to-speech and gesture-to-speech technology to push the voice back to the meeting. 
Eventually, I completed a Voice Aid Component on Teams. I had the opportunity to demo this to the VP in the US, emphasizing that I only spent 3 days completing this idea. I won a second-place prize in the Asia-Pacific region, and our platform's features became popular through this demo series, with more teams inquiring about our platform. 
This visibility in front of the VP made many things easier.

* 我的主动，创新精神，和ownership精神帮助我们项目在Media VP面前建立了良好的visibility。我能够给你一个具体的例子。
* S: 我们下一代Media开发完成了，宣称reuse，快速集成，不需要care infra和failover，但是没有客户buy in,因为migration需要精力，这是一个tidious work
* A: 我的想法是，我们得主动做一些feature demo，利用我们得平台从0到1开发，然后证明它真的有这些优点。
* T: 因此我主动和beijing得research做AI的团队，询问他们是否有一些关于media的AI算法能够拿来即用，他们给了我一些灵感，例如reduce noisy，super resolution, LLM to describe meeting background
* R: 在我主动和老板沟通以及Research团队沟通过程中，我发现Teams完全没有支持unable to speak的人的功能，要知道残障人士的市场非常广大。idea有了，平台我很熟悉，我利用文字转语音，手势转语音技术，把语音push back给meeting
* 最终完成了一个Voice Aid Component在Teams上。我有了机会去给VP in US demo，并且着重sell了我只花了3天完成了这个idea。
* 我拿了亚太地区的二等奖，我们的平台的这些特性通过这个Demo series一炮走红，越来越多team来询问我们这个platform的情况，在VP面前有了visibility，很多事情也更容易了。

## Why do you want to leave?

I really love and grateful to my teammate and manager,
but recenly I feel like I come into the my comfort zone, and want to chase more possibility, why? I can give you a example

* Three years ago, our team had only 5-6 people. We only were working on migrating from PaaS to Kubernetes for the Teams app.
* through migration opportunity and my managed believe my ability of learning quickly and move fast
* my boss make me involved in different business scnaro, like routing gateway,autoscaling,media,big data, messaging
* now our team grown to 40 and had all kinds of business requirement and project
* I'm not saying it's all my doing, but I indeed contribute a lot innovation to my team. I get great reward and be promoted three times.
* but Gradually I found myself very too familiar with every aspect of our team's work.
* I realized I no longer had new innovative ideas, which is why I said I had entered my comfort zone.

so I want to chase more opportuntiy and possibility,

Coincidentally, I saw the job description posted by Attila Chen on WeChat, which led me to start learning about Booking.
* Booking had a totally different business model comparing to online meeting system
* Booking had A/B testing culture, I love data driven company
* Booking using Java/Perl, it's new area I can explore
* Booking is a pure forigner company, had diversity and includsive cluster and hold dear growth mindset, 这个和我在微软经历的很像，我相信我可以无缝适应。

## Why want to join booking?

I have to say I am attracted by the slogan.
**It's more than a job, it's a new journey. this booking slogan sounds supper exciting,** right? haha, just a joking.

TBH, the most attract me that booking really match my past working experience in foreiner company not like local company:
* Booking app is very clean and focused
* Booking is really pure foreiner company in China, so we need to communicate with different time zone, had similar culture like diversity and includsive
* Booking office in China had 180 people now, when I just join O365 team, we are also around 200 people, but now we are 1000, I believe booking shanghai will be constantly growth
* And in the meantime, booking had high-value and promising business impact now and future. it's post-covid19 times, everyone in the earth want to explore the world
and booking is the market leader in this area.

I am excited and I think I can grow up alongside the company.
In one words this job really match my current skill, large scalable and flexiable system, the problem sovling skill, make vague to be clear.
and I also love the business model, I believe the china office team can constanly obtain the trust from the stateholder

## 职业生涯规划和未来5年的安排

我认为有4点:
* Technology is fundamental; I need to enhance the depth and breadth of my technical skills.(技术深度, 软件系统的复杂，海量数据的处理和并发的处)
* But more importantly, technology is just a approach; the ability to drive projects is even more important.
  Therefore, I hope to improve my communication skills and soft skills at Booking to create a greater business impact.
* Enhance the understanding of the business, how the company makes money, what consumers want more, and what kind of A/B testing is effective.
* Open up an international perspective and learn more about how to communatie with differnt country and time zone

## MS是如何赚钱的?

In general, Teams make money by selling subscription and packge feautre.

* We sell subscriptions of different levels, for example, we have three types of subscriptions: A1, A2, A3.
* Each subscription has a different price and includes different features.
    * For example, A1 only has the screen recording function, but A3 has both screen recording and AI-generated meeting notes features.
* There are two billing methods: one is per user, and the other is package billing for big company like fortune500

## Booking是如何赚钱的

Booking has several business lines:
1. agency model, Collecting commissions from hotels and apartments,
2. Advertising business promotion,
3. extra services such as flights and car rentals.

The main business model  around collecting commissions on reservations, with the company's revenue and profit continuously growing by 20%.

## Booking A/B test 文化

* Booking有着非常浓厚(strong)的A/B testing的文化去帮助booking提高Conversion rate optimization, transform vistor to be paid customer.
* 根据我的search，我认为有以下几点，please correct me：
    * 1.insist on data better than personal decision
        * The homepage of Booking is very clean, without complex advertisements and functions.
          It only asks the user where they are going, how many people, and the date.
    * 2.Democratize Experimentation
        * anyone in booking can easily did A/B testing without strict application
    * 3.Booking is a role model in the marking
        * Booking had best A/B testing platform and circle in the marking
            * any one can made hypothesis
            * break it down and test it in small data scope
            * constantly iterate it

## Booking knowledge

from business side:
* Collecting commissions from hotels and apartments by using agency model
* Diverse business lines, such as car rentals and airplane advertisements.(多元的业务线例如租车和飞机广告)
* also had merchant model to sell hourse

from tech side:
* most the service relied on perl, I heared that some of services had already migrated to Java echosystem, but there are still some.
* strong a/b testing culture
* Continus tech innovation

Agency Model（代理模式）
* 在代理模式下，Booking.com充当客户和住宿提供者之间的中介。
* 客户通过Booking.com平台预订住宿，但实际的交易是直接在客户和住宿提供者之间进行的。
* 在这种模式下，Booking.com通常会从每笔预订中收取一定比例的佣金作为其服务费用。
* 这种模式的优点包括灵活性较高，因为它允许住宿提供者控制最终的定价和可用性。

Merchant Model（商家模式）
* 在商家模式下，Booking.com以批发价格从住宿提供者购买房间或住宿空间，然后在其平台上以零售价格销售给客户。
* 这意味着Booking.com在客户预订房间时承担了更大的风险，因为它需要预先购买这些房间。
* 商家模式使Booking.com能够更好地控制定价和库存，可能会提高利润率，
* 但同时也增加了财务风险，特别是在需求预测不准确的情况下。

## 问题

* 如果我能加入booking团队，你们对我的期待是什么? 或者你觉得我最大的困难是什么加入之后?
* 我们需要去和印度团队竞争获取更多的sposor 从我们的stateholder吗？
* 你们更喜欢招聘什么样的人，或者说什么样的人更适合你们团队
* 你能给我一些feedback帮助我提高吗？

* If I can join the Booking team, what are your expectations for me? Or what do you think will be my biggest challenge after joining?
* Do we need to compete with the India team to get more sponsors from our stakeholders?
* What kind of people do you prefer to hire, or who is more suitable for your team?
* Can you give me some feedback to help me improve?