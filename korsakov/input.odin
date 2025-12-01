package korsakov

import "buffer"
import "core:fmt"
import "core:log"
import "core:unicode/utf8"
import "tty"

Action :: proc(e: ^Editor)
Action_Map :: map[string]Action

Key :: enum rune {
  EOF       = 4,
  SIGINT    = 5,
  ESC       = 27,
  BACKSPACE = 127, // DEL character (typical backspace)
  CTRL_H    = 8, // Alternative backspace
  ENTER     = 13, // Carriage Return (what terminals actually send)
  LF        = 10, // Line Feed (Unix newline in files)
}

// input_buffer: [8]u8 // TODO
keymaps: [Mode]Action_Map

handle_input :: proc(e: ^Editor, ch: rune) {
  log.debugf("Received char: %d (0x%x) mode: %v", ch, ch, e.mode)

  // global bindings
  #partial switch Key(ch) {
  case .ESC:
    if e.mode != .Navigate do set_mode(e, .Navigate)
  case .SIGINT, .EOF: e.running = false
  case:
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

// Handle input for command mode - buffers characters
handle_command_input :: proc(e: ^Editor, ch: rune) {
  // Handle backspace/delete
  if Key(ch) == .BACKSPACE || Key(ch) == .CTRL_H {
    if len(e.command_buffer) > 0 {
      // Remove last character from command buffer
      runes := utf8.string_to_runes(e.command_buffer)
      defer delete(runes)
      old_buffer := e.command_buffer
      e.command_buffer = utf8.runes_to_string(runes[:len(runes) - 1])
      if len(old_buffer) > 0 {
        delete(old_buffer)
      }
    }
    return
  }

  // For command mode, append any printable character to command buffer
  if ch >= 32 && ch <= 126 || ch == ' ' || ch == '\t' {
    old_buffer := e.command_buffer
    // Use aprintf which allocates on the heap, not temp allocator
    e.command_buffer = fmt.aprintf("%s%c", e.command_buffer, ch)
    if len(old_buffer) > 0 {
      delete(old_buffer)
    }
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
  } else if e.mode == .Command {
    // Fallback for command mode: buffer the character
    handle_command_input(e, ch)
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

  // insert mode - Enter key splits the current line
  imap["\r"] = proc(e: ^Editor) {
    buffer.split_line(editor_active_buffer(e))
  }

  // command mode - Enter key executes the buffered command
  cmap["\r"] = proc(e: ^Editor) {
    command_execute(&e.commands, e, e.command_buffer)
    set_mode(e, .Navigate)
  }
}

@(fini)
init_fini :: proc() {
  for kmap in keymaps {
    delete(kmap)
  }
}

set_mode :: proc(e: ^Editor, mode: Mode) {
  assert(e.mode != mode)

  // Save state when exiting insert mode (after changes were made)
  if e.mode == .Insert {
    buffer.save_state(editor_active_buffer(e))
  }

  // Clear cmd buffer when entering or leaving command mode
  if mode == .Command || e.mode == .Command {
    if len(e.command_buffer) > 0 {
      delete(e.command_buffer)
    }
    e.command_buffer = ""
  }

  e.mode = mode
  log.debug("mode:", mode)
}
