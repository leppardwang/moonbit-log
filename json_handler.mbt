/// JSON handler that outputs log entries as JSON-formatted strings.
pub(all) struct JsonHandler {
  level : Level
  fmt : (LogEntry) -> String
}

/// Creates a new JsonHandler with the given minimum level and formatter.
pub fn JsonHandler::new(level : Level, fmt : (LogEntry) -> String) -> JsonHandler {
  { level: level, fmt: fmt }
}

/// Logs an entry in JSON format if its level meets the threshold.
pub fn JsonHandler::log(self : JsonHandler, entry : LogEntry) -> Unit {
  if entry.level.enabled(self.level) {
    let line = (self.fmt)(entry)
    println(line)
  }
}

/// Flushes buffered output. No-op for JSON handler.
pub fn JsonHandler::flush(self : JsonHandler) -> Unit {
}

/// Closes the handler and releases resources. No-op for JSON handler.
pub fn JsonHandler::close(self : JsonHandler) -> Unit {
}