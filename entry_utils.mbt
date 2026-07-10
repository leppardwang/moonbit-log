/// Serializes a LogEntry to a JSON string.
pub fn entry_to_json_string(entry : LogEntry) -> String {
  json_formatter()(entry)
}

/// Deserializes a JSON string into a LogEntry, returning None on failure.
pub fn entry_from_json(json : String) -> LogEntry? {
  let ts = extract_json_field_int64(json, "timestamp")
  let level_str = extract_json_field_str(json, "level")
  let msg = extract_json_field_str(json, "message")
  let mod_name = extract_json_field_str(json, "module")
  let file = extract_json_field_str(json, "file")
  let line = extract_json_field_int(json, "line")
  let thread = extract_json_field_int(json, "thread_id")
  let seq = extract_json_field_int64(json, "sequence")
  match (ts, level_str, msg) {
    (Some(t), Some(l), Some(m)) => {
      let level = Level::from_string(l)
      let mut builder = LogEntryBuilder::new(level, m)
        .with_timestamp(t)
      match mod_name {
        Some(mn) => {
          if mn.length() > 0 { builder = builder.with_module(mn) }
        }
        None => ()
      }
      match file {
        Some(f) => {
          let ln = match line { Some(v) => v; None => 0 }
          builder = builder.with_location(f, ln)
        }
        None => ()
      }
      let tid = match thread { Some(v) => v; None => 0 }
      builder = builder.with_thread(tid)
      let sq = match seq { Some(v) => v; None => t }
      builder = builder.with_sequence(sq)
      Some(builder.build())
    }
    _ => None
  }
}

// Extracts an Int64 field from a JSON string by field name.
fn extract_json_field_int64(json : String, name : String) -> Int64? {
  let pattern = "\"" + name + "\":"
  let pos = json.find(pattern[:])
  match pos {
    Some(p) => {
      let start = p + pattern.length()
      let mut end = start
      let chars = json.iter()
      let mut idx = 0
      for c in chars {
        if idx >= start {
          if c >= '0' && c <= '9' || c == '-' {
            end = idx + 1
          } else if idx > start {
            break
          }
        }
        idx = idx + 1
      }
      if end > start {
        let num_str = json[start:end].to_owned()
        Some(parse_int64(num_str))
      } else {
        None
      }
    }
    None => None
  }
}

// Extracts an Int field from a JSON string by field name.
fn extract_json_field_int(json : String, name : String) -> Int? {
  let pattern = "\"" + name + "\":"
  let pos = json.find(pattern[:])
  match pos {
    Some(p) => {
      let start = p + pattern.length()
      let mut end = start
      let chars = json.iter()
      let mut idx = 0
      for c in chars {
        if idx >= start {
          if (c >= '0' && c <= '9') || c == '-' {
            end = idx + 1
          } else if idx > start {
            break
          }
        }
        idx = idx + 1
      }
      if end > start {
        let num_str = json[start:end].to_owned()
        Some(parse_int(num_str))
      } else {
        None
      }
    }
    None => None
  }
}

// Extracts a string field from a JSON string by field name.
fn extract_json_field_str(json : String, name : String) -> String? {
  let pattern = "\"" + name + "\":\""
  let pos = json.find(pattern[:])
  match pos {
    Some(p) => {
      let start = p + pattern.length()
      let chars = json.iter()
      let mut end = start
      let mut escaped = false
      let mut idx = 0
      for c in chars {
        if idx >= start {
          if escaped { escaped = false
          } else if c == '\\' { escaped = true
          } else if c == '"' { end = idx; break }
        }
        idx = idx + 1
      }
      if end > start {
        Some(json[start:end].to_owned())
      } else {
        None
      }
    }
    None => None
  }
}

// Parses a decimal string to an Int.
fn parse_int(s : String) -> Int {
  let mut val = 0
  let mut neg = false
  let chars = s.iter()
  let mut idx = 0
  for c in chars {
    if idx == 0 && c == '-' { neg = true; idx = idx + 1; continue }
    val = val * 10 + (c.to_int() - 48)
    idx = idx + 1
  }
  if neg { -val } else { val }
}

// Parses a decimal string to an Int64.
fn parse_int64(s : String) -> Int64 {
  let mut val = 0L
  let mut neg = false
  let chars = s.iter()
  let mut idx = 0
  for c in chars {
    if idx == 0 && c == '-' { neg = true; idx = idx + 1; continue }
    val = val * 10L + (c.to_int() - 48).to_int64()
    idx = idx + 1
  }
  if neg { -val } else { val }
}

/// Returns true if the entry contains a field with the given key.
pub fn entry_has_field(entry : LogEntry, key : String) -> Bool {
  let n = entry.fields.length()
  let mut i = 0
  while i < n {
    let (k, _) = entry.fields[i]
    if k == key { return true }
    i = i + 1
  }
  false
}

/// Returns the value of a field by key, or None if not found.
pub fn entry_get_field(entry : LogEntry, key : String) -> String? {
  let n = entry.fields.length()
  let mut i = 0
  while i < n {
    let (k, v) = entry.fields[i]
    if k == key { return Some(v) }
    i = i + 1
  }
  None
}

/// Merges two log entries, combining their fields (base fields first, then other).
pub fn entry_merge(base : LogEntry, other : LogEntry) -> LogEntry {
  let all_fields = base.fields + other.fields
  { ..base, fields: all_fields }
}

/// Returns a copy of the entry with additional fields appended.
pub fn entry_with_fields(entry : LogEntry, extras : Array[(String, String)]) -> LogEntry {
  { ..entry, fields: entry.fields + extras }
}

/// Serializes an array of LogEntries to a JSON array string.
pub fn entries_to_json_array(entries : Array[LogEntry]) -> String {
  let sb = StringBuilder()
  sb.write_string("[")
  let n = entries.length()
  let mut i = 0
  while i < n {
    if i > 0 { sb.write_string(",") }
    sb.write_string(entry_to_json_string(entries[i]))
    i = i + 1
  }
  sb.write_string("]")
  sb.to_string()
}

/// Sorts an array of LogEntries by timestamp in ascending order.
pub fn entries_sort_by_timestamp(entries : Array[LogEntry]) -> Array[LogEntry] {
  let n = entries.length()
  let result = entries
  let mut i = 0
  while i < n {
    let mut j = i + 1
    while j < n {
      if result[j].timestamp < result[i].timestamp {
        let tmp = result[i]
        result[i] = result[j]
        result[j] = tmp
      }
      j = j + 1
    }
    i = i + 1
  }
  result
}

/// Filters entries using a predicate function, returning matching entries.
pub fn entries_filter(entries : Array[LogEntry], predicate : (LogEntry) -> Bool) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  for e in entries {
    if predicate(e) { result.push(e) }
  }
  result
}

/// Returns the number of entries in the array.
pub fn entries_count(entries : Array[LogEntry]) -> Int {
  entries.length()
}