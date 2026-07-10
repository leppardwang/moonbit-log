test "Level::from_string case insensitive" {
  inspect(Level::from_string("debug"), content="DEBUG")
  inspect(Level::from_string("DEBUG"), content="DEBUG")
  inspect(Level::from_string("Debug"), content="DEBUG")
  inspect(Level::from_string("INFO"), content="INFO")
  inspect(Level::from_string("info"), content="INFO")
  inspect(Level::from_string("Warn"), content="WARN")
  inspect(Level::from_string("error"), content="ERROR")
  inspect(Level::from_string("FATAL"), content="FATAL")
}

test "Level::from_string unknown defaults to Debug" {
  inspect(Level::from_string("UNKNOWN"), content="DEBUG")
  inspect(Level::from_string(""), content="DEBUG")
}

test "Level ordering" {
  inspect(Level::Debug.to_int() < Level::Info.to_int(), content="true")
  inspect(Level::Info.to_int() < Level::Warn.to_int(), content="true")
  inspect(Level::Warn.to_int() < Level::Error.to_int(), content="true")
  inspect(Level::Error.to_int() < Level::Fatal.to_int(), content="true")
}

test "LogEntryBuilder chaining" {
  let entry = LogEntryBuilder::new(Level::Info, "chain")
    .with_module("mod")
    .with_field("k1", "v1")
    .with_field("k2", "v2")
    .with_location("f.mbt", 10)
    .with_thread(99)
    .with_sequence(5L)
    .with_timestamp(1000L)
    .build()
  inspect(entry.module_name(), content="mod")
  inspect(entry.fields().length(), content="2")
  inspect(entry.location_file(), content="f.mbt")
  inspect(entry.location_line(), content="10")
  inspect(entry.thread_id(), content="99")
  inspect(entry.sequence(), content="5")
  inspect(entry.timestamp(), content="1000")
}

test "LogEntryBuilder empty fields" {
  let entry = LogEntryBuilder::new(Level::Debug, "empty").build()
  inspect(entry.fields().length(), content="0")
}

test "LogEntryBuilder empty module" {
  let entry = LogEntryBuilder::new(Level::Info, "nomod").build()
  inspect(entry.module_name(), content="")
}

test "MemoryHandler level filtering" {
  let fmt = compact_formatter()
  let h = MemoryHandler::new(Level::Warn, fmt)
  h.log(LogEntryBuilder::new(Level::Debug, "d").build())
  h.log(LogEntryBuilder::new(Level::Info, "i").build())
  h.log(LogEntryBuilder::new(Level::Warn, "w").build())
  h.log(LogEntryBuilder::new(Level::Error, "e").build())
  inspect(h.count(), content="2")
}

test "MemoryHandler formatted_lines" {
  let fmt = compact_formatter()
  let h = MemoryHandler::new(Level::Debug, fmt)
  h.log(LogEntryBuilder::new(Level::Info, "fmt").build())
  let lines = h.formatted_lines()
  inspect(lines.length(), content="1")
  inspect(lines[0].contains("INFO"), content="true")
}

test "MemoryHandler first_entry" {
  let fmt = compact_formatter()
  let h = MemoryHandler::new(Level::Debug, fmt)
  inspect(h.first_entry() is None, content="true")
  inspect(h.last_entry() is None, content="true")
  h.log(LogEntryBuilder::new(Level::Info, "first").build())
  h.log(LogEntryBuilder::new(Level::Info, "last").build())
  match h.first_entry() {
    Some(e) => inspect(e.message(), content="first")
    None => ()
  }
  match h.last_entry() {
    Some(e) => inspect(e.message(), content="last")
    None => ()
  }
}

test "DedupHandler no repeat single" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = DedupHandler::new(inner)
  h.log(LogEntryBuilder::new(Level::Info, "unique").build())
  h.flush()
  inspect(mem.count(), content="1")
}

test "DedupHandler repeat without flush" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = DedupHandler::new(inner)
  h.log(LogEntryBuilder::new(Level::Info, "dup").build())
  h.log(LogEntryBuilder::new(Level::Info, "dup").build())
  h.log(LogEntryBuilder::new(Level::Info, "dup").build())
  inspect(mem.count(), content="1")
}

