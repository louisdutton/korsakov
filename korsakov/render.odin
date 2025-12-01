package korsakov

import "buffer"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:terminal/ansi"
import "core:unicode/utf8"
import "tty"

// Renders the editor to the terminal
render_editor :: proc(e: ^Editor) {
  b := editor_active_buffer(e)

  render_buffer(e, b)
  render_status_bar(e, b)
  render_cursor(b, e.mode) // must be rendered last
}
