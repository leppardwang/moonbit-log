///|
/// Async logger that batches log entries and flushes them in bulk to the inner handler.
pub(all) struct AsyncLogger {
  inner : HandlerFn
  mut queue : Array[LogEntry]
  mut batch_size : Int
  mut dropped_count : Int
}

///|
/// Creates an AsyncLogger with the given inner handler and batch size.
pub fn AsyncLogger::new(inner : HandlerFn, batch_size : Int) -> AsyncLogger {
  { inner, queue: [], batch_size, dropped_count: 0 }
}

///|
/// Queues an entry; automatically flushes when the queue reaches batch size.
pub fn AsyncLogger::log(self : AsyncLogger, entry : LogEntry) -> Unit {
  self.queue.push(entry)
  if self.queue.length() >= self.batch_size {
    self.flush()
  }
}

///|
/// Flushes all queued entries to the inner handler.
pub fn AsyncLogger::flush(self : AsyncLogger) -> Unit {
  if self.queue.length() > 0 {
    let batch = self.queue
    self.queue = []
    for e in batch {
      self.inner.log(e)
    }
    self.inner.flush()
  }
}

///|
/// Flushes the queue and closes the inner handler.
pub fn AsyncLogger::close(self : AsyncLogger) -> Unit {
  self.flush()
  self.inner.close()
}

///|
/// Returns the current number of queued entries.
pub fn AsyncLogger::queue_size(self : AsyncLogger) -> Int {
  self.queue.length()
}

///|
/// Returns the count of dropped entries (entries that were skipped).
pub fn AsyncLogger::dropped_count(self : AsyncLogger) -> Int {
  self.dropped_count
}

///|
/// Sets the batch size threshold for automatic flushing.
pub fn AsyncLogger::set_batch_size(self : AsyncLogger, size : Int) -> Unit {
  self.batch_size = size
}

///|
/// Batching logger that flushes entries based on batch size or time interval.
pub(all) struct BatchingLogger {
  inner : HandlerFn
  mut entries : Array[LogEntry]
  mut batch_size : Int
  flush_interval : Int64
  mut last_flush : Int64
}

///|
/// Creates a BatchingLogger with the given handler, batch size, and flush interval in microseconds.
pub fn BatchingLogger::new(
  inner : HandlerFn,
  batch_size : Int,
  flush_interval_us : Int64,
) -> BatchingLogger {
  {
    inner,
    entries: [],
    batch_size,
    flush_interval: flush_interval_us,
    last_flush: 0L,
  }
}

///|
/// Queues an entry; flushes automatically when batch size is reached.
pub fn BatchingLogger::log(self : BatchingLogger, entry : LogEntry) -> Unit {
  self.entries.push(entry)
  if self.entries.length() >= self.batch_size {
    self.flush()
  }
}

///|
/// Flushes all queued entries to the inner handler and resets the flush timer.
pub fn BatchingLogger::flush(self : BatchingLogger) -> Unit {
  if self.entries.length() > 0 {
    let batch = self.entries
    self.entries = []
    for e in batch {
      self.inner.log(e)
    }
    self.inner.flush()
    self.last_flush = 0L
  }
}

///|
/// Flushes the queue and closes the inner handler.
pub fn BatchingLogger::close(self : BatchingLogger) -> Unit {
  self.flush()
  self.inner.close()
}

///|
/// Returns the current number of queued entries.
pub fn BatchingLogger::queue_size(self : BatchingLogger) -> Int {
  self.entries.length()
}

///|
/// Handler that transforms each log entry before forwarding to the inner handler.
pub(all) struct EntryTransformer {
  inner : HandlerFn
  transform : (LogEntry) -> LogEntry
}

///|
/// Creates an EntryTransformer with the given inner handler and transform function.
pub fn EntryTransformer::new(
  inner : HandlerFn,
  transform : (LogEntry) -> LogEntry,
) -> EntryTransformer {
  { inner, transform }
}

///|
/// Applies the transform function to the entry, then forwards it to the inner handler.
pub fn EntryTransformer::log(self : EntryTransformer, entry : LogEntry) -> Unit {
  let transformed = (self.transform)(entry)
  self.inner.log(transformed)
}

///|
/// Delegates flush to the inner handler.
pub fn EntryTransformer::flush(self : EntryTransformer) -> Unit {
  self.inner.flush()
}

///|
/// Delegates close to the inner handler.
pub fn EntryTransformer::close(self : EntryTransformer) -> Unit {
  self.inner.close()
}

///|
/// Returns a copy of the entry with timestamp set to sequence + 1.
pub fn add_timestamp(entry : LogEntry) -> LogEntry {
  let e = entry
  { ..e, timestamp: entry.sequence + 1L }
}

///|
/// Returns a copy of the entry with the thread_id field replaced.
pub fn add_thread_id(entry : LogEntry, id : Int) -> LogEntry {
  { ..entry, thread_id: id }
}

///|
/// Returns a copy of the entry with all fields removed.
pub fn strip_fields(entry : LogEntry) -> LogEntry {
  { ..entry, fields: [] }
}

///|
/// Returns a copy of the entry with a prefix prepended to the message.
pub fn prefix_message(entry : LogEntry, prefix : String) -> LogEntry {
  { ..entry, message: prefix + entry.message }
}

///|
/// Returns a copy of the entry with a suffix appended to the message.
pub fn suffix_message(entry : LogEntry, suffix : String) -> LogEntry {
  { ..entry, message: entry.message + suffix }
}

///|
/// Returns a copy of the entry with the level changed from `from` to `to`.
pub fn redirect_level(entry : LogEntry, from : Level, to : Level) -> LogEntry {
  if entry.level == from {
    { ..entry, level: to }
  } else {
    entry
  }
}

///|
/// Returns a copy of the entry with the specified field value masked as "****".
pub fn mask_field(entry : LogEntry, field_key : String) -> LogEntry {
  let new_fields : Array[(String, String)] = []
  let n = entry.fields.length()
  let mut i = 0
  while i < n {
    let (k, v) = entry.fields[i]
    if k == field_key {
      new_fields.push((k, "****"))
    } else {
      new_fields.push((k, v))
    }
    i = i + 1
  }
  { ..entry, fields: new_fields }
}
