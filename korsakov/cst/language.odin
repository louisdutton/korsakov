package cst

import "core:dynlib"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:strings"
import ts "treesitter"

// Language loader structure
Language_Library :: struct {
  language:         ts.Language,
  highlights:       string,
  optional_modules: [Optional_Module]Maybe(string),
  __handle:         dynlib.Library,
}

Optional_Module :: enum {
  Folds,
  Indents,
  Injections,
  Locals,
  Tags,
}

module_names :: [Optional_Module]string {
  .Folds      = "folds",
  .Indents    = "indents",
  .Injections = "injections",
  .Locals     = "locals",
  .Tags       = "tags",
}

// Function signature for tree-sitter language functions
// All tree-sitter languages export a function like tree_sitter_c(), tree_sitter_python(), etc.
Language_Loader :: proc() -> ts.Language


load_language :: proc(name: string) -> (lang: Language_Library, ok: bool) {
  grammar_location := os.get_env("TS_GRAMMARS")
  defer delete(grammar_location)

  // load the dynamic library
  // we don't care about the lib once we have the language construct in memory
  {
    path := filepath.join({grammar_location, "parser"})
    defer delete(path)

    // this has to live for the duration of the parser's usage
    lang.__handle = dynlib.load_library(path) or_return

    fn_name := fmt.aprintf("tree_sitter_%s", name)
    defer delete(fn_name)

    load_language := cast(Language_Loader)dynlib.symbol_address(
      lang.__handle,
      fn_name,
    ) or_return

    lang.language = load_language()
  }

  // required modules
  {
    path := filepath.join({grammar_location, "queries/highlights.scm"})
    defer delete(path)

    bytes := os.read_entire_file(path) or_return
    lang.highlights = string(bytes)
  }

  // optional modules
  for name, idx in module_names {
    path := strings.concatenate({grammar_location, "/queries/", name, ".scm"})
    defer delete(path)

    bytes, ok := os.read_entire_file(path)
    if ok {
      lang.optional_modules[idx] = string(bytes)
    }
  }

  return lang, true
}

unload_langage :: proc(lib: ^Language_Library) {
  delete(lib.highlights)

  for module in lib.optional_modules {
    if content, ok := module.(string); ok {
      delete(content)
    }
  }

  dynlib.unload_library(lib.__handle)
}
