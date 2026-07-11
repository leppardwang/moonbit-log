///|
/// Multi-handler that delegates log operations to a list of sub-handlers.
pub(all) struct MultiHandler {
  handlers : Array[HandlerFn]
}

///|
/// Creates an empty MultiHandler with no sub-handlers.
pub fn MultiHandler::new() -> MultiHandler {
  { handlers: [] }
}

///|
/// Adds a sub-handler to the multi-handler.
pub fn MultiHandler::add(self : MultiHandler, h : HandlerFn) -> Unit {
  self.handlers.push(h)
}

///|
/// Delegates logging to all registered sub-handlers.
pub fn MultiHandler::log(self : MultiHandler, entry : LogEntry) -> Unit {
  let n = self.handlers.length()
  let mut i = 0
  while i < n {
    self.handlers[i].log(entry)
    i = i + 1
  }
}

///|
/// Flushes all registered sub-handlers.
pub fn MultiHandler::flush(self : MultiHandler) -> Unit {
  let n = self.handlers.length()
  let mut i = 0
  while i < n {
    self.handlers[i].flush()
    i = i + 1
  }
}

///|
/// Closes all registered sub-handlers.
pub fn MultiHandler::close(self : MultiHandler) -> Unit {
  let n = self.handlers.length()
  let mut i = 0
  while i < n {
    self.handlers[i].close()
    i = i + 1
  }
}
