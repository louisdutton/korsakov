use std::{io, process::exit};
use crossterm::{cursor::MoveLeft, style::Print, QueueableCommand};
use crate::editor::{Editor, Mode};

#[derive(Debug, PartialEq, Copy, Clone)]
pub enum Action {
    // navigate
    MoveUp(u16),
    MoveDown(u16),
    MoveLeft(u16),
    MoveRight(u16),
    Paste,
    Delete,

    // insert
    Input(char),
    Backspace,

    // generic
    SetMode(Mode),
    Quit
}

pub fn exec(e: &mut Editor, action: Action) -> io::Result<()> {
    _ = match action {
        Action::MoveUp(n) => {
            if e.cursor.1 > n-1 {
                e.cursor.1 -= n;
            }
        },
        Action::MoveDown(n) => {
            if e.cursor.1 < e.size.1 - n {
                e.cursor.1 += n;
            }
        },
        Action::MoveLeft(n) => {
            if e.cursor.0 > n-1 {
                e.cursor.0 -= n;
            }
        },
        Action::MoveRight(n) => {
            if e.cursor.0 < e.size.0 - n  {
                e.cursor.0 += n;
            }
        },
        Action::SetMode(mode) => {
            e.set_mode(mode)?
        },
        Action::Paste => {
            e.stdout.queue(Print(e.text.as_str()))?;
            exec(e, Action::MoveRight(e.text.len() as u16))?;
        },
        Action::Quit => {
            exit(1)
        }, 
        Action::Input(ch) => {
            e.text.push(ch);
            e.stdout.queue(Print(ch))?;
            exec(e, Action::MoveRight(1))?;
                
        },
        Action::Backspace => {
            e.stdout
                .queue(MoveLeft(1))?
                .queue(Print(' '))?;
            exec(e, Action::MoveLeft(1))?;
        },
        Action::Delete => {
            e.stdout.queue(Print(' '))?;
        }
    };
    Ok(())
}
