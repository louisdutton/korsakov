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
  if line_length == 0 || position.x >= line_length do return ' '

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

// Inserts a new line below the current line and positions cursor at the start
insert_line_below :: proc(b: ^Buffer) {
  if b.cursor.y >= 0 && b.cursor.y < len(b.lines) {
    new_line_idx := b.cursor.y + 1
    inject_at(&b.lines, new_line_idx, "")
    b.cursor.y = new_line_idx
    b.cursor.x = 0
    b.modified = true
  }
}

// Inserts a new line above the current line and positions cursor at the start
insert_line_above :: proc(b: ^Buffer) {
  if b.cursor.y >= 0 && b.cursor.y < len(b.lines) {
    inject_at(&b.lines, b.cursor.y, "")
    // cursor.y stays the same since we inserted above
    b.cursor.x = 0
    b.modified = true
  }
}

// Positions cursor at the end of the current line
cursor_to_line_end :: proc(b: ^Buffer) {
  if b.cursor.y >= 0 && b.cursor.y < len(b.lines) {
    line := b.lines[b.cursor.y]
    b.cursor.x = len(line)
  }
}
