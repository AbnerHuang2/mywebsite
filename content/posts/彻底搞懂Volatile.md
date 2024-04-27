---
title: 彻底搞懂volatile
date: 2023-05-18 21:32:32
tags:
- Java并发
categories:
- Java
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## volatile是什么
volatile是Java中的一个关键字，用于保证数据的可见性和有序性。
### 可见性
在并发场景下，cpu对变量的修改，需要立马写入到主存，并通过缓存一致性协议实现其他cpu的缓存数据
### 有序性
禁止指令重排序，主要通过JRE的内存屏障来实现
## volatile使用场景
### DCL
单例模式的DCL（Double-Checked Locking）实现中，需要用volatile修饰变量。防止出现指令重排序导致并发场景下其他线程拿到未初始化完成的对象
```java
public class Singleton {
    private volatile static Singleton singleton;// 通过volatile关键字来确保安全

    private Singleton(){}

    public static Singleton getInstance(){
        if(singleton == null){
            synchronized (Singleton.class){
                if(singleton == null){
                    singleton = new Singleton();
                }
            }
        }
        return singleton;
    }
}
```
## 可见性保证（CPU层面）
### CPU多线程模型
从CPU说起，CPU设置了三级缓存解决CPU和主存的处理能力不对等问题。大概的模型如下
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1656939829720-08b7e299-1efa-4017-b713-3da11c0bb1a6.jpeg)
为了加快Java代码的处理能力，就需要用到CPU的多核处理能力。但是呢，这就会造成一个结果，A线程修改了数据，但是B线程读取数据时，依然是从缓存中读取旧数据。
那么需要怎么做才能保证数据的一致性呢？
Java中定义了Volatile关键字，用于保证这种数据的一致性。
原理就是Cache Aside模式，当数据更新之后，失效其他CPU的缓存。
### volatile工作原理
![](https://cdn.nlark.com/yuque/0/2022/jpeg/21760570/1656941444575-3398e320-854f-44cd-9b6b-985ad64990e0.jpeg)
### MESI 协议：缓存一致性协议
保证数据更新能够及时被其他CPU及时读取到最新值
**实现方式**

1. 修改指令增加lock前缀指令
2. CPU对总线进行嗅探，捕捉到lock前缀指令成功更新，就失效缓存中的值，从而保证其他CPU能够读取到最新的值
## 有序性保证
### Java层面
```java
public class TestVolatile {
    public static volatile int counter = 1;

    public static void main(String[] args) {
        counter = 2;
        System.out.println(counter);
    }
}

```
### 字节码层面
```shell
	public static volatile int counter;
    descriptor: I
    flags: ACC_PUBLIC, ACC_STATIC, ACC_VOLATILE
    // 下面为初始化counter时的字节码
    0: iconst_2
    1: putstatic     #2                  // Field counter:I
    4: getstatic     #3                  // Field 

```
### JVM层面（HotSpot 源码层面）
![image.png](https://cdn.nlark.com/yuque/0/2024/png/21760570/1712580536789-90a257bb-a151-4b85-a42b-52fb555e8267.png#averageHue=%23202020&clientId=ud0786218-4879-4&from=paste&height=156&id=MzHQo&originHeight=311&originWidth=792&originalType=binary&ratio=2&rotation=0&showTitle=false&size=297679&status=done&style=none&taskId=ufb0b53a0-1d34-4993-9777-15cf3593af4&title=&width=396)

1. hotspot中会有根据这个ACC_VOLATILE标识做判断的逻辑处理(is_volatile方法)
2. is_volatile在处理的时候，使用了OrderAccess的storeload方法。
3. OrderAccess::storeload是调用compiler_barrier。内部使用的c++ 的volatile关键字。（的四个方法loadload，storestore，loadstore，storeload都是使用的c++的volatile）
#### 两个重要原则

1. **hanppens-before原则** （Happens-before 关系中对于 volatile 是这样描述的：对一个 volatile 变量的写操作 happen-before 后面对该变量的读操作。 这就代表了如果变量被 volatile 修饰，那么每次修改之后，接下来在读取这个变量的时候一定能读取到该变量最新的值。）
2. **as if serial **（不管如何重排序，单线程执行的结果不会改变）

## 并发重要特性
volatile可以保证有序性，可见性。但是不能保证原子性
#### 禁止指令重排序（有序性保证）
为了优化CPU的执行效率，编译器和处理器会对代码进行重排序。但是这对导致执行结果受影响。
如：
```java
int a = 1; //1
int b = 2; //2
int c = a+b; //3
```
如果3排在1，2之前或之中，执行结果就会有问题。
Volatile会禁止指令的重排序，保证变量的写和读不会乱序。
#### 可见性保证
Happens-before 关系中对于 volatile 是这样描述的：对一个 volatile 变量的写操作 happen-before 后面对该变量的读操作。 这就代表了如果变量被 volatile 修饰，那么每次修改之后，接下来在读取这个变量的时候一定能读取到该变量最新的值。
#### 原子性
我们都知道Volatile不能保证原子性。但是我们从上面的过程可以看到，通过MESI协议，数据更新后，不是会把其他CPU的数据失效掉吗？那不是就可以获取到最新的数据吗？为什么还说不能保证原子性呢？
从单独的读/写场景来看，这种操作确实能保证原子性。
但是从i++这种读-改-写的复合操作来看，就不能保证了。假设CPU1和CPU2同时读取到了旧数据，然后都同时改了数据，然后写回到主存中，CPU1先到总线上，写入了主存，然后被CPU2的总线嗅探到，失效了CPU2的缓存。但其实这个时候，CPU2的写入操作已经到了总线上，再次触发数据更新。然后CPU1嗅探到数据变更，失效掉CPU1的缓存。但实际上CPU1和CPU2都是基于旧值去加1的。

## 参考
[https://xiaohuang.blog.csdn.net/article/details/122096863?spm=1001.2014.3001.5502](https://xiaohuang.blog.csdn.net/article/details/122096863?spm=1001.2014.3001.5502)