test "DedupHandler flush with pending repeat" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = DedupHandler::new(inner)
  h.log(LogEntryBuilder::new(Level::Info, "dup").build())
  h.log(LogEntryBuilder::new(Level::Info, "dup").build())
  h.flush()
  let found_repeat = fn() -> Bool {
    let n = mem.entries().length()
    let mut i = 0
    while i < n {
      if mem.entries()[i].message().contains("repeated") { return true }
      i = i + 1
    }
    false
  }
  inspect(found_repeat(), content="true")
}

test "SamplingHandler reset" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = SamplingHandler::new(inner, 2)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  inspect(mem.count(), content="0")
  h.reset()
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  inspect(mem.count(), content="0")
  h.log(LogEntryBuilder::new(Level::Info, "c").build())
  inspect(mem.count(), content="1")
}

test "SamplingHandler rate 1 (all pass)" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = SamplingHandler::new(inner, 1)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  inspect(mem.count(), content="2")
}

test "RingBufferHandler empty entries" {
  let fmt = compact_formatter()
  let h = RingBufferHandler::new(Level::Debug, fmt, 5)
  inspect(h.entries().length(), content="0")
  inspect(h.is_full(), content="false")
  let fr = h.fill_ratio()
  inspect(fr < 0.001, content="true")
}

test "RingBufferHandler is_full" {
  let fmt = compact_formatter()
  let h = RingBufferHandler::new(Level::Debug, fmt, 2)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  inspect(h.is_full(), content="false")
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  inspect(h.is_full(), content="true")
}

test "RingBufferHandler overwrite oldest" {
  let fmt = compact_formatter()
  let h = RingBufferHandler::new(Level::Debug, fmt, 2)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  h.log(LogEntryBuilder::new(Level::Info, "c").build())
  let all = h.entries()
  inspect(all.length(), content="2")
  inspect(all[1].message(), content="c")
}

test "LevelFilteredHandler single level" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = LevelFilteredHandler::new(inner, Level::Error, Level::Error)
  h.log(LogEntryBuilder::new(Level::Debug, "d").build())
  h.log(LogEntryBuilder::new(Level::Error, "e").build())
  h.log(LogEntryBuilder::new(Level::Fatal, "f").build())
  inspect(mem.count(), content="1")
}

test "RateLimitedHandler resets window" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = RateLimitedHandler::new(inner, 1)
  let e1 = LogEntryBuilder::new(Level::Info, "a").with_timestamp(100L).build()
  let e2 = LogEntryBuilder::new(Level::Info, "b").with_timestamp(200L).build()
  let e3 = LogEntryBuilder::new(Level::Info, "c").with_timestamp(2000100L).build()
  h.log(e1); h.log(e2); h.log(e3)
  inspect(mem.count(), content="2")
}

test "AsyncLogger flush on demand" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = AsyncLogger::new(inner, 10)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  inspect(h.queue_size(), content="2")
  inspect(mem.count(), content="0")
  h.flush()
  inspect(h.queue_size(), content="0")
  inspect(mem.count(), content="2")
}

test "AsyncLogger close flushes" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = AsyncLogger::new(inner, 10)
  h.log(LogEntryBuilder::new(Level::Info, "x").build())
  h.close()
  inspect(mem.count(), content="1")
}

test "AsyncLogger set_batch_size" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = AsyncLogger::new(inner, 5)
  h.set_batch_size(2)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  inspect(h.queue_size(), content="1")
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  inspect(h.queue_size(), content="0")
}

test "BatchingLogger flush on demand" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = BatchingLogger::new(inner, 5, 1000L)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  inspect(h.queue_size(), content="1")
  h.flush()
  inspect(h.queue_size(), content="0")
  inspect(mem.count(), content="1")
}

test "BatchingLogger close flushes" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = BatchingLogger::new(inner, 5, 1000L)
  h.log(LogEntryBuilder::new(Level::Info, "x").build())
  h.close()
  inspect(mem.count(), content="1")
}

test "EntryTransformer flush close propagate" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = EntryTransformer::new(inner, fn(e) { e })
  h.log(LogEntryBuilder::new(Level::Info, "pass").build())
  inspect(mem.count(), content="1")
  h.flush()
  h.close()
}

test "EntryTransformer strip_fields" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = EntryTransformer::new(inner, fn(e) { strip_fields(e) })
  let entry = LogEntryBuilder::new(Level::Info, "strip")
    .with_field("k", "v").build()
  h.log(entry)
  match mem.last_entry() {
    Some(e) => inspect(e.fields().length(), content="0")
    None => ()
  }
}

