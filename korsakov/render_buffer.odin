package korsakov

import "buffer"
import "core:fmt"
import "core:os"
import "core:terminal/ansi"
import "tty"

STATUS_BAR_HEIGHT :: 1
NUMBER_COLUMN_PADDING :: 1

// Renders the buffer content
render_buffer :: proc(b: ^buffer.Buffer) {
  for i in 0 ..< b.dimensions.y {
    tty.cursor_move(0, i)

    if i < buffer.line_count(b) {
      // project lines based on viewport scroll offset
      line_idx := min(i + b.scroll.y, len(b.lines) - 1)
      line := buffer.get_line(b, line_idx)

      // line number
      tty.write(ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR)
      fmt.print(i + b.scroll.y)

      tty.cursor_move(b.x_offset, i)
      tty.write(ansi.CSI + ansi.FG_WHITE + ansi.SGR)

      // horizontal scrolling
      width := b.dimensions.x - b.x_offset + 1
      line_length := len(line)
      start := min(b.scroll.x, line_length)
      end := min(width + b.scroll.x, line_length)
      tty.write(line[start:end])
    }

    tty.clear_line()
  }

  render_cursor(b)
}
