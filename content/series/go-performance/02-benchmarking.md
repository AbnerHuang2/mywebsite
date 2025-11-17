---
title: "第2章：基准测试（Benchmarking）"
description: "学习如何正确编写和运行Go基准测试，避免常见陷阱，准确测量代码性能"
date: 2024-11-17
series: ["Go高性能编程"]
series_order: 2
tags:
  - Go
  - 性能优化
  - 基准测试
  - testing
categories:
  - Go
---

<meta name="referrer" content="no-referrer" />

> 测量两次，切割一次。 — 古老的谚语

在我们尝试提高一段代码的性能之前，首先我们必须知道它当前的性能。

本节重点介绍如何使用Go testing框架构建有用的基准测试，并提供避免陷阱的实用技巧。

## 2.1 基准测试的基本规则

在开始编写基准测试之前，你需要有一个安静稳定的环境来运行测试。

### 不要在共享硬件上运行基准测试

不要在共享硬件上运行基准测试，不要在运行基准测试时浏览网页或播放音乐。

### 注意功耗管理和热伸缩（thermal scaling）

确保机器处于空闲状态——不要在运行基准测试时运行系统更新，不要在笔记本电脑上使用电池运行基准测试，确保笔记本电脑已完全充电并插上电源。

如果你在运行基准测试时遇到不一致的结果，可能是由于热伸缩（thermal scaling）导致机器变热并降频。有一些工具可以让你降低机器的最大时钟速度以获得一致的结果（<https://github.com/aclements/perflock>）。

### 注意虚拟化和云基础设施

如果使用虚拟机或云基础设施，请注意虚拟化管理程序（hypervisor）的影响。

### 运行足够长的时间以获得准确的结果

基准测试必须运行足够长的时间才能准确。微基准测试（micro-benchmarks）<1µs尤其难以进行准确测试。提高基准测试运行时间以产生更一致的结果：

```bash
go test -bench=. -benchtime=10s
```

### 多次运行以消除噪音

基准测试受到系统上其他进程的调度、CPU热伸缩以及现代CPU上的各种超线程效果的影响。

多次运行基准测试并取平均值可以帮助消除这些因素的影响：

```bash
go test -bench=. -count=10
```

## 2.2 使用testing包进行基准测试

`testing`包内置了对编写基准测试的支持。如果我们有一个简单的函数：

```go
func Fib(n int) int {
    if n < 2 {
        return n
    }
    return Fib(n-1) + Fib(n-2)
}
```

则该函数的基准测试如下：

```go
func BenchmarkFib20(b *testing.B) {
    for n := 0; n < b.N; n++ {
        Fib(20)  // 运行Fib(20) b.N次
    }
}
```

**基准测试的规则：**
- 基准测试函数以`Benchmark`开头
- 基准测试函数接受一个`*testing.B`参数
- 基准测试循环必须运行`b.N`次
  - `b.N`的值由测试框架自动调整
  - 框架会调整`b.N`直到基准测试运行足够长时间（默认1秒）

### 运行基准测试

使用`go test`的`-bench`标志运行基准测试：

```bash
# 运行当前包中的所有基准测试
go test -bench=.

# 运行匹配特定模式的基准测试
go test -bench=Fib

# 运行包中的所有基准测试，匹配Fib
go test -bench=Fib .
```

**注意：**
- 默认情况下，`go test`会运行单元测试然后运行基准测试
- 要只运行基准测试而跳过单元测试，使用`-run`标志并提供一个不匹配任何测试的模式：

```bash
go test -run=^$ -bench=.
```

### 基准测试输出解读

运行基准测试会产生类似这样的输出：

```
BenchmarkFib20-8         500      2837849 ns/op
```

**输出解释：**
- `BenchmarkFib20-8`：基准测试名称
  - `8`：`GOMAXPROCS`的值（可用的CPU核心数）
- `500`：循环运行了500次（`b.N`的值）
- `2837849 ns/op`：每次操作平均耗时2,837,849纳秒（约2.8毫秒）

### 提高基准测试准确性

