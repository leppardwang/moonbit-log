///|
test "Level::to_int" {
  inspect(Level::Debug.to_int(), content="0")
  inspect(Level::Info.to_int(), content="1")
  inspect(Level::Warn.to_int(), content="2")
  inspect(Level::Error.to_int(), content="3")
  inspect(Level::Fatal.to_int(), content="4")
}

///|
test "Level::to_string" {
  inspect(Level::Debug.to_string(), content="DEBUG")
  inspect(Level::Info.to_string(), content="INFO")
  inspect(Level::Warn.to_string(), content="WARN")
  inspect(Level::Error.to_string(), content="ERROR")
  inspect(Level::Fatal.to_string(), content="FATAL")
}

///|
test "Level::from_string" {
  inspect(Level::from_string("DEBUG"), content="DEBUG")
  inspect(Level::from_string("info"), content="INFO")
  inspect(Level::from_string("WARN"), content="WARN")
}

///|
test "Level::enabled" {
  inspect(Level::Debug.enabled(Level::Debug), content="true")
  inspect(Level::Debug.enabled(Level::Info), content="false")
  inspect(Level::Error.enabled(Level::Debug), content="true")
  inspect(Level::Error.enabled(Level::Error), content="true")
  inspect(Level::Error.enabled(Level::Fatal), content="false")
}

///|
test "Level::all" {
  let all = Level::all()
  inspect(all.length(), content="5")
  inspect(all[0].to_string(), content="DEBUG")
}

///|
test "Level::min_max" {
  inspect(Level::min(Level::Debug, Level::Error).to_string(), content="DEBUG")
  inspect(Level::max(Level::Debug, Level::Error).to_string(), content="ERROR")
}

///|
test "LogEntryBuilder::basic" {
  let entry = LogEntryBuilder::new(Level::Info, "hello").build()
  inspect(entry.level().to_string(), content="INFO")
  inspect(entry.message(), content="hello")
}

///|
test "LogEntryBuilder::with_module" {
  let entry = LogEntryBuilder::new(Level::Warn, "test")
    .with_module("auth")
    .build()
  inspect(entry.module_name(), content="auth")
}

///|
test "LogEntryBuilder::with_field" {
  let entry = LogEntryBuilder::new(Level::Error, "err")
    .with_field("user_id", "42")
    .with_field("action", "login")
    .build()
  let fs = entry.fields()
  inspect(fs.length(), content="2")
  let (k1, v1) = fs[0]
  inspect(k1, content="user_id")
  inspect(v1, content="42")
}

///|
test "LogEntryBuilder::with_location" {
  let entry = LogEntryBuilder::new(Level::Debug, "loc")
    .with_location("main.mbt", 42)
    .build()
  inspect(entry.location_file(), content="main.mbt")
  inspect(entry.location_line(), content="42")
}

///|
test "LogEntryBuilder::with_sequence" {
  let entry = LogEntryBuilder::new(Level::Info, "seq")
    .with_sequence(99L)
    .build()
  inspect(entry.sequence(), content="99")
}

///|
test "text_formatter output" {
  let fmt = text_formatter()
  let entry = LogEntryBuilder::new(Level::Info, "hello")
    .with_module("test")
    .with_field("key", "val")
    .build()
  let line = fmt(entry)
  inspect(line.contains("INFO"), content="true")
  inspect(line.contains("hello"), content="true")
  inspect(line.contains("test"), content="true")
  inspect(line.contains("key=val"), content="true")
}

///|
test "compact_formatter output" {
  let fmt = compact_formatter()
  let entry = LogEntryBuilder::new(Level::Warn, "short").build()
  let line = fmt(entry)
  inspect(line.contains("WARN"), content="true")
  inspect(line.contains("short"), content="true")
}

///|
test "json_formatter output" {
  let fmt = json_formatter()
  let entry = LogEntryBuilder::new(Level::Error, "json_test")
    .with_field("code", "500")
    .build()
  let line = fmt(entry)
  inspect(line.contains("ERROR"), content="true")
  inspect(line.contains("json_test"), content="true")
  inspect(line.contains("\"fields\""), content="true")
}

///|
test "audit_formatter output" {
  let fmt = audit_formatter("|")
  let entry = LogEntryBuilder::new(Level::Fatal, "audit_event")
    .with_module("security")
    .with_location("log.mbt", 10)
    .build()
  let line = fmt(entry)
  inspect(line.contains("|FATAL|"), content="true")
  inspect(line.contains("|security|"), content="true")
  inspect(line.contains("audit_event"), content="true")
}

