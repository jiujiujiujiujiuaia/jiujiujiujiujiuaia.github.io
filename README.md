# TODO

- 弄一个域名的确有助于长期运营，能够被方便的找到
- [x] 1.本地安装jekyll环境，方便本地调试
- [x] 2.增加博客总浏览数和每一篇博客的浏览数（搞一下每一篇博客的）
- [] 3.增加评论功能
- [x] 4.增加搜索功能
- [] 5.尝试置顶功能和草稿功能
- [] 6.每一个博客有一个前言，怎么弄
- [] 把上一个博客的文章同步过来
- [] 把算法的一些文章再重新润色，重新写的更好
- [] 修改github主页的链接
- [] 等算法的文章弄好后，可以搞一个纯算法的wiki版本?
- [] 增加置顶功能
- [] 仿照这个文章解决大部分的问题https://lemonchann.github.io/create_blog_with_github_pages/
- [x] 把github作为图床，并且修改成正确的格式

# Blog

## Golang

### 并发编程


[并发编程库](https://github.com/jiujiujiujiujiuaia/MIT-6.824-Study-Notes/blob/master/Lectures/Lec_concurrency_code.md)

//把go module memory写进去 然后把爬虫拿出来

[并发编程模型](https://github.com/jiujiujiujiujiuaia/MIT-6.824-Study-Notes/blob/master/Lectures/Lec_thread_introduction.md)

[并发实战(Russ Cox)](https://github.com/jiujiujiujiujiuaia/MIT-6.824-Study-Notes/blob/master/Lectures/Lec_Russ_Concurrency.md)

### 语法

//Slice

## 算法

[二分搜索](https://github.com/jiujiujiujiujiuaia/leetcode_golang/blob/main/document/BinartSearch.md)

[动态规划](https://github.com/jiujiujiujiujiuaia/leetcode_golang/blob/main/document/DynamicProgramming.md)

[回溯法](https://github.com/jiujiujiujiujiuaia/leetcode_golang/blob/main/document/BackTracking.md)

[动态规划实战](https://github.com/jiujiujiujiujiuaia/leetcode_golang/blob/main/document/DynamicProgrammingTip.md)

## 大纲
* [Leetcode](leetcode/leetcode.md)
    * [Golang](leetcode/golang/golang.md)
        * [基本语法](leetcode/golang_syntax/golang_syntax.md)
        * [常用数据结构](leetcode/golang_structure/golang_structure.md)
        * [常用库](leetcode/golang_common_lib/golang_common_lib.md)
    * [Array](leetcode/array/introduction.md)
        * [数组](leetcode/array/array.md)
* [分布式]()
* [简历]()
* [日常博客]()

## 脚本使用
脚本逻辑:
1. 把所有_posts的图片移动到指定目录，确保唯一性，该目录有时间戳
2. 由于goland复制不会有重复的图片名，所以时间戳目录内的图片文件是唯一的
3. 把markdown内所有的带有(img全部替换成指定的带有域名和时间戳的地址

.\imgReplace.ps1 -f "2023-06-01-sample.md" -i "test"
.\imgReplace.ps1 -c "comments"
.\imgReplace.ps1 -f "2023-06-01-sample.md" -i "test" -c "comments"


执行效果:
![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/index/img.png)


## 博客本地启动

bundle exec jekyll serve