**使用`-benchtime`标志：**

```bash
# 运行更长时间以提高准确性
go test -bench=. -benchtime=10s

# 或指定固定的迭代次数
go test -bench=. -benchtime=20x
```

### 比较不同输入的基准测试

让我们比较`Fib(1)`、`Fib(10)`和`Fib(20)`的性能：

```go
func BenchmarkFib1(b *testing.B) {
    for n := 0; n < b.N; n++ {
        Fib(1)
    }
}

func BenchmarkFib10(b *testing.B) {
    for n := 0; n < b.N; n++ {
        Fib(10)
    }
}

func BenchmarkFib20(b *testing.B) {
    for n := 0; n < b.N; n++ {
        Fib(20)
    }
}
```

运行结果：

```bash
$ go test -bench=.
BenchmarkFib1-8     1000000000      2.06 ns/op
BenchmarkFib10-8      5000000       338 ns/op
BenchmarkFib20-8         500      2837849 ns/op
```

**观察：**
- `Fib(1)`非常快，只需2纳秒
- `Fib(10)`需要338纳秒
- `Fib(20)`需要约2.8毫秒
- 递归算法的性能随输入呈指数增长

## 2.3 使用benchstat比较基准测试

在上一节中，我们看到单次基准测试运行受到功率管理、后台进程和热管理的影响。

对于一组基准测试，问题更加严重，当值变化时，很难判断基准测试的结果是真实的还是误差范围内的变化。

### 安装benchstat

```bash
go install golang.org/x/perf/cmd/benchstat@latest
```

### 使用benchstat

Benchstat 可以获取一组基准测试运行并告诉你它们的稳定性。这是一个示例：

```bash
# 运行基准测试10次并保存结果
go test -bench=Fib20 -count=10 > old.txt
```

假设我们对代码进行了优化，现在想看看改进了多少：

```bash
# 再次运行基准测试10次
go test -bench=Fib20 -count=10 > new.txt

# 使用benchstat比较
benchstat old.txt new.txt
```

**benchstat输出：**

```
name     old time/op  new time/op  delta
Fib20-8  2.83ms ± 1%  1.71ms ± 3%  -39.43%  (p=0.000 n=10+10)
```

**输出解释：**
- `old time/op`：优化前的平均时间
- `new time/op`：优化后的平均时间
- `±1%`：标准差（结果的变化范围）
- `-39.43%`：性能提升了39.43%
- `(p=0.000 n=10+10)`：
  - `p=0.000`：p值，非常接近0表示差异显著
  - `n=10+10`：每组运行了10次

**p值的含义：**
- `p < 0.05`：差异统计上显著（95%置信度）
- `p < 0.01`：差异非常显著（99%置信度）
- `p > 0.05`：差异可能只是噪音

Benchstat还会报告在样本之间**未检测到**性能变化：

```
name     old time/op  new time/op  delta
Fib20-8  2.83ms ± 1%  2.82ms ± 2%   ~     (p=0.190 n=10+10)
```

`~`表示benchstat无法确定新旧样本之间是否存在性能变化。

**建议：**
- 在进行任何优化之前，先运行基准测试并保存结果
- 进行优化后，再次运行并使用benchstat比较
- 只有当benchstat显示显著差异时，才认为优化有效

## 2.4 避免基准测试的启动成本

有时你的基准测试有一次性设置逻辑，你不想包含在基准测试的时间中：

```go
func BenchmarkExpensive(b *testing.B) {
    // 昂贵的设置
    boringAndExpensiveSetup()
    
    b.ResetTimer()  // 重置计时器
    
    for n := 0; n < b.N; n++ {
        // 要测试的函数
        thing()
    }
}
```

**`b.ResetTimer()`** 会重置基准测试时钟，排除设置时间。

### 如果设置逻辑在循环内部

如果你的基准测试的设置逻辑在`for`循环内部，使用`b.StopTimer()`和`b.StartTimer()`来暂停基准测试计时器：

