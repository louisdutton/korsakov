package korsakov

import "buffer"
import "core:fmt"

// Action :: enum {
//   // Movement actions
//   MoveLeft,
//   MoveRight,
//   MoveUp,
//   MoveDown,
//
//   // Mode changes
//   EnterInsertMode,
//   EnterVisualMode,
//   EnterCommandMode,
//   ExitToNavigateMode,
//
//   // Text editing
//   InsertChar,
//   DeleteChar,
//   InsertNewLine,
//
//   // File operations
//   SaveFile,
//   QuitEditor,
// }
//
// ActionData :: struct {
//   action:    Action,
//   char_data: rune, // For InsertChar action
// }
//
// // Executes an action on the editor
// execute_action :: proc(e: ^Editor, action_data: ActionData) {
//   b := editor_active_buffer(e)
//
//   switch action_data.action {
//   case .MoveLeft: b.cursor.x = max(0, b.cursor.x - 1)
//
//   case .MoveRight:
//     buffer.cursor_right(b)
//
//   case .MoveUp:
//     buffer.cursor_up(b)
//
//   case .MoveDown:
//     buffer.cursor_down(b)
//
//   case .EnterInsertMode: e.mode = .Insert
//
//   case .EnterVisualMode: e.mode = .Visual
//
//   case .EnterCommandMode: e.mode = .Command
//
//   case .ExitToNavigateMode: e.mode = .Navigate
//
//   case .InsertChar:
//     if e.mode == .Insert {
//       buffer.insert_char(b, action_data.char_data)
//     }
//
//   case .DeleteChar:
//     buffer.delete_char(b)
//
//   case .InsertNewLine:
//     if e.mode == .Insert {
//       // TODO: Implement newline insertion
//       fmt.println("TODO: Insert newline")
//     }
//
//   case .SaveFile:
//     if err := buffer.write(b); err != 0 {
//       fmt.printf("Error saving file: %v\n", err)
//     }
//
//   case .QuitEditor: e.running = false
//   }
// }
