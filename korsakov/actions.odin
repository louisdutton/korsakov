package korsakov

import "core:fmt"

Action :: enum {
	// Movement actions
	MoveLeft,
	MoveRight,
	MoveUp,
	MoveDown,

	// Mode changes
	EnterInsertMode,
	EnterVisualMode,
	EnterCommandMode,
	ExitToNavigateMode,

	// Text editing
	InsertChar,
	DeleteChar,
	InsertNewLine,

	// File operations
	SaveFile,
	QuitEditor,
}

ActionData :: struct {
	action:    Action,
	char_data: rune, // For InsertChar action
}

/// Executes an action on the editor
execute_action :: proc(editor: ^Editor, action_data: ActionData) {
	switch action_data.action {
	case .MoveLeft:
		if buffer := editor_active_buffer(editor); buffer != nil {
			buffer.cursor.x = max(0, buffer.cursor.x - 1)
		}

	case .MoveRight:
		if buffer := editor_active_buffer(editor); buffer != nil {
			line := buffer_get_line(buffer, buffer.cursor.y)
			buffer.cursor.x = min(len(line), buffer.cursor.x + 1)
		}

	case .MoveUp:
		if buffer := editor_active_buffer(editor); buffer != nil {
			buffer.cursor.y = max(0, buffer.cursor.y - 1)
			// Clamp x to line length
			line := buffer_get_line(buffer, buffer.cursor.y)
			buffer.cursor.x = min(buffer.cursor.x, len(line))
		}

	case .MoveDown:
		if buffer := editor_active_buffer(editor); buffer != nil {
			buffer.cursor.y = min(buffer_line_count(buffer) - 1, buffer.cursor.y + 1)
			// Clamp x to line length
			line := buffer_get_line(buffer, buffer.cursor.y)
			buffer.cursor.x = min(buffer.cursor.x, len(line))
		}

	case .EnterInsertMode:
		editor.mode = .Insert

	case .EnterVisualMode:
		editor.mode = .Visual

	case .EnterCommandMode:
		editor.mode = .Command

	case .ExitToNavigateMode:
		editor.mode = .Navigate

	case .InsertChar:
		if editor.mode == .Insert {
			if buffer := editor_active_buffer(editor); buffer != nil {
				buffer_insert_char(buffer, action_data.char_data)
			}
		}

	case .DeleteChar:
		if buffer := editor_active_buffer(editor); buffer != nil {
			buffer_delete_char(buffer)
		}

	case .InsertNewLine:
		if editor.mode == .Insert {
			if buffer := editor_active_buffer(editor); buffer != nil {
				// TODO: Implement newline insertion
				fmt.println("TODO: Insert newline")
			}
		}

	case .SaveFile:
		if buffer := editor_active_buffer(editor); buffer != nil {
			if err := buffer_save(buffer); err != 0 {
				fmt.printf("Error saving file: %v\n", err)
			}
		}

	case .QuitEditor:
		editor.running = false
	}
}
