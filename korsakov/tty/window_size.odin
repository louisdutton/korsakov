package tty

import "base:intrinsics"
import "core:os"
import "core:sys/posix"
import "core:sys/unix"

@private
STDOUT :: uintptr(posix.STDOUT_FILENO)

Winsize :: struct {
  ws_row:    u16,
  ws_col:    u16,
  ws_xpixel: u16,
  ws_ypixel: u16,
}

// Gets terminal size
get_terminal_size :: proc() -> [2]int {
  ws: Winsize

  when ODIN_OS == .Linux {
    TIOCGWINSZ :uintptr: 0x5413
    SYS_ioctl :: 16
  } else when ODIN_OS == .Darwin {
    TIOCGWINSZ :uintptr: 0x40087468
    SYS_ioctl :: 54
  }

  result := intrinsics.syscall(SYS_ioctl, STDOUT, TIOCGWINSZ, uintptr(&ws))
  assert(result == 0)

  return {int(ws.ws_col), int(ws.ws_row)}
}
