package buffer

import "core:unicode/utf8"

// Deletes a range of text from start to end (inclusive)
// This is used for visual mode deletion
// TODO: reduce complexity
delete_selection :: proc(b: ^Buffer) {
  start := b.visual_anchor
  end := b.cursor

  // Normalize range so start is before or equal to end
  norm_start, norm_end := start, end
  if start.y > end.y || (start.y == end.y && start.x > end.x) {
    norm_start, norm_end = end, start
  }

  // Bounds checking
  if norm_start.y < 0 || norm_start.y >= len(b.lines) do return
  if norm_end.y < 0 || norm_end.y >= len(b.lines) do return

  // Single line deletion
  if norm_start.y == norm_end.y {
    line := b.lines[norm_start.y]
    runes := utf8.string_to_runes(line)
    defer delete(runes)

    // Build new line without the deleted range
    new_runes := make([dynamic]rune)
    defer delete(new_runes)

    // Keep everything before start
    for i in 0 ..< norm_start.x {
      if i < len(runes) {
        append(&new_runes, runes[i])
      }
    }

    // Keep everything after end (inclusive deletion, so skip end.x)
    for i in norm_end.x + 1 ..< len(runes) {
      append(&new_runes, runes[i])
    }

    delete(b.lines[norm_start.y])
    b.lines[norm_start.y] = utf8.runes_to_string(new_runes[:])

    // Position cursor at start of deletion
    b.cursor = norm_start
    b.modified = true
    b.needs_highlight = true
    return
  }

  // Multi-line deletion
  start_line := b.lines[norm_start.y]
  end_line := b.lines[norm_end.y]

  start_runes := utf8.string_to_runes(start_line)
  defer delete(start_runes)

  end_runes := utf8.string_to_runes(end_line)
  defer delete(end_runes)

  // Build the new combined line
  new_runes := make([dynamic]rune)
  defer delete(new_runes)

  // Keep text before start position on first line
  for i in 0 ..< norm_start.x {
    if i < len(start_runes) {
      append(&new_runes, start_runes[i])
    }
  }

  // Keep text after end position on last line
  for i in norm_end.x + 1 ..< len(end_runes) {
    append(&new_runes, end_runes[i])
  }

  // Update the start line with the combined result
  delete(b.lines[norm_start.y])
  b.lines[norm_start.y] = utf8.runes_to_string(new_runes[:])

  // Delete all lines from start+1 to end (inclusive)
  for i := norm_end.y; i > norm_start.y; i -= 1 {
    if i < len(b.lines) {
      delete(b.lines[i])
      ordered_remove(&b.lines, i)
    }
  }

  // Position cursor at start of deletion
  b.cursor = norm_start
  b.modified = true
  b.needs_highlight = true
  save_state(b) // commit to history
}
