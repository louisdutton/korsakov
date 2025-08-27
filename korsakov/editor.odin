package korsakov

import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:slice"
import "core:sys/linux"
import "tty"

Mode :: enum {
	Navigate,
	Insert,
	Visual,
	Command,
}

Vec2 :: [2]int
vec2 :: proc(x, y: int) -> Vec2 {return Vec2{x, y}}

Editor :: struct {
	mode:           Mode,
	buffers:        [dynamic]Buffer,
	active_buffer:  int,
	size:           Vec2,
	commands:       CommandRegistry,
	running:        bool,
	command_buffer: string, // For command mode input
}

/// Creates a new headless editor instance for testing
editor_new_headless :: proc() -> Editor {
	return {
		mode = .Navigate,
		buffers = make([dynamic]Buffer),
		active_buffer = 0,
		size = vec2(80, 24),
		commands = command_registry_new(),
		running = true,
		command_buffer = "",
	}
}

/// Creates a new interactive editor instance
editor_new :: proc() -> Editor {
	editor := Editor {
		mode           = .Navigate,
		buffers        = make([dynamic]Buffer),
		active_buffer  = 0,
		size           = tty.get_terminal_size(), // TODO: Get actual terminal size
		commands       = command_registry_new(),
		running        = true,
		command_buffer = "",
	}

	// TODO: Initialize terminal, treesitter, input maps, etc.

	return editor
}

/// Destroys the editor and cleans up resources
editor_destroy :: proc(editor: ^Editor) {
	for &buffer in editor.buffers {
		buffer_destroy(&buffer)
	}
	delete(editor.buffers)
	command_registry_destroy(&editor.commands)
}

/// Loads a file into the editor
editor_load_file :: proc(editor: ^Editor, filename: string) -> os.Error {
	buffer := buffer_from_file(filename) or_return
	append(&editor.buffers, buffer)
	if len(editor.buffers) == 1 {
		editor.active_buffer = 0
	}

	return os.ERROR_NONE
}

/// Adds a buffer to the editor
editor_add_buffer :: proc(editor: ^Editor, buffer: Buffer) {
	append(&editor.buffers, buffer)
	if len(editor.buffers) == 1 {
		editor.active_buffer = 0
	}
}

/// Gets the currently active buffer
editor_active_buffer :: proc(editor: ^Editor) -> ^Buffer {
	return &editor.buffers[editor.active_buffer]
}

/// Evaluates input actions in headless mode
editor_eval :: proc(editor: ^Editor, input_actions: string) {
	// TODO: Parse and execute vim-style input actions
	// For now, just print that we received the actions
	fmt.printf("Headless mode: executing actions '%s'\n", input_actions)
}

/// Main event loop for interactive mode
editor_listen :: proc(editor: ^Editor) {
	original_state := tty.set_raw_mode()
	tty.cursor_hide()
	tty.alt_screen_enable()

	defer {
		tty.cursor_show()
		tty.alt_screen_disable()
		tty.restore(&original_state)
	}

	for editor.running {
		render_editor(editor)

		buffer := editor_active_buffer(editor)

		char := tty.read()
		switch char {
		case 'q', 27:
			editor.running = false
		case 'j':
			buffer.cursor.y = min(buffer.cursor.y + 1, len(buffer.lines))
		case 'k':
			buffer.cursor.y = max(buffer.cursor.y - 1, 0)
		case 'h':
			buffer.cursor.x = max(buffer.cursor.x - 1, 0)
		case 'l':
			buffer.cursor.x = min(buffer.cursor.x + 1, editor.size.x)
		}
	}
}
