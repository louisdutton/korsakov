package terminal

import "core:terminal/ansi"
import "core:fmt"
import "core:os"

// Terminal control sequences and functionality
// This is a basic implementation - would need to be expanded for full crossterm compatibility

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

CursorStyle :: enum {
	Block,
	Line,
	Underline,
}

/// Enters alternate screen mode
enter_alternate_screen :: proc() {
	fmt.print(ansi.CSI "\x1b[?1049h")
}

/// Leaves alternate screen mode  
leave_alternate_screen :: proc() {
	fmt.print("\x1b[?1049l")
}

/// Clears the terminal screen
clear_screen :: proc() {
	fmt.print("\x1b[2J")
}

/// Moves cursor to specific position (1-based)
move_cursor :: proc(x, y: int) {
	fmt.printf("\x1b[%d;%dH", y, x)
}

/// Sets cursor style
set_cursor_style :: proc(style: CursorStyle) {
	switch style {
	case .Block:
		fmt.print("\x1b[2 q")
	case .Line:
		fmt.print("\x1b[6 q")
	case .Underline:
		fmt.print("\x1b[4 q")
	}
}

/// Enables line wrap
enable_line_wrap :: proc() {
	fmt.print("\x1b[?7h")
}

/// Disables line wrap
disable_line_wrap :: proc() {
	fmt.print("\x1b[?7l")
}

/// Polls for terminal events (simplified - would need proper implementation)
poll_event :: proc() -> (Event, bool) {
	// TODO: Implement proper terminal event polling
	// This is a placeholder that would need platform-specific implementation
	return Event{}, false
}

/// Reads a terminal event (simplified)
read_event :: proc() -> (Event, os.Errno) {
	// TODO: Implement proper terminal event reading
	// This is a placeholder that would need platform-specific implementation
	return Event{}, os.ERROR_NONE
}

/// Gets terminal size
get_terminal_size :: proc() -> (int, int) {
	// TODO: Implement proper terminal size detection
	// For now, return default size
	return 80, 24
}
