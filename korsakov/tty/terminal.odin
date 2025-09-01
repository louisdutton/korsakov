package tty

import "core:fmt"
import "core:os"

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

// writes to stdout
write :: proc(str: string) {os.write_string(os.stdout, str)}

// reads from stdin
read :: proc() -> rune {
  buffer: [1]byte
  os.read(os.stdin, buffer[:])
  return rune(buffer[0])
}
