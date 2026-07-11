///|
/// Handler that discards all log entries (null pattern).
pub(all) struct NullHandler {
  level : Level
}

///|
/// Creates a NullHandler that discards all entries below the given level.
pub fn NullHandler::new(level : Level) -> NullHandler {
  { level, }
}

///|
/// Discards the entry (no-op).
pub fn NullHandler::log(self : NullHandler, _entry : LogEntry) -> Unit {
  let _ = self
}

///|
/// No-op flush.
pub fn NullHandler::flush(self : NullHandler) -> Unit {
  let _ = self
}

///|
/// No-op close.
pub fn NullHandler::close(self : NullHandler) -> Unit {
  let _ = self
}

///|
/// Handler that only logs when a predicate condition is met.
pub(all) struct ConditionHandler {
  inner : HandlerFn
  condition : (LogEntry) -> Bool
}

///|
/// Creates a ConditionHandler that only passes entries matching the predicate.
pub fn ConditionHandler::new(
  inner : HandlerFn,
  condition : (LogEntry) -> Bool,
) -> ConditionHandler {
  { inner, condition }
}

///|
/// Logs the entry only if the condition predicate returns true.
pub fn ConditionHandler::log(self : ConditionHandler, entry : LogEntry) -> Unit {
  if (self.condition)(entry) {
    self.inner.log(entry)
  }
}

///|
/// Flushes the inner handler.
pub fn ConditionHandler::flush(self : ConditionHandler) -> Unit {
  self.inner.flush()
}

///|
/// Closes the inner handler.
pub fn ConditionHandler::close(self : ConditionHandler) -> Unit {
  self.inner.close()
}

///|
/// Handler that limits log output to at most one entry per unique message.
pub(all) struct ThrottledHandler {
  inner : HandlerFn
  mut seen : Array[String]
}

///|
/// Creates a ThrottledHandler that only logs each unique message once.
pub fn ThrottledHandler::new(inner : HandlerFn) -> ThrottledHandler {
  { inner, seen: [] }
}

///|
/// Logs the entry only if its message has not been seen before.
pub fn ThrottledHandler::log(self : ThrottledHandler, entry : LogEntry) -> Unit {
  let mut already_seen = false
  let n = self.seen.length()
  let mut i = 0
  while i < n {
    if self.seen[i] == entry.message {
      already_seen = true
      i = n
    }
    i = i + 1
  }
  if !already_seen {
    self.seen.push(entry.message)
    self.inner.log(entry)
  }
}

///|
/// Flushes the inner handler.
pub fn ThrottledHandler::flush(self : ThrottledHandler) -> Unit {
  self.inner.flush()
}

///|
/// Closes the inner handler and clears seen messages.
pub fn ThrottledHandler::close(self : ThrottledHandler) -> Unit {
  self.seen = []
  self.inner.close()
}

///|
/// Handler that counts entries by level, useful for monitoring.
pub(all) struct CountingHandler {
  inner : HandlerFn
  mut debug_count : Int
  mut info_count : Int
  mut warn_count : Int
  mut error_count : Int
  mut fatal_count : Int
}

///|
/// Creates a CountingHandler that tracks log counts per level.
pub fn CountingHandler::new(inner : HandlerFn) -> CountingHandler {
  {
    inner,
    debug_count: 0,
    info_count: 0,
    warn_count: 0,
    error_count: 0,
    fatal_count: 0,
  }
}

///|
/// Logs the entry and increments the level counter.
pub fn CountingHandler::log(self : CountingHandler, entry : LogEntry) -> Unit {
  match entry.level {
    Debug => self.debug_count = self.debug_count + 1
    Info => self.info_count = self.info_count + 1
    Warn => self.warn_count = self.warn_count + 1
    Error => self.error_count = self.error_count + 1
    Fatal => self.fatal_count = self.fatal_count + 1
  }
  self.inner.log(entry)
}

///|
/// Flushes the inner handler.
pub fn CountingHandler::flush(self : CountingHandler) -> Unit {
  self.inner.flush()
}

///|
/// Closes the inner handler.
pub fn CountingHandler::close(self : CountingHandler) -> Unit {
  self.inner.close()
}

///|
/// Returns the count of debug-level entries.
pub fn CountingHandler::debug_count(self : CountingHandler) -> Int {
  self.debug_count
}

///|
/// Returns the count of info-level entries.
pub fn CountingHandler::info_count(self : CountingHandler) -> Int {
  self.info_count
}

///|
/// Returns the count of warn-level entries.
pub fn CountingHandler::warn_count(self : CountingHandler) -> Int {
  self.warn_count
}

///|
/// Returns the count of error-level entries.
pub fn CountingHandler::error_count(self : CountingHandler) -> Int {
  self.error_count
}

///|
/// Returns the count of fatal-level entries.
pub fn CountingHandler::fatal_count(self : CountingHandler) -> Int {
  self.fatal_count
}

///|
/// Returns the total count across all levels.
pub fn CountingHandler::total_count(self : CountingHandler) -> Int {
  self.debug_count +
  self.info_count +
  self.warn_count +
  self.error_count +
  self.fatal_count
}

///|
/// Resets all level counters to zero.
pub fn CountingHandler::reset(self : CountingHandler) -> Unit {
  self.debug_count = 0
  self.info_count = 0
  self.warn_count = 0
  self.error_count = 0
  self.fatal_count = 0
}