///|
test "custom_formatter" {
  let fmt = custom_formatter(fn(e : LogEntry) -> String {
    "CUSTOM: " + e.message()
  })
  let entry = LogEntryBuilder::new(Level::Info, "custom").build()
  let line = fmt(entry)
  inspect(line, content="CUSTOM: custom")
}

///|
test "ConsoleHandler filters by level" {
  let fmt = compact_formatter()
  let h = ConsoleHandler::new(Level::Error, fmt)
  let e1 = LogEntryBuilder::new(Level::Debug, "debug").build()
  let e2 = LogEntryBuilder::new(Level::Error, "error").build()
  h.log(e1)
  h.log(e2)
}

///|
test "MemoryHandler records entries" {
  let fmt = compact_formatter()
  let h = MemoryHandler::new(Level::Debug, fmt)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  h.log(LogEntryBuilder::new(Level::Warn, "b").build())
  inspect(h.count(), content="2")
  let last = h.last_entry()
  inspect(last is Some(_), content="true")
}

///|
test "MemoryHandler count_by_level" {
  let fmt = compact_formatter()
  let h = MemoryHandler::new(Level::Debug, fmt)
  h.log(LogEntryBuilder::new(Level::Info, "i1").build())
  h.log(LogEntryBuilder::new(Level::Info, "i2").build())
  h.log(LogEntryBuilder::new(Level::Error, "e1").build())
  inspect(h.count_by_level(Level::Info), content="2")
  inspect(h.count_by_level(Level::Error), content="1")
}

///|
test "MemoryHandler clear" {
  let fmt = compact_formatter()
  let h = MemoryHandler::new(Level::Debug, fmt)
  h.log(LogEntryBuilder::new(Level::Info, "x").build())
  inspect(h.count(), content="1")
  h.clear()
  inspect(h.count(), content="0")
}

///|
test "FileHandler buffers and flushes" {
  let fmt = compact_formatter()
  let h = FileHandler::new(Level::Debug, fmt, 3)
  h.log(LogEntryBuilder::new(Level::Info, "m1").build())
  h.log(LogEntryBuilder::new(Level::Info, "m2").build())
  inspect(h.lines().length(), content="2")
  h.log(LogEntryBuilder::new(Level::Info, "m3").build())
  inspect(h.lines().length(), content="0")
}

///|
test "AuditHandler stores and filters" {
  let fmt = audit_formatter("|")
  let h = AuditHandler::new(Level::Debug, fmt, 100)
  h.log(
    LogEntryBuilder::new(Level::Info, "login_ok")
    .with_module("auth")
    .with_field("user", "alice")
    .build(),
  )
  h.log(
    LogEntryBuilder::new(Level::Warn, "login_fail")
    .with_module("auth")
    .with_field("user", "bob")
    .build(),
  )
  h.log(
    LogEntryBuilder::new(Level::Info, "data_access").with_module("data").build(),
  )
  inspect(h.entries().length(), content="3")
  let filtered = h.filter_by_level(Level::Info)
  inspect(filtered.length(), content="2")
  let mod_search = h.search_by_module("auth")
  inspect(mod_search.length(), content="2")
  let msg_search = h.search_by_message("login")
  inspect(msg_search.length(), content="2")
}

///|
test "Logger basic logging" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let logger = Logger::new()
  logger.add_handler(
    make_handler(fn(e) { mem.log(e) }, fn() { mem.flush() }, fn() {
      mem.close()
    }),
  )
  logger.debug("debug msg")
  logger.info("info msg")
  logger.warn("warn msg")
  logger.error("error msg")
  inspect(mem.count(), content="4")
}

///|
test "Logger level filtering" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Error, fmt)
  let logger = Logger::new().with_level(Level::Error)
  logger.add_handler(
    make_handler(fn(e) { mem.log(e) }, fn() { mem.flush() }, fn() {
      mem.close()
    }),
  )
  logger.debug("should not appear")
  logger.info("should not appear")
  logger.warn("should not appear")
  logger.error("should appear")
  logger.fatal("should appear")
  inspect(mem.count(), content="2")
}

///|
test "Logger log_with fields" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let logger = Logger::new()
  logger.add_handler(
    make_handler(fn(e) { mem.log(e) }, fn() { mem.flush() }, fn() {
      mem.close()
    }),
  )
  logger.log_with(Level::Info, "with fields", [("k1", "v1"), ("k2", "v2")])
  inspect(mem.count(), content="1")
}

///|
test "LogEntry accessors" {
  let entry = LogEntryBuilder::new(Level::Info, "acc")
    .with_module("mod")
    .with_field("f", "v")
    .with_location("f.mbt", 5)
    .with_thread(1)
    .with_sequence(7L)
    .build()
  inspect(entry.level().to_int(), content="1")
  inspect(entry.message(), content="acc")
  inspect(entry.module_name(), content="mod")
  inspect(entry.fields().length(), content="1")
  inspect(entry.location_file(), content="f.mbt")
  inspect(entry.location_line(), content="5")
  inspect(entry.thread_id(), content="1")
  inspect(entry.sequence(), content="7")
}

