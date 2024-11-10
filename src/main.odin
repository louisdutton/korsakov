package korsakov

import "core:encoding/ansi"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:text/edit"
import "termios"

Mode :: enum u8 {
	Normal,
	Input,
}

BACKSPACE :: 127
QUIT :: 'q'
CLEAR_TO_END_OF_LINE :: ansi.CSI + ansi.EL

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

	// stdin buffer
	buf: [1]byte

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
		}

		queue("\r", strings.to_string(state.builder^), CLEAR_TO_END_OF_LINE)
		flush()
	}
}

input_mode :: proc(ch: rune) {
	switch ch {
	case BACKSPACE:
		//edit.perform_command(&state, .Backspace)
		if len(state.builder.buf) > 0 do pop(&state.builder.buf)
	case:
		//edit.input_rune(&state, ch)
		append(&state.builder.buf, byte(ch))
	}
}
