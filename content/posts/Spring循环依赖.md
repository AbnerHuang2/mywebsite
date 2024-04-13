---
title: Spring循环依赖
date: 2022-06-21
description: Spring循环依赖

categories:
- Spring
---
<meta name="referrer" content="no-referrer" />
<!-- more -->

## 什么是循环依赖
spring在初始化bean的过程中，内部属性依赖了其他容器内部的bean，如果被依赖的bean还没有被创建，就需要先去初始化被依赖的bean，如果被依赖的bean有依赖的原有bean，就会造成循环依赖。
### 举个例子
![image.png](https://cdn.nlark.com/yuque/0/2024/png/21760570/1712997766349-9058bcc3-1e54-40aa-90d4-3d1c7acd2ba8.png#averageHue=%23f7ede4&clientId=u8c1c37d7-243d-4&from=paste&height=258&id=u8b1ea2b8&originHeight=515&originWidth=840&originalType=binary&ratio=2&rotation=0&showTitle=false&size=93821&status=done&style=none&taskId=ubee1597b-5e70-41df-81e5-6a6d982d874&title=&width=420)
## 如何解决循环依赖
### 核心原理
提前暴露对象引用，具体来讲，**通过singletonObjectRegistry维护三级缓存，依次维护成品bean对象singletonObjects，半成品对象earlySingletonObjects，和工厂对象 singletonFactoryObjects（原有对象和aop对象的创建方式有所差异，具体体现在**AbstractAutowireCapableBeanFactory#getEarlyBeanReference**）**
### 源码分析
#### 获取单例对象
```java
public Object getSingleton(String beanName) {
    Object singletonObject = singletonObjects.get(beanName);
    if (null == singletonObject){
        // 从earlySingletonObjects中获取
        singletonObject = earlySingletonObjects.get(beanName);
        if (null == singletonObject){
            ObjectFactory<?> singletonFactory = singletonFactories.get(beanName);
            if (null != singletonFactory){
                singletonObject = singletonFactory.getObject();
                // 把三级缓存中的代理对象中的真实对象获取出来，放入二级缓存中
                earlySingletonObjects.put(beanName, singletonObject);
                singletonFactories.remove(beanName);
            }
        }
    }
    return singletonObject;
}
```
#### 添加单例对象
```java
protected void addSingletonFactory(String beanName, ObjectFactory<?> singletonFactory) {
    if (! this.singletonObjects.containsKey(beanName)) {
        this.singletonFactories.put(beanName, singletonFactory);
        // 为什么要从二级缓存中移除. 应该不存在bean还没创建，但是二级缓存中已经有了的情况
        this.earlySingletonObjects.remove(beanName);
    }
}
```
##### 添加时机
实例化bean之后，
添加工厂bean，工厂bean的处理逻辑，
如果是aop对象，工厂的getObject方法会获取代理对象，否则返回bean实例
![image.png](https://cdn.nlark.com/yuque/0/2024/png/21760570/1712998123840-6269c2a1-0711-49f5-9d6e-8d266fc2f1b9.png#averageHue=%23253238&clientId=u8c1c37d7-243d-4&from=paste&height=231&id=u717c9989&originHeight=462&originWidth=1692&originalType=binary&ratio=2&rotation=0&showTitle=false&size=102384&status=done&style=none&taskId=ua16528f4-30cd-4495-8098-d88f120265c&title=&width=846)
```java
private Object getEarlyBeanReference(String beanName, BeanDefinition beanDefinition, Object bean) {
    Object exposedObject = bean;
    for (BeanPostProcessor bp : getBeanPostProcessors()) {
        if (bp instanceof InstantiationAwareBeanPostProcessor) {
            //如果被aop代理了，返回代理对象
            exposedObject = ((InstantiationAwareBeanPostProcessor) bp).getEarlyBeanReference(exposedObject, beanName);
        }
    }
    return exposedObject;
}
```
## 为什么需要三级缓存
因为如果对象被aop代理了，对象的引用是会发送改变的。为了解决这个问题，引入了三级缓存的工厂对象缓存策略方式获取对象来解决引用变更问题。
具体代码见上述添加单例对象的过程。
## 总结

1. 回答问题思路
   1. 是什么
   2. 怎么解决
   3. 底层实现
2. 底层实现通过SingletonObjectRegistry维护三级缓存来解决. **成品bean对象singletonObjects，半成品对象earlySingletonObjects（主要是aop代理对象），和工厂对象 singletonFactoryObjects（原有创建对象）**
3. 三级缓存的工厂对象缓存策略方式获取对象解决aop代理对象导致的对象引用改变的问题

## 思考题
如果两个相互依赖的对象都经过了aop的操作。那还会不会存在循环依赖问题？