///|
test "Stopwatch basic" {
  let sw = Stopwatch::new()
  sw.start()
  let mut acc = 0
  let mut i = 0
  while i < 1000 {
    acc = acc + 1
    i = i + 1
  }
  ignore(acc)
  sw.stop()
  let elapsed = sw.elapsed_micros()
  inspect(elapsed > 0.0, content="true")
}

///|
test "Stopwatch reset" {
  let sw = Stopwatch::new()
  sw.start()
  sw.stop()
  sw.reset()
  inspect(sw.elapsed_micros(), content="0")
}

///|
test "Stopwatch restart" {
  let sw = Stopwatch::new()
  sw.start()
  sw.stop()
  sw.restart()
  inspect(sw.is_running(), content="true")
  sw.stop()
}

///|
test "Stopwatch units" {
  let sw = Stopwatch::new()
  sw.start()
  sw.stop()
  let us = sw.elapsed_micros()
  let ms = sw.elapsed_millis()
  inspect(ms <= us, content="true")
}

///|
test "benchmark runs function" {
  let r = benchmark("empty", 5, fn() {  })
  inspect(r.iterations(), content="5")
  inspect(r.total_time_us() > 0.0, content="true")
}

///|
test "benchmark report format" {
  let r = benchmark("test", 1, fn() {  })
  let report = benchmark_report(r)
  inspect(report.contains("Benchmark: test"), content="true")
  inspect(report.contains("Iterations:"), content="true")
}

///|
test "MultiHandler dispatches" {
  let fmt = compact_formatter()
  let mem1 = MemoryHandler::new(Level::Debug, fmt)
  let mem2 = MemoryHandler::new(Level::Debug, fmt)
  let multi = MultiHandler::new()
  multi.add(make_handler(fn(e) { mem1.log(e) }, fn() {  }, fn() {  }))
  multi.add(make_handler(fn(e) { mem2.log(e) }, fn() {  }, fn() {  }))
  multi.log(LogEntryBuilder::new(Level::Info, "multi").build())
  inspect(mem1.count(), content="1")
  inspect(mem2.count(), content="1")
}

///|
test "AuditHandler search_by_message" {
  let fmt = audit_formatter("|")
  let h = AuditHandler::new(Level::Debug, fmt, 100)
  h.log(LogEntryBuilder::new(Level::Info, "user login success").build())
  h.log(LogEntryBuilder::new(Level::Warn, "user login failed").build())
  h.log(LogEntryBuilder::new(Level::Info, "data exported").build())
  let r1 = h.search_by_message("login")
  inspect(r1.length(), content="2")
  let r2 = h.search_by_message("exported")
  inspect(r2.length(), content="1")
  let r3 = h.search_by_message("nonexistent")
  inspect(r3.length(), content="0")
}

///|
test "LogEntryBuilder::with_sequence idempotent" {
  let e1 = LogEntryBuilder::new(Level::Info, "a").with_sequence(1L).build()
  let e2 = LogEntryBuilder::new(Level::Info, "b").with_sequence(1L).build()
  inspect(e1.sequence(), content="1")
  inspect(e2.sequence(), content="1")
}

///|
test "Logger with multiple handlers" {
  let fmt = compact_formatter()
  let mem1 = MemoryHandler::new(Level::Debug, fmt)
  let mem2 = MemoryHandler::new(Level::Debug, fmt)
  let logger = Logger::new()
  logger.add_handler(make_handler(fn(e) { mem1.log(e) }, fn() {  }, fn() {  }))
  logger.add_handler(make_handler(fn(e) { mem2.log(e) }, fn() {  }, fn() {  }))
  logger.info("broadcast")
  inspect(mem1.count(), content="1")
  inspect(mem2.count(), content="1")
}

///|
test "Flush and close handlers" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let logger = Logger::new()
  logger.add_handler(make_handler(fn(e) { mem.log(e) }, fn() {  }, fn() {  }))
  logger.flush()
  logger.close()
  inspect(mem.count(), content="0")
}

///|
test "Level::Eq comparison" {
  inspect(Level::Debug == Level::Debug, content="true")
  inspect(Level::Debug == Level::Info, content="false")
  inspect(Level::Error != Level::Warn, content="true")
}

///|
test "Level::Show display" {
  let s = Level::Debug.to_string()
  inspect(s, content="DEBUG")
}
