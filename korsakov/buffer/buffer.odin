package buffer

Vec2 :: [2]int

Buffer :: struct {
  lines:    [dynamic]string,
  filename: string,
  cursor:   Vec2,
  modified: bool,
  scroll:   int,
}

// Creates a new empty buffer
new :: proc() -> Buffer {
  buffer := Buffer {
    lines    = make([dynamic]string), // must have at least one empty line
    filename = "",
    cursor   = {0, 0},
    modified = false,
    scroll   = 0,
  }

  append(&buffer.lines, "")

  return buffer
}

// Destroys a buffer and cleans up resources
destroy :: proc(b: ^Buffer) {
  for line in b.lines {
    delete(line)
  }
  delete(b.lines)
}

// Gets the number of lines in the buffer
line_count :: proc(b: ^Buffer) -> int {
  return len(b.lines)
}
