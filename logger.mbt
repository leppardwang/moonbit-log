///|
/// Logger managing log level, handlers, and sequence numbering.
pub(all) struct Logger {
  mut handlers : Array[HandlerFn]
  mut level : Level
  mut seq : Int64
}

///|
/// Creates a new Logger with no handlers and Debug level.
pub fn Logger::new() -> Logger {
  { handlers: [], level: Debug, seq: 0L }
}

///|
/// Sets the minimum log level, returning a new Logger instance.
pub fn Logger::with_level(self : Logger, l : Level) -> Logger {
  { handlers: self.handlers, level: l, seq: self.seq }
}

///|
/// Registers a handler to receive log entries.
pub fn Logger::add_handler(self : Logger, h : HandlerFn) -> Unit {
  self.handlers.push(h)
}

///|
/// Removes all registered handlers.
pub fn Logger::clear_handlers(self : Logger) -> Unit {
  self.handlers = []
}

///|
/// Sets the minimum log level for filtering.
pub fn Logger::set_level(self : Logger, l : Level) -> Unit {
  self.level = l
}

///|
fn Logger::dispatch(self : Logger, entry : LogEntry) -> Unit {
  let n = self.handlers.length()
  let mut i = 0
  while i < n {
    self.handlers[i].log(entry)
    i = i + 1
  }
}

///|
/// Logs a message at the given level if it passes the threshold.
pub fn Logger::log(self : Logger, level : Level, message : String) -> Unit {
  if level.enabled(self.level) {
    self.seq = self.seq + 1L
    let entry = LogEntryBuilder::new(level, message)
      .with_sequence(self.seq)
      .build()
    self.dispatch(entry)
  }
}

///|
/// Logs a message at the Debug level.
pub fn Logger::debug(self : Logger, msg : String) -> Unit {
  self.log(Debug, msg)
}

///|
/// Logs a message at the Info level.
pub fn Logger::info(self : Logger, msg : String) -> Unit {
  self.log(Info, msg)
}

///|
/// Logs a message at the Warn level.
pub fn Logger::warn(self : Logger, msg : String) -> Unit {
  self.log(Warn, msg)
}

///|
/// Logs a message at the Error level.
pub fn Logger::error(self : Logger, msg : String) -> Unit {
  self.log(Error, msg)
}

///|
/// Logs a message at the Fatal level.
pub fn Logger::fatal(self : Logger, msg : String) -> Unit {
  self.log(Fatal, msg)
}

///|
/// Logs a message with additional key-value fields.
pub fn Logger::log_with(
  self : Logger,
  level : Level,
  msg : String,
  fields : Array[(String, String)],
) -> Unit {
  if level.enabled(self.level) {
    self.seq = self.seq + 1L
    let entry = LogEntryBuilder::new(level, msg)
      .with_fields(fields)
      .with_sequence(self.seq)
      .build()
    self.dispatch(entry)
  }
}

///|
/// Logs a pre-built entry if its level passes the threshold.
pub fn Logger::log_entry(self : Logger, entry : LogEntry) -> Unit {
  if entry.level.enabled(self.level) {
    self.dispatch(entry)
  }
}

///|
/// Flushes all registered handlers.
pub fn Logger::flush(self : Logger) -> Unit {
  let n = self.handlers.length()
  let mut i = 0
  while i < n {
    self.handlers[i].flush()
    i = i + 1
  }
}

///|
/// Closes all registered handlers.
pub fn Logger::close(self : Logger) -> Unit {
  let n = self.handlers.length()
  let mut i = 0
  while i < n {
    self.handlers[i].close()
    i = i + 1
  }
}
