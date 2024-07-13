use crate::editor::{Editor, Mode};
use crossterm::{cursor::MoveLeft, style::Print, QueueableCommand};
use std::{io, process::exit};

#[derive(Debug, PartialEq, Clone)]
pub enum Action {
    // navigate
    CursorUp(u16),
    CursorDown(u16),
    CursorLeft(u16),
    CursorRight(u16),
    CursorLineStart,
    CursorLineEnd,
    CursorBufferStart,
    CursorBufferEnd,
    Paste,
    Delete,

    // insert
    Input(char),
    Backspace,

    // generic
    SetMode(Mode),
    Chain(Vec<Action>),
    Quit,
}

pub fn exec(e: &mut Editor, action: Action) -> io::Result<()> {
    _ = match action {
        Action::CursorUp(n) => {
            if e.cursor.1 > n - 1 {
                e.cursor.1 -= n;
            }
        }
        Action::CursorDown(n) => {
            if e.cursor.1 < e.size.1 - n {
                e.cursor.1 += n;
            }
        }
        Action::CursorLeft(n) => {
            if e.cursor.0 > n - 1 {
                e.cursor.0 -= n;
            }
        }
        Action::CursorLineStart => {
            e.cursor.0 = 0;
        }
        Action::CursorLineEnd => {
            e.cursor.0 = e.size.0;
        }
        Action::CursorBufferStart => {
            e.cursor.1 = 0;
        }
        Action::CursorBufferEnd => {
            e.cursor.1 = e.size.1;
        }
        Action::CursorRight(n) => {
            if e.cursor.0 < e.size.0 - n {
                e.cursor.0 += n;
            }
        }
        Action::SetMode(mode) => e.set_mode(mode)?,
        Action::Paste => {
            e.stdout.queue(Print(e.text.as_str()))?;
            exec(e, Action::CursorRight(e.text.len() as u16))?;
            e.dirty = true;
        }
        Action::Quit => exit(1),
        Action::Input(ch) => {
            e.text.insert(e.cursor.0.into(), ch);
            exec(e, Action::CursorRight(1))?;
            e.dirty = true;
        }
        Action::Backspace => {
            if e.text.len() > 0 && e.cursor.0 > 0 {
                e.stdout.queue(MoveLeft(1))?.queue(Print(' '))?;
                exec(e, Action::CursorLeft(1))?;
                exec(e, Action::Delete)?;
                e.dirty = true;
            }
        }
        Action::Delete => {
            if e.text.len() > 0 {
                e.text.remove(e.cursor.0.into());
                e.dirty = true;
            }
        }
        Action::Chain(actions) => {
            for action in actions {
                exec(e, action)?;
            }
        }
    };
    Ok(())
}
