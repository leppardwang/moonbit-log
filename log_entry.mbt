///|
/// Structured log entry carrying metadata and message content.
pub(all) struct LogEntry {
  timestamp : Int64
  level : Level
  message : String
  mod_name : String
  fields : Array[(String, String)]
  file : String
  line : Int
  thread_id : Int
  sequence : Int64
}

///|
/// Builder for constructing a LogEntry with optional metadata.
pub(all) struct LogEntryBuilder {
  entry : LogEntry
}

///|
/// Creates a new builder with the given level and message.
pub fn LogEntryBuilder::new(level : Level, message : String) -> LogEntryBuilder {
  {
    entry: {
      timestamp: 0L,
      level,
      message,
      mod_name: "",
      fields: [],
      file: "",
      line: 0,
      thread_id: 0,
      sequence: 0L,
    },
  }
}

///|
/// Sets the module name on the entry.
pub fn LogEntryBuilder::with_module(
  self : LogEntryBuilder,
  name : String,
) -> LogEntryBuilder {
  let e = self.entry
  { entry: { ..e, mod_name: name } }
}

///|
/// Adds a single key-value field to the entry.
pub fn LogEntryBuilder::with_field(
  self : LogEntryBuilder,
  key : String,
  value : String,
) -> LogEntryBuilder {
  let e = self.entry
  let new_fields = e.fields + [(key, value)]
  { entry: { ..e, fields: new_fields } }
}

///|
/// Appends multiple key-value fields to the entry.
pub fn LogEntryBuilder::with_fields(
  self : LogEntryBuilder,
  extras : Array[(String, String)],
) -> LogEntryBuilder {
  let e = self.entry
  { entry: { ..e, fields: e.fields + extras } }
}

///|
/// Sets the source file and line number on the entry.
pub fn LogEntryBuilder::with_location(
  self : LogEntryBuilder,
  file : String,
  line : Int,
) -> LogEntryBuilder {
  let e = self.entry
  { entry: { ..e, file, line } }
}

///|
/// Sets the thread ID on the entry.
pub fn LogEntryBuilder::with_thread(
  self : LogEntryBuilder,
  id : Int,
) -> LogEntryBuilder {
  let e = self.entry
  { entry: { ..e, thread_id: id } }
}

///|
/// Sets the sequence number on the entry.
pub fn LogEntryBuilder::with_sequence(
  self : LogEntryBuilder,
  seq : Int64,
) -> LogEntryBuilder {
  let e = self.entry
  { entry: { ..e, sequence: seq } }
}

///|
/// Sets the timestamp on the entry.
pub fn LogEntryBuilder::with_timestamp(
  self : LogEntryBuilder,
  ts : Int64,
) -> LogEntryBuilder {
  let e = self.entry
  { entry: { ..e, timestamp: ts } }
}

///|
/// Finalizes and returns the constructed LogEntry.
pub fn LogEntryBuilder::build(self : LogEntryBuilder) -> LogEntry {
  self.entry
}

///|
/// Returns the log level of the entry.
pub fn LogEntry::level(self : LogEntry) -> Level {
  self.level
}

///|
/// Returns the log message of the entry.
pub fn LogEntry::message(self : LogEntry) -> String {
  self.message
}

///|
/// Returns the module name associated with the entry.
pub fn LogEntry::module_name(self : LogEntry) -> String {
  self.mod_name
}

///|
/// Returns the key-value fields attached to the entry.
pub fn LogEntry::fields(self : LogEntry) -> Array[(String, String)] {
  self.fields
}

///|
/// Returns the timestamp of the entry.
pub fn LogEntry::timestamp(self : LogEntry) -> Int64 {
  self.timestamp
}

///|
/// Returns the source file path of the log call.
pub fn LogEntry::location_file(self : LogEntry) -> String {
  self.file
}

///|
/// Returns the source line number of the log call.
pub fn LogEntry::location_line(self : LogEntry) -> Int {
  self.line
}

///|
/// Returns the thread ID of the log call.
pub fn LogEntry::thread_id(self : LogEntry) -> Int {
  self.thread_id
}

///|
/// Returns the sequence number of the entry.
pub fn LogEntry::sequence(self : LogEntry) -> Int64 {
  self.sequence
}
