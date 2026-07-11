///|
/// Rotating file handler with size-based log rotation.
pub(all) struct RotatingFileHandler {
  level : Level
  fmt : (LogEntry) -> String
  mut lines : Array[String]
  max_lines : Int
  max_files : Int
  base_path : String
  mut file_count : Int
}

///|
/// Creates a new RotatingFileHandler with the given level, formatter, base path, and rotation limits.
pub fn RotatingFileHandler::new(
  level : Level,
  fmt : (LogEntry) -> String,
  base_path : String,
  max_lines : Int,
  max_files : Int,
) -> RotatingFileHandler {
  { level, fmt, lines: [], max_lines, max_files, base_path, file_count: 0 }
}

///|
/// Logs an entry if its level is enabled, buffering until rotation threshold is met.
pub fn RotatingFileHandler::log(
  self : RotatingFileHandler,
  entry : LogEntry,
) -> Unit {
  if entry.level.enabled(self.level) {
    let line = (self.fmt)(entry)
    self.lines.push(line)
    if self.lines.length() >= self.max_lines {
      self.rotate()
    }
  }
}

///|
/// Flushes buffered lines to disk and clears the buffer.
pub fn RotatingFileHandler::flush(self : RotatingFileHandler) -> Unit {
  if self.lines.length() > 0 {
    self.write_current()
    self.lines = []
  }
}

///|
/// Flushes and closes the handler.
pub fn RotatingFileHandler::close(self : RotatingFileHandler) -> Unit {
  self.flush()
}

// Rotates the log file: writes current buffer and increments file counter.

///|
fn RotatingFileHandler::rotate(self : RotatingFileHandler) -> Unit {
  self.write_current()
  self.lines = []
  self.file_count = self.file_count + 1
  if self.file_count > self.max_files {
    self.file_count = 0
  }
}

// Writes the current buffered lines to the rotated file path.

///|
fn RotatingFileHandler::write_current(self : RotatingFileHandler) -> Unit {
  let content = self.lines.join("\n")
  let path = self.rotate_path()
  write_to_file(path, content)
}

// Generates the file path for the current rotation index.

///|
fn RotatingFileHandler::rotate_path(self : RotatingFileHandler) -> String {
  self.base_path + "." + self.file_count.to_string()
}

///|
/// Returns the current buffered lines.
pub fn RotatingFileHandler::lines(self : RotatingFileHandler) -> Array[String] {
  self.lines
}

///|
/// Returns the current file rotation count.
pub fn RotatingFileHandler::file_count(self : RotatingFileHandler) -> Int {
  self.file_count
}

// Placeholder for file I/O; actual implementation should write content to path.

///|
fn write_to_file(_path : String, _content : String) -> Unit {

}

///|
/// Handler that filters log entries by a minimum and maximum level range.
pub(all) struct LevelFilteredHandler {
  inner : HandlerFn
  min_level : Level
  max_level : Level
}

///|
/// Creates a LevelFilteredHandler with the given inner handler and level bounds.
pub fn LevelFilteredHandler::new(
  inner : HandlerFn,
  min_level : Level,
  max_level : Level,
) -> LevelFilteredHandler {
  { inner, min_level, max_level }
}

///|
/// Forwards the entry to the inner handler only if its level falls within [min_level, max_level].
pub fn LevelFilteredHandler::log(
  self : LevelFilteredHandler,
  entry : LogEntry,
) -> Unit {
  if entry.level.enabled(self.min_level) && self.max_level.enabled(entry.level) {
    self.inner.log(entry)
  }
}

///|
/// Delegates flush to the inner handler.
pub fn LevelFilteredHandler::flush(self : LevelFilteredHandler) -> Unit {
  self.inner.flush()
}

///|
/// Delegates close to the inner handler.
pub fn LevelFilteredHandler::close(self : LevelFilteredHandler) -> Unit {
  self.inner.close()
}

///|
/// Handler that only logs every N-th entry (sampling).
pub(all) struct SamplingHandler {
  inner : HandlerFn
  rate : Int
  mut count : Int
}

///|
/// Creates a SamplingHandler that logs one out of every `rate` entries.
pub fn SamplingHandler::new(inner : HandlerFn, rate : Int) -> SamplingHandler {
  { inner, rate, count: 0 }
}

///|
/// Logs the entry if the internal counter is divisible by the sampling rate.
pub fn SamplingHandler::log(self : SamplingHandler, entry : LogEntry) -> Unit {
  self.count = self.count + 1
  if self.count % self.rate == 0 {
    self.inner.log(entry)
  }
}

///|
/// Delegates flush to the inner handler.
pub fn SamplingHandler::flush(self : SamplingHandler) -> Unit {
  self.inner.flush()
}

///|
/// Delegates close to the inner handler.
pub fn SamplingHandler::close(self : SamplingHandler) -> Unit {
  self.inner.close()
}

///|
/// Resets the sampling counter to zero.
pub fn SamplingHandler::reset(self : SamplingHandler) -> Unit {
  self.count = 0
}

///|
/// Handler that suppresses consecutive duplicate log messages.
pub(all) struct DedupHandler {
  inner : HandlerFn
  mut last_message : String
  mut repeat_count : Int
}

///|
/// Creates a DedupHandler that deduplicates repeated log messages.
pub fn DedupHandler::new(inner : HandlerFn) -> DedupHandler {
  { inner, last_message: "", repeat_count: 0 }
}