```go
func BenchmarkComplicated(b *testing.B) {
    for n := 0; n < b.N; n++ {
        b.StopTimer()  // 暂停计时
        complicatedSetup()
        b.StartTimer()  // 继续计时
        
        // 要测试的函数
        thing()
    }
}
```

**注意：** 过度使用`StopTimer`和`StartTimer`会影响基准测试的准确性。尽量在循环外部进行设置。

## 2.5 基准测试内存分配

分配（allocations）计数和大小与基准测试时间密切相关。

你可以告诉`testing`框架记录被测试代码的分配统计信息：

```bash
go test -bench=. -benchmem
```

**示例：**

```go
func BenchmarkRead(b *testing.B) {
    b.ReportAllocs()  // 或者在命令行使用-benchmem
    for n := 0; n < b.N; n++ {
        // 要测试的代码
    }
}
```

**输出：**

```
BenchmarkRead-8   500000   3557 ns/op   800 B/op   6 allocs/op
```

**输出解释：**
- `3557 ns/op`：每次操作耗时
- `800 B/op`：每次操作分配的字节数
- `6 allocs/op`：每次操作的分配次数

### 为什么关注分配？

1. **分配本身需要时间**
2. **增加GC压力**
3. **影响缓存性能**

减少分配通常是提高性能的有效方法。

### 示例：预分配slice

```go
func WithoutPrealloc(size int) []int {
    var s []int
    for i := 0; i < size; i++ {
        s = append(s, i)
    }
    return s
}

func WithPrealloc(size int) []int {
    s := make([]int, 0, size)  // 预分配容量
    for i := 0; i < size; i++ {
        s = append(s, i)
    }
    return s
}

func BenchmarkWithoutPrealloc(b *testing.B) {
    for n := 0; n < b.N; n++ {
        WithoutPrealloc(1000)
    }
}

func BenchmarkWithPrealloc(b *testing.B) {
    for n := 0; n < b.N; n++ {
        WithPrealloc(1000)
    }
}
```

运行：

```bash
$ go test -bench=. -benchmem
BenchmarkWithoutPrealloc-8   50000   32420 ns/op   57344 B/op  11 allocs/op
BenchmarkWithPrealloc-8     100000   16580 ns/op    8192 B/op   1 allocs/op
```

**结果分析：**
- 预分配快了约2倍
- 预分配使用的内存少了86%
- 预分配的分配次数从11次减少到1次

## 2.6 注意编译器优化

