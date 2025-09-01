package cst

import "base:runtime"
import ts "treesitter"

@(private)
parser: ts.Parser
language: Language_Library // TODO

init :: proc(logger: ^runtime.Logger) {
  parser = ts.parser_new()
  parser_set_odin_logger(parser, logger, .Debug)
}

fini :: proc() {
  ts.parser_delete(parser)
}
