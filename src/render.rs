use crate::editor::{Editor, Mode};
use crossterm::{
    cursor::MoveTo,
    style::{Color, Print, ResetColor, SetBackgroundColor, SetForegroundColor},
    terminal::{Clear, ClearType},
    QueueableCommand,
};
use std::io::{self, Write};

const BLACK: Color = Color::Rgb { r: 0, g: 0, b: 0 };

/// Renders all TUI elements.
pub fn render(e: &mut Editor) -> io::Result<()> {
    let fg: Color;
    let bg: Color;
    let text: &str;

    match e.mode {
        Mode::Insert => {
            fg = BLACK;
            bg = Color::Green;
            text = " INS "
        }
        Mode::Navigate => {
            fg = BLACK;
            bg = Color::Blue;
            text = " NAV "
        }
        Mode::Visual => {
            fg = BLACK;
            bg = Color::Magenta;
            text = " VIS "
        }
        Mode::Command => {
            fg = BLACK;
            bg = Color::Yellow;
            text = " CMD "
        }
    }

    if e.dirty {
        e.stdout
            // buffer
            .queue(Clear(ClearType::All))?
            .queue(MoveTo(0, 0))?
            .queue(Print(&e.text))?;

        e.dirty = false;
    }

    e.stdout
        // status bar
        .queue(MoveTo(0, e.size.1))?
        .queue(SetBackgroundColor(bg))?
        .queue(SetForegroundColor(fg))?
        .queue(Print(text))?
        .queue(ResetColor)?
        .queue(MoveTo(e.cursor.0, e.cursor.1))?
        // submit
        .flush()
}
