package korsakov

import "buffer"
import "core:log"
import "core:unicode/utf8"
import "tty"

Action :: proc(e: ^Editor)
Action_Map :: map[string]Action

Key :: enum rune {
  ESC       = 27,
  BACKSPACE = 127, // DEL character (typical backspace)
  CTRL_H    = 8, // Alternative backspace
}

// input_buffer: [8]u8 // TODO
keymaps: [Mode]Action_Map

handle_input :: proc(e: ^Editor, ch: rune) {
  if Key(ch) == .ESC && e.mode != .Navigate {
    set_mode(e, .Navigate)
  } else {
    exec(e, &keymaps[e.mode], ch)
  }
}

// Handle input for insert mode with fallback for unmapped characters
handle_insert_input :: proc(e: ^Editor, ch: rune) {
  // Handle backspace/delete
  if Key(ch) == .BACKSPACE || Key(ch) == .CTRL_H {
    buffer.delete_char(editor_active_buffer(e))
    return
  }

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

  // mode controls - insert mode variants
  nmap["i"] = proc(e: ^Editor) {set_mode(e, .Insert)}
  nmap["a"] = proc(e: ^Editor) {
    buffer.cursor_right(editor_active_buffer(e))
    set_mode(e, .Insert)
  }
  nmap["A"] = proc(e: ^Editor) {
    buffer.cursor_to_line_end(editor_active_buffer(e))
    set_mode(e, .Insert)
  }
  nmap["I"] = proc(e: ^Editor) {
    buffer.cursor_xmin(editor_active_buffer(e))
    set_mode(e, .Insert)
  }
  nmap["o"] = proc(e: ^Editor) {
    buffer.insert_line_below(editor_active_buffer(e))
    set_mode(e, .Insert)
  }
  nmap["O"] = proc(e: ^Editor) {
    buffer.insert_line_above(editor_active_buffer(e))
    set_mode(e, .Insert)
  }

  // other modes
  nmap["v"] = proc(e: ^Editor) {set_mode(e, .Visual)}
  nmap[";"] = proc(e: ^Editor) {set_mode(e, .Command)}

  // undo/redo
  nmap["u"] = proc(e: ^Editor) {buffer.undo(editor_active_buffer(e))}
  nmap["U"] = proc(e: ^Editor) {buffer.redo(editor_active_buffer(e))}

  // insert mode uses fallback handler in exec() for character input

  // command mode commands
  cmap["q"] = proc(e: ^Editor) {command_execute(&e.commands, e, "q")}
  cmap["w"] = proc(e: ^Editor) {command_execute(&e.commands, e, "w")}
}

@(fini)
init_fini :: proc() {
  for kmap in keymaps {
    delete(kmap)
  }
}

set_mode :: proc(e: ^Editor, mode: Mode) {
  // Save state when exiting insert mode (after changes were made)
  if e.mode == .Insert && mode != .Insert {
    buffer.save_state(editor_active_buffer(e))
  }

  e.mode = mode
  log.debug("mode:", mode)
}
