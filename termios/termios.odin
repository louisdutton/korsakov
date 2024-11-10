package termios

import "core:sys/posix"

@(private)
original_termios: posix.termios = {}

enable_raw_mode :: proc() {
	using posix
	assert(isatty(STDOUT_FILENO) == true)
	tcgetattr(STDIN_FILENO, &original_termios)
	raw := original_termios
	raw.c_lflag &= {(.ECHO | .ICANON)}
	tcsetattr(STDIN_FILENO, .TCSAFLUSH, &raw)
}

disable_raw_mode :: proc() {
	using posix
	tcsetattr(STDIN_FILENO, .TCSAFLUSH, &original_termios)
}
