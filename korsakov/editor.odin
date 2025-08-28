package korsakov

import buffer "buffer"
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
	buffers:        [dynamic]buffer.Buffer,
	active_buffer:  int,
	size:           Vec2,
	commands:       CommandRegistry,
	running:        bool,
	command_buffer: string, // For command mode input
}

/// Creates a new interactive editor instance
editor_new :: proc() -> Editor {
	editor := Editor {
		mode           = .Navigate,
		buffers        = make([dynamic]buffer.Buffer),
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
	for &buf in editor.buffers {
		buffer.destroy(&buf)
	}
	delete(editor.buffers)
	command_registry_destroy(&editor.commands)
}

/// Loads a file into the editor
editor_load_file :: proc(editor: ^Editor, filename: string) -> os.Error {
	buffer := buffer.read(filename) or_return
	append(&editor.buffers, buffer)
	if len(editor.buffers) == 1 {
		editor.active_buffer = 0
	}

	return os.ERROR_NONE
}

/// Adds a buffer to the editor
editor_add_buffer :: proc(e: ^Editor, b: buffer.Buffer) {
	append(&e.buffers, b)
	if len(e.buffers) == 1 {
		e.active_buffer = 0
	}
}

/// Gets the currently active buffer
editor_active_buffer :: proc(e: ^Editor) -> ^buffer.Buffer {
	return &e.buffers[e.active_buffer]
}

/// Main event loop for interactive mode
editor_listen :: proc(e: ^Editor) {
	original_state := tty.set_raw_mode()
	tty.cursor_hide()
	tty.alt_screen_enable()

	defer {
		tty.cursor_show()
		tty.alt_screen_disable()
		tty.restore(&original_state)
	}

	render_editor(e)
	char: rune

	for e.running {
		render_editor(e)
		handle_input(e, tty.read())

	}
}
