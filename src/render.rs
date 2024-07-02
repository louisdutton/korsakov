use termion::{color, cursor};

use crate::editor::{Mode, Position};

/// Returns the status line as a string
pub fn render_status_line(mode: &Mode, col: u16, cursor: &Position) -> String {
    format!(
        "{}{}{}{}",
        cursor::Goto(0, col),
        color::Bg(color::Green),
        match mode {
            Mode::NAVIGATE=> "NAV",
            Mode::Insert => "INS",
            Mode::Visual => "VIS",
            Mode::Command => "COM"
        },
        cursor::Goto(cursor.row, cursor.col)
    )
}
