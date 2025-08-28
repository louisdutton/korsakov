package korsakov

import "buffer"
import "tty"

ESC :: 27

handle_input :: proc(e: ^Editor, ch: rune) {
	switch e.mode {
	case .Navigate:
		handle_nav_input(e, ch)
	case .Insert:
		handle_insert_input(e, ch)
	case .Visual:
		handle_visual_input(e, ch)
	case .Command:
		handle_command_input(e, ch)
	}
}

@(private = "file")
handle_nav_input :: proc(e: ^Editor, ch: rune) {
	b := editor_active_buffer(e)

	switch ch {
	case 'q':
		e.running = false
	case 'j':
		buffer.cursor_down(b)
	case 'k':
		buffer.cursor_up(b)
	case 'h':
		buffer.cursor_left(b)
	case 'l':
		buffer.cursor_right(b)
	case 'i':
		set_mode(e, .Insert)
	case 'v':
		set_mode(e, .Visual)
	case ';':
		set_mode(e, .Command)
	}
}

set_mode :: proc(e: ^Editor, mode: Mode) {
	e.mode = mode
	// potentially do some stuff here in future
}

@(private = "file")
handle_insert_input :: proc(e: ^Editor, ch: rune) {
	switch ch {
	case ESC:
		set_mode(e, .Navigate)
	}
}

@(private = "file")
handle_visual_input :: proc(e: ^Editor, ch: rune) {
	switch ch {
	case ESC:
		set_mode(e, .Navigate)
	}
}

@(private = "file")
handle_command_input :: proc(e: ^Editor, ch: rune) {
	switch ch {
	case ESC:
		set_mode(e, .Navigate)
	}
}
