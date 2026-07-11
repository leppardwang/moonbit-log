///|
/// Audit handler that stores entries and auto-flushes when the buffer is full.
pub(all) struct AuditHandler {
  level : Level
  fmt : (LogEntry) -> String
  mut entries : Array[LogEntry]
  max_entries : Int
}

///|
/// Creates a new AuditHandler with the given level, formatter, and max buffer size.
pub fn AuditHandler::new(
  level : Level,
  fmt : (LogEntry) -> String,
  max_entries : Int,
) -> AuditHandler {
  { level, fmt, entries: [], max_entries }
}

///|
/// Stores an entry and auto-flushes to stdout when the buffer reaches max_entries.
pub fn AuditHandler::log(self : AuditHandler, entry : LogEntry) -> Unit {
  if entry.level.enabled(self.level) {
    self.entries.push(entry)
    if self.entries.length() >= self.max_entries {
      self.flush()
    }
  }
}

///|
/// Flushes all buffered entries to stdout and clears the buffer.
pub fn AuditHandler::flush(self : AuditHandler) -> Unit {
  let n = self.entries.length()
  if n > 0 {
    let mut i = 0
    while i < n {
      let line = (self.fmt)(self.entries[i])
      println(line)
      i = i + 1
    }
    self.entries = []
  }
}

///|
/// Flushes buffered entries and closes the handler.
pub fn AuditHandler::close(self : AuditHandler) -> Unit {
  self.flush()
}

///|
/// Returns all buffered entries.
pub fn AuditHandler::entries(self : AuditHandler) -> Array[LogEntry] {
  self.entries
}

///|
/// Filters stored entries to those matching the given log level.
pub fn AuditHandler::filter_by_level(
  self : AuditHandler,
  target : Level,
) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  let n = self.entries.length()
  let mut i = 0
  while i < n {
    if self.entries[i].level.to_int() == target.to_int() {
      result.push(self.entries[i])
    }
    i = i + 1
  }
  result
}

///|
/// Searches stored entries by module name.
pub fn AuditHandler::search_by_module(
  self : AuditHandler,
  mod_name : String,
) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  let n = self.entries.length()
  let mut i = 0
  while i < n {
    if self.entries[i].mod_name == mod_name {
      result.push(self.entries[i])
    }
    i = i + 1
  }
  result
}

///|
/// Searches stored entries whose message contains the given keyword.
pub fn AuditHandler::search_by_message(
  self : AuditHandler,
  keyword : String,
) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  let n = self.entries.length()
  let mut i = 0
  while i < n {
    if self.entries[i].message.contains(keyword[:]) {
      result.push(self.entries[i])
    }
    i = i + 1
  }
  result
}
