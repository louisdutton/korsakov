package korsakov

import "buffer"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "core:unicode/utf8"
import "tty"

STATUS_BAR_HEIGHT :: 1
NUMBER_COLUMN_PADDING :: 1

// Get the full buffer content as a single string for highlighting
get_buffer_content :: proc(b: ^buffer.Buffer) -> string {
	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)
	
	for line, i in b.lines {
		strings.write_string(&builder, line)
		if i < len(b.lines) - 1 {
			strings.write_byte(&builder, '\n')
		}
	}
	
	return strings.clone(strings.to_string(builder))
}

// Calculate byte offset for a given line and column
get_byte_offset :: proc(b: ^buffer.Buffer, line: int, col: int) -> u32 {
	byte_offset: u32 = 0
	
	for i in 0 ..< min(line, len(b.lines)) {
		byte_offset += u32(len(b.lines[i]))
		if i < len(b.lines) - 1 {
			byte_offset += 1 // newline character
		}
	}
	
	if line < len(b.lines) {
		line_str := b.lines[line]
		byte_offset += u32(min(col, len(line_str)))
	}
	
	return byte_offset
}

// Renders the buffer content with syntax highlighting
render_buffer :: proc(e: ^Editor, b: ^buffer.Buffer) {
	// Get the full buffer content for highlighting
	content := get_buffer_content(b)
	defer delete(content)
	
	// Update highlights
	highlighter_highlight_buffer(&e.highlighter, content)
	
	for i in 0 ..< b.dimensions.y {
		tty.cursor_move(0, i)

		if i < buffer.line_count(b) {
			// project lines based on viewport scroll offset
			line_idx := min(i + b.scroll.y, len(b.lines) - 1)
			line := buffer.get_line(b, line_idx)

			// line number
			tty.write(ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR)
			number := i + b.scroll.y
			// pad zeros to prevent tearing
			// FIXME: this is very slow way of doing this
			for j in 0 ..< count_digits(len(b.lines)) - count_digits(number) {
				tty.write("0")
			}
			// we only need this if why the above padding method is in place
			// otherwise we end up with an extra zero
			if number > 0 {
				fmt.print(number)
			}

			tty.cursor_move(b.x_offset, i)

			// horizontal scrolling
			width := b.dimensions.x - b.x_offset + 1
			line_length := len(line)
			start := min(b.scroll.x, line_length)
			end := min(width + b.scroll.x, line_length)
			
			// Render line with syntax highlighting
			render_line_highlighted(&e.highlighter, b, line, line_idx, start, end)
		}

		tty.clear_line()
	}

	render_cursor(b)
}

// Renders a line with syntax highlighting
render_line_highlighted :: proc(h: ^Highlighter, b: ^buffer.Buffer, line: string, line_idx: int, start: int, end: int) {
	// Get byte offset for this line
	line_start_offset := get_byte_offset(b, line_idx, 0)
	
	current_color := ansi.FG_WHITE
	{
		color_str := strings.concatenate({ansi.CSI, current_color, ansi.SGR})
		defer delete(color_str)
		tty.write(color_str)
	}
	
	// Render character by character with highlighting
	for col in start ..< end {
		if col >= len(line) {
			break
		}
		
		char_byte_offset := line_start_offset + u32(col)
		new_color := highlighter_get_color_at(h, char_byte_offset)
		
		// Only change color if it's different
		if new_color != current_color {
			current_color = new_color
			color_str := strings.concatenate({ansi.CSI, current_color, ansi.SGR})
			defer delete(color_str)
			tty.write(color_str)
		}
		
		// Write the character
		tty.write(string([]byte{line[col]}))
	}
	
	// Reset to default color
	tty.write(ansi.CSI + ansi.FG_WHITE + ansi.SGR)
}
