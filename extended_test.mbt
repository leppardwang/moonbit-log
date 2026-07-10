test "LevelFilteredHandler filters correctly" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = LevelFilteredHandler::new(inner, Level::Warn, Level::Error)
  h.log(LogEntryBuilder::new(Level::Debug, "d").build())
  h.log(LogEntryBuilder::new(Level::Info, "i").build())
  h.log(LogEntryBuilder::new(Level::Warn, "w").build())
  h.log(LogEntryBuilder::new(Level::Error, "e").build())
  h.log(LogEntryBuilder::new(Level::Fatal, "f").build())
  inspect(mem.count(), content="2")
}

test "SamplingHandler samples at rate" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = SamplingHandler::new(inner, 3)
  h.log(LogEntryBuilder::new(Level::Info, "1").build())
  h.log(LogEntryBuilder::new(Level::Info, "2").build())
  h.log(LogEntryBuilder::new(Level::Info, "3").build())
  inspect(mem.count(), content="1")
}

test "DedupHandler deduplicates repeats" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = DedupHandler::new(inner)
  h.log(LogEntryBuilder::new(Level::Info, "same").build())
  h.log(LogEntryBuilder::new(Level::Info, "same").build())
  h.log(LogEntryBuilder::new(Level::Info, "same").build())
  h.log(LogEntryBuilder::new(Level::Info, "different").build())
  h.flush()
  inspect(mem.count(), content="3")
}

test "RingBufferHandler capacity" {
  let fmt = compact_formatter()
  let h = RingBufferHandler::new(Level::Debug, fmt, 3)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  h.log(LogEntryBuilder::new(Level::Info, "c").build())
  h.log(LogEntryBuilder::new(Level::Info, "d").build())
  let all = h.entries()
  inspect(all.length(), content="3")
}

test "RingBufferHandler drain" {
  let fmt = compact_formatter()
  let h = RingBufferHandler::new(Level::Debug, fmt, 5)
  h.log(LogEntryBuilder::new(Level::Info, "x").build())
  h.log(LogEntryBuilder::new(Level::Info, "y").build())
  let drained = h.drain()
  inspect(drained.length(), content="2")
  inspect(h.entries().length(), content="0")
}

test "RingBufferHandler fill_ratio" {
  let fmt = compact_formatter()
  let h = RingBufferHandler::new(Level::Debug, fmt, 4)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  let r = h.fill_ratio()
  inspect(r > 0.0, content="true")
}

test "RotatingFileHandler rotation" {
  let fmt = compact_formatter()
  let h = RotatingFileHandler::new(Level::Debug, fmt, "/tmp/test", 2, 3)
  h.log(LogEntryBuilder::new(Level::Info, "m1").build())
  h.log(LogEntryBuilder::new(Level::Info, "m2").build())
  inspect(h.lines().length(), content="0")
  inspect(h.file_count(), content="1")
}

test "RateLimitedHandler respects limit" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = RateLimitedHandler::new(inner, 2)
  let e1 = LogEntryBuilder::new(Level::Info, "a").with_timestamp(1L).build()
  let e2 = LogEntryBuilder::new(Level::Info, "b").with_timestamp(2L).build()
  let e3 = LogEntryBuilder::new(Level::Info, "c").with_timestamp(3L).build()
  h.log(e1); h.log(e2); h.log(e3)
  inspect(mem.count(), content="2")
}

test "AsyncLogger batches entries" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = AsyncLogger::new(inner, 3)
  h.log(LogEntryBuilder::new(Level::Info, "a").build())
  h.log(LogEntryBuilder::new(Level::Info, "b").build())
  inspect(h.queue_size(), content="2")
  h.log(LogEntryBuilder::new(Level::Info, "c").build())
  inspect(h.queue_size(), content="0")
  inspect(mem.count(), content="3")
}

test "BatchingLogger batches" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = BatchingLogger::new(inner, 2, 1000L)
  h.log(LogEntryBuilder::new(Level::Info, "x").build())
  inspect(h.queue_size(), content="1")
  h.log(LogEntryBuilder::new(Level::Info, "y").build())
  inspect(mem.count(), content="2")
}

test "EntryTransformer transforms entry" {
  let fmt = compact_formatter()
  let mem = MemoryHandler::new(Level::Debug, fmt)
  let inner = make_handler(fn(e) { mem.log(e) }, fn() {}, fn() {})
  let h = EntryTransformer::new(inner, fn(e) { prefix_message(e, "PREFIX:") })
  h.log(LogEntryBuilder::new(Level::Info, "msg").build())
  let last = mem.last_entry()
  match last {
    Some(e) => inspect(e.message(), content="PREFIX:msg")
    None => ()
  }
}

test "redirect_level changes level" {
  let entry = LogEntryBuilder::new(Level::Info, "test").build()
  let r = redirect_level(entry, Level::Info, Level::Warn)
  inspect(r.level().to_int(), content="2")
}

