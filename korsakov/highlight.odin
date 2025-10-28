#+feature dynamic-literals
package korsakov

import "buffer"
import "cst"
import "core:log"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:terminal/ansi"
import ts "cst/treesitter"

// Get syntax highlighting color for a capture name
get_highlight_color :: proc(capture_name: string) -> string {
	switch capture_name {
	// Keywords
	case "keyword": return ansi.FG_MAGENTA
	case "keyword.function": return ansi.FG_BLUE
	case "keyword.return": return ansi.FG_MAGENTA
	
	// Types and storage
	case "type": return ansi.FG_CYAN
	case "storageclass": return ansi.FG_YELLOW
	
	// Literals
	case "string": return ansi.FG_GREEN
	case "character": return ansi.FG_GREEN
	case "number": return ansi.FG_RED
	case "boolean": return ansi.FG_RED
	
	// Comments
	case "comment": return ansi.FG_BRIGHT_BLACK
	
	// Functions and variables
	case "function": return ansi.FG_BLUE
	case "variable": return ansi.FG_WHITE
	case "parameter": return ansi.FG_CYAN
	
	// Preprocessor
	case "preproc": return ansi.FG_YELLOW
	case "include": return ansi.FG_MAGENTA
	
	// Operators and punctuation
	case "operator": return ansi.FG_WHITE
	case "punctuation": return ansi.FG_WHITE
	
	case: return ansi.FG_WHITE
	}
}

// Represents a highlighted token with its position and color
Highlight_Token :: struct {
	start_byte: u32,
	end_byte:   u32,
	color:      string,
}

// Syntax highlighter state
Highlighter :: struct {
	parser:  ts.Parser,
	lang:    cst.Language_Library,
	query:   ts.Query,
	cursor:  ts.Query_Cursor,
	tokens:  [dynamic]Highlight_Token,
}

// Initialize the syntax highlighter
highlighter_init :: proc(h: ^Highlighter, language_name: string) -> bool {
	h.parser = ts.parser_new()
	
	// Load the language
	lang, ok := cst.load_language(language_name)
	if !ok {
		log.error("Failed to load language for highlighting")
		return false
	}
	h.lang = lang
	
	// Set the language on the parser
	if !ts.parser_set_language(h.parser, h.lang.language) {
		log.error("Failed to set language on parser")
		return false
	}
	
	// Create the highlight query
	query, err_offset, err := cst.query_new(h.lang.language, h.lang.highlights)
	if err != .None {
		log.errorf("Failed to create highlight query: %v at %v", err, err_offset)
		return false
	}
	h.query = query
	
	// Create query cursor
	h.cursor = ts.query_cursor_new()
	
	// Initialize tokens array
	h.tokens = make([dynamic]Highlight_Token)
	
	return true
}

// Clean up highlighter resources
highlighter_destroy :: proc(h: ^Highlighter) {
	if h.parser != nil {
		ts.parser_delete(h.parser)
	}
	if h.query != nil {
		ts.query_delete(h.query)
	}
	if h.cursor != nil {
		ts.query_cursor_delete(h.cursor)
	}
	cst.unload_langage(&h.lang)
	delete(h.tokens)
}

// Highlight a buffer and populate the tokens array
highlighter_highlight_buffer :: proc(h: ^Highlighter, content: string) {
	// Clear previous tokens
	clear(&h.tokens)
	
	// Parse the content
	tree := cst.parser_parse_string(h.parser, content)
	if tree == nil {
		log.error("Failed to parse content for highlighting")
		return
	}
	defer ts.tree_delete(tree)
	
	root := ts.tree_root_node(tree)
	
	// Execute the highlight query
	ts.query_cursor_exec(h.cursor, h.query, root)
	
	// Collect all highlights
	for match, cap_idx in cst.query_cursor_next_capture(h.cursor) {
		cap := match.captures[cap_idx]
		
		// Skip predicates for now (they require more complex handling)
		if len(cst.query_predicates_for_pattern(h.query, u32(match.pattern_index))) > 0 {
			continue
		}
		
		// Get the capture name
		capture_name := cst.query_capture_name_for_id(h.query, cap.index)
		
		// Look up the color for this capture
		color := get_highlight_color(capture_name)
		token := Highlight_Token{
			start_byte = ts.node_start_byte(cap.node),
			end_byte   = ts.node_end_byte(cap.node),
			color      = color,
		}
		append(&h.tokens, token)
	}
	
	// Sort tokens by position for easier lookup during rendering
	slice.sort_by(h.tokens[:], proc(a, b: Highlight_Token) -> bool {
		return a.start_byte < b.start_byte
	})
}

// Get the highlight color for a specific byte position
highlighter_get_color_at :: proc(h: ^Highlighter, byte_pos: u32) -> string {
	for token in h.tokens {
		if byte_pos >= token.start_byte && byte_pos < token.end_byte {
			return token.color
		}
	}
	return ansi.FG_WHITE // Default color
}

// Get all tokens that intersect with a byte range
highlighter_get_tokens_in_range :: proc(h: ^Highlighter, start_byte, end_byte: u32) -> []Highlight_Token {
	result: [dynamic]Highlight_Token
	
	for token in h.tokens {
		// Check if token intersects with the range
		if token.start_byte < end_byte && token.end_byte > start_byte {
			append(&result, token)
		}
	}
	
	return result[:]
}
