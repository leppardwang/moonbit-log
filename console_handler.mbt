/// Console handler that prints formatted log output to stdout.
pub(all) struct ConsoleHandler {
  level : Level
  fmt : (LogEntry) -> String
  use_stderr : Bool
}

/// Creates a new ConsoleHandler with the given minimum level and formatter.
pub fn ConsoleHandler::new(level : Level, fmt : (LogEntry) -> String) -> ConsoleHandler {
  { level: level, fmt: fmt, use_stderr: false }
}

/// Sets whether output goes to stderr. Returns a new handler.
pub fn ConsoleHandler::with_stderr(self : ConsoleHandler, v : Bool) -> ConsoleHandler {
  { ..self, use_stderr: v }
}

/// Logs an entry if its level meets the configured threshold.
pub fn ConsoleHandler::log(self : ConsoleHandler, entry : LogEntry) -> Unit {
  if entry.level.enabled(self.level) {
    let line = (self.fmt)(entry)
    println(line)
  }
}

/// Flushes buffered output. No-op for console handler.
pub fn ConsoleHandler::flush(self : ConsoleHandler) -> Unit {
}

/// Closes the handler and releases resources. No-op for console handler.
pub fn ConsoleHandler::close(self : ConsoleHandler) -> Unit {
}