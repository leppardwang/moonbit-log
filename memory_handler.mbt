///|
/// In-memory handler that stores log entries for later retrieval.
pub(all) struct MemoryHandler {
  level : Level
  fmt : (LogEntry) -> String
  mut entries : Array[LogEntry]
}

///|
/// Creates a new MemoryHandler with the given minimum level and formatter.
pub fn MemoryHandler::new(
  level : Level,
  fmt : (LogEntry) -> String,
) -> MemoryHandler {
  { level, fmt, entries: [] }
}

///|
/// Stores an entry in memory if its level meets the configured threshold.
pub fn MemoryHandler::log(self : MemoryHandler, entry : LogEntry) -> Unit {
  if entry.level.enabled(self.level) {
    self.entries.push(entry)
  }
}

///|
/// Flushes buffered output. No-op for memory handler.
pub fn MemoryHandler::flush(self : MemoryHandler) -> Unit {
  let _ = self
}

///|
/// Closes the handler and releases resources. No-op for memory handler.
pub fn MemoryHandler::close(self : MemoryHandler) -> Unit {
  let _ = self
}

///|
/// Returns all stored log entries.
pub fn MemoryHandler::entries(self : MemoryHandler) -> Array[LogEntry] {
  self.entries
}

///|
/// Clears all stored log entries.
pub fn MemoryHandler::clear(self : MemoryHandler) -> Unit {
  self.entries = []
}

///|
/// Returns the total number of stored entries.
pub fn MemoryHandler::count(self : MemoryHandler) -> Int {
  self.entries.length()
}

///|
/// Counts entries that match the given log level.
pub fn MemoryHandler::count_by_level(
  self : MemoryHandler,
  target : Level,
) -> Int {
  let mut cnt = 0
  let n = self.entries.length()
  let mut i = 0
  while i < n {
    if self.entries[i].level.to_int() == target.to_int() {
      cnt = cnt + 1
    }
    i = i + 1
  }
  cnt
}

///|
/// Returns all stored entries formatted as strings using the handler's formatter.
pub fn MemoryHandler::formatted_lines(self : MemoryHandler) -> Array[String] {
  let result : Array[String] = []
  for e in self.entries {
    result.push((self.fmt)(e))
  }
  result
}

///|
/// Returns the most recent entry, or `None` if no entries exist.
pub fn MemoryHandler::last_entry(self : MemoryHandler) -> LogEntry? {
  let n = self.entries.length()
  if n > 0 {
    Some(self.entries[n - 1])
  } else {
    None
  }
}

///|
/// Returns the oldest entry, or `None` if no entries exist.
pub fn MemoryHandler::first_entry(self : MemoryHandler) -> LogEntry? {
  let n = self.entries.length()
  if n > 0 {
    Some(self.entries[0])
  } else {
    None
  }
}