///|
/// Logs the entry; if it repeats the previous message, increments a counter instead.
pub fn DedupHandler::log(self : DedupHandler, entry : LogEntry) -> Unit {
  if entry.message == self.last_message {
    self.repeat_count = self.repeat_count + 1
  } else {
    if self.repeat_count > 0 {
      self.inner.log(
        LogEntryBuilder::new(
          Level::Info,
          "[repeated " + self.repeat_count.to_string() + " times]",
        ).build(),
      )
    }
    self.inner.log(entry)
    self.last_message = entry.message
    self.repeat_count = 0
  }
}

///|
/// Flushes any pending repeat summary and delegates to the inner handler.
pub fn DedupHandler::flush(self : DedupHandler) -> Unit {
  if self.repeat_count > 0 {
    self.inner.log(
      LogEntryBuilder::new(
        Level::Info,
        "[repeated " + self.repeat_count.to_string() + " times]",
      ).build(),
    )
    self.repeat_count = 0
  }
  self.inner.flush()
}

///|
/// Flushes pending repeats and closes the inner handler.
pub fn DedupHandler::close(self : DedupHandler) -> Unit {
  self.flush()
  self.inner.close()
}

///|
/// Ring buffer handler that keeps a fixed-capacity sliding window of recent log entries.
pub(all) struct RingBufferHandler {
  level : Level
  fmt : (LogEntry) -> String
  mut buffer : Array[LogEntry]
  capacity : Int
  mut head : Int
  mut count : Int
}

///|
/// Creates a RingBufferHandler with the given level, formatter, and capacity.
pub fn RingBufferHandler::new(
  level : Level,
  fmt : (LogEntry) -> String,
  capacity : Int,
) -> RingBufferHandler {
  { level, fmt, buffer: [], capacity, head: 0, count: 0 }
}

///|
/// Adds an entry to the ring buffer, overwriting the oldest entry if full.
pub fn RingBufferHandler::log(
  self : RingBufferHandler,
  entry : LogEntry,
) -> Unit {
  if entry.level.enabled(self.level) {
    if self.count < self.capacity {
      self.buffer.push(entry)
    } else {
      self.buffer[self.head] = entry
    }
    self.head = (self.head + 1) % self.capacity
    if self.count < self.capacity {
      self.count = self.count + 1
    }
  }
}

///|
/// No-op for ring buffer; entries are managed in memory.
pub fn RingBufferHandler::flush(self : RingBufferHandler) -> Unit {
  let _ = self
}

///|
/// No-op for ring buffer; entries are managed in memory.
pub fn RingBufferHandler::close(self : RingBufferHandler) -> Unit {
  let _ = self
}

///|
/// Returns all entries in the ring buffer in insertion order.
pub fn RingBufferHandler::entries(self : RingBufferHandler) -> Array[LogEntry] {
  let n = self.count
  if n == 0 {
    return []
  }
  let result : Array[LogEntry] = []
  let start = if n < self.capacity { 0 } else { self.head }
  let mut i = 0
  while i < n {
    let idx = (start + i) % n
    result.push(self.buffer[idx])
    i = i + 1
  }
  result
}

///|
/// Returns and clears all entries from the ring buffer.
pub fn RingBufferHandler::drain(self : RingBufferHandler) -> Array[LogEntry] {
  let result = self.entries()
  self.buffer = []
  self.head = 0
  self.count = 0
  result
}

///|
/// Returns true if the ring buffer has reached its capacity.
pub fn RingBufferHandler::is_full(self : RingBufferHandler) -> Bool {
  self.count >= self.capacity
}

///|
/// Returns the fraction of capacity currently used, as a value between 0.0 and 1.0.
pub fn RingBufferHandler::fill_ratio(self : RingBufferHandler) -> Double {
  self.count.to_double() / self.capacity.to_double()
}

///|
/// Handler that rate-limits log entries to a maximum per second.
pub(all) struct RateLimitedHandler {
  inner : HandlerFn
  max_per_second : Int
  mut window_count : Int
  mut window_start : Int64
  window_duration : Int64
}

///|
/// Creates a RateLimitedHandler that limits to `max_per_second` entries per second.
pub fn RateLimitedHandler::new(
  inner : HandlerFn,
  max_per_second : Int,
) -> RateLimitedHandler {
  {
    inner,
    max_per_second,
    window_count: 0,
    window_start: 0L,
    window_duration: 1000000L,
  }
}

///|
/// Forwards the entry to the inner handler if the rate limit has not been exceeded.
pub fn RateLimitedHandler::log(
  self : RateLimitedHandler,
  entry : LogEntry,
) -> Unit {
  let now = entry.timestamp
  if now - self.window_start > self.window_duration {
    self.window_start = now
    self.window_count = 0
  }
  if self.window_count < self.max_per_second {
    self.inner.log(entry)
    self.window_count = self.window_count + 1
  }
}

///|
/// Delegates flush to the inner handler.
pub fn RateLimitedHandler::flush(self : RateLimitedHandler) -> Unit {
  self.inner.flush()
}

///|
/// Delegates close to the inner handler.
pub fn RateLimitedHandler::close(self : RateLimitedHandler) -> Unit {
  self.inner.close()
}
