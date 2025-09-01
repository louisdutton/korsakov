package cst

import "core:log"
import "core:mem"
import "core:os"
import ts "treesitter"

main :: proc() {
  logger := log.create_console_logger(
    .Debug when ODIN_DEBUG else .Info,
    {.Level, .Terminal_Color, .Short_File_Path, .Line},
  )
  context.logger = logger

  {
    parser := ts.parser_new()
    defer ts.parser_delete(parser)

    // Load the language
    lib, ok := load_language("odin")
    if !ok {
      log.error("Failed to load language")
      return
    }
    defer unload_langage(&lib)

    if !ts.parser_set_language(parser, lib.language) {
      log.error("Failed to set language")
      return
    }

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
          node_text(cap.node, source),
          query_capture_name_for_id(query, cap.index),
        )
      }
    }
  }
}
