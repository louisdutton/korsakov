package tty

import "core:fmt"
import "core:os"
import "core:strings"
import "core:unicode/utf8"

KeyCode :: enum {
  Char,
  Enter,
  Tab,
  Backspace,
  Delete,
  Up,
  Down,
  Left,
  Right,
  Escape,
  F1,
  F2,
  F3,
  F4,
  F5,
  F6,
  F7,
  F8,
  F9,
  F10,
  F11,
  F12,
}


Event :: struct {
  key_code:   KeyCode,
  char_value: rune, // Only valid when key_code is Char
}

// Output buffering
output_buffer: strings.Builder
buffering_enabled: bool = false

// Enable output buffering for batched writes
begin_buffering :: proc() {
  output_buffer = strings.builder_make()
  buffering_enabled = true
}

// Flush buffered output to stdout and disable buffering
end_buffering :: proc() {
  if buffering_enabled {
    os.write_string(os.stdout, strings.to_string(output_buffer))
    strings.builder_destroy(&output_buffer)
    buffering_enabled = false
  }
}

// writes to stdout or buffer if buffering is enabled
write :: proc(str: string) {
  if buffering_enabled {
    strings.write_string(&output_buffer, str)
  } else {
    os.write_string(os.stdout, str)
  }
}

// writes a rune to stdout or buffer if buffering is enabled
write_rune :: proc(r: rune) {
  buf, n := utf8.encode_rune(r)
  write(string(buf[:]))
}

// reads from stdin
read :: proc() -> rune {
  buffer: [1]byte
  os.read(os.stdin, buffer[:])
  return rune(buffer[0])
}
