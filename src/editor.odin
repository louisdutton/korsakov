package korsakov

import "core:fmt"
import "core:os"
import "core:slice"

Mode :: enum {
	Navigate,
	Insert,
	Visual,
	Command,
}

Vec2 :: struct {
	x: int,
	y: int,
}

vec2 :: proc(x, y: int) -> Vec2 {
	return Vec2{x, y}
}

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
editor_new_headless :: proc() -> (Editor, os.Errno) {
	editor := Editor {
		mode           = .Navigate,
		buffers        = make([dynamic]Buffer),
		active_buffer  = 0,
		size           = vec2(80, 24),
		commands       = command_registry_new(),
		running        = true,
		command_buffer = "",
	}

	return editor, os.ERROR_NONE
}

/// Creates a new interactive editor instance
editor_new :: proc() -> (Editor, os.Errno) {
	editor := Editor {
		mode           = .Navigate,
		buffers        = make([dynamic]Buffer),
		active_buffer  = 0,
		size           = vec2(80, 24), // TODO: Get actual terminal size
		commands       = command_registry_new(),
		running        = true,
		command_buffer = "",
	}

	// TODO: Initialize terminal, treesitter, input maps, etc.

	return editor, os.ERROR_NONE
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
editor_load_file :: proc(editor: ^Editor, filename: string) -> os.Errno {
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
	if editor.active_buffer >= 0 && editor.active_buffer < len(editor.buffers) {
		return &editor.buffers[editor.active_buffer]
	}
	return nil
}

/// Evaluates input actions in headless mode
editor_eval :: proc(editor: ^Editor, input_actions: string) -> os.Errno {
	// TODO: Parse and execute vim-style input actions
	// For now, just print that we received the actions
	fmt.printf("Headless mode: executing actions '%s'\n", input_actions)
	return os.ERROR_NONE
}

/// Main event loop for interactive mode
editor_listen :: proc(editor: ^Editor) -> os.Errno {
	// Setup terminal
	enter_alternate_screen()
	defer leave_alternate_screen()
	
	for editor.running {
		// Render the current state
		render_editor(editor)
		
		// Simple demo: just print a message and exit after a moment
		fmt.println("Korsakov editor is running! Press any key to exit...")
		
		// For now, just exit immediately since we don't have proper input handling yet
		// In a real implementation, this would read terminal events and handle them
		break
	}
	return os.ERROR_NONE
}
