package main

// This file contains tiny wrappers/replacements of the C API.

import ts ".."
import "core:os"
import "core:strings"
import "core:time"

// set the ranges of text that the parser should include when parsing.
//
// by default, the parser will always include entire documents. this function
// allows you to parse only a *portion* of a document but still return a syntax
// tree whose ranges match up with the document as a whole. you can also pass
// multiple disjoint ranges.
//
// the second parameter specifies the slice of ranges.
// the parser does *not* take ownership of these ranges; it copies the data,
// so it doesn't matter how these ranges are allocated.
//
// if `len(ranges)` is zero, then the entire document will be parsed. otherwise,
// the given ranges must be ordered from earliest to latest in the document,
// and they must not overlap. that is, the following must hold for all:
//
// `i < len(ranges) - 1`: `ranges[i].end_byte <= ranges[i + 1].start_byte`
//
// if this requirement is not satisfied, the operation will fail, the ranges
// will not be assigned, and this function will return `false`. on success,
// this function returns `true`
parser_set_included_ranges :: #force_inline proc(
  self: ts.Parser,
  ranges: []ts.Range,
) -> bool {
  return ts.parser_set_included_ranges(
    self,
    raw_data(ranges),
    u32(len(ranges)),
  )
}

// Get the ranges of text that the parser will include when parsing.
parser_included_ranges :: #force_inline proc(self: ts.Parser) -> []ts.Range {
  length: u32 = ---
  multi := ts.parser_included_ranges(self, &length)
  return multi[:length]
}

// Use the parser to parse some source code stored in one contiguous buffer.
// The other two parameters are the same as in the [`parser_parse`] function
// above.
parser_parse_string :: #force_inline proc(
  self: ts.Parser,
  string: string,
  old_tree: ts.Tree = nil,
) -> ts.Tree {
  return ts.parser_parse_string(
    self,
    old_tree,
    strings.unsafe_string_to_cstring(string),
    u32(len(string)),
  )
}

// Use the parser to parse some source code stored in one contiguous buffer with
// a given encoding. The other parameters work the same as in the
// [`parser_parse_string`] method above. The `encoding` parameter indicates whether
// the text is encoded as UTF8 or UTF16.
parser_parse_string_encoding :: #force_inline proc(
  self: ts.Parser,
  string: string,
  encoding: ts.Input_Encoding,
  old_tree: ts.Tree = nil,
) -> ts.Tree {
  return ts.parser_parse_string_encoding(
    self,
    old_tree,
    strings.unsafe_string_to_cstring(string),
    u32(len(string)),
    encoding,
  )
}

// Set the maximum duration that parsing should be allowed to take before halting.
//
// If parsing takes longer than this, it will halt early, returning NULL.
// See [`parser_parse`] for more information.
parser_set_timeout :: #force_inline proc(
  self: ts.Parser,
  timeout: time.Duration,
) {
  ts.parser_set_timeout_micros(self, u64(timeout / time.Microsecond))
}

// Get the duration that parsing is allowed to take.
parser_timeout :: #force_inline proc(self: ts.Parser) -> time.Duration {
  micros := ts.parser_timeout_micros(self)
  return time.Duration(time.Duration(micros) * time.Microsecond)
}

// Set the file descriptor to which the parser should write debugging graphs
// during parsing. The graphs are formatted in the DOT language. You may want
// to pipe these graphs directly to a `dot(1)` process in order to generate
// SVG output. You can turn off this logging by passing a negative `fd`.
parser_print_dot_graphs :: #force_inline proc(self: ts.Parser, fd: os.Handle) {
  ts.parser_print_dot_graphs(self, i32(fd))
}

// Get the array of included ranges that was used to parse the syntax tree.
//
// NOTE: The returned slice must be freed by the caller.
tree_included_ranges :: #force_inline proc(self: ts.Tree) -> []ts.Range {
  length: u32 = ---
  multi := ts.tree_included_ranges(self, &length)
  return multi[:length]
}

// Compare an old edited syntax tree to a new syntax tree representing the same
// document, returning a slice of ranges whose syntactic structure has changed.
//
// For this to work correctly, the old syntax tree must have been edited such
// that its ranges match up to the new tree. Generally, you'll want to call
// this function right after calling one of the [`parser_parse`] functions.
// You need to pass the old tree that was passed to parse, as well as the new
// tree that was returned from that function.
//
// NOTE: The returned array is allocated using the provided `malloc` and the caller is responsible
// for freeing.
tree_get_changed_ranges :: #force_inline proc(
  old_tree: ts.Tree,
  new_tree: ts.Tree,
) -> []ts.Range {
  length: u32 = ---
  multi := ts.tree_get_changed_ranges(old_tree, new_tree, &length)
  return multi[:length]
}

