# moonbit-log

结构化日志库 - MoonBit CCF 开源创新大赛参赛作品

[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![MoonBit](https://img.shields.io/badge/MoonBit-latest-orange)](https://www.moonbitlang.com/)

## 特性

- **6 种日志级别**: Debug, Info, Warn, Error, Fatal, Audit
- **12+ 格式器**: text, compact, json, audit, logfmt, XML, pretty(ANSI 彩色), pattern, multi_line, kv, banner, CSV, stats
- **15 个 Handler**: Console, File, JSON, Text, Memory, Audit, RotatingFile, RingBuffer, Sampling, Dedup, RateLimited, Async, Throttled, Condition, Counting
- **Handler 包装器**: MultiHandler, HandlerFn, EntryTransformer
- **异步批处理**: AsyncLogger（批量队列 + 自动 flush）, BatchingLogger（超时+批量）
- **审计日志**: 存储、过滤、搜索
- **文件轮转**: 按大小/数量自动轮转
- **字段脱敏**: mask_field 保护敏感信息
- **性能工具**: Stopwatch (μs/ms/s), Benchmark, ThroughputMeter
- **配置系统**: LogConfig + 工厂方法 + JSON 配置解析
- **全局 Logger**: g_debug / g_info / g_warn / g_error / g_fatal
- **零依赖**: 仅使用 MoonBit 标准库
- **163 个测试覆盖**: 基础功能 + 扩展场景 + 边界情况

## 快速开始

### 创建项目

```bash
moon new my-app
cd my-app
```

### 添加依赖

在 `moon.pkg` 中添加：

```
import {
  "leppard/moonbit-log" @log
}
```

在 `moon.mod` 中添加：

```toml
[deps]
leppard/moonbit-log = { version = "1.0.0" }
```

### 基本使用

```moonbit
fn main {
  // 使用全局 Logger
  @log.init_default_console()
  @log.g_info("Hello, moonbit-log!")
  @log.g_info("User login", [("user_id", "42"), ("ip", "10.0.0.1")])

  // 自定义 Logger
  let fmt = @log.compact_formatter()
  let handler = @log.make_handler(
    fn(e) { println(@log.text_formatter()(e)) },
    fn() {},
    fn() {}
  )
  let logger = @log.Logger::new()
  logger.add_handler(handler)
  logger.info("Custom logger ready")
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
// 查询审计条目
println(audit.entries().length())  // 审计条目计数
```

### 文件日志

```moonbit
let handler = @log.FileHandler::new(
  "app.log",
  @log.Level::Info,
  @log.json_formatter()
)
let logger = @log.Logger::new()
logger.add_handler(@log.make_handler(fn(e) { handler.log(e) }, fn() {}, fn() {}))
logger.info("写入文件")
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
// 通过配置 Builder 构建
let logger = @log.build_logger(
  level: @log.Level::Info,
  format: "json",
  output: "console"
)
@log.configure(
  level: @log.Level::Debug,
  format: "compact",
  output: "console"
)
@log.g_debug("配置已生效")
```

## 文档

完整文档和 API 参考请查看 [docs/](docs/) 目录。

- [项目申报书](docs/declaration.pdf) - CCF 大赛参赛文档（含架构图）
- [架构图](docs/architecture.png) - 项目架构图

## 测试

```bash
moon test
```

当前 163 个测试全部通过。

## 许可证

Apache-2.0

## 参赛信息

- 赛事: CCF 开源创新大赛 · MoonBit 赛道
- 仓库: https://gitlink.org.cn/leppard/moonbit-log
- 代码行数: 4,127
- 源文件: 24
- 测试用例: 163