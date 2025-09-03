package korsakov

import "buffer"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "core:unicode/utf8"
import "tty"

STATUS_BAR_HEIGHT :: 2

// Renders the editor to the terminal
render_editor :: proc(e: ^Editor) {
  b := editor_active_buffer(e)

  render_buffer(b)
  render_status_bar(e, b)
}

// Renders the buffer content
render_buffer :: proc(b: ^buffer.Buffer) {
  number_column_width := len(b.lines) / 10
  max_width := b.dimensions.x - number_column_width

  for i in 0 ..< b.dimensions.y {
    tty.cursor_move(0, i)

    if i < buffer.line_count(b) {
      // project lines based on viewport scroll offset
      line_idx := min(i + b.scroll.y, len(b.lines) - 1)
      line := buffer.get_line(b, line_idx)

      // line number
      tty.write(ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR)
      fmt.print(i)

      tty.cursor_move(number_column_width + 1, i)
      tty.write(ansi.CSI + ansi.FG_WHITE + ansi.SGR)

      // Truncate line if it's too long for the screen
      if len(line) > max_width {
        tty.write(line[:max_width])
      } else {
        fmt.print(line)
      }
    }

    tty.clear_line()
  }

  render_cursor(b, number_column_width)
}

// Renders the cursor
render_cursor :: proc(b: ^buffer.Buffer, num_col_w: int) {
  tty.cursor_move(b.cursor.x + num_col_w + 1, b.cursor.y - b.scroll.y)
  tty.sgr_invert()
  char := buffer.get_current_char(b)
  os.write_rune(os.stdout, char)
  tty.sgr_reset()
}

// Renders the status bar
render_status_bar :: proc(editor: ^Editor, b: ^buffer.Buffer) {
  status_y := editor.size.y - 1
  tty.cursor_move(0, status_y)

  // Set background color for status bar
  tty.sgr_invert()

  // Build status string
  status_builder := strings.builder_make()
  defer strings.builder_destroy(&status_builder)

  // Mode indicator
  mode_str := ""
  switch editor.mode {
  case .Navigate: mode_str = " NAV "
  case .Insert: mode_str = " INS "
  case .Visual: mode_str = " VIS "
  case .Command: mode_str = " CMD "
  }
  strings.write_string(&status_builder, mode_str)

  // Filename
  if len(b.filename) > 0 {
    strings.write_string(&status_builder, " ")
    strings.write_string(&status_builder, b.filename)
  } else {
    strings.write_string(&status_builder, " [No Name]")
  }

  // Modified indicator
  if b.modified {
    strings.write_string(&status_builder, " [+]")
  }

  // Cursor position
  strings.write_string(
    &status_builder,
    fmt.tprintf(" pos=%d:%d", b.cursor.y + 1, b.cursor.x + 1),
  )

  // scroll
  strings.write_string(
    &status_builder,
    fmt.tprintf(" scr=%d:%d", b.scroll.y, b.scroll.x),
  )

  status := strings.to_string(status_builder)

  // Print status and pad to full width
  fmt.print(status)
  padding := editor.size.x - len(status)
  for i in 0 ..< padding {
    tty.write(" ")
  }

  tty.sgr_reset()
}