///|
/// Formats a log entry in key=value format with a timestamp prefix.
pub fn kv_formatter() -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string("ts=")
    sb.write_string(entry.timestamp.to_string())
    sb.write_string(" level=")
    sb.write_string(entry.level.to_string())
    sb.write_string(" msg=")
    sb.write_string(kv_esc(entry.message))
    if entry.mod_name.length() > 0 {
      sb.write_string(" module=")
      sb.write_string(kv_esc(entry.mod_name))
    }
    let n = entry.fields.length()
    let mut i = 0
    while i < n {
      let (k, v) = entry.fields[i]
      sb.write_string(" ")
      sb.write_string(k)
      sb.write_string("=")
      sb.write_string(kv_esc(v))
      i = i + 1
    }
    sb.to_string()
  }
}

///|
fn kv_esc(s : String) -> String {
  if !s.contains(" ") && !s.contains("=") {
    return s
  }
  let sb = StringBuilder()
  sb.write_string("\"")
  for c in s.iter() {
    if c == '\\' {
      sb.write_string("\\\\")
    } else if c == '"' {
      sb.write_string("\\\"")
    } else if c == '\n' {
      sb.write_string("\\n")
    } else {
      sb.write_char(c)
    }
  }
  sb.write_string("\"")
  sb.to_string()
}

///|
/// Formats a log entry as a full-width banner for emphasis.
pub fn banner_formatter(width : Int) -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let border = String::make(width, '=')
    let sb = StringBuilder()
    sb.write_string(border)
    sb.write_string("\n")
    sb.write_string("  ")
    sb.write_string(entry.level.to_string())
    if entry.mod_name.length() > 0 {
      sb.write_string(" (")
      sb.write_string(entry.mod_name)
      sb.write_string(")")
    }
    sb.write_string("\n")
    sb.write_string("  ")
    sb.write_string(entry.message)
    sb.write_string("\n")
    sb.write_string(border)
    sb.to_string()
  }
}

///|
/// Formats a log entry in CSV-like format.
pub fn csv_formatter(
  separator : String,
  _include_header : Bool,
) -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string(entry.timestamp.to_string())
    sb.write_string(separator)
    sb.write_string(entry.level.to_string())
    sb.write_string(separator)
    sb.write_string(csv_esc(entry.message))
    sb.write_string(separator)
    sb.write_string(csv_esc(entry.mod_name))
    sb.write_string(separator)
    sb.write_string(entry.file)
    sb.write_string(separator)
    sb.write_string(entry.line.to_string())
    sb.to_string()
  }
}

///|
fn csv_esc(s : String) -> String {
  if !s.contains(",") && !s.contains("\"") && !s.contains("\n") {
    return s
  }
  let sb = StringBuilder()
  sb.write_string("\"")
  for c in s.iter() {
    if c == '"' {
      sb.write_string("\"\"")
    } else {
      sb.write_char(c)
    }
  }
  sb.write_string("\"")
  sb.to_string()
}

///|
/// Returns a summary string of all entries in an array.
pub fn entries_summary(entries : Array[LogEntry]) -> String {
  let sb = StringBuilder()
  let n = entries.length()
  sb.write_string("Entries: ")
  sb.write_string(n.to_string())
  sb.write_string("\n")
  if n > 0 {
    let level_counts = [0, 0, 0, 0, 0]
    let mut i = 0
    while i < n {
      let idx = entries[i].level.to_int()
      level_counts[idx] = level_counts[idx] + 1
      i = i + 1
    }
    sb.write_string("  DEBUG: ")
    sb.write_string(level_counts[0].to_string())
    sb.write_string("\n")
    sb.write_string("  INFO:  ")
    sb.write_string(level_counts[1].to_string())
    sb.write_string("\n")
    sb.write_string("  WARN:  ")
    sb.write_string(level_counts[2].to_string())
    sb.write_string("\n")
    sb.write_string("  ERROR: ")
    sb.write_string(level_counts[3].to_string())
    sb.write_string("\n")
    sb.write_string("  FATAL: ")
    sb.write_string(level_counts[4].to_string())
  }
  sb.to_string()
}

///|
/// Returns only entries of the specified level.
pub fn entries_by_level(
  entries : Array[LogEntry],
  target : Level,
) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  let n = entries.length()
  let mut i = 0
  while i < n {
    if entries[i].level == target {
      result.push(entries[i])
    }
    i = i + 1
  }
  result
}

///|
/// Returns the entry with the earliest timestamp, or None if empty.
pub fn entries_earliest(entries : Array[LogEntry]) -> LogEntry? {
  let n = entries.length()
  if n == 0 {
    return None
  }
  let mut best = entries[0]
  let mut i = 1
  while i < n {
    if entries[i].timestamp < best.timestamp {
      best = entries[i]
    }
    i = i + 1
  }
  Some(best)
}

///|
/// Returns the entry with the latest timestamp, or None if empty.
pub fn entries_latest(entries : Array[LogEntry]) -> LogEntry? {
  let n = entries.length()
  if n == 0 {
    return None
  }
  let mut best = entries[0]
  let mut i = 1
  while i < n {
    if entries[i].timestamp > best.timestamp {
      best = entries[i]
    }
    i = i + 1
  }
  Some(best)
}

///|
/// Returns a new array without entries that match the predicate.
pub fn entries_reject(
  entries : Array[LogEntry],
  predicate : (LogEntry) -> Bool,
) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  for e in entries {
    if !predicate(e) {
      result.push(e)
    }
  }
  result
}
