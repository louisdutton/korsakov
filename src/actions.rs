use crate::editor::{Editor, Mode};
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

    // visual
    DeleteSelection,
    YankSelection,

    // insert
    Input(char),
    Backspace,

    // generic
    SetMode(Mode),
    Chain(Vec<Action>),
    Quit,
}

pub fn exec(e: &mut Editor, action: Action) -> io::Result<()> {
    let buff = e.buffers.get_mut(e.active_buffer).unwrap();
    let len = buff.content.len();
    let line_end = match e.mode {
        Mode::Insert => e.size.0.min(len as u16) + 1,
        _ => e.size.0.min(len as u16),
    };

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
            e.cursor.0 = e.cursor.0.saturating_sub(n);
            let new_pos = e.cursor.0;
            if let Some(sel) = &mut e.get_active_buffer_mut().selection {
                sel.end = new_pos;
            }
        }
        Action::CursorRight(n) => {
            if e.cursor.0 < line_end.saturating_sub(n) {
                e.cursor.0 += n;
                let new_pos = e.cursor.0;
                if let Some(sel) = &mut e.get_active_buffer_mut().selection {
                    sel.end = new_pos;
                }
            }
        }
        Action::CursorLineStart => {
            e.cursor.0 = 0;
        }
        Action::CursorLineEnd => {
            e.cursor.0 = line_end.saturating_sub(1);
        }
        Action::CursorBufferStart => {
            e.cursor.1 = 0;
        }
        Action::CursorBufferEnd => {
            e.cursor.1 = e.size.1;
        }
        Action::SetMode(mode) => {
            e.set_mode(mode)?;
        }
        Action::Paste => {
            buff.dirty = true;
            buff.content.insert_str(e.cursor.0 as usize, "hello");
            exec(e, Action::CursorRight(len as u16))?;
        }
        Action::Quit => exit(1),
        Action::Input(ch) => {
            buff.dirty = true;
            buff.content.insert(e.cursor.0.into(), ch);
            exec(e, Action::CursorRight(1))?;
        }
        Action::Backspace => {
            if len > 0 && e.cursor.0 > 0 {
                buff.dirty = true;
                exec(e, Action::CursorLeft(1))?;
                exec(e, Action::Delete)?;
            }
        }
        Action::Delete => {
            if len > 0 {
                buff.dirty = true;
                buff.content.remove(e.cursor.0.into());
            }
        }
        Action::Chain(actions) => {
            for action in actions {
                exec(e, action)?;
            }
        }
        Action::DeleteSelection => {
            if let Some(selection) = &buff.selection {
                let start = selection.start.min(selection.end) as usize;
                let end = selection.start.max(selection.end) as usize;
                buff.dirty = true;
                buff.content.replace_range(start..end, &"");
            }
        }
        Action::YankSelection => todo!(),
    };
    Ok(())
}
