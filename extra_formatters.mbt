///|
/// Logfmt-style formatter producing key=value pairs.
pub fn logfmt_formatter() -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string("level=")
    sb.write_string(entry.level.to_string())
    sb.write_string(" msg=")
    sb.write_string(logfmt_esc(entry.message))
    sb.write_string(" ts=")
    sb.write_string(entry.timestamp.to_string())
    if entry.mod_name.length() > 0 {
      sb.write_string(" module=")
      sb.write_string(logfmt_esc(entry.mod_name))
    }
    if entry.file.length() > 0 {
      sb.write_string(" file=")
      sb.write_string(logfmt_esc(entry.file))
      sb.write_string(":")
      sb.write_string(entry.line.to_string())
    }
    let n = entry.fields.length()
    let mut i = 0
    while i < n {
      let (k, v) = entry.fields[i]
      sb.write_string(" ")
      sb.write_string(k)
      sb.write_string("=")
      sb.write_string(logfmt_esc(v))
      i = i + 1
    }
    sb.to_string()
  }
}

// Escape a string value for safe inclusion in logfmt output.

///|
fn logfmt_esc(s : String) -> String {
  let needs_quoting = s.contains(" ") ||
    s.contains("=") ||
    s.contains("\"") ||
    s.contains("\n")
  if !needs_quoting {
    return s
  }
  let sb = StringBuilder()
  sb.write_string("\"")
  for c in s.iter() {
    if c == '\\' {
      sb.write_string("\\\\")
    } else if c == '"' {
      sb.write_string("\\\"")
    } else if c == '\n' {
      sb.write_string("\\n")
    } else {
      sb.write_char(c)
    }
  }
  sb.write_string("\"")
  sb.to_string()
}

///|
/// XML formatter producing <log> element with structured children.
pub fn xml_formatter() -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    sb.write_string("<log>")
    sb.write_string("<timestamp>")
    sb.write_string(entry.timestamp.to_string())
    sb.write_string("</timestamp>")
    sb.write_string("<level>")
    sb.write_string(xml_esc(entry.level.to_string()))
    sb.write_string("</level>")
    sb.write_string("<message>")
    sb.write_string(xml_esc(entry.message))
    sb.write_string("</message>")
    sb.write_string("<module>")
    sb.write_string(xml_esc(entry.mod_name))
    sb.write_string("</module>")
    sb.write_string("<file>")
    sb.write_string(xml_esc(entry.file))
    sb.write_string("</file>")
    sb.write_string("<line>")
    sb.write_string(entry.line.to_string())
    sb.write_string("</line>")
    sb.write_string("<thread_id>")
    sb.write_string(entry.thread_id.to_string())
    sb.write_string("</thread_id>")
    sb.write_string("<sequence>")
    sb.write_string(entry.sequence.to_string())
    sb.write_string("</sequence>")
    if entry.fields.length() > 0 {
      sb.write_string("<fields>")
      let n = entry.fields.length()
      let mut i = 0
      while i < n {
        let (k, v) = entry.fields[i]
        sb.write_string("<field key=\"")
        sb.write_string(xml_esc(k))
        sb.write_string("\" value=\"")
        sb.write_string(xml_esc(v))
        sb.write_string("\"/>")
        i = i + 1
      }
      sb.write_string("</fields>")
    }
    sb.write_string("</log>")
    sb.to_string()
  }
}

// Escape special XML characters (<, >, &, ", ').

///|
fn xml_esc(s : String) -> String {
  let sb = StringBuilder()
  for c in s.iter() {
    if c == '<' {
      sb.write_string("&lt;")
    } else if c == '>' {
      sb.write_string("&gt;")
    } else if c == '&' {
      sb.write_string("&amp;")
    } else if c == '"' {
      sb.write_string("&quot;")
    } else if c == '\'' {
      sb.write_string("&apos;")
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

// Keep for future ANSI terminal color support

///|
fn _esc_ansi(s : String) -> String {
  let sb = StringBuilder()
  for c in s.iter() {
    if c == '\\' {
      sb.write_string("\\\\")
    } else if c == 'e' || c == 'E' {
      sb.write_string("\u001b")
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
/// Colorized formatter with optional ANSI color codes by log level.
pub fn pretty_formatter(use_color : Bool) -> (LogEntry) -> String {
  fn(entry : LogEntry) -> String {
    let sb = StringBuilder()
    if use_color {
      sb.write_string(color_code(entry.level))
    }
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
    if use_color {
      sb.write_string("\u001b[0m")
    }
    sb.to_string()
  }
}

// Return ANSI color code for the given log level.

///|
fn color_code(l : Level) -> String {
  match l {
    Debug => "\u001b[90m"
    Info => "\u001b[92m"
    Warn => "\u001b[93m"
    Error => "\u001b[91m"
    Fatal => "\u001b[35m"
  }
}

///|
/// ANSI red foreground color code.
pub fn ansi_red() -> String {
  "\u001b[91m"
}

///|
/// ANSI green foreground color code.
pub fn ansi_green() -> String {
  "\u001b[92m"
}

///|
/// ANSI yellow foreground color code.
pub fn ansi_yellow() -> String {
  "\u001b[93m"
}

///|
/// ANSI blue foreground color code.
pub fn ansi_blue() -> String {
  "\u001b[94m"
}

///|
/// ANSI magenta foreground color code.
pub fn ansi_magenta() -> String {
  "\u001b[35m"
}

///|
/// ANSI cyan foreground color code.
pub fn ansi_cyan() -> String {
  "\u001b[96m"
}

///|
/// ANSI gray foreground color code.
pub fn ansi_gray() -> String {
  "\u001b[90m"
}

///|
/// ANSI reset code to clear all attributes.
pub fn ansi_reset() -> String {
  "\u001b[0m"
}

///|
/// ANSI bold / increased intensity code.
pub fn ansi_bold() -> String {
  "\u001b[1m"
}

///|
/// ANSI dim / decreased intensity code.
pub fn ansi_dim() -> String {
  "\u001b[2m"
}
