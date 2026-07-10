fn main {
  println("moonbit-log 示例应用")
  println("")
  basic_usage()
  json_logging()
  audit_logging()
  level_filtering()
  structured_logging()
  async_logging()
  benchmark_demo()
  println("所有示例执行完成")
}

fn basic_usage() -> Unit {
  println("[基本日志]")
  let fmt = @log.compact_formatter()
  let mem = @log.MemoryHandler::new(@log.Level::Debug, fmt)
  let logger = @log.Logger::new()
  logger.add_handler(@log.make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {}))
  logger.debug("debug消息")
  logger.info("info消息")
  logger.warn("warn消息")
  logger.error("error消息")
  let lines = mem.formatted_lines()
  for line in lines { println("  " + line) }
}

fn json_logging() -> Unit {
  println("[JSON日志]")
  let fmt = @log.json_formatter()
  let mem = @log.MemoryHandler::new(@log.Level::Debug, fmt)
  let logger = @log.Logger::new()
  logger.add_handler(@log.make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {}))
  logger.log_with(@log.Level::Info, "用户登录", [("user_id", "42"), ("ip", "192.168.1.1")])
  let lines = mem.formatted_lines()
  for line in lines { println("  " + line) }
}

fn audit_logging() -> Unit {
  println("[审计日志]")
  let fmt = @log.audit_formatter("|")
  let audit = @log.AuditHandler::new(@log.Level::Info, fmt, 100)
  let logger = @log.Logger::new()
  logger.add_handler(@log.make_handler(fn(e) { audit.log(e) }, fn() {}, fn() {}))
  logger.log_with(@log.Level::Info, "数据导出", [("user", "admin"), ("records", "1000")])
  logger.log_with(@log.Level::Warn, "登录失败", [("user", "unknown"), ("attempts", "3")])
  println("  审计条目: " + audit.entries().length().to_string())
  println("  警告级别: " + audit.filter_by_level(@log.Level::Warn).length().to_string())
}

fn level_filtering() -> Unit {
  println("[级别过滤]")
  let fmt = @log.compact_formatter()
  let mem = @log.MemoryHandler::new(@log.Level::Debug, fmt)
  let inner = @log.make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let filtered = @log.LevelFilteredHandler::new(inner, @log.Level::Warn, @log.Level::Error)
  filtered.log(@log.LogEntryBuilder::new(@log.Level::Debug, "调试").build())
  filtered.log(@log.LogEntryBuilder::new(@log.Level::Info, "信息").build())
  filtered.log(@log.LogEntryBuilder::new(@log.Level::Warn, "警告").build())
  filtered.log(@log.LogEntryBuilder::new(@log.Level::Error, "错误").build())
  println("  过滤后: " + mem.count().to_string() + " (期望2)")
}

fn structured_logging() -> Unit {
  println("[结构化日志]")
  let entry = @log.LogEntryBuilder::new(@log.Level::Info, "用户操作")
    .with_module("auth")
    .with_field("action", "login")
    .with_field("user", "alice")
    .with_location("main.mbt", 42)
    .build()
  println("  模块: " + entry.module_name())
  let masked = @log.mask_field(entry, "user")
  let user_val = @log.entry_get_field(masked, "user")
  match user_val {
    Some(v) => println("  脱敏user: " + v)
    None => ()
  }
  println("  JSON: " + @log.entry_to_json_string(entry))
}

fn async_logging() -> Unit {
  println("[批量日志]")
  let fmt = @log.compact_formatter()
  let mem = @log.MemoryHandler::new(@log.Level::Debug, fmt)
  let inner = @log.make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let batch = @log.AsyncLogger::new(inner, 3)
  batch.log(@log.LogEntryBuilder::new(@log.Level::Info, "消息1").build())
  batch.log(@log.LogEntryBuilder::new(@log.Level::Info, "消息2").build())
  println("  队列: " + batch.queue_size().to_string() + " (期望2)")
  batch.log(@log.LogEntryBuilder::new(@log.Level::Info, "消息3").build())
  println("  队列: " + batch.queue_size().to_string() + " (期望0)")
  println("  已处理: " + mem.count().to_string() + " (期望3)")
}

fn benchmark_demo() -> Unit {
  println("[性能基准]")
  let r = @log.benchmark("空函数", 100, fn() {
    let mut x = 0
    x = x + 1
    ignore(x)
  })
  println(@log.benchmark_report(r))
}