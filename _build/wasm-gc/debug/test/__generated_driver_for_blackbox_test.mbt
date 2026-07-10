// #region Define traits with default implementations

///|
/// is_being_cancelled may be unused if there's no async test
#warnings("-unused_value")
trait MoonBit_Async_Test_Driver {
  fn run_async_tests(@moonbitlang/core/prelude.Array[async () -> Unit]) -> Unit = _
  fn is_being_cancelled() -> Bool = _
}

///|
impl MoonBit_Async_Test_Driver with fn run_async_tests(_) {
  ()
}

///|
impl MoonBit_Async_Test_Driver with fn is_being_cancelled() {
  false
}

///|
trait MoonBit_Test_Driver {
  /// returns if the test is found and executed
  fn run_test(
    @moonbitlang/core/prelude.Array[async () -> Unit],
    String,
    Int,
    () -> Unit,
    (String, String, Bool) -> Unit,
    (Error) -> String,
  ) -> Bool raise MoonBitTestDriverInternalSkipTest = _
}

///|
impl MoonBit_Test_Driver with fn run_test(_, _, _, _, _, _) {
  false
}

// #endregion
// #region Define abstract types for namespace with implementation declarations

///|
priv type MoonBit_Test_Driver_Internal_No_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_No_Args

///|
priv type MoonBit_Test_Driver_Internal_With_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_With_Args

///|
priv type MoonBit_Test_Driver_Internal_Async_No_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_Async_No_Args

///|
priv type MoonBit_Test_Driver_Internal_Async_With_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_Async_With_Args

///|
priv type MoonBit_Test_Driver_Internal_With_Bench_Args

///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_With_Bench_Args

///|
priv type MoonBit_Async_Test_Driver_Impl

///|
impl MoonBit_Async_Test_Driver for MoonBit_Async_Test_Driver_Impl

// #endregion

// #region Utility Types

///|
/// Maybe unused if there's no tests
#warnings("-unused_type_declaration")
priv struct MoonBitTestDriverInternalTestMap[F](
  @moonbitlang/core/prelude.Map[
    String,
    @moonbitlang/core/prelude.Map[Int, (F, ReadOnlyArray[String])],
  ]
)

///|
priv suberror MoonBitTestDriverInternalSkipTest {
  MoonBitTestDriverInternalSkipTest(name~ : String)
}

// #endregion
///|
fn moonbit_test_driver_internal_error_to_string(x : Error) -> String = "%error.to_string"

///|
#cfg(any(target="native", target="llvm"))
fn string_get(s : String, index : Int) -> Int = "%string_get"

///|
#cfg(not(target="js"))
fn moonbit_unsafe_char_from_int(x : Int) -> Char = "%identity"

///|
#cfg(any(target="native", target="llvm"))
const MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE = true

///|
#cfg(not(any(target="native", target="llvm")))
const MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE = false

