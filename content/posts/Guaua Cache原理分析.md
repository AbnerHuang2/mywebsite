---
title: Guaua Cache原理分析
description: Guaua Cache原理分析
date: 2022-01-02

categories:
- Cache

---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 什么是LocalCache
LocalCache见名知意，就是本地缓存，通过本地缓存一些数据，提升应用程序的访问性能。其中Java中一个比较好的实现框架就是guaua的LocalCache，底层是借用了jvm的堆内存来存放数据的
## 特性
本地缓存的实现，其实用concurrentMap也能实现，那guaua有什么优点呢？

1. 过期处理
2. 自动加载
3. 并发控制，最多只会有一个线程去加载数据
4. 配置回收策略
5. 统计命中率
## 使用场景

1. 热点数据访问，通过多级数据缓存提升访问性能
2. 本地热点数据，或者重复耗时计算的逻辑产生的数据
### 基本使用
```bash
//定义一个本地缓存
LoadingCache<String, Optional<String>> cache = CacheBuilder.newBuilder()
                        .maximumSize(1000)
                        .expireAfterWrite(10L, java.util.concurrent.TimeUnit.SECONDS)
                        .concurrencyLevel(Runtime.getRuntime().availableProcessors())
                        .weakKeys()
                        .weakValues()
                        .build(new CacheLoader<String, Optional<String>>() {
                            //重写一个CacheLoader来实现加载方法
                            @Override
                            public Optional<String> load(String key) throws Exception {
                                System.out.println(key+" load success");
                                return Optional.of("key - "+ key +" - value");
                            }
                        });
//从缓存中获取数据
 try {
      //get方法需要处理为null的异常
      System.out.println(cache.get("key99999").orElseGet(()->"null"));
  } catch (ExecutionException e) {
      e.printStackTrace();
  }
  //不用处理异常，但是如果cache中不存在数据，不会触发加载逻辑
  cache.getIfPresent("key99999");
```
## 底层原理分析
### 整体流程
![](https://cdn.nlark.com/yuque/__puml/ec26d7b591c84d7575087b48bc11a4f8.svg#lake_card_v2=eyJ0eXBlIjoicHVtbCIsImNvZGUiOiJAc3RhcnR1bWxcblxuc3RhcnRcblxuOuiOt-WPluWIhuautemUgTtcbjrpgJrov4fliIbmrrXplIHojrflj5bliLDlr7nlupTnmoTlvJXnlKjlrp7kvZNSZWZlcmVuY2VFbnRyeTtcbjrojrflj5blrZjmtLvlr7nosaHvvIzlpITnkIbov4fmnJ_kuYvnsbvnmoQ7XG5pZiAo5Yik5pat5byV55So5YC85piv5ZCm5aSE5LqO5Yqg6L295LitKSB0aGVuICh0cnVlKVxuICA6562J5b6F5Yqg6L295a6M5oiQ77yM5YaN6YeN5paw6I635Y-WO1xuZWxzZSAoZmFsc2UpXG4gIDrliqDplIHliqDovb3mlbDmja47XG5ub3RlIHJpZ2h0OuS4gOasoeWPquiDveacieS4gOS4que6v-eoi-WKoOi9veaVsOaNrlxuZW5kaWZcblxuc3RvcFxuQGVuZHVtbCIsInVybCI6Imh0dHBzOi8vY2RuLm5sYXJrLmNvbS95dXF1ZS9fX3B1bWwvZWMyNmQ3YjU5MWM4NGQ3NTc1MDg3YjQ4YmMxMWE0Zjguc3ZnIiwiaWQiOiJkbHdBRSIsIm1hcmdpbiI6eyJ0b3AiOnRydWUsImJvdHRvbSI6dHJ1ZX0sImNhcmQiOiJkaWFncmFtIn0=)
### LocalCache
LoadingCache的核心在于get，追踪get源码，会发现大部分逻辑都在LocalCache类中。
```java
V get(K key, CacheLoader<? super K, V> loader) throws ExecutionException {
    int hash = hash(checkNotNull(key));
    //找到对应的segment，然后从segment中获取数据
    return segmentFor(hash).get(key, hash, loader);
}

public @Nullable V getIfPresent(Object key) {
int hash = hash(checkNotNull(key));
V value = segmentFor(hash).get(key, hash);
if (value == null) {
    globalStatsCounter.recordMisses(1);
} else {
    globalStatsCounter.recordHits(1);
}
return value;
}
```
### Segment
```java
@CanIgnoreReturnValue
V get(K key, int hash, CacheLoader<? super K, V> loader) throws ExecutionException {
  checkNotNull(key);
  checkNotNull(loader);
  try {
    if (count != 0) { // read-volatile
      // don't call getLiveEntry, which would ignore loading values
      ReferenceEntry<K, V> e = getEntry(key, hash);
      if (e != null) {
        long now = map.ticker.read();
        V value = getLiveValue(e, now);
        if (value != null) {
          recordRead(e, now);
          statsCounter.recordHits(1);
          return scheduleRefresh(e, key, hash, value, now, loader);
        }
        ValueReference<K, V> valueReference = e.getValueReference();
        //如果引用对象正在加载中，等待加载完成再获取
        if (valueReference.isLoading()) {
          return waitForLoadingValue(e, key, valueReference);
        }
      }
    }
    //加锁获取数据
    // at this point e is either null or expired;
    return lockedGetOrLoad(key, hash, loader);
  } catch (ExecutionException ee) {
    Throwable cause = ee.getCause();
    if (cause instanceof Error) {
      throw new ExecutionError((Error) cause);
    } else if (cause instanceof RuntimeException) {
      throw new UncheckedExecutionException(cause);
    }
    throw ee;
  } finally {
    postReadCleanup();
  }
}
```
### 存储结构
![](https://cdn.nlark.com/yuque/0/2024/jpeg/21760570/1713234531453-08ff34bd-f86c-4501-9b03-dcad528c7f6f.jpeg)
## LocalCache 和 ConcurrentMap的区别
|  | 功能 | 特性 | 底层实现 |
| --- | --- | --- | --- |
| LocalCache | 缓存 | 1. 缓存过期 2. 自动加载 3. 并发控制 4. 命中率统计| 显式Segment分段锁机制加锁 |
| ConcurrentMap | 并发k-v存储 | 1. 并发控制| CAS+ synchronized 对node节点加锁 |
