///|
/// Configuration struct for building loggers with preset options.
pub(all) struct LogConfig {
  level : Level
  format_type : String
  output_type : String
  batch_size : Int
  max_files : Int
  max_lines : Int
  ansi_color : Bool
  audit_separator : String
}

///|
/// Returns a LogConfig with default values (Debug level, text format, console output).
pub fn LogConfig::default() -> LogConfig {
  {
    level: Level::Debug,
    format_type: "text",
    output_type: "console",
    batch_size: 100,
    max_files: 3,
    max_lines: 1000,
    ansi_color: false,
    audit_separator: "|",
  }
}

///|
/// Returns a copy with the log level replaced.
pub fn LogConfig::with_level(self : LogConfig, l : Level) -> LogConfig {
  { ..self, level: l }
}

///|
/// Returns a copy with the format type replaced (e.g. "text", "json", "compact").
pub fn LogConfig::with_format(self : LogConfig, fmt : String) -> LogConfig {
  { ..self, format_type: fmt }
}

///|
/// Returns a copy with the output type replaced (e.g. "console", "file", "audit").
pub fn LogConfig::with_output(self : LogConfig, out : String) -> LogConfig {
  { ..self, output_type: out }
}

///|
/// Returns a copy with the batch size replaced.
pub fn LogConfig::with_batch(self : LogConfig, size : Int) -> LogConfig {
  { ..self, batch_size: size }
}

///|
/// Returns a copy with the ANSI color flag replaced.
pub fn LogConfig::with_color(self : LogConfig, color : Bool) -> LogConfig {
  { ..self, ansi_color: color }
}

///|
/// Builds a synchronous Logger from this configuration.
pub fn LogConfig::build_logger(self : LogConfig) -> Logger {
  let logger = Logger::new()
  logger.set_level(self.level)
  let fmt = self.select_formatter()
  let h = ConsoleHandler::new(self.level, fmt)
  let hfn = make_handler(fn(e) { h.log(e) }, fn() {  }, fn() {  })
  logger.add_handler(hfn)
  logger
}

///|
/// Builds an async Logger that batches log entries before writing.
pub fn LogConfig::build_async(self : LogConfig) -> Logger {
  let logger = Logger::new()
  logger.set_level(self.level)
  let fmt = self.select_formatter()
  let mem = MemoryHandler::new(self.level, fmt)
  let hfn = make_handler(fn(e) { mem.log(e) }, fn() {  }, fn() {  })
  let async_h = AsyncLogger::new(hfn, self.batch_size)
  let ahfn = make_handler(fn(e) { async_h.log(e) }, fn() { async_h.flush() }, fn() {
    async_h.close()
  })
  logger.add_handler(ahfn)
  logger
}

///|
/// Builds a MultiHandler from this configuration, allowing multiple outputs.
pub fn LogConfig::build_multi(self : LogConfig) -> MultiHandler {
  let mh = MultiHandler::new()
  let fmt = self.select_formatter()
  let h = ConsoleHandler::new(self.level, fmt)
  let hfn = make_handler(fn(e) { h.log(e) }, fn() {  }, fn() {  })
  mh.add(hfn)
  mh
}

// Selects the formatter function based on the format_type field.

///|
fn LogConfig::select_formatter(self : LogConfig) -> (LogEntry) -> String {
  match self.format_type {
    "text" => text_formatter()
    "compact" => compact_formatter()
    "json" => json_formatter()
    "audit" => audit_formatter(self.audit_separator)
    "logfmt" => logfmt_formatter()
    "xml" => xml_formatter()
    "pretty" => pretty_formatter(self.ansi_color)
    _ => text_formatter()
  }
}

///|
/// Returns a human-readable description of this configuration.
pub fn LogConfig::describe(self : LogConfig) -> String {
  let sb = StringBuilder()
  sb.write_string("LogConfig(")
  sb.write_string("level=")
  sb.write_string(self.level.to_string())
  sb.write_string(", format=")
  sb.write_string(self.format_type)
  sb.write_string(", output=")
  sb.write_string(self.output_type)
  sb.write_string(", batch=")
  sb.write_string(self.batch_size.to_string())
  sb.write_string(", color=")
  sb.write_string(self.ansi_color.to_string())
  sb.write_string(")")
  sb.to_string()
}

///|
/// Creates a logger with default config at the given level.
pub fn quick_logger(level : Level) -> Logger {
  let cfg = LogConfig::default().with_level(level)
  cfg.build_logger()
}

///|
/// Creates a JSON-format logger at the given level.
pub fn json_logger(level : Level) -> Logger {
  let cfg = LogConfig::default().with_level(level).with_format("json")
  cfg.build_logger()
}

///|
/// Creates an audit logger with the given level and separator.
pub fn audit_logger(level : Level, sep : String) -> Logger {
  let _ = LogConfig::default()
    .with_level(level)
    .with_format("audit")
    .with_output("audit")
  let logger = Logger::new()
  logger.set_level(level)
  let fmt = audit_formatter(sep)
  let audit = AuditHandler::new(level, fmt, 1000)
  let hfn = make_handler(fn(e) { audit.log(e) }, fn() {  }, fn() {  })
  logger.add_handler(hfn)
  logger
}

///|
/// Creates a logger with default Debug level and compact console format.
pub fn default_setup() -> Logger {
  let logger = Logger::new()
  logger.set_level(Level::Debug)
  let fmt = compact_formatter()
  let console = ConsoleHandler::new(Level::Debug, fmt)
  let hfn = make_handler(fn(e) { console.log(e) }, fn() {  }, fn() {  })
  logger.add_handler(hfn)
  logger
}