test "EntryTransformer mask_field" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = EntryTransformer::new(inner, fn(e) { mask_field(e, "secret") })
  let entry = LogEntryBuilder::new(Level::Info, "mask")
    .with_field("secret", "sensitive").build()
  h.log(entry)
  match mem.last_entry() {
    Some(e) => {
      match entry_get_field(e, "secret") {
        Some(v) => inspect(v, content="****")
        None => ()
      }
    }
    None => ()
  }
}

test "text_formatter without module" {
  let fmt = text_formatter()
  let entry = LogEntryBuilder::new(Level::Info, "plain").build()
  let line = fmt(entry)
  inspect(line.contains("INFO"), content="true")
  inspect(line.contains("plain"), content="true")
}

test "compact_formatter no extra" {
  let fmt = compact_formatter()
  let entry = LogEntryBuilder::new(Level::Debug, "simple").build()
  let line = fmt(entry)
  inspect(line, content="[DEBUG] simple")
}

test "audit_formatter custom separator" {
  let fmt = audit_formatter(",")
  let entry = LogEntryBuilder::new(Level::Info, "csv")
    .with_module("m").with_location("f", 1).build()
  let line = fmt(entry)
  inspect(line.contains(",INFO,"), content="true")
}

test "logfmt_formatter quoting" {
  let fmt = logfmt_formatter()
  let entry = LogEntryBuilder::new(Level::Info, "hello world")
    .with_field("key", "val with spaces").build()
  let line = fmt(entry)
  inspect(line.contains("msg=\"hello world\""), content="true")
}

test "xml_formatter special chars" {
  let fmt = xml_formatter()
  let entry = LogEntryBuilder::new(Level::Info, "a<b&c").build()
  let line = fmt(entry)
  inspect(line.contains("a&lt;b&amp;c"), content="true")
}

test "pretty_formatter no color" {
  let fmt = pretty_formatter(false)
  let entry = LogEntryBuilder::new(Level::Info, "nocolor").with_module("m").build()
  let line = fmt(entry)
  inspect(line.contains("nocolor"), content="true")
  inspect(line.contains("(m)"), content="true")
}

test "pattern_formatter custom template" {
  let fmt = pattern_formatter("{level} - {message}")
  let entry = LogEntryBuilder::new(Level::Warn, "custom").build()
  let line = fmt(entry)
  inspect(line, content="WARN - custom")
}

test "multi_line_formatter basic" {
  let fmt = multi_line_formatter(2)
  let entry = LogEntryBuilder::new(Level::Error, "multi").build()
  let line = fmt(entry)
  inspect(line.contains("LogEntry {"), content="true")
  inspect(line.contains("  level: ERROR"), content="true")
  inspect(line.contains("  message: multi"), content="true")
  inspect(line.contains("}"), content="true")
}

test "stats_formatter with fields and location" {
  let fmt = stats_formatter(true, true)
  let entry = LogEntryBuilder::new(Level::Info, "stats")
    .with_location("s.mbt", 5).with_field("x", "1").build()
  let line = fmt(entry)
  inspect(line.contains("INFO"), content="true")
  inspect(line.contains("s.mbt:5"), content="true")
  inspect(line.contains("x: 1"), content="true")
}

test "stats_formatter without fields" {
  let fmt = stats_formatter(false, false)
  let entry = LogEntryBuilder::new(Level::Info, "stats").build()
  let line = fmt(entry)
  inspect(line.contains("INFO"), content="true")
  inspect(line, content="[INFO] stats")
}

test "entry_to_json_string roundtrip" {
  let entry = LogEntryBuilder::new(Level::Info, "roundtrip")
    .with_module("test").with_field("k", "v").build()
  let json = entry_to_json_string(entry)
  inspect(json.contains("INFO"), content="true")
  inspect(json.contains("roundtrip"), content="true")
  inspect(json.contains("test"), content="true")
  inspect(json.contains("k"), content="true")
  inspect(json.contains("v"), content="true")
}

test "entry_from_json valid" {
  let json = "{\"timestamp\":12345,\"level\":\"WARN\",\"message\":\"parsed\"}"
  let result = entry_from_json(json)
  match result {
    Some(e) => {
      inspect(e.level().to_string(), content="WARN")
      inspect(e.message(), content="parsed")
    }
    None => inspect(false, content="true")
  }
}

test "entry_from_json invalid returns None" {
  inspect(entry_from_json("invalid json") is None, content="true")
  inspect(entry_from_json("{\"no\":\"fields\"}") is None, content="true")
}

