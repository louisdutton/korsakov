package korsakov

import "buffer"
import "tty"

render_cursor :: proc(b: ^buffer.Buffer, mode: Mode) {
  switch mode {
  // Block cursor - (virtual)
  case .Navigate, .Visual:
    tty.cursor_move(b.cursor.x + b.x_offset, b.cursor.y - b.scroll.y)
    tty.cursor_hide()
    tty.sgr_invert()
    char := buffer.get_current_char(b)
    tty.write_rune(char)
    tty.sgr_reset()

  // Bar cursor - (native)
  case .Insert:
    tty.cursor_move(b.cursor.x + b.x_offset, b.cursor.y - b.scroll.y)
    tty.cursor_line()
    tty.cursor_show()

  case .Command:
    tty.cursor_hide()
  }
}
