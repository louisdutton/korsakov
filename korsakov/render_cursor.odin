package korsakov

import "core:os"
import "tty"
import "buffer"

render_cursor :: proc(b: ^buffer.Buffer) {
  tty.cursor_move(b.cursor.x + b.x_offset, b.cursor.y - b.scroll.y)
  tty.sgr_invert()
  char := buffer.get_current_char(b)
  os.write_rune(os.stdout, char)
  tty.sgr_reset()
}
