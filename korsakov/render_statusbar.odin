package korsakov

import "buffer"
import "core:fmt"
import "core:strings"
import "tty"

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
    fmt.tprintf(" pos=%d:%d", b.cursor.y, b.cursor.x),
  )

  // scroll
  strings.write_string(
    &status_builder,
    fmt.tprintf(" scr=%d:%d", b.scroll.y, b.scroll.x),
  )

  // Command buffer (shown when in command mode)
  if editor.mode == .Command {
    strings.write_string(&status_builder, " :")
    strings.write_string(&status_builder, editor.command_buffer)
  }

  status := strings.to_string(status_builder)

  // Print status and pad to full width
  tty.write(status)
  padding := editor.size.x - len(status)
  for i in 0 ..< padding {
    tty.write(" ")
  }

  tty.sgr_reset()
}
