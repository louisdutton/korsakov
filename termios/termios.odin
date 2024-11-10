package termios

import "core:sys/posix"

@(private)
original_termios: posix.termios = {}

enable_raw_mode :: proc() {
	assert(posix.isatty(posix.STDOUT_FILENO) == true)
	posix.tcgetattr(posix.STDIN_FILENO, &original_termios)
	raw := original_termios
	raw.c_lflag &= {(.ECHO | .ICANON)}
	posix.tcsetattr(posix.STDIN_FILENO, .TCSAFLUSH, &raw)
}

disable_raw_mode :: proc() {
	posix.tcsetattr(posix.STDIN_FILENO, .TCSAFLUSH, &original_termios)
}
