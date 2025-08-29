package treesitter

import "core:dynlib"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:strings"

// Language loader structure
Language_Library :: struct {
  language:   Language,
  highlights: string,
  tags:       Maybe(string),
}

// Function signature for tree-sitter language functions
// All tree-sitter languages export a function like tree_sitter_c(), tree_sitter_python(), etc.
Language_Loader :: proc() -> Language

grammar_location := os.get_env("TS_GRAMMARS")

load_language :: proc(name: string) -> (lang: Language_Library, ok: bool) {
  // load the dynamic library
  // we don't care about the lib once we have the language construct in memory
  {
    path := filepath.join({grammar_location, "parser"})
    defer delete(path)

    lib := dynlib.load_library(path) or_return
    // defer {dynlib.unload_library(lib)}
    // FIXME

    fn_name := fmt.aprintf("tree_sitter_%s", name)
    defer delete(fn_name)

    load_language := cast(Language_Loader)dynlib.symbol_address(
      lib,
      fn_name,
    ) or_return

    lang.language = load_language()
  }

  // highlights (required)
  {
    path := filepath.join({grammar_location, "queries/highlights.scm"})
    defer delete(path)

    highlights := os.read_entire_file(path) or_return
    lang.highlights = string(highlights)
  }

  // tags (optional)
  {
    path := filepath.join({grammar_location, "queries/tags.scm"})
    defer delete(path)

    tags, ok := os.read_entire_file(path)

    if ok {
      lang.tags = string(tags)
    }
  }

  return lang, true
}

unload_langage :: proc(lib: ^Language_Library) {
  delete(lib.highlights)

  if tags, tags_ok := lib.tags.?; tags_ok {delete(tags)}

  // TODO: workout how to free the actual language struct
}
