package tty

import "core:fmt"
import "core:os"
import "core:sys/posix"

STDIN :: posix.FD(0)

set_raw_mode :: proc() -> (original: posix.termios) {
  // Get current terminal attributes
  assert(posix.tcgetattr(STDIN, &original) == .OK)

  // Create modified termios for raw mode
  raw := original

  raw.c_iflag -= {.ICRNL, .INPCK, .ISTRIP, .IXON}
  raw.c_oflag -= {.OPOST}
  raw.c_lflag -= {.IEXTEN, .ICANON, .ISIG, .ECHO}
  raw.c_cc[.VMIN] = 1 // Return each byte as it arrives
  raw.c_cc[.VTIME] = 0 // No timeout

  // Apply the new settings
  assert(posix.tcsetattr(STDIN, {}, &raw) == .OK)

  return original
}

restore :: proc(original: ^posix.termios) {
  assert(posix.tcsetattr(STDIN, {}, original) == .OK)
}
