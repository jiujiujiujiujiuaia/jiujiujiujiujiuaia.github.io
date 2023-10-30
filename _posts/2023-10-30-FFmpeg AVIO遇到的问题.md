---
title: FFmpeg AVIO遇到的问题
date: 2023-10-30 22:30:09
categories:
- 音视频
- C语言
- Debug
---

## 1.前言
有一个工作需求是需要从内存中拿到Elementary Stream(ES指的是只包含一个类型的数据的流，比如音频流or视频流)而不是从文件或者网络中拿到。正好FFmpeg中有一个AVIO的lib就是专门做这个事情的，在实际的使用中，
遇到了一个十分诡异的问题，那就是明明视频本身是有音频流和视频流的，但是从stream info拿到的时候，竟然是两个视频流。

## 2.背景
在managed code中，划分多个chunk，把一个文件的bytes按照chunk size依次放到内存中存起来。

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img.png)

然后从内存中的这个avio队列，利用自己写的read_buffer的回调函数，把media data读到`AVFormatContext`结构体中

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_1.png)

最后利用`avformat_open_input`函数尝试从context中读到stream的信息

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_2.png)

一切看起来都很正常，然后碰到了什么问题呢？

## 3.问题描述

运行起来的时候，就出问题了。

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_3.png)

```
[h264 @ 000001365E9A6CC0] corrupted macroblock 113 24 (total_coeff=-1)
[h264 @ 000001365E9A6CC0] error while decoding MB 113 24
[h264 @ 000001365E9A6CC0] concealing 5216 DC, 5216 AC, 5216 MV errors in P frame
[h264 @ 000001365EB2E400] Could not find codec parameters for stream 1 (Video: h264, none): unspecified size
Consider increasing the value for the 'analyzeduration' (10000000) and 'probesize' (10000000) options
```

上面这个错误，是FFmpeg在执行的时候抛出来的，描述了两个问题，一个是在解码H.264流时遇到损坏的宏块，另一个是FFmpeg无法为视频流找到正确的编解码器参数。

咋一看感觉是input file是损坏的，丢失了一部分，导致找不到正确的编码器参数。咱们接着往下看，同时还贴心的提示你，你可以给下面这两个参数增加值，来获取更多的信息。

```
Consider increasing the value for the 'analyzeduration' (10000000) and 'probesize' (10000000) options
```

### 什么是probesize和analyzeduration?

ffmpeg在avformat_find_stream_info中会读取一部分源文件的音视频数据，来分析文件信息，那么这个操作读取多少数据呢?

就是由`analyzeduration`和`probesize`决定的

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_4.png)

从上面的头文件可以看出，`probesize`是从源文件中读取的最大字节数，单位为字节。 max_analyze_duration是从文件中读取的最大时长，单位为 AV_TIME_BASE units。

对于默认值，`probesize`是5000000字节，`analyzeduration`是5s

### 思路

* 首先，我会思考，上面这个FFmpeg的error是哪一行代码引入的，是哪个环节出的问题？
* 其次，我会怀疑，是不是文件真的出现的问题，换一个问题会不会好一些呢？
* 再然后，如果文件没有问题，那就说明是code出现了问题，换一个格式比如mp4会不会更好呢？或者说从新写一个AVIO scratch，看看能不能读取到呢？

## 4.排查过程

### 1.Increase analyzeduration 和 probesize

无功而返，哪怕这两个值都比文件size和文件播放时长更大了，依然无济于事

### 2.输入文件是否有问题?

```shell
ffprobe -i .\file.webM
```

很明显，ffprobe通过从文件流（disk）中读到文件，可以正确的解析出包含两个流。

也就是说，文件没问题，就是AVIO的方式有了问题（从文件读没问题）！

![img_5.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_5.png)

### 3.AVIO的code有问题吗？

为了省事，我直接从FFmpeg的官网找到了一个[example](https://github.com/FFmpeg/FFmpeg/blob/n4.1/doc/examples/avio_reading.c)

然后修修补补，保证这个simple code和我业务上复杂的code调用FFmpeg的lib是一样的。

![img_6.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_6.png)

日志如下，最终读到了A/V stream的codec方式!!

![img_7.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_7.png)

太棒了，这就意味着，文件没有问题，代码（使用AVIO的方式）本身也没有问题，问题出在了那里呢？

## 5.下一步

还记得最开始managed code那个截图吗？是分chunk去读的file，而我的simple code是一次性dump到内存中的。

然后一个未知的原因导致这种chunk的方式是行不通的

![img_8.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_8.png)


## 6.Reference

* 1.[sample code](https://github.com/FFmpeg/FFmpeg/blob/n4.1/doc/examples/avio_reading.c)
* 2.[probesize and duration](https://www.jianshu.com/p/37d705aa0e01)
* 3.[什么是avio](https://ffmpeg.xianwaizhiyin.net/api-ffmpeg/avio.html)
* 4.https://www.cnblogs.com/leisure_chn/p/10318145.html
* 5.https://octalzero.com/article/17802173-7d46-4be2-be66-46c5a1824724
