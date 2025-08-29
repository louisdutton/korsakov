package main

import ts ".."
import "base:builtin"
import "core:c"
import "core:fmt"
import "core:log"
import "core:math/linalg/glsl"
import "core:mem"
import "core:os"
import "core:strings"

main :: proc() {
  logger := log.create_console_logger(
    .Debug when ODIN_DEBUG else .Info,
    {.Level, .Terminal_Color, .Short_File_Path, .Line},
  )
  context.logger = logger

  track: mem.Tracking_Allocator
  mem.tracking_allocator_init(&track, context.allocator)
  defer mem.tracking_allocator_destroy(&track)
  context.allocator = mem.tracking_allocator(&track)

  la: log.Log_Allocator
  log.log_allocator_init(&la, .Debug, .Human)
  context.allocator = log.log_allocator(&la)

  compat: ts.Compat_Allocator
  ts.compat_allocator_init(&compat)

  defer {
    for _, leak in track.allocation_map {
      log.errorf("%v leaked %m\n", leak.location, leak.size)
    }
    for bad_free in track.bad_free_array {
      log.errorf(
        "%v allocation %p was freed badly\n",
        bad_free.location,
        bad_free.memory,
      )
    }
  }

  {
    ts.set_odin_allocator(ts.compat_allocator(&compat))

    parser := ts.parser_new()
    defer ts.parser_delete(parser)

    ts.parser_set_odin_logger(parser, &logger, .Debug)

    // Load the language
    lib, ok := ts.load_language("c")
    if !ok {
      log.error("Failed to load C language")
      return
    }
    defer ts.unload_langage(&lib)

    if !ts.parser_set_language(parser, lib.language) {
      log.error("Failed to set language")
      return
    }

    // FIXME: there seems to be a version mismatch things
    // seem to work none the less
    set_lang_ok := ts.parser_set_language(parser, lib.language)
    log.assert(
      set_lang_ok,
      "version mismatch between the language and tree-sitter itself",
    )

    data, read_ok := os.read_entire_file(#file)
    log.assertf(read_ok, "reading current file at %q failed", #file)
    source := string(data)
    defer delete(source)

    tree := parser_parse_string(parser, source)
    assert(tree != nil)
    defer ts.tree_delete(tree)

    root := ts.tree_root_node(tree)

    {
      query, err_offset, err := query_new(lib.language, lib.highlights)
      log.assertf(
        err == nil,
        "could not new a query, %v at %v",
        err,
        err_offset,
      )
      defer ts.query_delete(query)

      cursor := ts.query_cursor_new()
      defer ts.query_cursor_delete(cursor)

      ts.query_cursor_exec(cursor, query, root)

      for match, cap_idx in query_cursor_next_capture(cursor) {
        cap := match.captures[cap_idx]
        if len(query_predicates_for_pattern(query, u32(match.pattern_index))) >
           0 {
          continue
        }
        log.infof(
          "%q: %s",
          ts.node_text(cap.node, source),
          query_capture_name_for_id(query, cap.index),
        )
      }
    }
  }
}
