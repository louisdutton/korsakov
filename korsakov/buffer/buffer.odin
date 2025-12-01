package buffer

import "core:strings"

Vec2 :: [2]int

// Represents a state snapshot for undo/redo
BufferState :: struct {
  lines:  [dynamic]string,
  cursor: Vec2,
}

Buffer :: struct {
  lines:         [dynamic]string,
  filename:      string,
  filetype:      string,
  cursor:        Vec2,
  modified:      bool,

  // sign/number column
  x_offset:      int,

  // viewport (this can potentially be it's own distinct entity)
  dimensions:    Vec2,
  scroll:        Vec2,

  // undo/redo history
  history:       [dynamic]BufferState,
  history_index: int, // Current position in history

  // syntax highlighting cache
  needs_highlight: bool, // true when buffer content changes
}

// Creates a new empty buffer
new :: proc() -> Buffer {
  buffer := Buffer {
    lines           = make([dynamic]string), // must have at least one empty line
    filename        = "",
    cursor          = {0, 0},
    modified        = false,
    scroll          = 0,
    history         = make([dynamic]BufferState),
    history_index   = -1,
    needs_highlight = true,
  }

  append(&buffer.lines, "")

  // Save initial state
  save_state(&buffer)

  return buffer
}

// Destroys a buffer and cleans up resources
destroy :: proc(b: ^Buffer) {
  for line in b.lines {
    delete(line)
  }
  delete(b.lines)

  // Clean up history
  for &state in b.history {
    for line in state.lines {
      delete(line)
    }
    delete(state.lines)
  }
  delete(b.history)
}

// Gets the number of lines in the buffer
line_count :: proc(b: ^Buffer) -> int {
  return len(b.lines)
}

// Saves the current buffer state to history
save_state :: proc(b: ^Buffer) {
  // If we're not at the end of history, truncate everything after current position
  if b.history_index < len(b.history) - 1 {
    // Delete states that will be discarded
    for i in b.history_index + 1 ..< len(b.history) {
      state := &b.history[i]
      for line in state.lines {
        delete(line)
      }
      delete(state.lines)
    }
    resize(&b.history, b.history_index + 1)
  }

  // Create a deep copy of current state
  state := BufferState {
    lines  = make([dynamic]string),
    cursor = b.cursor,
  }

  for line in b.lines {
    append(&state.lines, strings.clone(line))
  }

  append(&b.history, state)
  b.history_index = len(b.history) - 1

  // Limit history size to prevent excessive memory usage
  MAX_HISTORY :: 100
  if len(b.history) > MAX_HISTORY {
    // Remove oldest state
    oldest := &b.history[0]
    for line in oldest.lines {
      delete(line)
    }
    delete(oldest.lines)
    ordered_remove(&b.history, 0)
    b.history_index -= 1
  }
}

// Undo the last operation
undo :: proc(b: ^Buffer) -> bool {
  if b.history_index <= 0 {
    return false // Nothing to undo
  }

  b.history_index -= 1
  restore_state(b, &b.history[b.history_index])
  return true
}

// Redo the next operation
redo :: proc(b: ^Buffer) -> bool {
  if b.history_index >= len(b.history) - 1 {
    return false // Nothing to redo
  }

  b.history_index += 1
  restore_state(b, &b.history[b.history_index])
  return true
}

// Restores buffer state from a history entry
restore_state :: proc(b: ^Buffer, state: ^BufferState) {
  // Clear current lines
  for line in b.lines {
    delete(line)
  }
  clear(&b.lines)

  // Restore lines from state
  for line in state.lines {
    append(&b.lines, strings.clone(line))
  }

  // Restore cursor position
  b.cursor = state.cursor
  b.modified = true
  b.needs_highlight = true
}
