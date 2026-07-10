/// Log level enumeration indicating severity.
pub(all) enum Level {
  Debug
  Info
  Warn
  Error
  Fatal
}

/// Converts the level to its integer representation (0-4).
pub fn Level::to_int(self : Level) -> Int {
  match self {
    Debug => 0
    Info => 1
    Warn => 2
    Error => 3
    Fatal => 4
  }
}

/// Converts the level to its uppercase string representation.
pub fn Level::to_string(self : Level) -> String {
  match self {
    Debug => "DEBUG"
    Info => "INFO"
    Warn => "WARN"
    Error => "ERROR"
    Fatal => "FATAL"
  }
}

/// Parses a string into a Level. Falls back to Debug on unknown input.
pub fn Level::from_string(s : String) -> Level {
  match s {
    "DEBUG" | "debug" | "Debug" => Debug
    "INFO" | "info" | "Info" => Info
    "WARN" | "warn" | "Warn" => Warn
    "ERROR" | "error" | "Error" => Error
    "FATAL" | "fatal" | "Fatal" => Fatal
    _ => Debug
  }
}

/// Returns true if this level is at or above the given threshold.
pub fn Level::enabled(self : Level, threshold : Level) -> Bool {
  self.to_int() >= threshold.to_int()
}

/// Returns all available log levels in ascending severity order.
pub fn Level::all() -> Array[Level] {
  [Debug, Info, Warn, Error, Fatal]
}

/// Returns the less severe of two levels.
pub fn Level::min(a : Level, b : Level) -> Level {
  if a.to_int() <= b.to_int() { a } else { b }
}

/// Returns the more severe of two levels.
pub fn Level::max(a : Level, b : Level) -> Level {
  if a.to_int() >= b.to_int() { a } else { b }
}

pub impl Show for Level with fn to_string(self : Level) -> String {
  Level::to_string(self)
}

pub impl Eq for Level with fn equal(self : Level, other : Level) -> Bool {
  self.to_int() == other.to_int()
}