test "mask_field hides sensitive data" {
  let entry = LogEntryBuilder::new(Level::Info, "test")
    .with_field("password", "secret123")
    .with_field("user", "alice")
    .build()
  let masked = mask_field(entry, "password")
  let pwd = entry_get_field(masked, "password")
  match pwd {
    Some(v) => inspect(v, content="****")
    None => ()
  }
}

test "strip_fields removes all fields" {
  let entry = LogEntryBuilder::new(Level::Info, "test")
    .with_field("a", "1").build()
  let stripped = strip_fields(entry)
  inspect(stripped.fields().length(), content="0")
}

test "entry_has_field and entry_get_field" {
  let entry = LogEntryBuilder::new(Level::Info, "t")
    .with_field("key1", "val1").build()
  inspect(entry_has_field(entry, "key1"), content="true")
  inspect(entry_has_field(entry, "missing"), content="false")
  let v = entry_get_field(entry, "key1")
  match v {
    Some(s) => inspect(s, content="val1")
    None => ()
  }
}

test "entry_merge combines fields" {
  let a = LogEntryBuilder::new(Level::Info, "a").with_field("k1", "v1").build()
  let b = LogEntryBuilder::new(Level::Warn, "b").with_field("k2", "v2").build()
  let merged = entry_merge(a, b)
  inspect(merged.fields().length(), content="2")
  inspect(merged.message(), content="a")
}

test "logfmt_formatter output" {
  let fmt = logfmt_formatter()
  let entry = LogEntryBuilder::new(Level::Info, "hello world")
    .with_field("key", "val").build()
  let line = fmt(entry)
  inspect(line.contains("level=INFO"), content="true")
  inspect(line.contains("msg="), content="true")
}

test "xml_formatter output" {
  let fmt = xml_formatter()
  let entry = LogEntryBuilder::new(Level::Info, "test").build()
  let line = fmt(entry)
  inspect(line.contains("<log>"), content="true")
  inspect(line.contains("<level>INFO</level>"), content="true")
  inspect(line.contains("</log>"), content="true")
}

test "pretty_formatter with color" {
  let fmt = pretty_formatter(true)
  let entry = LogEntryBuilder::new(Level::Info, "pretty").build()
  let line = fmt(entry)
  inspect(line.contains("INFO"), content="true")
  inspect(line.contains("pretty"), content="true")
}

test "ansi helper functions" {
  inspect(ansi_red().length() > 0, content="true")
  inspect(ansi_reset().length() > 0, content="true")
}

test "global_logger singleton" {
  let logger = get_global_logger()
  inspect(logger.level.to_int(), content="0")
}

test "configure global logger" {
  configure(Level::Warn, compact_formatter())
  let logger = get_global_logger()
  inspect(logger.level.to_int(), content="2")
}

test "entries_to_json_array" {
  let e1 = LogEntryBuilder::new(Level::Info, "a").build()
  let e2 = LogEntryBuilder::new(Level::Info, "b").build()
  let json = entries_to_json_array([e1, e2])
  inspect(json.contains("\"message\""), content="true")
}

test "entry_to_json_string output" {
  let entry = LogEntryBuilder::new(Level::Info, "json").build()
  let json = entry_to_json_string(entry)
  inspect(json.contains("INFO"), content="true")
  inspect(json.contains("json"), content="true")
}

test "entries_filter" {
  let e1 = LogEntryBuilder::new(Level::Info, "info msg").build()
  let e2 = LogEntryBuilder::new(Level::Warn, "warn msg").build()
  let filtered = entries_filter([e1, e2], fn(e) { e.level == Level::Warn })
  inspect(filtered.length(), content="1")
}

test "entries_sort_by_timestamp" {
  let e1 = LogEntryBuilder::new(Level::Info, "late").with_timestamp(10L).build()
  let e2 = LogEntryBuilder::new(Level::Info, "early").with_timestamp(5L).build()
  let sorted = entries_sort_by_timestamp([e1, e2])
  inspect(sorted[0].message(), content="early")
  inspect(sorted[1].message(), content="late")
}

test "init_default_console" {
  init_default_console()
  let logger = get_global_logger()
  inspect(logger.handlers.length() > 0, content="true")
}

test "add_thread_id transformer" {
  let entry = LogEntryBuilder::new(Level::Info, "t").build()
  let r = add_thread_id(entry, 42)
  inspect(r.thread_id(), content="42")
}

test "suffix_message transformer" {
  let entry = LogEntryBuilder::new(Level::Info, "hello").build()
  let r = suffix_message(entry, " world")
  inspect(r.message(), content="hello world")
}

test "from_config_json with console" {
  let logger = from_config_json("{\"type\":\"console\",\"level\":\"debug\"}")
  inspect(logger.level.to_int(), content="0")
}