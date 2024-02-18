---
title: Csharp常用snippets
date: 2020-06-01 23:30:09
categories:
- Leetcode
---

## 常用代码库(TODO 看已有的onenote常用库)

### 1.排序

#### Array Sort

使用Array.sort for string数组和char数组

```csharp
using System;

char[] array = { 'z', 'a', 'b' };
// Convert array to a string and print it.
Console.WriteLine("UNSORTED: " + new string(array));

// Sort the char array.
Array.Sort<char>(array);
Console.WriteLine("SORTED: " + new string(array));

====
UNSORTED: zab
SORTED: abz
```

```csharp
using System;

string[] pets = new string[]
{
    "dog",
    "bird",
    "cat"
};
// Step 1: invoke Array.Sort method on string array.
Array.Sort(pets);

// Step 2: loop over strings in array and print them.
foreach (string pet in pets)
{
    Console.WriteLine(pet);
}

====
bird
cat
dog
```

#### OrderBy(Linq)

![img.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/snippets/20240106124505/img.png)

#### List Sort

使用List.sort
```csharp
using System;
using System.Collections.Generic;

List<string> fruitNames = new List<string>()
{
    "mango",
    "pineapple",
    "kiwi",
    "apple",
    "tomato"
};
// Sort the fruit in alphabetical order.
fruitNames.Sort();

// Print the sorted fruit.
foreach (string fruit in fruitNames)
{
    Console.WriteLine(fruit);
}

====
apple
kiwi
mango
pineapple
tomato
```

自定义排序
```csharp
            var meetings = new List<int[]>();
            foreach (var item in intervals) {
                var begin = new int[] { item[0], 1 };
                var end = new int[] { item[1], -1 };
                meetings.Add(begin);
                meetings.Add(end);
            }

            meetings.Sort((o1, o2) => o1[0] != o2[0] ? o1[0].CompareTo(o2[0]) : o1[1].CompareTo(o2[1]));
```

### 2.返回多个value

https://www.dotnetperls.com/multiple-return-values

### 3.StringBuilder

![img_6.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/snippets/20240106124505/img_6.png)

![img_7.png](https://raw.githubusercontent.com/jiujiujiujiujiuaia/jiujiujiujiujiuaia.github.io/master/_posts/pic/snippets/20240106124505/img_7.png)

