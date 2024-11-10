package korsakov

import "core:fmt"
import "core:os"
import "core:strings"
import "core:text/edit"
import "termios"
import "vendor:raylib"

Mode :: enum u8 {
	Normal,
	Input,
}

mode := Mode.Input
state := edit.State{}

main :: proc() {
	// raw tty
	termios.enable_raw_mode()
	defer termios.disable_raw_mode()

	// init
	builder := strings.Builder{}
	strings.builder_init(&builder)
	edit.setup_once(&state, &builder)

	set_mode(.Normal)

	// stdin buffer
	buf: [1]byte

	// default_mode
	set_mode(.Normal)

	for true {
		// TODO manage id
		edit.begin(&state, 1, &builder)
		defer edit.end(&state)

		os.read(os.stdin, buf[:]) or_break
		ch := rune(buf[0])

		if (ch == QUIT) {break}

		switch mode {
		case .Input:
			input_mode(ch)
		case .Normal:
			normal_mode(ch)
		}

		queue("\r", strings.to_string(state.builder^), CLEAR_TO_END_OF_LINE)
	}
}

input_mode :: proc(ch: rune) {
	switch ch {
	case ESCAPE, '0':
		set_mode(.Normal)
	case BACKSPACE, DELETE:
		//edit.perform_command(&state, .Backspace)
		if len(state.builder.buf) > 0 do pop(&state.builder.buf)
	case:
		//edit.input_rune(&state, ch)
		append(&state.builder.buf, byte(ch))
	}
}

normal_mode :: proc(ch: rune) {
	switch ch {
	case 'i':
		set_mode(.Input)
	// TODO sync tty cursor with editor cursor
	case 'h':
		edit.perform_command(&state, .Left)
	case 'j':
		edit.perform_command(&state, .Down)
	case 'k':
		edit.perform_command(&state, .Up)
	case 'l':
		edit.perform_command(&state, .Right)
	}
}

set_mode :: proc(m: Mode) {
	switch m {
	case .Input:
		mode = .Input
		exec(DECSCUSR_BAR)
	case .Normal:
		mode = .Normal
		exec(DECSCUSR_BLOCK)
	}
}
