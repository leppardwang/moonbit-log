# Changelog

## [1.0.0] - 2026-07-15

### Added
- 6-level log system: Debug, Info, Warn, Error, Fatal, Audit
- 15 handler types: Console, File, JSON, Text, Memory, Audit, RotatingFile, RingBuffer, Sampling, Dedup, RateLimited, LevelFiltered, AsyncLogger, BatchingLogger, NullHandler
- 14 formatters: text, compact, json, audit, logfmt, xml, pretty (ANSI), pattern, multi_line, kv, banner, csv, stats, custom
- Structured logging with key-value field pairs
- Global logger convenience API (g_debug/info/warn/error/fatal)
- Builder-based configuration system with JSON config support
- Log entry utilities: JSON serialization, filtering, sorting, merging, field masking
- Performance toolkit: Stopwatch, Benchmark, ThroughputMeter, benchmark_compare
- Entry transformation pipeline: mask_field, strip_fields, redirect_level
- File rotation by size with retention count limit
- Ring buffer with drain and fill ratio
- Message deduplication with duplicate counting
- Rate limiting by operations per second
- Level-based sampling
- Async batch logging with queue size triggers
- Time-interval batch logging
- ANSI colorized pretty printer
