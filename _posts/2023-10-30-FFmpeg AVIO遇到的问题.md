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

翻译一下上面的这个错误: 

* 宏块损坏：corrupted macroblock 113 24 (total_coeff=-1) 这条消息表示在指定的坐标（第113个宏块，第24行）发现了一个损坏的宏块。total_coeff=-1 可能表明在视频压缩的熵编码（系数处理）部分出现了错误。
* 解码时错误：error while decoding MB 113 24 这条消息与上面的问题相关，指出在尝试解码同一个宏块时发生了错误。
* 隐藏错误：concealing 5216 DC, 5216 AC, 5216 MV errors in P frame 这条消息表明解码器正在试图隐藏P帧中的错误。P帧是一种使用前面帧的数据来预测当前帧内容的帧。DC和AC指的是图像块（宏块）中的直流和交流分量，MV指的是运动矢量。数字表明有大量的错误被隐藏，这可能意味着视频质量受到了严重影响。
* 缺少编解码器参数：Could not find codec parameters for stream 1 (Video: h264, none): unspecified size 这条消息意味着FFmpeg无法确定视频流所需的编解码器参数。这可能是由于文件损坏、缺失元数据或不支持的流格式。

什么是宏块？它是编码、解码、处理和预测算法的基本单元。如果独立编码每个像素，看每个像素的帧间和帧内的预测差异，效率很低，计算量爆炸。 因此通常使用4X4或者16X16的宏块作为最小单元，来预测最佳的运动矢量，预测误差校正

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img.png)

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

### 初始思路

* 首先，我会思考，上面这个FFmpeg的error是哪一行代码引入的，是哪个环节出的问题？追踪出错的代码行
* 其次，我会怀疑，是不是文件真的出现的问题？比如用ffprobe或者自己写一个程序处理这个文件是否真的出问题了？
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

## 5.Apple-to-Apple Comparison

还记得最开始managed code那个截图吗？是分chunk去读的file，而我的simple code是一次性dump到内存中的。会不会是因为一个是从文件流读的，一个是从内存流读的，从而有问题呢？

![img_8.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231030121233/img_8.png)

### 文件流 vs 内存流

无论是从文件流读取还是从其他来源（如网络或直接内存访问）读取，最终数据都必须被加载到内存中以供处理。这是因为计算机的CPU只能直接访问内存中的数据，不论数据最初来源于哪里。

当我们说“从文件流读取”，这实际上意味着：

* 数据的物理存储：数据最初存储在磁盘上的文件中。
* 数据读取过程：当需要读取这些数据时，操作系统的文件系统会负责从磁盘读取数据，并将其放置到进程的内存空间中。
* 内存中的数据处理：一旦数据位于内存中，应用程序（如FFmpeg）就可以对其进行处理，例如解码、转码或播放。

![img_1.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_1.png)

### Visual studio memory tool

用了这个工具，只需要输入一个运行时的指针地址，就可以返回内存的data。

我发现MCR native code少了4个字节! 这不就是真相了，因为少了4个字节，所有文件损坏了呀！我觉得肯定是这个问题，到这里的时候我已经半场开香槟了。

![img_2.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_2.png)

回到最开始的代码，的确代码中跳过了4个字节

![img_3.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_3.png)

### 更差的结果

令我绝望的是，这里竟然报了另外一个我从未见过的错误，并且你仔细会发现，这里比最开始的时候还不如，甚至连video都没打印出来， 兜兜转转，到这里我已经花了一个星期，没有进度甚至还倒退。

![img_4.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_4.png)

### 比较内存中字节的内容

我所看到的是真实的吗？内存中两端的字节是否完全相同？除了顺序错误之外，还会有更多的问题吗？

我没去看这个错误，我只是很奇怪，为什么文件是一样的， 使用Lib的方式是一样的，但是两个不同的结局，所以我已经不相信我设想的或者我看到的，我要重新验证每一步。

我加入了一个hash函数，然后看看内存中的字节是否一致。

![img_5.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_5.png)

### 漫长的体力活 - 比较

接下来，我不断修改Business code和Sampe code，以确保进行同类比较：

* 确保文件读取方法相同。
* 确保 AVIO 回调的缓冲区大小相同。
* 确保所有与 FFmpeg 相关的参数设置都相同。
* ...

### Root Cause!!

最终找到了问题！我非常疑惑，为什么在我的pure code中，`avformat_open_input`函数中只调用了一次，而在business code中

这个函数被调用了两次（后面发现这是一个bug，开发人员疏忽了，在AVIO的if scope中调用了一次，然后又在公共的地方调用了一次，它忘记了）

![img_7.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_7.png)

## 6.更多的问题..

* 1.为什么同一个函数`avformat_open_input`调用两次就会出错呢？
* 2.为什么跳过4个字节能读到音视频流，而不跳过，保留完整的文件，反而直接抛错了呢？

###  #1 问题

C语言是过程式的语言，函数是运来操作和改变参数的状态，核心观点是通过函数来组织代码，C语言的函数通常会产生副作用，即除了返回值之外，它们还会修改某些外部状态或数据结构。

### #2 问题

问题2就复杂的多了，我们先看看`avformat_open_input`源码

![img_8.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_8.png)

![img_9.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_9.png)

最终聚焦在这个`ebml_read_num`函数上，先读取头字节，确定表示EBML data的长度有长，然后发现长度竟然是8字节长(2^56)

然后max size规定了只能是4字节长。所以导致抛了下面这个错误。因为正好读到了0x01这一字节上。

```text
[matroska,webm @ 0000024F733C8440] Length 8 indicated by an EBML number's first byte 0x01 at pos 219 (0xdb) exceeds max length 4.
[matroska,webm @ 0000024F733C8440] EBML header parsing failed
```

#### 什么是EBML

当格式被识别为WebM时，会调用 matroska_read_header 函数来处理头部。

这个过程涉及根据EBML规范解析EBML（可扩展二进制元语言）。

EBML（可扩展二进制元语言）是一种灵活的、大小可变的二进制标记语言，设计用于作为多媒体容器格式的基础，例如Matroska（.mkv、.mka、.mks文件）

EBML文件通常由一个头部和随后的多个数据元素组成。每个元素包含一个ID、长度描述和实际的数据内容： 
* ID：唯一标识元素类型。 
* 长度描述：使用EBML的长度编码规则，标识数据内容的大小。 
* 数据内容：实际的元素数据。

在EBML中，数字的长度由第一个字节的高位字节中前导零位的数量决定。高字节中第一个'1'位之前的零位数量（包括'1'位本身）决定了用于数字部分的字节数。

例如下面这个例子，第一个字节表示，这个length的长度有几个字节，然后去掉一个1后，剩下的总长度表示数据的length有多长。

![img_11.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_11.png)

#### 指针0x01

16进制0x01转换成2进制就是`0000 0001`

同理可得，0x01是一个非常大的数字，说data的size长达2^56次方，这是不可能的，因为EBML格式规定了max size是4

![img_12.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/avio/20231216155645/img_12.png)


## 7.Reference

* 1.[sample code](https://github.com/FFmpeg/FFmpeg/blob/n4.1/doc/examples/avio_reading.c)
* 2.[probesize and duration](https://www.jianshu.com/p/37d705aa0e01)
* 3.[什么是avio](https://ffmpeg.xianwaizhiyin.net/api-ffmpeg/avio.html)
* 4.https://www.cnblogs.com/leisure_chn/p/10318145.html
* 5.https://octalzero.com/article/17802173-7d46-4be2-be66-46c5a1824724

