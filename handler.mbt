/// Creates a HandlerFn from individual log, flush, and close callbacks.
pub fn make_handler(log_fn : (LogEntry) -> Unit, flush_fn : () -> Unit, close_fn : () -> Unit) -> HandlerFn {
  { log_fn: log_fn, flush_fn: flush_fn, close_fn: close_fn }
}

/// Function-based log handler dispatching to user-supplied callbacks.
pub(all) struct HandlerFn {
  log_fn : (LogEntry) -> Unit
  flush_fn : () -> Unit
  close_fn : () -> Unit
}

/// Dispatches a log entry to the underlying log callback.
pub fn HandlerFn::log(self : HandlerFn, entry : LogEntry) -> Unit {
  (self.log_fn)(entry)
}

/// Flushes the underlying handler callback.
pub fn HandlerFn::flush(self : HandlerFn) -> Unit {
  (self.flush_fn)()
}

/// Closes the underlying handler callback.
pub fn HandlerFn::close(self : HandlerFn) -> Unit {
  (self.close_fn)()
}