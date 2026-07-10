/// A simple stopwatch for measuring elapsed time in microseconds.
pub(all) struct Stopwatch {
  mut elapsed : Double
  mut running : Bool
  mut start_time : @bench.Timestamp
}

/// Creates a new stopped Stopwatch with zero elapsed time.
pub fn Stopwatch::new() -> Stopwatch {
  { elapsed: 0.0, running: false, start_time: @bench.monotonic_clock_start() }
}

/// Starts the stopwatch; no-op if already running.
pub fn Stopwatch::start(self : Stopwatch) -> Unit {
  if !self.running {
    self.running = true
    self.start_time = @bench.monotonic_clock_start()
  }
}

/// Stops the stopwatch and accumulates the elapsed time; no-op if not running.
pub fn Stopwatch::stop(self : Stopwatch) -> Unit {
  if self.running {
    self.elapsed = self.elapsed + @bench.monotonic_clock_end(self.start_time)
    self.running = false
  }
}

/// Resets the stopwatch to zero and stops it.
pub fn Stopwatch::reset(self : Stopwatch) -> Unit {
  self.elapsed = 0.0
  self.running = false
}

/// Resets and immediately starts the stopwatch.
pub fn Stopwatch::restart(self : Stopwatch) -> Unit {
  self.reset()
  self.start()
}

/// Returns the total elapsed time in microseconds (including current run if running).
pub fn Stopwatch::elapsed_micros(self : Stopwatch) -> Double {
  if self.running {
    self.elapsed + @bench.monotonic_clock_end(self.start_time)
  } else {
    self.elapsed
  }
}

/// Returns the total elapsed time in milliseconds.
pub fn Stopwatch::elapsed_millis(self : Stopwatch) -> Double {
  self.elapsed_micros() / 1000.0
}

/// Returns the total elapsed time in seconds.
pub fn Stopwatch::elapsed_secs(self : Stopwatch) -> Double {
  self.elapsed_micros() / 1000000.0
}

/// Returns true if the stopwatch is currently running.
pub fn Stopwatch::is_running(self : Stopwatch) -> Bool {
  self.running
}

/// Result of a benchmark run, containing timing statistics.
pub(all) struct BenchmarkResult {
  name : String
  iterations : Int
  total_time_us : Double
  min_time_us : Double
  max_time_us : Double
}

/// Returns the benchmark name.
pub fn BenchmarkResult::name(self : BenchmarkResult) -> String { self.name }

/// Returns the number of iterations executed.
pub fn BenchmarkResult::iterations(self : BenchmarkResult) -> Int { self.iterations }

/// Returns the total time across all iterations in microseconds.
pub fn BenchmarkResult::total_time_us(self : BenchmarkResult) -> Double { self.total_time_us }

/// Returns the average time per iteration in microseconds.
pub fn BenchmarkResult::avg_time_us(self : BenchmarkResult) -> Double {
  self.total_time_us / self.iterations.to_double()
}

/// Returns the minimum single-iteration time in microseconds.
pub fn BenchmarkResult::min_time_us(self : BenchmarkResult) -> Double { self.min_time_us }

/// Returns the maximum single-iteration time in microseconds.
pub fn BenchmarkResult::max_time_us(self : BenchmarkResult) -> Double { self.max_time_us }

/// Runs a function `iterations` times and returns timing statistics.
pub fn benchmark(name : String, iterations : Int, f : () -> Unit) -> BenchmarkResult {
  let mut total = 0.0
  let mut min_val = 999999999.0
  let mut max_val = 0.0
  let mut i = 0
  while i < iterations {
    let sw = Stopwatch::new()
    sw.start()
    f()
    sw.stop()
    let elapsed = sw.elapsed_micros()
    total = total + elapsed
    if elapsed < min_val { min_val = elapsed }
    if elapsed > max_val { max_val = elapsed }
    i = i + 1
  }
  { name: name, iterations: iterations, total_time_us: total, min_time_us: min_val, max_time_us: max_val }
}

/// Runs warmup iterations, then benchmarks and returns timing statistics.
pub fn benchmark_warmup(name : String, iterations : Int, warmup : Int, f : () -> Unit) -> BenchmarkResult {
  let mut i = 0
  while i < warmup {
    f()
    i = i + 1
  }
  benchmark(name, iterations, f)
}

