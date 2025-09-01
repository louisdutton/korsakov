package tty

import "base:intrinsics"
import "core:os"
import "core:sys/linux"
import "core:sys/unix"

Winsize :: struct {
  ws_row:    u16,
  ws_col:    u16,
  ws_xpixel: u16,
  ws_ypixel: u16,
}

/// Gets terminal size
get_terminal_size :: proc() -> [2]int {
  ws: Winsize

  linux.ioctl(linux.STDIN_FILENO, linux.TIOCGWINSZ, uintptr(&ws))
  assert(intrinsics.syscall(unix.SYS_ioctl, uintptr(os.stdout)) == 0)

  return {int(ws.ws_col), int(ws.ws_row)}
}