test "entries_filter all pass" {
  let es = [
    LogEntryBuilder::new(Level::Info, "a").build(),
    LogEntryBuilder::new(Level::Info, "b").build(),
  ]
  let filtered = entries_filter(es, fn(_) { true })
  inspect(filtered.length(), content="2")
}

test "entries_filter none pass" {
  let es = [LogEntryBuilder::new(Level::Info, "a").build()]
  let filtered = entries_filter(es, fn(_) { false })
  inspect(filtered.length(), content="0")
}

test "entries_sort_by_timestamp already sorted" {
  let e1 = LogEntryBuilder::new(Level::Info, "a").with_timestamp(1L).build()
  let e2 = LogEntryBuilder::new(Level::Info, "b").with_timestamp(2L).build()
  let sorted = entries_sort_by_timestamp([e1, e2])
  inspect(sorted[0].message(), content="a")
}

test "entries_sort_by_timestamp empty" {
  let sorted = entries_sort_by_timestamp([])
  inspect(sorted.length(), content="0")
}

test "entry_merge with empty fields" {
  let a = LogEntryBuilder::new(Level::Info, "a").build()
  let b = LogEntryBuilder::new(Level::Info, "b").with_field("k", "v").build()
  let merged = entry_merge(a, b)
  inspect(merged.fields().length(), content="1")
}

test "entry_with_fields appends" {
  let entry = LogEntryBuilder::new(Level::Info, "base")
    .with_field("k1", "v1").build()
  let result = entry_with_fields(entry, [("k2", "v2")])
  inspect(result.fields().length(), content="2")
}

test "entries_to_json_array empty" {
  let json = entries_to_json_array([])
  inspect(json, content="[]")
}

test "entries_to_json_array single" {
  let e = LogEntryBuilder::new(Level::Info, "single").build()
  let json = entries_to_json_array([e])
  inspect(json.contains("single"), content="true")
}

test "entries_count utility" {
  let es = [LogEntryBuilder::new(Level::Debug, "a").build()]
  inspect(entries_count(es), content="1")
  inspect(entries_count([]), content="0")
}

test "LogConfig describe format" {
  let cfg = LogConfig::default()
  let desc = cfg.describe()
  inspect(desc.contains("LogConfig("), content="true")
  inspect(desc.contains("level="), content="true")
  inspect(desc.contains("format="), content="true")
}

test "LogConfig with_color" {
  let cfg = LogConfig::default().with_color(true)
  inspect(cfg.ansi_color, content="true")
}

test "LogConfig with_batch" {
  let cfg = LogConfig::default().with_batch(50)
  inspect(cfg.batch_size, content="50")
}

test "quick_logger and json_logger" {
  let ql = quick_logger(Level::Info)
  inspect(ql.level.to_int(), content="1")
  let jl = json_logger(Level::Debug)
  inspect(jl.level.to_int(), content="0")
}

test "default_setup creates logger" {
  let logger = default_setup()
  inspect(logger.level.to_int(), content="0")
}

test "MultiHandler flush and close" {
  let mh = MultiHandler::new()
  let mem = MemoryHandler::new(Level::Debug, compact_formatter())
  mh.add(make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {}))
  mh.log(LogEntryBuilder::new(Level::Info, "mh").build())
  inspect(mem.count(), content="1")
  mh.flush()
  mh.close()
}

test "RotatingFileHandler no rotation below max" {
  let fmt = compact_formatter()
  let h = RotatingFileHandler::new(Level::Debug, fmt, "/tmp/r", 10, 3)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  inspect(h.lines().length(), content="1")
}

test "Stopwatch elapsed units consistency" {
  let sw = Stopwatch::new()
  sw.start()
  sw.stop()
  let us = sw.elapsed_micros()
  let ms = sw.elapsed_millis()
  let s = sw.elapsed_secs()
  inspect(ms * 1000.0 <= us + 1.0, content="true")
  inspect(s * 1000000.0 <= us + 1.0, content="true")
}

test "Stopwatch format_elapsed output" {
  let sw = Stopwatch::new()
  sw.start()
  sw.stop()
  let formatted = sw.format_elapsed()
  inspect(formatted.length() > 0, content="true")
}

test "measure_time returns positive" {
  let us = measure_time(fn() {
    let mut x = 0
    x = x + 1
    ignore(x)
  })
  inspect(us >= 0.0, content="true")
}

