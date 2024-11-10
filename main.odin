package korsaov

import "core:encoding/ansi"
import "core:fmt"
import "core:os"
import "core:text/edit"
import "core:unicode/utf8"
import "termios"

Mode :: enum u8 {
	Normal,
	Input,
}

mode := Mode.Input
text := [dynamic]rune{}

main :: proc() {
	termios.enable_raw_mode()
	defer termios.disable_raw_mode()

	buf: [1]byte
	fmt.println("Please enter some text:")

	for true {
		os.read(os.stdin, buf[:]) or_break
		ch := rune(buf[0])

		if (ch == 'q') {break}

		switch mode {
		case .Input:
			input_mode(ch)
		case .Normal:
		}

		fmt.print(
			'\r', // wipe current line
			utf8.runes_to_string(text[:]),
			ansi.CSI + ansi.EL, // clear to end of line
			sep = "", // no separator
			flush = true,
		)
	}
}

BACKSPACE :: 127

input_mode :: proc(ch: rune) {
	switch ch {
	case BACKSPACE:
		if (len(text) > 0) {
			pop(&text)
		}
	case:
		append(&text, ch)
	}
}
