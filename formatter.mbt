///|
/// Plain-text formatter with timestamp, level, module, message and fields.
pub fn text_formatter() -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string("[")
    sb.write_string(entry.timestamp.to_string())
    sb.write_string("] [")
    sb.write_string(entry.level.to_string())
    sb.write_string("]")
    if entry.mod_name.length() > 0 {
      sb.write_string(" (")
      sb.write_string(entry.mod_name)
      sb.write_string(")")
    }
    sb.write_string(" ")
    sb.write_string(entry.message)
    let n = entry.fields.length()
    let mut i = 0
    while i < n {
      let (k, v) = entry.fields[i]
      sb.write_string(" ")
      sb.write_string(k)
      sb.write_string("=")
      sb.write_string(v)
      i = i + 1
    }
    sb.to_string()
  }
}

///|
/// Minimal formatter producing only level and message.
pub fn compact_formatter() -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string("[")
    sb.write_string(entry.level.to_string())
    sb.write_string("] ")
    sb.write_string(entry.message)
    sb.to_string()
  }
}

///|
/// JSON formatter producing structured log output.
pub fn json_formatter() -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string("{")
    json_field(sb, "timestamp", entry.timestamp.to_string(), true)
    json_field(sb, "level", jstr(entry.level.to_string()), false)
    json_field(sb, "message", jstr(entry.message), false)
    json_field(sb, "module", jstr(entry.mod_name), false)
    json_field(sb, "file", jstr(entry.file), false)
    json_field(sb, "line", entry.line.to_string(), false)
    json_field(sb, "thread_id", entry.thread_id.to_string(), false)
    json_field(sb, "sequence", entry.sequence.to_string(), false)
    let n = entry.fields.length()
    if n > 0 {
      sb.write_string(",\"fields\":{")
      let mut i = 0
      while i < n {
        let (k, v) = entry.fields[i]
        if i > 0 {
          sb.write_string(",")
        }
        sb.write_string(jstr(k))
        sb.write_string(":")
        sb.write_string(jstr(v))
        i = i + 1
      }
      sb.write_string("}")
    }
    sb.write_string("}")
    sb.to_string()
  }
}

// Write a JSON key-value pair, with optional leading comma.

///|
fn json_field(
  sb : StringBuilder,
  key : String,
  value : String,
  first : Bool,
) -> Unit {
  if !first {
    sb.write_string(",")
  }
  sb.write_string("\"")
  sb.write_string(key)
  sb.write_string("\":")
  sb.write_string(value)
}

// Escape and quote a string for JSON output.

///|
fn jstr(s : String) -> String {
  let sb = StringBuilder()
  sb.write_string("\"")
  let chars : Iter[Char] = s.iter()
  for c in chars {
    if c == '\\' {
      sb.write_string("\\\\")
    } else if c == '"' {
      sb.write_string("\\\"")
    } else if c == '\n' {
      sb.write_string("\\n")
    } else if c == '\r' {
      sb.write_string("\\r")
    } else if c == '\t' {
      sb.write_string("\\t")
    } else {
      sb.write_char(c)
    }
  }
  sb.write_string("\"")
  sb.to_string()
}

///|
/// Separator-delimited formatter suitable for audit trails.
pub fn audit_formatter(separator : String) -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string(entry.timestamp.to_string())
    sb.write_string(separator)
    sb.write_string(entry.level.to_string())
    sb.write_string(separator)
    sb.write_string(entry.mod_name)
    sb.write_string(separator)
    sb.write_string(entry.file)
    sb.write_string(":")
    sb.write_string(entry.line.to_string())
    sb.write_string(separator)
    sb.write_string(entry.message)
    let n = entry.fields.length()
    let mut i = 0
    while i < n {
      let (k, v) = entry.fields[i]
      sb.write_string(separator)
      sb.write_string(k)
      sb.write_string("=")
      sb.write_string(v)
      i = i + 1
    }
    sb.to_string()
  }
}

///|
/// Wraps a user-provided formatting function as a LogEntry formatter.
pub fn custom_formatter(f : (LogEntry) -> String) -> (LogEntry) -> String {
  f
}