test "measure_time_ms returns positive" {
  let ms = measure_time_ms(fn() {})
  inspect(ms >= 0.0, content="true")
}

test "ThroughputMeter basic ops" {
  let tm = ThroughputMeter::new()
  tm.increment()
  tm.increment()
  tm.increment()
  tm.stop()
  let ops = tm.ops_per_second()
  inspect(ops >= 0.0, content="true")
}

test "ThroughputMeter record_batch" {
  let tm = ThroughputMeter::new()
  tm.record_batch(100L)
  tm.stop()
  let ops = tm.ops_per_second()
  inspect(ops >= 0.0, content="true")
}

test "ThroughputMeter format throughput" {
  let tm = ThroughputMeter::new()
  tm.increment()
  tm.stop()
  let s = tm.format_throughput()
  inspect(s.length() > 0, content="true")
}

test "ThroughputMeter elapsed_str" {
  let tm = ThroughputMeter::new()
  tm.increment()
  tm.stop()
  let s = tm.elapsed_str()
  inspect(s.length() > 0, content="true")
}

test "benchmark_warmup runs" {
  let r = benchmark_warmup("warm", 5, 3, fn() {})
  inspect(r.iterations(), content="5")
  inspect(r.total_time_us() > 0.0, content="true")
}

test "benchmark_compare produces output" {
  let s = benchmark_compare("a", "b", 3, fn() {}, fn() {})
  inspect(s.contains("Comparison:"), content="true")
  inspect(s.contains("Benchmark: a"), content="true")
  inspect(s.contains("Benchmark: b"), content="true")
}

test "lazy_format template" {
  let entry = LogEntryBuilder::new(Level::Info, "hello").with_module("m").build()
  let result = lazy_format("{level}: {message} [{module}]", entry)
  inspect(result, content="INFO: hello [m]")
}

test "lazy_format unknown placeholder stays" {
  let entry = LogEntryBuilder::new(Level::Info, "test").build()
  let result = lazy_format("{unknown}", entry)
  inspect(result, content="{unknown}")
}

test "global_logger g_log_with" {
  g_log_with(Level::Info, "global fields", [("k", "v")])
}

test "global_logger g_flush and g_close" {
  g_flush()
  g_close()
}

test "configure with compact formatter" {
  configure(Level::Debug, compact_formatter())
  let logger = get_global_logger()
  inspect(logger.level.to_int(), content="0")
}

test "from_config_json with json" {
  let logger = from_config_json("{\"type\":\"json\",\"level\":\"info\"}")
  inspect(logger.level.to_int(), content="1")
}

test "handler fn wrapping" {
  let mem = MemoryHandler::new(Level::Debug, compact_formatter())
  let hfn = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  hfn.log(LogEntryBuilder::new(Level::Info, "via_hfn").build())
  inspect(mem.count(), content="1")
  hfn.flush()
  hfn.close()
}

test "NullHandler discards all" {
  let h = NullHandler::new(Level::Debug)
  h.log(LogEntryBuilder::new(Level::Info, "gone").build())
  h.flush()
  h.close()
}

test "ConditionHandler filters by level" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = ConditionHandler::new(inner, fn(e) { e.level.to_int() >= Level::Error.to_int() })
  h.log(LogEntryBuilder::new(Level::Info, "skip").build())
  h.log(LogEntryBuilder::new(Level::Error, "pass").build())
  inspect(mem.count(), content="1")
}

test "ConditionHandler flush close propagate" {
  let mem = MemoryHandler::new(Level::Debug, compact_formatter())
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = ConditionHandler::new(inner, fn(_) { true })
  h.flush()
  h.close()
}

test "ThrottledHandler deduplicates messages" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = ThrottledHandler::new(inner)
  h.log(LogEntryBuilder::new(Level::Info, "unique1").build())
  h.log(LogEntryBuilder::new(Level::Info, "unique2").build())
  h.log(LogEntryBuilder::new(Level::Info, "unique1").build())
  inspect(mem.count(), content="2")
}

test "ThrottledHandler flush close" {
  let mem = MemoryHandler::new(Level::Debug, compact_formatter())
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = ThrottledHandler::new(inner)
  h.flush()
  h.close()
}