// =========================================================
// ================== BEGIN WASM SPECIFIC ==================
// =========================================================

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_get_file_name(
  file_name : MoonbitTestDriverInternalExternString,
) -> String {
  moonbit_test_driver_internal_string_from_extern(file_name)
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
#external
type MoonbitTestDriverInternalStringReadHandle

///|
#cfg(any(target="wasm", target="wasm-gc"))
#external
type MoonbitTestDriverInternalExternString

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_begin_read_string(
  s : MoonbitTestDriverInternalExternString,
) -> MoonbitTestDriverInternalStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_string_read_char(
  handle : MoonbitTestDriverInternalStringReadHandle,
) -> Int = "__moonbit_fs_unstable" "string_read_char"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_finish_read_string(
  handle : MoonbitTestDriverInternalStringReadHandle,
) = "__moonbit_fs_unstable" "finish_read_string"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn fixedarray_to_bytes(arr : FixedArray[Byte]) -> Bytes = "%identity"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn moonbit_test_driver_internal_string_from_extern(
  e : MoonbitTestDriverInternalExternString,
) -> String {
  let buf = FixedArray::make(512, Byte::default())
  let mut len = 0
  let handle = moonbit_test_driver_internal_begin_read_string(e)
  while true {
    let ch = moonbit_test_driver_internal_string_read_char(handle)
    if ch == -1 {
      break
    } else {
      let written_bytes_len = buf.set_utf16le_char(
        len,
        moonbit_unsafe_char_from_int(ch),
      )
      len += written_bytes_len
    }
  }
  moonbit_test_driver_internal_finish_read_string(handle)
  fixedarray_to_bytes(buf).to_unchecked_string(offset=0, length=len).to_string()
}

// =========================================================
// =================== END WASM SPECIFIC ===================
// =========================================================

// =========================================================
// ============== BEGIN NATIVE/LLVM SPECIFIC ===============
// =========================================================

///|
#cfg(any(target="native", target="llvm"))
fn moonbit_test_driver_internal_native_parse_args() -> @moonbitlang/core/prelude.Array[
  (String, Int),
] {
  fn moonbit_test_driver_internal_parse_int_(s : String) -> Int {
    let mut res = 0
    let len = s.length()
    for i in 0..<len {
      res = res * 10 + (string_get(s, i) - '0')
    }
    res
  }

  fn moonbit_test_driver_internal_utf8_bytes_to_mbt_string(
    bytes : Bytes,
  ) -> String {
    let res = @moonbitlang/core/prelude.StringBuilder::new()
    let len = bytes.length()
    let mut i = 0
    while i < len {
      let mut c = bytes[i].to_int()
      if c < 0x80 {
        res.write_char(moonbit_unsafe_char_from_int(c))
        i += 1
      } else if c < 0xE0 {
        if i + 1 >= len {
          break
        }
        c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
        res.write_char(moonbit_unsafe_char_from_int(c))
        i += 2
      } else if c < 0xF0 {
        if i + 2 >= len {
          break
        }
        c = ((c & 0x0F) << 12) |
          ((bytes[i + 1].to_int() & 0x3F) << 6) |
          (bytes[i + 2].to_int() & 0x3F)
        res.write_char(moonbit_unsafe_char_from_int(c))
        i += 3
      } else {
        if i + 3 >= len {
          break
        }
        c = ((c & 0x07) << 18) |
          ((bytes[i + 1].to_int() & 0x3F) << 12) |
          ((bytes[i + 2].to_int() & 0x3F) << 6) |
          (bytes[i + 3].to_int() & 0x3F)
        c -= 0x10000
        res.write_char(moonbit_unsafe_char_from_int((c >> 10) + 0xD800))
        res.write_char(moonbit_unsafe_char_from_int((c & 0x3FF) + 0xDC00))
        i += 4
      }
    }
    res.to_string()
  }

  fn moonbit_test_driver_internal_get_cli_args_internal() -> @moonbitlang/core/prelude.Array[
    String,
  ] {
    let tmp = moonbit_test_driver_internal_get_cli_args_ffi()
    let res = @moonbitlang/core/prelude.Array::new(capacity=tmp.length())
    for i in 0..<tmp.length() {
      res.push(moonbit_test_driver_internal_utf8_bytes_to_mbt_string(tmp[i]))
    }
    res
  }

  fn moonbit_test_driver_internal_split_mbt_string(
    s : String,
    sep : Char,
  ) -> @moonbitlang/core/prelude.Array[String] {
    let res = []
    let mut i = 0
    let mut start = 0
    while i < s.length() {
      if moonbit_unsafe_char_from_int(string_get(s, i)) == sep {
        res.push(s.unsafe_substring(start~, end=i))
        start = i + 1
      }
      i += 1
    }
    if start < s.length() {
      res.push(s.unsafe_substring(start~, end=s.length()))
    }
    res
  }

  let file_and_index = []
  let cli_args = moonbit_test_driver_internal_get_cli_args_internal()
  let test_args = moonbit_test_driver_internal_split_mbt_string(
    cli_args[1],
    '/',
  )
  for arg in test_args {
    let file_and_range = moonbit_test_driver_internal_split_mbt_string(arg, ':')
    let file = file_and_range[0]
    let range = file_and_range[1]
    let start_and_end = moonbit_test_driver_internal_split_mbt_string(
      range, '-',
    )
    let start = moonbit_test_driver_internal_parse_int_(start_and_end[0])
    let end = moonbit_test_driver_internal_parse_int_(start_and_end[1])
    for i in start..<end {
      file_and_index.push((file, i))
    }
  }
  file_and_index
}

///|
#cfg(any(target="native", target="llvm"))
fn moonbit_test_driver_internal_get_cli_args_ffi() -> FixedArray[Bytes] = "$moonbit.get_cli_args"

// =========================================================
// =============== END NATIVE/LLVM SPECIFIC ================
// =========================================================

// =========================================================
// -================== BEGIN JS SPECIFIC ===================
// =========================================================

///|
#cfg(target="js")
#external
type MoonBitTestDriverInternalTestEntry

///|
#cfg(target="js")
extern "js" fn MoonBitTestDriverInternalTestEntry::filename(
  self : Self,
) -> String =
  #| (entry) => entry[0]

///|
#cfg(target="js")
extern "js" fn MoonBitTestDriverInternalTestEntry::index(self : Self) -> Int =
  #| (entry) => entry[1]

///|
/// JavaScript error captured by the generated test driver.
pub(all) suberror MoonBitTestDriverInternalJsError {
  MoonBitTestDriverInternalJsError(String)
}

///|
/// Maybe unused if there's no tests
#cfg(target="js")
#warnings("-unused_value")
fn moonbit_test_driver_internal_catch_error(
  f : () -> Unit raise,
  on_ok~ : () -> Unit,
  on_err~ : (Error) -> Unit,
) -> Unit {
  moonbit_test_driver_internal_js_catch(
    on_err=err_str => on_err(MoonBitTestDriverInternalJsError(err_str)),
    () => {
      try f() catch {
        err => on_err(err)
      } noraise {
        _ => on_ok()
      }
    },
  )
}

///|
#cfg(target="js")
extern "js" fn moonbit_test_driver_internal_js_catch(
  f : () -> Unit,
  on_err~ : (String) -> Unit,
) =
  #| (f, on_err) => {
  #|   try {
  #|     f()
  #|   } catch (err) {
  #|     const msg = err.stack.toString()
  #|     on_err(msg)
  #|   }
  #| }

///|
/// Maybe unused if there's no tests
#cfg(not(target="js"))
#warnings("-unused_value")
fn moonbit_test_driver_internal_catch_error(
  f : () -> Unit raise,
  on_ok~ : () -> Unit,
  on_err~ : (Error) -> Unit,
) -> Unit {
  try f() catch {
    err => on_err(err)
  } noraise {
    _ => on_ok()
  }
}

// =========================================================
// -=================== END JS SPECIFIC ====================
// =========================================================
// This file is introduced when tests without args is needed

///|
let moonbit_test_driver_internal_no_args_tests : MoonBitTestDriverInternalTestMap[
  () -> Unit raise,
] = {
  "text_handler.mbt": {
  },
  "template_formatter.mbt": {
  },
  "stopwatch.mbt": {
  },
  "multi_handler.mbt": {
  },
  "memory_handler.mbt": {
  },
  "logger.mbt": {
  },
  "log_test.mbt": {
    0: (__test_6c6f675f746573742e6d6274_0, ["Level::to_int"]),
    1: (__test_6c6f675f746573742e6d6274_1, ["Level::to_string"]),
    2: (__test_6c6f675f746573742e6d6274_2, ["Level::from_string"]),
    3: (__test_6c6f675f746573742e6d6274_3, ["Level::enabled"]),
    4: (__test_6c6f675f746573742e6d6274_4, ["Level::all"]),
    5: (__test_6c6f675f746573742e6d6274_5, ["Level::min_max"]),
    6: (__test_6c6f675f746573742e6d6274_6, ["LogEntryBuilder::basic"]),
    7: (__test_6c6f675f746573742e6d6274_7, ["LogEntryBuilder::with_module"]),
    8: (__test_6c6f675f746573742e6d6274_8, ["LogEntryBuilder::with_field"]),
    9: (__test_6c6f675f746573742e6d6274_9, ["LogEntryBuilder::with_location"]),
    10: (__test_6c6f675f746573742e6d6274_10, ["LogEntryBuilder::with_sequence"]),
    11: (__test_6c6f675f746573742e6d6274_11, ["text_formatter output"]),
    12: (__test_6c6f675f746573742e6d6274_12, ["compact_formatter output"]),
    13: (__test_6c6f675f746573742e6d6274_13, ["json_formatter output"]),
    14: (__test_6c6f675f746573742e6d6274_14, ["audit_formatter output"]),
    15: (__test_6c6f675f746573742e6d6274_15, ["custom_formatter"]),
    16: (__test_6c6f675f746573742e6d6274_16, ["ConsoleHandler filters by level"]),
    17: (__test_6c6f675f746573742e6d6274_17, ["MemoryHandler records entries"]),
    18: (__test_6c6f675f746573742e6d6274_18, ["MemoryHandler count_by_level"]),
    19: (__test_6c6f675f746573742e6d6274_19, ["MemoryHandler clear"]),
    20: (__test_6c6f675f746573742e6d6274_20, ["FileHandler buffers and flushes"]),
    21: (__test_6c6f675f746573742e6d6274_21, ["AuditHandler stores and filters"]),
    22: (__test_6c6f675f746573742e6d6274_22, ["Logger basic logging"]),
    23: (__test_6c6f675f746573742e6d6274_23, ["Logger level filtering"]),
    24: (__test_6c6f675f746573742e6d6274_24, ["Logger log_with fields"]),
    25: (__test_6c6f675f746573742e6d6274_25, ["LogEntry accessors"]),
    26: (__test_6c6f675f746573742e6d6274_26, ["Stopwatch basic"]),
    27: (__test_6c6f675f746573742e6d6274_27, ["Stopwatch reset"]),
    28: (__test_6c6f675f746573742e6d6274_28, ["Stopwatch restart"]),
    29: (__test_6c6f675f746573742e6d6274_29, ["Stopwatch units"]),
    30: (__test_6c6f675f746573742e6d6274_30, ["benchmark runs function"]),
    31: (__test_6c6f675f746573742e6d6274_31, ["benchmark report format"]),
    32: (__test_6c6f675f746573742e6d6274_32, ["MultiHandler dispatches"]),
    33: (__test_6c6f675f746573742e6d6274_33, ["AuditHandler search_by_message"]),
    34: (__test_6c6f675f746573742e6d6274_34, ["LogEntryBuilder::with_sequence idempotent"]),
    35: (__test_6c6f675f746573742e6d6274_35, ["Logger with multiple handlers"]),
    36: (__test_6c6f675f746573742e6d6274_36, ["Flush and close handlers"]),
    37: (__test_6c6f675f746573742e6d6274_37, ["Level::Eq comparison"]),
    38: (__test_6c6f675f746573742e6d6274_38, ["Level::Show display"]),
  },
  "log_entry.mbt": {
  },
  "level.mbt": {
  },
  "json_handler.mbt": {
  },
  "handler.mbt": {
  },
  "global_logger.mbt": {
  },
  "formatter.mbt": {
  },
  "file_handler.mbt": {
  },
  "extra_handler_utils.mbt": {
  },
  "extra_formatters.mbt": {
  },
  "extended_test.mbt": {
    0: (__test_657874656e6465645f746573742e6d6274_0, ["LevelFilteredHandler filters correctly"]),
    1: (__test_657874656e6465645f746573742e6d6274_1, ["SamplingHandler samples at rate"]),
    2: (__test_657874656e6465645f746573742e6d6274_2, ["DedupHandler deduplicates repeats"]),
    3: (__test_657874656e6465645f746573742e6d6274_3, ["RingBufferHandler capacity"]),
    4: (__test_657874656e6465645f746573742e6d6274_4, ["RingBufferHandler drain"]),
    5: (__test_657874656e6465645f746573742e6d6274_5, ["RingBufferHandler fill_ratio"]),
    6: (__test_657874656e6465645f746573742e6d6274_6, ["RotatingFileHandler rotation"]),
    7: (__test_657874656e6465645f746573742e6d6274_7, ["RateLimitedHandler respects limit"]),
    8: (__test_657874656e6465645f746573742e6d6274_8, ["AsyncLogger batches entries"]),
    9: (__test_657874656e6465645f746573742e6d6274_9, ["BatchingLogger batches"]),
    10: (__test_657874656e6465645f746573742e6d6274_10, ["EntryTransformer transforms entry"]),
    11: (__test_657874656e6465645f746573742e6d6274_11, ["redirect_level changes level"]),
    12: (__test_657874656e6465645f746573742e6d6274_12, ["mask_field hides sensitive data"]),
    13: (__test_657874656e6465645f746573742e6d6274_13, ["strip_fields removes all fields"]),
    14: (__test_657874656e6465645f746573742e6d6274_14, ["entry_has_field and entry_get_field"]),
    15: (__test_657874656e6465645f746573742e6d6274_15, ["entry_merge combines fields"]),
    16: (__test_657874656e6465645f746573742e6d6274_16, ["logfmt_formatter output"]),
    17: (__test_657874656e6465645f746573742e6d6274_17, ["xml_formatter output"]),
    18: (__test_657874656e6465645f746573742e6d6274_18, ["pretty_formatter with color"]),
    19: (__test_657874656e6465645f746573742e6d6274_19, ["ansi helper functions"]),
    20: (__test_657874656e6465645f746573742e6d6274_20, ["global_logger singleton"]),
    21: (__test_657874656e6465645f746573742e6d6274_21, ["configure global logger"]),
    22: (__test_657874656e6465645f746573742e6d6274_22, ["entries_to_json_array"]),
    23: (__test_657874656e6465645f746573742e6d6274_23, ["entry_to_json_string output"]),
    24: (__test_657874656e6465645f746573742e6d6274_24, ["entries_filter"]),
    25: (__test_657874656e6465645f746573742e6d6274_25, ["entries_sort_by_timestamp"]),
    26: (__test_657874656e6465645f746573742e6d6274_26, ["init_default_console"]),
    27: (__test_657874656e6465645f746573742e6d6274_27, ["add_thread_id transformer"]),
    28: (__test_657874656e6465645f746573742e6d6274_28, ["suffix_message transformer"]),
    29: (__test_657874656e6465645f746573742e6d6274_29, ["from_config_json with console"]),
  },
  "entry_utils.mbt": {
  },
  "edge_case_test.mbt": {
    0: (__test_656467655f636173655f746573742e6d6274_0, ["Level::from_string case insensitive"]),
    1: (__test_656467655f636173655f746573742e6d6274_1, ["Level::from_string unknown defaults to Debug"]),
    2: (__test_656467655f636173655f746573742e6d6274_2, ["Level ordering"]),
    3: (__test_656467655f636173655f746573742e6d6274_3, ["LogEntryBuilder chaining"]),
    4: (__test_656467655f636173655f746573742e6d6274_4, ["LogEntryBuilder empty fields"]),
    5: (__test_656467655f636173655f746573742e6d6274_5, ["LogEntryBuilder empty module"]),
    6: (__test_656467655f636173655f746573742e6d6274_6, ["MemoryHandler level filtering"]),
    7: (__test_656467655f636173655f746573742e6d6274_7, ["MemoryHandler formatted_lines"]),
    8: (__test_656467655f636173655f746573742e6d6274_8, ["MemoryHandler first_entry"]),
    9: (__test_656467655f636173655f746573742e6d6274_9, ["DedupHandler no repeat single"]),
    10: (__test_656467655f636173655f746573742e6d6274_10, ["DedupHandler repeat without flush"]),
    11: (__test_656467655f636173655f746573742e6d6274_11, ["DedupHandler flush with pending repeat"]),
    12: (__test_656467655f636173655f746573742e6d6274_12, ["SamplingHandler reset"]),
    13: (__test_656467655f636173655f746573742e6d6274_13, ["SamplingHandler rate 1 (all pass)"]),
    14: (__test_656467655f636173655f746573742e6d6274_14, ["RingBufferHandler empty entries"]),
    15: (__test_656467655f636173655f746573742e6d6274_15, ["RingBufferHandler is_full"]),
    16: (__test_656467655f636173655f746573742e6d6274_16, ["RingBufferHandler overwrite oldest"]),
    17: (__test_656467655f636173655f746573742e6d6274_17, ["LevelFilteredHandler single level"]),
    18: (__test_656467655f636173655f746573742e6d6274_18, ["RateLimitedHandler resets window"]),
    19: (__test_656467655f636173655f746573742e6d6274_19, ["AsyncLogger flush on demand"]),
    20: (__test_656467655f636173655f746573742e6d6274_20, ["AsyncLogger close flushes"]),
    21: (__test_656467655f636173655f746573742e6d6274_21, ["AsyncLogger set_batch_size"]),
    22: (__test_656467655f636173655f746573742e6d6274_22, ["BatchingLogger flush on demand"]),
    23: (__test_656467655f636173655f746573742e6d6274_23, ["BatchingLogger close flushes"]),
    24: (__test_656467655f636173655f746573742e6d6274_24, ["EntryTransformer flush close propagate"]),
    25: (__test_656467655f636173655f746573742e6d6274_25, ["EntryTransformer strip_fields"]),
    26: (__test_656467655f636173655f746573742e6d6274_26, ["EntryTransformer mask_field"]),
    27: (__test_656467655f636173655f746573742e6d6274_27, ["text_formatter without module"]),
    28: (__test_656467655f636173655f746573742e6d6274_28, ["compact_formatter no extra"]),
    29: (__test_656467655f636173655f746573742e6d6274_29, ["audit_formatter custom separator"]),
    30: (__test_656467655f636173655f746573742e6d6274_30, ["logfmt_formatter quoting"]),
    31: (__test_656467655f636173655f746573742e6d6274_31, ["xml_formatter special chars"]),
    32: (__test_656467655f636173655f746573742e6d6274_32, ["pretty_formatter no color"]),
    33: (__test_656467655f636173655f746573742e6d6274_33, ["pattern_formatter custom template"]),
    34: (__test_656467655f636173655f746573742e6d6274_34, ["multi_line_formatter basic"]),
    35: (__test_656467655f636173655f746573742e6d6274_35, ["stats_formatter with fields and location"]),
    36: (__test_656467655f636173655f746573742e6d6274_36, ["stats_formatter without fields"]),
    37: (__test_656467655f636173655f746573742e6d6274_37, ["entry_to_json_string roundtrip"]),
    38: (__test_656467655f636173655f746573742e6d6274_38, ["entry_from_json valid"]),
    39: (__test_656467655f636173655f746573742e6d6274_39, ["entry_from_json invalid returns None"]),
    40: (__test_656467655f636173655f746573742e6d6274_40, ["entries_filter all pass"]),
    41: (__test_656467655f636173655f746573742e6d6274_41, ["entries_filter none pass"]),
    42: (__test_656467655f636173655f746573742e6d6274_42, ["entries_sort_by_timestamp already sorted"]),
    43: (__test_656467655f636173655f746573742e6d6274_43, ["entries_sort_by_timestamp empty"]),
    44: (__test_656467655f636173655f746573742e6d6274_44, ["entry_merge with empty fields"]),
    45: (__test_656467655f636173655f746573742e6d6274_45, ["entry_with_fields appends"]),
    46: (__test_656467655f636173655f746573742e6d6274_46, ["entries_to_json_array empty"]),
    47: (__test_656467655f636173655f746573742e6d6274_47, ["entries_to_json_array single"]),
    48: (__test_656467655f636173655f746573742e6d6274_48, ["entries_count utility"]),
    49: (__test_656467655f636173655f746573742e6d6274_49, ["LogConfig describe format"]),
    50: (__test_656467655f636173655f746573742e6d6274_50, ["LogConfig with_color"]),
    51: (__test_656467655f636173655f746573742e6d6274_51, ["LogConfig with_batch"]),
    52: (__test_656467655f636173655f746573742e6d6274_52, ["quick_logger and json_logger"]),
    53: (__test_656467655f636173655f746573742e6d6274_53, ["default_setup creates logger"]),
    54: (__test_656467655f636173655f746573742e6d6274_54, ["MultiHandler flush and close"]),
    55: (__test_656467655f636173655f746573742e6d6274_55, ["RotatingFileHandler no rotation below max"]),
    56: (__test_656467655f636173655f746573742e6d6274_56, ["Stopwatch elapsed units consistency"]),
    57: (__test_656467655f636173655f746573742e6d6274_57, ["Stopwatch format_elapsed output"]),
    58: (__test_656467655f636173655f746573742e6d6274_58, ["measure_time returns positive"]),
    59: (__test_656467655f636173655f746573742e6d6274_59, ["measure_time_ms returns positive"]),
    60: (__test_656467655f636173655f746573742e6d6274_60, ["ThroughputMeter basic ops"]),
    61: (__test_656467655f636173655f746573742e6d6274_61, ["ThroughputMeter record_batch"]),
    62: (__test_656467655f636173655f746573742e6d6274_62, ["ThroughputMeter format throughput"]),
    63: (__test_656467655f636173655f746573742e6d6274_63, ["ThroughputMeter elapsed_str"]),
    64: (__test_656467655f636173655f746573742e6d6274_64, ["benchmark_warmup runs"]),
    65: (__test_656467655f636173655f746573742e6d6274_65, ["benchmark_compare produces output"]),
    66: (__test_656467655f636173655f746573742e6d6274_66, ["lazy_format template"]),
    67: (__test_656467655f636173655f746573742e6d6274_67, ["lazy_format unknown placeholder stays"]),
    68: (__test_656467655f636173655f746573742e6d6274_68, ["global_logger g_log_with"]),
    69: (__test_656467655f636173655f746573742e6d6274_69, ["global_logger g_flush and g_close"]),
    70: (__test_656467655f636173655f746573742e6d6274_70, ["configure with compact formatter"]),
    71: (__test_656467655f636173655f746573742e6d6274_71, ["from_config_json with json"]),
    72: (__test_656467655f636173655f746573742e6d6274_72, ["handler fn wrapping"]),
    73: (__test_656467655f636173655f746573742e6d6274_73, ["NullHandler discards all"]),
    74: (__test_656467655f636173655f746573742e6d6274_74, ["ConditionHandler filters by level"]),
    75: (__test_656467655f636173655f746573742e6d6274_75, ["ConditionHandler flush close propagate"]),
    76: (__test_656467655f636173655f746573742e6d6274_76, ["ThrottledHandler deduplicates messages"]),
    77: (__test_656467655f636173655f746573742e6d6274_77, ["ThrottledHandler flush close"]),
    78: (__test_656467655f636173655f746573742e6d6274_78, ["CountingHandler counts by level"]),
    79: (__test_656467655f636173655f746573742e6d6274_79, ["CountingHandler reset"]),
    80: (__test_656467655f636173655f746573742e6d6274_80, ["CountingHandler flush close"]),
    81: (__test_656467655f636173655f746573742e6d6274_81, ["kv_formatter output"]),
    82: (__test_656467655f636173655f746573742e6d6274_82, ["banner_formatter output"]),
    83: (__test_656467655f636173655f746573742e6d6274_83, ["csv_formatter output"]),
    84: (__test_656467655f636173655f746573742e6d6274_84, ["entries_summary output"]),
    85: (__test_656467655f636173655f746573742e6d6274_85, ["entries_summary empty"]),
    86: (__test_656467655f636173655f746573742e6d6274_86, ["entries_by_level filters correctly"]),
    87: (__test_656467655f636173655f746573742e6d6274_87, ["entries_by_level no match"]),
    88: (__test_656467655f636173655f746573742e6d6274_88, ["entries_earliest and latest"]),
    89: (__test_656467655f636173655f746573742e6d6274_89, ["entries_earliest empty"]),
    90: (__test_656467655f636173655f746573742e6d6274_90, ["entries_latest empty"]),
    91: (__test_656467655f636173655f746573742e6d6274_91, ["entries_reject filters out"]),
    92: (__test_656467655f636173655f746573742e6d6274_92, ["entries_reject all pass"]),
    93: (__test_656467655f636173655f746573742e6d6274_93, ["Entries utility with empty array"]),
  },
  "console_handler.mbt": {
  },
  "config.mbt": {
  },
  "audit_handler.mbt": {
  },
  "async_logger.mbt": {
  },
  "advanced_handlers.mbt": {
  },
}


///|
impl MoonBit_Test_Driver for MoonBit_Test_Driver_Internal_No_Args with fn run_test(
  _,
  filename,
  index,
  handle_start,
  handle_result,
  error_to_string,
) {
  if moonbit_test_driver_internal_no_args_tests.0.get(filename)
    is Some(index_map) &&
    index_map.get(index) is Some((f, attrs)) {
    let name = if attrs is [name, ..] { name } else { "" }
    if MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE {
      for attr in attrs {
        if attr is [.. "panic", ..] {
          raise MoonBitTestDriverInternalSkipTest(name~)
        }
      }
    }
    handle_start()
    moonbit_test_driver_internal_catch_error(
      f,
      on_ok=() => handle_result(name, "", false),
      on_err=err => handle_result(name, error_to_string(err), false),
    )
    true
  } else {
    false
  }
}
///|
#cfg(any(target="native", target="llvm"))
#test_entry
fn main {
  let async_tests = []
  for arg in moonbit_test_driver_internal_native_parse_args() {
    moonbit_test_driver_internal_do_execute(async_tests, arg.0, arg.1)
  }
  MoonBit_Async_Test_Driver_Impl::run_async_tests(async_tests)
}

///|
#cfg(target="js")
#test_entry
fn main {
  let test_params = moonbit_test_driver_js_parse_args()
  moonbit_test_driver_internal_execute(test_params)
  moonbit_test_driver_finish()
}

///|
#cfg(any(target="wasm", target="wasm-gc"))
#test_entry
fn main {
  ()
}

///|
#cfg(target="js")
extern "js" fn moonbit_test_driver_js_parse_args() -> Array[
  MoonBitTestDriverInternalTestEntry,
] =
  #|() => {
  #|  try {
  #|    let testParams = []
  #|    // check if there is command line argument
  #|    if (process.argv.length > 2) {
  #|      const testArgs = JSON.parse(process.argv[2])
  #|      testParams = testArgs.file_and_index.flatMap(([file, ranges]) => {
  #|        let arr = []
  #|        for (let range of ranges) {
  #|          for (let i = range.start; i < range.end; i++) {
  #|            arr.push([file, i])
  #|          }
  #|        }
  #|        return arr
  #|      })
  #|      return testParams
  #|    }
  #|  } catch (error) {
  #|    console.error('failed to parse args: ', error.message)
  #|    process.exit(1)
  #|  }
  #|}

///|
/// Executes selected JavaScript tests from parsed test entries.
#cfg(target="js")
pub fn moonbit_test_driver_internal_execute(
  tests : Array[MoonBitTestDriverInternalTestEntry],
) -> Unit {
  let async_tests = []
  for i in 0..<tests.length() {
    let entry = tests[i]
    moonbit_test_driver_internal_do_execute(
      async_tests,
      entry.filename(),
      entry.index(),
    )
  }
  MoonBit_Async_Test_Driver_Impl::run_async_tests(async_tests)
}

///|
#cfg(target="wasm")
let moonbit_test_driver_internal_wasm_async_tests : Array[async () -> Unit] = []

///|
/// Executes one selected WebAssembly test and stores async work for finalization.
#cfg(target="wasm")
pub fn moonbit_test_driver_internal_execute(
  filename : MoonbitTestDriverInternalExternString,
  index : Int,
) -> Unit {
  let filename = moonbit_test_driver_internal_get_file_name(filename)
  moonbit_test_driver_internal_do_execute(
    moonbit_test_driver_internal_wasm_async_tests, filename, index,
  )
}

///|
/// Executes one selected WebAssembly GC test and drains async work immediately.
#cfg(target="wasm-gc")
pub fn moonbit_test_driver_internal_execute(
  filename : MoonbitTestDriverInternalExternString,
  index : Int,
) -> Unit {
  let filename = moonbit_test_driver_internal_get_file_name(filename)
  let async_tests = []
  moonbit_test_driver_internal_do_execute(async_tests, filename, index)
  MoonBit_Async_Test_Driver_Impl::run_async_tests(async_tests)
}

///|
/// Finishes pending WebAssembly async tests and coverage collection.
#cfg(target="wasm")
pub fn moonbit_test_driver_finish() -> Unit {
  MoonBit_Async_Test_Driver_Impl::run_async_tests(
    moonbit_test_driver_internal_wasm_async_tests,
  )
  
}

///|
/// Finishes coverage collection for backends without pending async work.
#cfg(any(target="js", target="wasm-gc"))
pub fn moonbit_test_driver_finish() -> Unit {
  
}

///|
fn moonbit_test_driver_internal_do_execute(
  async_tests : Array[async () -> Unit],
  filename : String,
  index : Int,
) -> Unit {
  // These two are internalized to avoid unused warnings

  fn handle_start() {
    let file_name = filename.escape()
    @moonbitlang/core/prelude.println("----- BEGIN MOON TEST RESULT -----")
    @moonbitlang/core/prelude.println(
      "{\"type\":\"start\",\"file\":\{file_name},\"index\":\{index}}",
    )
    @moonbitlang/core/prelude.println("----- END MOON TEST RESULT -----")
  }

  fn handle_result(_testname : String, message : String, skipped : Bool) {
    // In WASM, this function is called by the external test driver, but here
    // in native mode there's nothing that calls it, so we call it manually.
    if !skipped && MOONBIT_TEST_DRIVER_INTERNAL_IS_NATIVE {
      
    }
    let file_name = filename.escape()
    let message = message.escape()
    @moonbitlang/core/prelude.println("----- BEGIN MOON TEST RESULT -----")
    @moonbitlang/core/prelude.println(
      "{\"type\":\"result\",\"file\":\{file_name},\"index\":\{index},\"message\":\{message}}",
    )
    @moonbitlang/core/prelude.println("----- END MOON TEST RESULT -----")
  }

  fn error_to_string(err : Error) -> String {
    match err {
      @moonbitlang/core/prelude.Failure::Failure(e)
      | @moonbitlang/core/prelude.InspectError::InspectError(e)
      | @moonbitlang/core/prelude.SnapshotError::SnapshotError(e)
      | MoonBitTestDriverInternalJsError(e) => e
      e => moonbit_test_driver_internal_error_to_string(e)
    }
  }

  try {
    if !(MoonBit_Test_Driver_Internal_No_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_With_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_Async_No_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_Async_With_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      ) ||
      MoonBit_Test_Driver_Internal_With_Bench_Args::run_test(
        async_tests, filename, index, handle_start, handle_result, error_to_string,
      )) {
      raise MoonBitTestDriverInternalSkipTest(name="")
    }
  } catch {
    err => {
      guard err is MoonBitTestDriverInternalSkipTest(name~)
      handle_result(name, "skipped test", true)
    }
  }
}