这个例子来自issue [#14813](https://github.com/golang/go/issues/14813)：

```go
const m1 = 0x5555555555555555
const m2 = 0x3333333333333333
const m4 = 0x0f0f0f0f0f0f0f0f
const h01 = 0x0101010101010101

func popcnt(x uint64) uint64 {
    x -= (x >> 1) & m1
    x = (x & m2) + ((x >> 2) & m2)
    x = (x + (x >> 4)) & m4
    return (x * h01) >> 56
}

func BenchmarkPopcnt(b *testing.B) {
    for i := 0; i < b.N; i++ {
        popcnt(uint64(i))
    }
}
```

**问题：** 运行这个基准测试会显示它非常快，但可能是因为编译器优化掉了循环体。

### 解决方案：将结果赋值给包级变量

```go
var result uint64

func BenchmarkPopcnt(b *testing.B) {
    var r uint64
    for i := 0; i < b.N; i++ {
        r = popcnt(uint64(i))
    }
    result = r  // 确保编译器不会优化掉循环
}
```

**为什么这样有效：**
- 编译器必须假设`result`会被其他地方读取
- 因此不能优化掉`popcnt`的调用

### 更好的方式：使用testing.B的API

从Go 1.4开始，`testing`包提供了`b.SetBytes(n int64)`来记录每次操作处理的字节数。

虽然这主要用于IO基准测试，但也可以防止编译器优化：

```go
func BenchmarkPopcnt(b *testing.B) {
    for i := 0; i < b.N; i++ {
        x := popcnt(uint64(i))
        _ = x  // 明确表示我们使用了结果
    }
}
```

## 2.7 基准测试常见错误

### 错误1：在循环内做设置工作

```go
// ❌ 错误：每次迭代都重新创建数据
func BenchmarkBad(b *testing.B) {
    for n := 0; n < b.N; n++ {
        data := make([]int, 10000)  // 设置工作
        for i := range data {
            data[i] = i
        }
        processData(data)  // 实际要测试的代码
    }
}

// ✅ 正确：在循环外准备数据
func BenchmarkGood(b *testing.B) {
    data := make([]int, 10000)
    for i := range data {
        data[i] = i
    }
    b.ResetTimer()
    
    for n := 0; n < b.N; n++ {
        processData(data)
    }
}
```

### 错误2：测试环境不稳定

```go
// ❌ 问题：
// - 后台程序运行
// - CPU频率动态变化
// - 只运行一次

// ✅ 解决：
// - 关闭不必要的程序
// - 固定CPU频率
// - 多次运行
go test -bench=. -count=10 -benchmem
```

### 错误3：忽略内存分配

```go
// ❌ 只看时间，忽略分配
go test -bench=.

// ✅ 同时看时间和分配
go test -bench=. -benchmem
```

### 错误4：只运行一次基准测试

```go
// ❌ 单次运行结果不可靠
go test -bench=.

// ✅ 多次运行，使用benchstat
go test -bench=. -count=10 > old.txt
# 修改代码...
go test -bench=. -count=10 > new.txt
benchstat old.txt new.txt
```

## 2.8 从基准测试进行性能剖析

`testing`包内置了对生成CPU、内存和block profiling的支持。

### 生成CPU profile

```bash
go test -bench=. -cpuprofile=cpu.out
```

### 生成内存profile

```bash
go test -bench=. -memprofile=mem.out
```

### 生成block profile

```bash
go test -bench=. -blockprofile=block.out
```

### 分析profile

```bash
# 交互式分析CPU profile
go tool pprof cpu.out

# 在浏览器中查看
go tool pprof -http=:8080 cpu.out
```

**注意：** 一次只使用一个profile标志。

我们将在下一章详细讨论pprof。

## 2.9 讨论

**问题：**

1. **问：** 基准测试的`b.N`是如何确定的？
   
   **答：** `testing`包会自动调整`b.N`，使基准测试运行至少1秒（或`-benchtime`指定的时间）。它从`b.N=1`开始，如果运行得太快，就增加`b.N`并重新运行。

2. **问：** 为什么我的基准测试结果每次都不一样？
   
   **答：** 基准测试受到很多因素影响：系统负载、CPU频率缩放、缓存状态等。使用`-count`多次运行并用`benchstat`分析。

3. **问：** 我应该在CI中运行基准测试吗？
   
   **答：** 可以，但要小心。CI环境通常是虚拟化的，结果可能不稳定。考虑：
   - 使用专用的基准测试服务器
   - 只检查是否有显著的性能退化（>10%）
   - 使用工具如<https://pkg.go.dev/golang.org/x/perf/cmd/benchstat>

4. **问：** 基准测试够准确吗？需要用专业工具吗？
   
   **答：** 对于大多数情况，Go的基准测试工具已经足够。如果需要更深入的分析，可以使用：
   - `perf`（Linux）
   - `Instruments`（macOS）
   - `Intel VTune`

---

**系列导航：**
- 上一章：[第1章：微处理器性能的过去、现在与未来](/series/go-performance/01-microprocessor-performance/)
- 下一章：第3章：性能测量和剖析（待完成）
- 返回：[系列目录](/series/go-performance/)

## 参考资料

- [High Performance Go Workshop - Benchmarking](https://dave.cheney.net/high-performance-go-workshop/dotgo-paris.html#benchmarking)
- [Go Testing Package](https://pkg.go.dev/testing)
- [Benchstat Tool](https://pkg.go.dev/golang.org/x/perf/cmd/benchstat)
- [How to Write Benchmarks in Go - Dave Cheney](https://dave.cheney.net/2013/06/30/how-to-write-benchmarks-in-go)

