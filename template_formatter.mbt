///|
/// Replace {placeholder} tokens in a template string with log entry fields.
pub fn lazy_format(template : String, entry : LogEntry) -> String {
  let mut result = template
  result = result.replace(
    old="{timestamp}"[:],
    new=entry.timestamp.to_string()[:],
  )
  result = result.replace(old="{level}"[:], new=entry.level.to_string()[:])
  result = result.replace(old="{message}"[:], new=entry.message[:])
  result = result.replace(old="{module}"[:], new=entry.mod_name[:])
  result = result.replace(old="{file}"[:], new=entry.file[:])
  result = result.replace(old="{line}"[:], new=entry.line.to_string()[:])
  result = result.replace(old="{thread}"[:], new=entry.thread_id.to_string()[:])
  result = result.replace(old="{seq}"[:], new=entry.sequence.to_string()[:])
  let n = entry.fields.length()
  let mut i = 0
  while i < n {
    let (k, v) = entry.fields[i]
    let placeholder = "{" + k + "}"
    result = result.replace(old=placeholder[:], new=v[:])
    i = i + 1
  }
  result
}

///|
/// Create a formatter that applies the given template pattern to every entry.
pub fn pattern_formatter(pattern : String) -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String { lazy_format(pattern, entry) }
}

///|
/// Compact formatter with optional fields and source location display.
pub fn stats_formatter(
  show_fields : Bool,
  show_location : Bool,
) -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string("[")
    sb.write_string(entry.level.to_string())
    sb.write_string("] ")
    sb.write_string(entry.message)
    if show_location && entry.file.length() > 0 {
      sb.write_string(" (")
      sb.write_string(entry.file)
      sb.write_string(":")
      sb.write_string(entry.line.to_string())
      sb.write_string(")")
    }
    if show_fields {
      let n = entry.fields.length()
      if n > 0 {
        sb.write_string(" {")
        let mut i = 0
        while i < n {
          let (k, v) = entry.fields[i]
          if i > 0 {
            sb.write_string(", ")
          }
          sb.write_string(k)
          sb.write_string(": ")
          sb.write_string(v)
          i = i + 1
        }
        sb.write_string("}")
      }
    }
    sb.to_string()
  }
}

///|
/// Multi-line formatter that prints each field on its own line with indentation.
pub fn multi_line_formatter(indent : Int) -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let pad = String::make(indent, ' ')
    let sb = StringBuilder()
    sb.write_string("LogEntry {\n")
    sb.write_string(pad)
    sb.write_string("timestamp: ")
    sb.write_string(entry.timestamp.to_string())
    sb.write_string("\n")
    sb.write_string(pad)
    sb.write_string("level: ")
    sb.write_string(entry.level.to_string())
    sb.write_string("\n")
    sb.write_string(pad)
    sb.write_string("message: ")
    sb.write_string(entry.message)
    sb.write_string("\n")
    sb.write_string(pad)
    sb.write_string("module: ")
    sb.write_string(entry.mod_name)
    sb.write_string("\n")
    sb.write_string(pad)
    sb.write_string("file: ")
    sb.write_string(entry.file)
    sb.write_string("\n")
    sb.write_string(pad)
    sb.write_string("line: ")
    sb.write_string(entry.line.to_string())
    sb.write_string("\n")
    sb.write_string(pad)
    sb.write_string("fields: [")
    let n = entry.fields.length()
    let mut i = 0
    while i < n {
      if i > 0 {
        sb.write_string(", ")
      }
      let (k, v) = entry.fields[i]
      sb.write_string(k)
      sb.write_string("=")
      sb.write_string(v)
      i = i + 1
    }
    sb.write_string("]\n}")
    sb.to_string()
  }
}
