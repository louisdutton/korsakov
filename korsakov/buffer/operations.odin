package buffer

import "core:strings"
import "core:unicode/utf8"


// Gets a line from the buffer
get_line :: proc(b: ^Buffer, y: int) -> string {
  assert(y >= 0 && y < len(b.lines))
  return b.lines[y]
}

get_current_line :: proc(b: ^Buffer) -> string {
  return get_line(b, b.cursor.y)
}

// Returns the char at then given position
get_char :: proc(b: ^Buffer, position: Vec2) -> rune {
  assert(position.y < len(b.lines))
  line := b.lines[position.y]
  line_length := len(line)
  if line_length == 0 do return ' '
  assert(position.x < line_length)

  return rune(b.lines[position.y][position.x])
}

get_current_char :: proc(b: ^Buffer) -> rune {
  return get_char(b, b.cursor)
}

// Sets a line in the buffer
set_line :: proc(b: ^Buffer, line_idx: int, content: string) {
  if line_idx >= 0 && line_idx < len(b.lines) {
    delete(b.lines[line_idx])
    b.lines[line_idx] = strings.clone(content)
    b.modified = true
  }
}

// Inserts a character at the cursor position
insert_char :: proc(b: ^Buffer, ch: rune) {
  if b.cursor.y >= 0 && b.cursor.y < len(b.lines) {
    line := b.lines[b.cursor.y]

    // Convert to runes for proper Unicode handling
    runes := utf8.string_to_runes(line)
    defer delete(runes)

    // Insert character at cursor position
    new_runes := make([dynamic]rune)
    defer delete(new_runes)

    for i in 0 ..< b.cursor.x {
      if i < len(runes) {
        append(&new_runes, runes[i])
      }
    }
    append(&new_runes, ch)
    for i in b.cursor.x ..< len(runes) {
      append(&new_runes, runes[i])
    }

    // Convert back to string
    delete(b.lines[b.cursor.y])
    b.lines[b.cursor.y] = utf8.runes_to_string(new_runes[:])

    b.cursor.x += 1
    b.modified = true
  }
}

// Deletes a character at the cursor position
delete_char :: proc(b: ^Buffer) {
  if b.cursor.y >= 0 && b.cursor.y < len(b.lines) {
    line := b.lines[b.cursor.y]

    if b.cursor.x > 0 {
      // Convert to runes for proper Unicode handling
      runes := utf8.string_to_runes(line)
      defer delete(runes)

      // Remove character before cursor
      new_runes := make([dynamic]rune)
      defer delete(new_runes)

      for i in 0 ..< b.cursor.x - 1 {
        if i < len(runes) {
          append(&new_runes, runes[i])
        }
      }
      for i in b.cursor.x ..< len(runes) {
        if i < len(runes) {
          append(&new_runes, runes[i])
        }
      }

      // Convert back to string
      delete(b.lines[b.cursor.y])
      b.lines[b.cursor.y] = utf8.runes_to_string(new_runes[:])

      b.cursor.x -= 1
      b.modified = true
    }
  }
}

// the number of lines cursor has to be from the vertical bounds
// in order to trigger scroll behaviour
SCROLL_PADDING :: 10

// moves the cursor up N lines
cursor_up :: proc(b: ^Buffer, n := 1) {
  b.cursor.y = max(b.cursor.y - n, 0)
  clamp_cursor_x(b)

  if b.cursor.y <= b.scroll.y + SCROLL_PADDING {
    b.scroll.y = max(b.scroll.y - 1, 0)
  }
}

// moves the cursor down N lines
cursor_down :: proc(b: ^Buffer, n := 1) {
  b.cursor.y = min(b.cursor.y + n, len(b.lines) - 1)
  clamp_cursor_x(b)

  if b.cursor.y >= b.dimensions.y - SCROLL_PADDING {
    b.scroll.y = min(b.scroll.y + 1, len(b.lines) - b.dimensions.y)
  }
}

// moves the cursor left N characters
cursor_left :: proc(b: ^Buffer, n := 1) {
  b.cursor.x = max(b.cursor.x - n, 0)

  // TODO: horizontal scroll
}

// moves the cursor right N characters
cursor_right :: proc(b: ^Buffer, n := 1) {
  b.cursor.x = b.cursor.x + n
  clamp_cursor_x(b)

  // TODO: horizontal scroll
}

@(private)
clamp_cursor_x :: proc(b: ^Buffer) {
  b.cursor.x = max(min(b.cursor.x, len(get_current_line(b)) - 1), 0)
}
