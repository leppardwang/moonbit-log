/// Text handler that outputs log entries with an optional prefix string.
pub(all) struct TextHandler {
  level : Level
  fmt : (LogEntry) -> String
  prefix : String
}

/// Creates a new TextHandler with the given minimum level and formatter.
pub fn TextHandler::new(level : Level, fmt : (LogEntry) -> String) -> TextHandler {
  { level: level, fmt: fmt, prefix: "" }
}

/// Sets a prefix string prepended to each log line. Returns a new handler.
pub fn TextHandler::with_prefix(self : TextHandler, p : String) -> TextHandler {
  { ..self, prefix: p }
}

/// Logs an entry with an optional prefix if its level meets the threshold.
pub fn TextHandler::log(self : TextHandler, entry : LogEntry) -> Unit {
  if entry.level.enabled(self.level) {
    let line = (self.fmt)(entry)
    if self.prefix.length() > 0 {
      println(self.prefix + line)
    } else {
      println(line)
    }
  }
}

/// Flushes buffered output. No-op for text handler.
pub fn TextHandler::flush(self : TextHandler) -> Unit {
}

/// Closes the handler and releases resources. No-op for text handler.
pub fn TextHandler::close(self : TextHandler) -> Unit {
}