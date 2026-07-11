# moonbit-log

结构化日志库 — CCF OSC2026 MoonBit 赛道参赛作品

[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![MoonBit](https://img.shields.io/badge/MoonBit-latest-orange)](https://www.moonbitlang.com/)

## Project Status

- CCF OSC2026 MoonBit 赛道参赛项目
- `moon check --deny-warn` 通过
- `moon test` 163/163 通过
- 代码规模: 4,100+ 行 MoonBit 源码
- 零外部依赖，仅使用 MoonBit 标准库

## Features

### 日志级别 (6)
Debug, Info, Warn, Error, Fatal, Audit

### 处理器 (21)

| 类型 | 处理器 | 说明 |
|------|--------|------|
| 输出 | ConsoleHandler | 控制台输出（支持 stdout/stderr 切换） |
| 输出 | FileHandler | 缓冲批量输出，自动 flush |
| 输出 | JsonHandler | JSON 格式输出 |
| 输出 | TextHandler | 带前缀的文本输出 |
| 输出 | RotatingFileHandler | 按大小/文件数自动轮转 |
| 存储 | MemoryHandler | 内存存储，支持检索/统计 |
| 存储 | AuditHandler | 审计日志，支持过滤/搜索/导出 |
| 存储 | RingBufferHandler | 环形缓冲区，支持 drain |
| 控制 | SamplingHandler | 采样（1/N 比例） |
| 控制 | DedupHandler | 去重（基于消息哈希） |
| 控制 | RateLimitedHandler | 速率限制（时间窗口） |
| 控制 | ThrottledHandler | 节流（最小间隔） |
| 控制 | LevelFilteredHandler | 级别过滤 |
| 条件 | ConditionHandler | 条件谓词过滤 |
| 统计 | CountingHandler | 按级别计数统计 |
| 空操作 | NullHandler | 丢弃所有日志 |
| 组合 | MultiHandler | 多处理器路由分发 |
| 函数式 | HandlerFn | 闭包包装器 |
| 异步 | AsyncLogger | 批量队列异步日志 |
| 转换 | EntryTransformer | 日志条目转换器 |
| 异步 | BatchingLogger | 超时+批量双触发 flush |

### 格式器 (14)
text, compact, json, audit(分隔符), logfmt, xml, pretty(ANSI彩色), kv(key=value), banner(横幅), csv, pattern(模式), stats(统计), multi_line(缩进), custom(自定义)

### 性能工具
- **Stopwatch**: 微秒/毫秒/秒计时
- **Benchmark**: 重复执行基准测试，自动计算均值/标准差/吞吐量
- **ThroughputMeter**: 滑动窗口吞吐量测量

### 配置系统
- `LogConfig` + Builder 模式 + 工厂方法
- 代码/JSON 双模式配置
- 按名称选择 handler(format)/output 组合

### 全局 Logger
`g_debug` / `g_info` / `g_warn` / `g_error` / `g_fatal` / `g_log` / `g_log_with`
`init_default_console()` / `init_default_json()`

## Build & Test

```bash
# 编译检查（零警告）
moon check --target all --deny-warn

# 运行全部 163 个测试
moon test --target all

# 格式化代码
moon fmt

# 构建 WASM-GC
moon build --target wasm-gc --release

# 构建 JS
moon build --target js --release
```

## Quick Start

在 `moon.pkg` 中添加依赖:

```
import {
  "leppard/moonbit-log" @log
}
```

在 `moon.mod` 中添加:

```toml
[deps]
leppard/moonbit-log = { version = "1.0.0" }
```

### 基本使用

```moonbit
fn main {
  @log.init_default_console()
  @log.g_info("Hello, moonbit-log!")
  @log.g_info("User login", [("user_id", "42"), ("ip", "10.0.0.1")])
}
```

### JSON 日志

```moonbit
@log.init_default_json()
@log.g_info("Order created", [
  ("order_id", "ORD-001"),
  ("amount", "299.00"),
  ("currency", "CNY")
])
```

### 审计日志

```moonbit
let fmt = @log.audit_formatter("|")
let audit = @log.AuditHandler::new(@log.Level::Info, fmt, 100)
let logger = @log.Logger::new()
logger.add_handler(@log.make_handler(fn(e) { audit.log(e) }, fn() {}, fn() {}))
logger.log_with(@log.Level::Info, "数据导出", [("user", "admin"), ("records", "1000")])
println(audit.entries().length())
```

### 文件/缓冲输出

```moonbit
let handler = @log.FileHandler::new(
  @log.Level::Info,
  @log.json_formatter(),
  100
)
let logger = @log.Logger::new()
logger.add_handler(@log.make_handler(fn(e) { handler.log(e) }, fn() { handler.flush() }, fn() { handler.close() }))
logger.info("写入缓冲")
```

### 文件轮转

```moonbit
let handler = @log.RotatingFileHandler::new(
  @log.Level::Info,
  @log.text_formatter(),
  10,
  5
)
let logger = @log.Logger::new()
logger.add_handler(@log.make_handler(fn(e) { handler.log(e) }, fn() { handler.flush() }, fn() { handler.close() }))
// 超过 10 行自动轮转，保留 5 个历史文件
```

### 异步批处理

```moonbit
let handler = @log.ConsoleHandler::new(@log.Level::Debug, @log.compact_formatter())
let batch = @log.AsyncLogger::new(
  @log.make_handler(fn(e) { handler.log(e) }, fn() { handler.flush() }, fn() { handler.close() }),
  64
)
batch.log(@log.LogEntryBuilder::new(@log.Level::Info, "异步消息").build())
batch.flush()
```

### 性能基准

```moonbit
let r = @log.benchmark("计算测试", 1000, fn() {
  let mut x = 0
  x = x + 1
  @log.ignore(x)
})
println(@log.benchmark_report(r))
```

### 配置系统

```moonbit
@log.configure(
  level: @log.Level::Debug,
  format: "compact",
  output: "console"
)
@log.g_debug("配置已生效")
```

## API Reference

### Logger

| 方法 | 签名 | 说明 |
|------|------|------|
| `new()` | `Logger` | 创建 Logger |
| `add_handler(HandlerFn)` | `Unit` | 添加处理器 |
| `debug/info/warn/error/fatal(msg, fields?)` | `Unit` | 按级别记录 |
| `log_with(Level, msg, fields?)` | `Unit` | 指定级别记录 |
| `set_level(Level)` | `Unit` | 设置最低级别 |

### Handler 通用接口

每个 Handler 实现三个方法:
- `log(self, LogEntry) -> Unit` — 记录日志条目
- `flush(self) -> Unit` — 刷新缓冲
- `close(self) -> Unit` — 关闭并释放资源

### Stopwatch

| 方法 | 返回 | 说明 |
|------|------|------|
| `new()` | `Stopwatch` | 创建并启动计时 |
| `elapsed_ms()` | `Int64` | 已过毫秒数 |
| `elapsed_us()` | `Int64` | 已过微秒数 |
| `elapsed_s()` | `Double` | 已过秒数 |
| `lap(msg)` | `Int64` | 记录分段并返回耗时(ms) |
| `reset()` | `Unit` | 重置计时 |
| `laps()` | `Array[(String, Int64)]` | 返回全部分段记录 |
| `report()` | `String` | 生成可读报告 |

### LogEntry

| 字段 | 类型 | 说明 |
|------|------|------|
| `level` | `Level` | 日志级别 |
| `message` | `String` | 日志消息 |
| `fields` | `Array[(String, String)]` | 键值对字段 |
| `timestamp` | `Int64` | Unix 时间戳(ms) |
| `module` | `String` | 模块名 |
| `file` | `String` | 源文件名 |
| `line` | `Int` | 行号 |

## Project Structure

```
moonbit-log/
├── logger.mbt              # Logger 核心
├── log_entry.mbt           # LogEntry / LogEntryBuilder
├── level.mbt               # Level 枚举 / enabled / from_string
├── handler.mbt             # HandlerFn 函数式 Handler
├── formatter.mbt           # text / compact / json / audit / custom
├── console_handler.mbt     # ConsoleHandler
├── file_handler.mbt        # FileHandler (缓冲批量输出)
├── json_handler.mbt        # JsonHandler
├── text_handler.mbt        # TextHandler (带前缀)
├── memory_handler.mbt      # MemoryHandler (内存存储+检索)
├── audit_handler.mbt       # AuditHandler (审计日志)
├── multi_handler.mbt       # MultiHandler (多路分发)
├── advanced_handlers.mbt   # RotatingFile / LevelFilter / Sampling / Dedup / RingBuffer / RateLimited
├── extra_handler_utils.mbt # Null / Condition / Throttled / Counting / kv / banner / csv
├── extra_formatters.mbt    # logfmt / xml / pretty(ANSI)
├── template_formatter.mbt  # pattern / stats / multi_line
├── async_logger.mbt        # AsyncLogger / BatchingLogger / EntryTransformer
├── config.mbt              # LogConfig + 工厂方法 + JSON 配置
├── global_logger.mbt       # 全局 Logger 单例
├── stopwatch.mbt           # Stopwatch / Benchmark / ThroughputMeter
├── entry_utils.mbt         # 条目工具函数
├── log_test.mbt            # 基础测试 (~50 用例)
├── extended_test.mbt       # 扩展测试 (~50 用例)
├── edge_case_test.mbt      # 边界情况测试 (~63 用例)
├── cmd/example/main.mbt    # CLI 示例
├── moon.mod                # 模块元数据
└── moon.pkg                # 包配置
```

## 竞品对比

| 维度 | xlog | MoonLogTrace | BitLogger | **moonbit-log** |
|------|------|-------------|-----------|-----------------|
| 发布日期 | 2025 | 2025 | 2025 | 2026 |
| 构建状态 | 失败 | 成功 | 成功 | 成功 |
| 零依赖 | - | + | - | + |
| 测试数 | ? | ? | ? | 163 |
| 审计日志 | - | - | - | + |
| 文件轮转 | - | - | - | + |
| 去重/限速 | - | - | - | + |
| 性能基准 | - | - | - | + |
| Span 追踪 | - | + | - | - |
| 代码规模 | ~500 | ~3k | ~1.5k | 4.1k |

## License

Apache-2.0

## 参赛信息

- 赛事: CCF 开源创新大赛 (OSC 2026) · MoonBit 赛道
- 命名空间: leppard/moonbit-log
- 仓库: https://gitlink.org.cn/leppard/moonbit-log
- 代码行数: 4,127
- 源文件: 24
- 测试用例: 163
