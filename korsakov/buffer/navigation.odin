package buffer

// the number of lines cursor has to be from the vertical bounds
// in order to trigger scroll behaviour
SCROLL_PADDING_Y :: 10

// moves the cursor up N lines
cursor_up :: proc(b: ^Buffer, n := 1) {
  b.cursor.y = max(b.cursor.y - n, 0)
  clamp_cursor_x(b)
  clamp_scroll_x(b)

  if b.cursor.y <= b.scroll.y + SCROLL_PADDING_Y {
    b.scroll.y = max(b.scroll.y - n, 0)
  }
}

// moves the cursor down N lines
cursor_down :: proc(b: ^Buffer, n := 1) {
  b.cursor.y = min(b.cursor.y + n, len(b.lines) - 1)
  clamp_cursor_x(b)
  clamp_scroll_x(b)

  if b.cursor.y >= b.dimensions.y - SCROLL_PADDING_Y + b.scroll.y {
    b.scroll.y = min(b.scroll.y + n, len(b.lines) - b.dimensions.y)
  }
}

// moves the cursor left N characters
cursor_left :: proc(b: ^Buffer, n := 1) {
  b.cursor.x = max(b.cursor.x - n, 0)
  b.scroll.x = max(b.scroll.x - n, 0)
}

// moves the cursor right N characters
cursor_right :: proc(b: ^Buffer, n := 1) {
  b.cursor.x = b.cursor.x + n
  clamp_cursor_x(b)

  if b.cursor.x + n > b.dimensions.x - b.x_offset {
    b.scroll.x += n
  }
  clamp_scroll_x(b)
}

// moves the cursor to the end of the current line
cursor_xmax :: proc(b: ^Buffer) {
  b.cursor.x = max(0, len(get_current_line(b)) - 1)
  b.scroll.x = max(0, b.cursor.x - b.dimensions.x - b.x_offset)
}

// moves the cursor to the start of the current line
cursor_xmin :: proc(b: ^Buffer) {
  b.cursor.x = 0
  b.scroll.x = 0
}

// moves the cursor to the last line
cursor_ymax :: proc(b: ^Buffer) {
  count := len(b.lines)
  b.cursor.y = count - 1
  b.scroll.y = count - b.dimensions.y
}

// moves the cursor to the first line
cursor_ymin :: proc(b: ^Buffer) {
  b.cursor.y = 0
  b.scroll.y = 0
}

@(private)
clamp_cursor_x :: proc(b: ^Buffer) {
  line_length := len(get_current_line(b))
  b.cursor.x = max(min(b.cursor.x, line_length - 1), 0)
}

@(private)
clamp_scroll_x :: proc(b: ^Buffer) {
  line_length := len(get_current_line(b))
  width := (b.dimensions.x - b.x_offset)
  b.scroll.x = max(min(b.scroll.x, line_length - width), 0)
}
