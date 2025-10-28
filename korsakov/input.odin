package korsakov

import "buffer"
import "core:log"
import "core:unicode/utf8"
import "tty"

Action :: proc(e: ^Editor)
Action_Map :: map[string]Action

Key :: enum rune {
  ESC = 27,
}

// input_buffer: [8]u8 // TODO
keymaps: [Mode]Action_Map

handle_input :: proc(e: ^Editor, ch: rune) {
  if Key(ch) == .ESC && e.mode != .Navigate {
    e.mode = .Navigate
  } else {
    exec(e, &keymaps[e.mode], ch)
  }
}

// Handle input for insert mode with fallback for unmapped characters
handle_insert_input :: proc(e: ^Editor, ch: rune) {
  // For insert mode, insert any printable character
  if ch >= 32 && ch <= 126 || ch == ' ' || ch == '\t' {
    buffer.insert_char(editor_active_buffer(e), ch)
  }
}

exec :: proc(e: ^Editor, m: ^map[string]Action, ch: rune) {
  key := utf8.runes_to_string({ch})
  defer delete(key)
  if fn := m[key]; fn != nil {
    fn(e)
  } else if e.mode == .Insert {
    // Fallback for insert mode: insert any printable character
    handle_insert_input(e, ch)
  }
}

@(init)
input_init :: proc() {
  nmap := &keymaps[.Navigate]
  imap := &keymaps[.Insert]
  vmap := &keymaps[.Visual]
  cmap := &keymaps[.Command]

  // buffer navigation
  nmap["j"] = proc(e: ^Editor) {buffer.cursor_down(editor_active_buffer(e))}
  nmap["k"] = proc(e: ^Editor) {buffer.cursor_up(editor_active_buffer(e))}
  nmap["h"] = proc(e: ^Editor) {buffer.cursor_left(editor_active_buffer(e))}
  nmap["l"] = proc(e: ^Editor) {buffer.cursor_right(editor_active_buffer(e))}
  nmap["J"] = proc(e: ^Editor) {buffer.cursor_ymax(editor_active_buffer(e))}
  nmap["K"] = proc(e: ^Editor) {buffer.cursor_ymin(editor_active_buffer(e))}
  nmap["H"] = proc(e: ^Editor) {buffer.cursor_xmin(editor_active_buffer(e))}
  nmap["L"] = proc(e: ^Editor) {buffer.cursor_xmax(editor_active_buffer(e))}

  // mode controls
  nmap["i"] = proc(e: ^Editor) {set_mode(e, .Insert)}
  nmap["v"] = proc(e: ^Editor) {set_mode(e, .Visual)}
  nmap[";"] = proc(e: ^Editor) {set_mode(e, .Command)}

  // insert mode uses fallback handler in exec() for character input
  
  // this should need to be submitted
  cmap["q"] = proc(e: ^Editor) {e.running = false}
}

@(fini)
init_fini :: proc() {
  for kmap in keymaps {
    delete(kmap)
  }
}

set_mode :: proc(e: ^Editor, mode: Mode) {
  e.mode = mode
  log.debug("mode:", mode)
  // potentially do some stuff here in future
}
