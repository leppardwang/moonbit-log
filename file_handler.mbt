///|
/// File handler that buffers log entries and flushes them to a debug output.
pub(all) struct FileHandler {
  level : Level
  fmt : (LogEntry) -> String
  mut lines : Array[String]
  capacity : Int
}

///|
/// Creates a new FileHandler with the given level, formatter, and buffer capacity.
pub fn FileHandler::new(
  level : Level,
  fmt : (LogEntry) -> String,
  capacity : Int,
) -> FileHandler {
  { level, fmt, lines: [], capacity }
}

///|
/// Logs an entry into the buffer and auto-flushes when capacity is reached.
pub fn FileHandler::log(self : FileHandler, entry : LogEntry) -> Unit {
  if entry.level.enabled(self.level) {
    let line = (self.fmt)(entry)
    self.lines.push(line)
    if self.lines.length() >= self.capacity {
      self.flush()
    }
  }
}

///|
/// Flushes buffered lines to the debug output and clears the buffer.
pub fn FileHandler::flush(self : FileHandler) -> Unit {
  if self.lines.length() > 0 {
    let content = self.lines.join("\n")
    debug_write(content)
    self.lines = []
  }
}

///|
/// Flushes buffered output and closes the handler.
pub fn FileHandler::close(self : FileHandler) -> Unit {
  self.flush()
}

///|
/// Returns the buffered log lines.
pub fn FileHandler::lines(self : FileHandler) -> Array[String] {
  self.lines
}

///|
fn debug_write(content : String) -> Unit {
  println(content)
}

///|
/// Returns the default output path for file handler logs.
pub fn FileHandler::output_path() -> String {
  "/tmp/moonbit-log-output.txt"
}