test "CountingHandler counts by level" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = CountingHandler::new(inner)
  h.log(LogEntryBuilder::new(Level::Debug, "d").build())
  h.log(LogEntryBuilder::new(Level::Info, "i").build())
  h.log(LogEntryBuilder::new(Level::Info, "i2").build())
  h.log(LogEntryBuilder::new(Level::Warn, "w").build())
  h.log(LogEntryBuilder::new(Level::Error, "e").build())
  h.log(LogEntryBuilder::new(Level::Fatal, "f").build())
  inspect(h.debug_count(), content="1")
  inspect(h.info_count(), content="2")
  inspect(h.warn_count(), content="1")
  inspect(h.error_count(), content="1")
  inspect(h.fatal_count(), content="1")
  inspect(h.total_count(), content="6")
}

test "CountingHandler reset" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = CountingHandler::new(inner)
  h.log(LogEntryBuilder::new(Level::Info, "i").build())
  inspect(h.total_count(), content="1")
  h.reset()
  inspect(h.total_count(), content="0")
}

test "CountingHandler flush close" {
  let mem = MemoryHandler::new(Level::Debug, compact_formatter())
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = CountingHandler::new(inner)
  h.flush()
  h.close()
}

test "kv_formatter output" {
  let fmt = kv_formatter()
  let entry = LogEntryBuilder::new(Level::Info, "msg").with_field("key", "val").build()
  let line = fmt(entry)
  inspect(line.contains("level=INFO"), content="true")
  inspect(line.contains("msg=msg"), content="true")
  inspect(line.contains("key=val"), content="true")
}

test "banner_formatter output" {
  let fmt = banner_formatter(20)
  let entry = LogEntryBuilder::new(Level::Warn, "important").with_module("m").build()
  let line = fmt(entry)
  inspect(line.contains("===================="), content="true")
  inspect(line.contains("WARN"), content="true")
  inspect(line.contains("important"), content="true")
}

test "csv_formatter output" {
  let fmt = csv_formatter(",", false)
  let entry = LogEntryBuilder::new(Level::Info, "csv_msg")
    .with_location("f.mbt", 5).build()
  let line = fmt(entry)
  inspect(line.contains(",INFO,"), content="true")
  inspect(line.contains("csv_msg"), content="true")
}

test "entries_summary output" {
  let es = [LogEntryBuilder::new(Level::Info, "a").build()]
  let s = entries_summary(es)
  inspect(s.contains("Entries: 1"), content="true")
  inspect(s.contains("INFO"), content="true")
}

test "entries_summary empty" {
  let s = entries_summary([])
  inspect(s.contains("Entries: 0"), content="true")
}

test "entries_by_level filters correctly" {
  let e1 = LogEntryBuilder::new(Level::Info, "i").build()
  let e2 = LogEntryBuilder::new(Level::Warn, "w").build()
  let e3 = LogEntryBuilder::new(Level::Info, "i2").build()
  let result = entries_by_level([e1, e2, e3], Level::Info)
  inspect(result.length(), content="2")
}

test "entries_by_level no match" {
  let e = LogEntryBuilder::new(Level::Error, "e").build()
  let result = entries_by_level([e], Level::Info)
  inspect(result.length(), content="0")
}

test "entries_earliest and latest" {
  let e1 = LogEntryBuilder::new(Level::Info, "early").with_timestamp(1L).build()
  let e2 = LogEntryBuilder::new(Level::Info, "late").with_timestamp(10L).build()
  match entries_earliest([e1, e2]) {
    Some(e) => inspect(e.message(), content="early")
    None => ()
  }
  match entries_latest([e1, e2]) {
    Some(e) => inspect(e.message(), content="late")
    None => ()
  }
}

test "entries_earliest empty" {
  inspect(entries_earliest([]) is None, content="true")
}

test "entries_latest empty" {
  inspect(entries_latest([]) is None, content="true")
}

test "entries_reject filters out" {
  let e1 = LogEntryBuilder::new(Level::Info, "keep").build()
  let e2 = LogEntryBuilder::new(Level::Warn, "remove").build()
  let result = entries_reject([e1, e2], fn(e) { e.level == Level::Warn })
  inspect(result.length(), content="1")
  inspect(result[0].message(), content="keep")
}

test "entries_reject all pass" {
  let result = entries_reject([], fn(_) { true })
  inspect(result.length(), content="0")
}

test "Entries utility with empty array" {
  let empty : Array[LogEntry] = []
  inspect(entries_by_level(empty, Level::Info).length(), content="0")
  inspect(entries_reject(empty, fn(_) { true }).length(), content="0")
  inspect(entries_summary(empty).length() > 0, content="true")
}