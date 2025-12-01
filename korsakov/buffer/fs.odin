package buffer

import "core:os"
import "core:path/filepath"
import "core:strings"

// TODO: make this a user-configurable struct that allows a many-to-one
// relationship between extentions and filetype
get_filetype :: proc(path: string) -> (filetype: string, ok: bool) {
  switch filepath.ext(path) {
  case ".odin":
    return "odin", true
  case:
    return "", false
  }
}

// Creates a buffer from a file
read :: proc(filename: string) -> (Buffer, os.Error) {
  data, ok := os.read_entire_file(filename)
  if !ok {
    return new(), os.ENOENT
  }
  defer delete(data)

  content := string(data)
  lines := strings.split_lines(content)

  buffer := Buffer {
    lines           = make([dynamic]string),
    filename        = filename,
    cursor          = {0, 0},
    modified        = false,
    history         = make([dynamic]BufferState),
    history_index   = -1,
    needs_highlight = true,
  }


  for line in lines {
    append(&buffer.lines, strings.clone(line))
  }

  // Ensure at least one line exists
  if len(buffer.lines) == 0 {
    append(&buffer.lines, "")
  }

  // Save initial state for undo/redo
  save_state(&buffer)

  return buffer, os.ERROR_NONE
}

// Saves the buffer to its file
write :: proc(buffer: ^Buffer) -> os.Error {
  if len(buffer.filename) == 0 {
    return os.EINVAL
  }

  // Join lines with newlines
  content_builder := strings.builder_make()
  defer strings.builder_destroy(&content_builder)

  for line, idx in buffer.lines {
    strings.write_string(&content_builder, line)
    if idx < len(buffer.lines) - 1 {
      strings.write_byte(&content_builder, '\n')
    }
  }

  content := strings.to_string(content_builder)
  ok := os.write_entire_file(buffer.filename, transmute([]u8)content)

  if ok {
    buffer.modified = false
    buffer.needs_highlight = true
    return os.ERROR_NONE
  }

  return os.EIO
}
