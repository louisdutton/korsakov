package korsakov

import "core:fmt"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "tty"

// Renders the editor to the terminal
render_editor :: proc(editor: ^Editor) {
	buffer := editor_active_buffer(editor)

	render_buffer(buffer, editor.size)
	render_status_bar(editor, buffer)
}

// Renders the buffer content
render_buffer :: proc(buffer: ^Buffer, size: Vec2) {
	STATUS_BAR_HEIGHT :: 2
	visible_lines := size.y - STATUS_BAR_HEIGHT

	number_column_width := len(buffer.lines) / 10
	max_width := size.x - number_column_width

	for i in buffer.scroll ..< visible_lines {
		tty.cursor_move(0, i)

		if i < buffer_line_count(buffer) {
			line := buffer_get_line(buffer, i)
			// Truncate line if it's too long for the screen
			if len(line) > size.x {
				tty.write(line[:size.x])
			} else {
				// line number
				fmt.print(i)

				// actual line
				tty.cursor_move(number_column_width + 1, i)
				fmt.print(line)
			}
		} else {
			// Show tilde for empty lines (vim-style)
			fmt.print("~")
		}

		tty.clear_line()
	}

	render_cursor(buffer, number_column_width)
}

// Renders the cursor
render_cursor :: proc(buffer: ^Buffer, num_col_w: int) {
	tty.cursor_move(buffer.cursor.x + num_col_w + 1, buffer.cursor.y)
	tty.sgr_invert()
	os.write_rune(os.stdout, buffer_get_char(buffer, buffer.cursor.x, buffer.cursor.y))
	tty.sgr_reset()
}

// Renders the status bar
render_status_bar :: proc(editor: ^Editor, buffer: ^Buffer) {
	status_y := editor.size.y - 1
	tty.cursor_move(0, status_y)

	// Set background color for status bar
	tty.sgr_invert()

	// Build status string
	status_builder := strings.builder_make()
	defer strings.builder_destroy(&status_builder)

	// Mode indicator
	mode_str := ""
	switch editor.mode {
	case .Navigate:
		mode_str = " NAV "
	case .Insert:
		mode_str = " INS "
	case .Visual:
		mode_str = " VIS "
	case .Command:
		mode_str = " CMD "
	}
	strings.write_string(&status_builder, mode_str)

	// Filename
	if len(buffer.filename) > 0 {
		strings.write_string(&status_builder, " ")
		strings.write_string(&status_builder, buffer.filename)
	} else {
		strings.write_string(&status_builder, " [No Name]")
	}

	// Modified indicator
	if buffer.modified {
		strings.write_string(&status_builder, " [+]")
	}

	// Cursor position
	strings.write_string(
		&status_builder,
		fmt.tprintf(" %d:%d", buffer.cursor.y + 1, buffer.cursor.x + 1),
	)

	status := strings.to_string(status_builder)

	// Print status and pad to full width
	fmt.print(status)
	padding := editor.size.x - len(status)
	for i in 0 ..< padding {
		tty.write(" ")
	}

	tty.sgr_reset()
}
