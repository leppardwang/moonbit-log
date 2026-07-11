///|
let global_logger_inst : Logger = Logger::new()

///|
/// Returns the global singleton logger instance.
pub fn get_global_logger() -> Logger {
  global_logger_inst
}

///|
/// Replaces the global logger's level and handlers with those from the given logger.
pub fn set_global_logger(logger : Logger) -> Unit {
  global_logger_inst.set_level(logger.level)
  let n = logger.handlers.length()
  let mut i = 0
  while i < n {
    global_logger_inst.add_handler(logger.handlers[i])
    i = i + 1
  }
}

///|
/// Logs a debug message via the global logger.
pub fn g_debug(msg : String) -> Unit {
  global_logger_inst.debug(msg)
}

///|
/// Logs an info message via the global logger.
pub fn g_info(msg : String) -> Unit {
  global_logger_inst.info(msg)
}

///|
/// Logs a warning message via the global logger.
pub fn g_warn(msg : String) -> Unit {
  global_logger_inst.warn(msg)
}

///|
/// Logs an error message via the global logger.
pub fn g_error(msg : String) -> Unit {
  global_logger_inst.error(msg)
}

///|
/// Logs a fatal message via the global logger.
pub fn g_fatal(msg : String) -> Unit {
  global_logger_inst.fatal(msg)
}

///|
/// Logs a message at the specified level via the global logger.
pub fn g_log(level : Level, msg : String) -> Unit {
  global_logger_inst.log(level, msg)
}

///|
/// Logs a message with structured fields at the specified level via the global logger.
pub fn g_log_with(
  level : Level,
  msg : String,
  fields : Array[(String, String)],
) -> Unit {
  global_logger_inst.log_with(level, msg, fields)
}

///|
/// Flushes all handlers on the global logger.
pub fn g_flush() -> Unit {
  global_logger_inst.flush()
}

///|
/// Closes all handlers on the global logger.
pub fn g_close() -> Unit {
  global_logger_inst.close()
}

///|
/// Initializes the global logger with a default console handler using compact format.
pub fn init_default_console() -> Unit {
  let h = ConsoleHandler::new(Level::Debug, compact_formatter())
  let hfn = make_handler(fn(e) { h.log(e) }, fn() {  }, fn() {  })
  global_logger_inst.add_handler(hfn)
}

///|
/// Initializes the global logger with a default JSON console handler at Info level.
pub fn init_default_json() -> Unit {
  let h = ConsoleHandler::new(Level::Info, json_formatter())
  let hfn = make_handler(fn(e) { h.log(e) }, fn() {  }, fn() {  })
  global_logger_inst.add_handler(hfn)
}

///|
/// Creates a logger from a JSON config string describing level and output format.
pub fn from_config_json(json : String) -> Logger {
  let logger = Logger::new()
  let has_json = json.contains("json")
  let has_console = json.contains("console")
  let level_str = extract_json_field_str(json, "level")
  let level = match level_str {
    Some(s) => Level::from_string(s)
    None => Level::Debug
  }
  logger.set_level(level)
  if has_json {
    let h = ConsoleHandler::new(level, json_formatter())
    let hfn = make_handler(fn(e) { h.log(e) }, fn() {  }, fn() {  })
    logger.add_handler(hfn)
  }
  if has_console {
    let h = ConsoleHandler::new(level, compact_formatter())
    let hfn = make_handler(fn(e) { h.log(e) }, fn() {  }, fn() {  })
    logger.add_handler(hfn)
  }
  logger
}

///|
/// Reconfigures the global logger with the given level and formatter, replacing all handlers.
pub fn configure(level : Level, fmt : (LogEntry) -> String) -> Unit {
  global_logger_inst.set_level(level)
  let n = global_logger_inst.handlers.length()
  let mut i = 0
  while i < n {
    global_logger_inst.handlers[i].flush()
    i = i + 1
  }
  global_logger_inst.clear_handlers()
  let h = ConsoleHandler::new(level, fmt)
  let hfn = make_handler(fn(e) { h.log(e) }, fn() {  }, fn() {  })
  global_logger_inst.add_handler(hfn)
}
