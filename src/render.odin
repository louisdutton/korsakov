package korsakov

import "core:fmt"
import "core:strings"
import "core:terminal/ansi"

/// Renders the editor to the terminal
render_editor :: proc(editor: ^Editor) {
	clear_screen()
	move_cursor(1, 1)

	if buffer := editor_active_buffer(editor); buffer != nil {
		render_buffer(buffer, editor.size)
		render_cursor(buffer)
		render_status_bar(editor, buffer)
	}

	// Flush output
	fmt.print("")
}

/// Renders the buffer content
render_buffer :: proc(buffer: ^Buffer, size: Vec2) {
	visible_lines := size.y - 2 // Leave space for status bar

	for i in 0 ..< visible_lines {
		move_cursor(1, i + 1)

		if i < buffer_line_count(buffer) {
			line := buffer_get_line(buffer, i)
			// Truncate line if it's too long for the screen
			if len(line) > size.x {
				fmt.print(line[:size.x])
			} else {
				fmt.print(line)
			}
		} else {
			// Show tilde for empty lines (vim-style)
			fmt.print("~")
		}

		// Clear rest of line
		fmt.print("\x1b[K")
	}
}

/// Renders the cursor at the current position
render_cursor :: proc(buffer: ^Buffer) {
	// Move cursor to buffer position (convert to 1-based terminal coordinates)
	move_cursor(buffer.cursor.x + 1, buffer.cursor.y + 1)
}

/// Renders the status bar
render_status_bar :: proc(editor: ^Editor, buffer: ^Buffer) {
	status_y := editor.size.y
	move_cursor(1, status_y)

	// Set background color for status bar
	fmt.print("\x1b[7m") // Reverse video

	// Build status string
	status_builder := strings.builder_make()
	defer strings.builder_destroy(&status_builder)

	// Mode indicator
	mode_str := ""
	switch editor.mode {
	case .Navigate:
		mode_str = "NORMAL"
	case .Insert:
		mode_str = "INSERT"
	case .Visual:
		mode_str = "VISUAL"
	case .Command:
		mode_str = "COMMAND"
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
		fmt.tprintf(" %d,%d", buffer.cursor.y + 1, buffer.cursor.x + 1),
	)

	status := strings.to_string(status_builder)

	// Print status and pad to full width
	fmt.print(status)
	padding := editor.size.x - len(status)
	for i in 0 ..< padding {
		fmt.print(" ")
	}

	// Reset colors
	fmt.print(ansi.CSI + ansi.RESET + ansi.SGR)
}
