package korsakov

import "core:os"
import "core:slice"
import "core:strings"
import "core:unicode/utf8"

Buffer :: struct {
	lines:    [dynamic]string,
	filename: string,
	cursor:   Vec2,
	modified: bool,
	scroll:   int,
}

/// Creates a new empty buffer
buffer_new :: proc() -> Buffer {
	buffer := Buffer {
		lines    = make([dynamic]string), // must have at least one empty line
		filename = "",
		cursor   = vec2(0, 0),
		modified = false,
		scroll   = 0,
	}

	append(&buffer.lines, "")

	return buffer
}

/// Creates a buffer from a file
buffer_from_file :: proc(filename: string) -> (Buffer, os.Error) {
	data, ok := os.read_entire_file(filename)
	if !ok {
		return buffer_new(), os.ENOENT
	}
	defer delete(data)

	content := string(data)
	lines := strings.split_lines(content)

	buffer := Buffer {
		lines    = make([dynamic]string),
		filename = filename,
		cursor   = vec2(0, 0),
		modified = false,
	}

	for line in lines {
		append(&buffer.lines, strings.clone(line))
	}

	// Ensure at least one line exists
	if len(buffer.lines) == 0 {
		append(&buffer.lines, "")
	}

	return buffer, os.ERROR_NONE
}

/// Destroys a buffer and cleans up resources
buffer_destroy :: proc(buffer: ^Buffer) {
	for line in buffer.lines {
		delete(line)
	}
	delete(buffer.lines)
}

/// Gets the number of lines in the buffer
buffer_line_count :: proc(buffer: ^Buffer) -> int {
	return len(buffer.lines)
}

/// Gets a line from the buffer
buffer_get_line :: proc(buffer: ^Buffer, line_idx: int) -> string {
	if line_idx >= 0 && line_idx < len(buffer.lines) {
		return buffer.lines[line_idx]
	}
	return ""
}

// Returns the char at then given position
buffer_get_char :: proc(buffer: ^Buffer, x, y: int) -> rune {
	return rune(buffer.lines[y][x])
}

/// Sets a line in the buffer
buffer_set_line :: proc(buffer: ^Buffer, line_idx: int, content: string) {
	if line_idx >= 0 && line_idx < len(buffer.lines) {
		delete(buffer.lines[line_idx])
		buffer.lines[line_idx] = strings.clone(content)
		buffer.modified = true
	}
}

/// Inserts a character at the cursor position
buffer_insert_char :: proc(buffer: ^Buffer, ch: rune) {
	if buffer.cursor.y >= 0 && buffer.cursor.y < len(buffer.lines) {
		line := buffer.lines[buffer.cursor.y]

		// Convert to runes for proper Unicode handling
		runes := utf8.string_to_runes(line)
		defer delete(runes)

		// Insert character at cursor position
		new_runes := make([dynamic]rune)
		defer delete(new_runes)

		for i in 0 ..< buffer.cursor.x {
			if i < len(runes) {
				append(&new_runes, runes[i])
			}
		}
		append(&new_runes, ch)
		for i in buffer.cursor.x ..< len(runes) {
			append(&new_runes, runes[i])
		}

		// Convert back to string
		delete(buffer.lines[buffer.cursor.y])
		buffer.lines[buffer.cursor.y] = utf8.runes_to_string(new_runes[:])

		buffer.cursor.x += 1
		buffer.modified = true
	}
}

/// Deletes a character at the cursor position
buffer_delete_char :: proc(buffer: ^Buffer) {
	if buffer.cursor.y >= 0 && buffer.cursor.y < len(buffer.lines) {
		line := buffer.lines[buffer.cursor.y]

		if buffer.cursor.x > 0 {
			// Convert to runes for proper Unicode handling
			runes := utf8.string_to_runes(line)
			defer delete(runes)

			// Remove character before cursor
			new_runes := make([dynamic]rune)
			defer delete(new_runes)

			for i in 0 ..< buffer.cursor.x - 1 {
				if i < len(runes) {
					append(&new_runes, runes[i])
				}
			}
			for i in buffer.cursor.x ..< len(runes) {
				if i < len(runes) {
					append(&new_runes, runes[i])
				}
			}

			// Convert back to string
			delete(buffer.lines[buffer.cursor.y])
			buffer.lines[buffer.cursor.y] = utf8.runes_to_string(new_runes[:])

			buffer.cursor.x -= 1
			buffer.modified = true
		}
	}
}

/// Saves the buffer to its file
buffer_save :: proc(buffer: ^Buffer) -> os.Errno {
	if len(buffer.filename) == 0 {
		return os.EINVAL
	}

	// Join lines with newlines
	content_builder := strings.builder_make()
	defer strings.builder_destroy(&content_builder)

	for line, idx in buffer.lines {
		strings.write_string(&content_builder, line)
		if idx < len(buffer.lines) - 1 {
			strings.write_byte(&content_builder, '\n')
		}
	}

	content := strings.to_string(content_builder)
	ok := os.write_entire_file(buffer.filename, transmute([]u8)content)

	if ok {
		buffer.modified = false
		return os.ERROR_NONE
	}

	return os.EIO
}