// Write a DOT graph describing the syntax tree to the given file.
tree_print_dot_graph :: #force_inline proc(self: ts.Tree, fd: os.Handle) {
  ts.tree_print_dot_graph(self, i32(fd))
}

// Get the node's child with the given field name.
node_child_by_field_name :: #force_inline proc(
  self: ts.Node,
  name: string,
) -> ts.Node {
  return ts.node_child_by_field_name(
    self,
    strings.unsafe_string_to_cstring(name),
    u32(len(name)),
  )
}

// Get the smallest node within this node that spans the given range of bytes or (row, column) positions.
node_descendant_for_range :: proc {
  ts.node_descendant_for_byte_range,
  ts.node_descendant_for_point_range,
}

// Get the smallest named node within this node that spans the given range of bytes or (row, column) positions.
node_named_descendant_for_range :: proc {
  ts.node_named_descendant_for_byte_range,
  ts.node_named_descendant_for_point_range,
}

// Move the cursor to the first child of its current node that extends beyond
// the given byte offset or point.
//
// This returns the index of the child node if one was found, and returns -1
// if no such child was found.
tree_cursor_goto_first_child_for :: proc {
  ts.tree_cursor_goto_first_child_for_byte,
  ts.tree_cursor_goto_first_child_for_point,
}

// Create a new query from a string containing one or more S-expression
// patterns. The query is associated with a particular language, and can
// only be run on syntax nodes parsed with that language.
//
// If all of the given patterns are valid, this returns a [`TSQuery`].
// If a pattern is invalid, this returns `NULL`, and provides two pieces
// of information about the problem:
// 1. The byte offset of the error is returned in `err_offset`.
// 2. The type of error is returned in `err`.
query_new :: #force_inline proc(
  language: ts.Language,
  source: string,
) -> (
  query: ts.Query,
  err_offset: u32,
  err: ts.Query_Error,
) {
  query = ts.query_new(
    language,
    strings.unsafe_string_to_cstring(source),
    u32(len(source)),
    &err_offset,
    &err,
  )
  return
}

// Get all of the predicates for the given pattern in the query.
//
// The predicates are represented as a single slice of steps. There are three
// types of steps in this slice, which correspond to the three legal values for
// the `type` field:
// - `.Capture` - Steps with this type represent names of captures.
//    Their `value_id` can be used with the [`query_capture_name_for_id`] function
//    to obtain the name of the capture.
// - `.String` - Steps with this type represent literal strings.
//    Their `value_id` can be used with the [`query_string_value_for_id`] function
//    to obtain their string value.
// - `.Done` - Steps with this type are *sentinels* that represent the end of an individual predicate.
//    If a pattern has two predicates, then there will be two with this `type` in the slice.
query_predicates_for_pattern :: #force_inline proc(
  self: ts.Query,
  pattern_index: u32,
) -> []ts.Query_Predicate_Step {
  length: u32 = ---
  multi := ts.query_predicates_for_pattern(self, pattern_index, &length)
  return multi[:length]
}

// Get the name of one of the query's captures, or one of the
// query's string literals. Each capture and string is associated with a
// numeric id based on the order that it appeared in the query's source.
query_capture_name_for_id :: #force_inline proc(
  self: ts.Query,
  index: u32,
) -> string {
  length: u32 = ---
  cstr := ts.query_capture_name_for_id(self, index, &length)
  return string(([^]byte)(cstr)[:length])
}

query_string_value_for_id :: #force_inline proc(
  self: ts.Query,
  index: u32,
) -> string {
  length: u32 = ---
  cstr := ts.query_string_value_for_id(self, index, &length)
  return string(([^]byte)(cstr)[:length])
}

// Disable a certain capture within a query.
//
// This prevents the capture from being returned in matches, and also avoids
// any resource usage associated with recording the capture. Currently, there
// is no way to undo this.
query_disable_capture :: #force_inline proc(self: ts.Query, name: string) {
  ts.query_disable_capture(
    self,
    strings.unsafe_string_to_cstring(name),
    u32(len(name)),
  )
}

query_cursor_set_range :: proc {
  ts.query_cursor_set_byte_range,
  ts.query_cursor_set_point_range,
}