/// Returns a human-readable benchmark report string.
pub fn benchmark_report(result : BenchmarkResult) -> String {
  let sb = StringBuilder()
  sb.write_string("Benchmark: ")
  sb.write_string(result.name)
  sb.write_string("\n")
  sb.write_string("  Iterations: ")
  sb.write_string(result.iterations.to_string())
  sb.write_string("\n")
  sb.write_string("  Total time: ")
  sb.write_string(format_double(result.total_time_us, 2))
  sb.write_string(" us\n")
  sb.write_string("  Avg time:   ")
  sb.write_string(format_double(result.avg_time_us(), 2))
  sb.write_string(" us\n")
  sb.write_string("  Min time:   ")
  sb.write_string(format_double(result.min_time_us, 2))
  sb.write_string(" us\n")
  sb.write_string("  Max time:   ")
  sb.write_string(format_double(result.max_time_us, 2))
  sb.write_string(" us")
  sb.to_string()
}

/// Formats the stopwatch's elapsed time as a human-readable string (us/ms/s).
pub fn Stopwatch::format_elapsed(self : Stopwatch) -> String {
  let us = self.elapsed_micros()
  if us < 1000.0 {
    format_double(us, 0) + " us"
  } else if us < 1000000.0 {
    format_double(us / 1000.0, 2) + " ms"
  } else {
    format_double(us / 1000000.0, 3) + " s"
  }
}

/// Measures and returns the execution time of a function in microseconds.
pub fn measure_time(f : () -> Unit) -> Double {
  let sw = Stopwatch::new()
  sw.start()
  f()
  sw.stop()
  sw.elapsed_micros()
}

/// Measures and returns the execution time of a function in milliseconds.
pub fn measure_time_ms(f : () -> Unit) -> Double {
  measure_time(f) / 1000.0
}

/// Meter that counts operations and measures throughput (ops per second).
pub(all) struct ThroughputMeter {
  sw : Stopwatch
  mut count : Int64
}

/// Creates a new ThroughputMeter with zero count and a stopped stopwatch.
pub fn ThroughputMeter::new() -> ThroughputMeter {
  { sw: Stopwatch::new(), count: 0L }
}

/// Increments the operation count by one; starts the timer on first call.
pub fn ThroughputMeter::increment(self : ThroughputMeter) -> Unit {
  if self.count == 0L { self.sw.start() }
  self.count = self.count + 1L
}

/// Records a batch of operations (adds n to count); starts the timer on first call.
pub fn ThroughputMeter::record_batch(self : ThroughputMeter, n : Int64) -> Unit {
  if self.count == 0L { self.sw.start() }
  self.count = self.count + n
}

/// Stops the throughput measurement timer.
pub fn ThroughputMeter::stop(self : ThroughputMeter) -> Unit {
  self.sw.stop()
}

/// Returns the measured throughput in operations per second.
pub fn ThroughputMeter::ops_per_second(self : ThroughputMeter) -> Double {
  let elapsed_us = self.sw.elapsed_micros()
  if elapsed_us > 0.0 {
    self.count.to_double() / (elapsed_us / 1000000.0)
  } else {
    0.0
  }
}

/// Returns a human-readable throughput string (e.g. "1.23 K ops/s").
pub fn ThroughputMeter::format_throughput(self : ThroughputMeter) -> String {
  let ops = self.ops_per_second()
  if ops > 1000000.0 {
    format_double(ops / 1000000.0, 2) + " M ops/s"
  } else if ops > 1000.0 {
    format_double(ops / 1000.0, 2) + " K ops/s"
  } else {
    format_double(ops, 2) + " ops/s"
  }
}

/// Returns the elapsed measurement time as a human-readable string.
pub fn ThroughputMeter::elapsed_str(self : ThroughputMeter) -> String {
  self.sw.format_elapsed()
}

/// Runs two benchmarks and returns a side-by-side comparison report.
pub fn benchmark_compare(name_a : String, name_b : String, iterations : Int, f_a : () -> Unit, f_b : () -> Unit) -> String {
  let r_a = benchmark(name_a, iterations, f_a)
  let r_b = benchmark(name_b, iterations, f_b)
  let sb = StringBuilder()
  sb.write_string("Comparison: ")
  sb.write_string(name_a)
  sb.write_string(" vs ")
  sb.write_string(name_b)
  sb.write_string("\n")
  sb.write_string(benchmark_report(r_a))
  sb.write_string("\n")
  sb.write_string(benchmark_report(r_b))
  sb.write_string("\n")
  let avg_a = r_a.avg_time_us()
  let avg_b = r_b.avg_time_us()
  if avg_b > 0.0 {
    let ratio = avg_a / avg_b
    sb.write_string("Ratio: ")
    sb.write_string(format_double(ratio, 2))
    sb.write_string("x")
  }
  sb.to_string()
}

// Formats a double to the specified number of decimal places.
fn format_double(v : Double, decimals : Int) -> String {
  let s = v.to_string()
  let dot_pos = s.find(".")
  match dot_pos {
    Some(pos) => {
      let end = pos + 1 + decimals
      if end < s.length() {
        s[:end].to_owned()
      } else {
        s
      }
    }
    None => s
  }
}