// Advance to the next match of the currently running query.
query_cursor_next_match :: #force_inline proc(
  self: ts.Query_Cursor,
) -> (
  match: ts.Query_Match,
  ok: bool,
) {
  ok = ts.query_cursor_next_match(self, &match)
  return
}

// Advance to the next capture of the currently running query.
//
// If there is a capture, return it, and its index within the match's capture. Otherwise return `false`.
query_cursor_next_capture :: #force_inline proc(
  self: ts.Query_Cursor,
) -> (
  match: ts.Query_Match,
  capture_index: u32,
  ok: bool,
) {
  ok = ts.query_cursor_next_capture(self, &match, &capture_index)
  return
}

// Get the numerical id for the given node type string.
language_symbol_for_name :: #force_inline proc(
  self: ts.Language,
  string: string,
  is_named: bool,
) -> ts.Symbol {
  return ts.language_symbol_for_name(
    self,
    strings.unsafe_string_to_cstring(string),
    u32(len(string)),
    is_named,
  )
}

// Get the numerical id for the given field name string.
language_field_id_for_name :: #force_inline proc(
  self: ts.Language,
  name: string,
) -> ts.Field_Id {
  return ts.language_field_id_for_name(
    self,
    strings.unsafe_string_to_cstring(name),
    u32(len(name)),
  )
}

// Create a language from a buffer of Wasm. The resulting language behaves
// like any other Tree-sitter language, except that in order to use it with
// a parser, that parser must have a Wasm store. Note that the language
// can be used with any Wasm store, it doesn't need to be the same store that
// was used to originally load it.
wasm_store_load_language :: #force_inline proc(
  self: ^ts.Wasm_Store,
  name: cstring,
  wasm: string,
) -> (
  lang: ts.Language,
  err: ts.Wasm_Error,
) {
  lang = ts.wasm_store_load_language(
    self,
    name,
    strings.unsafe_string_to_cstring(wasm),
    u32(len(wasm)),
    &err,
  )
  return
}

// when BIND_HIGHLIGHT {
//
// 	// Construct a `Highlighter` by providing a list of strings containing
// 	// the HTML attributes that should be applied for each highlight value.
// 	highlighter_new :: #force_inline proc(highlight_names: []cstring, attribute_strings: []cstring) -> ^Highlighter {
// 		assert(len(highlight_names) == len(attribute_strings), "highlight_names must be the same length as attribute_strings")
// 		return _highlighter_new(raw_data(highlight_names), raw_data(attribute_strings), u32(len(highlight_names)))
// 	}
//
// 	// Add a `Language` to a highlighter. The language is associated with a
// 	// scope name, which can be used later to select a language for syntax
// 	// highlighting. Along with the language, you must provide a JSON string
// 	// containing the compiled PropertySheet to use for syntax highlighting
// 	// with that language. You can also optionally provide an 'injection regex',
// 	// which is used to detect when this language has been embedded in a document
// 	// written in a different language.
// 	highlighter_add_language :: #force_inline proc(
// 		self: ^Highlighter,
// 		language: Language,
// 		language_name: cstring,
// 		scope_name: cstring,
// 		highlight_query: string,
// 		injection_regex: cstring = nil,
// 		injection_query: string = "",
// 		locals_query: string = "",
// 		apply_all_captures: bool = true,
// 	) -> Highlight_Error {
// 		return _highlighter_add_language(
// 			self,
// 			language_name,
// 			scope_name,
// 			injection_regex,
// 			language,
// 			strings.unsafe_string_to_cstring(highlight_query),
// 			strings.unsafe_string_to_cstring(injection_query),
// 			strings.unsafe_string_to_cstring(locals_query),
// 			u32(len(highlight_query)),
// 			u32(len(injection_query)),
// 			u32(len(locals_query)),
// 			apply_all_captures,
// 		)
// 	}
//
// 	// Compute syntax highlighting for a given document. You must first
// 	// create a `HighlightBuffer` to hold the output.
// 	highlighter_highlight :: #force_inline proc(
// 		self: ^Highlighter,
// 		scope_name: cstring,
// 		source_code: string,
// 		output: ^Highlight_Buffer,
// 		cancellation_flag: ^uint = nil,
// 	) -> Highlight_Error {
// 		return _highlighter_highlight(
// 			self,
// 			scope_name,
// 			strings.unsafe_string_to_cstring(source_code),
// 			u32(len(source_code)),
// 			output,
// 			cancellation_flag,
// 		)
// 	}
// }
