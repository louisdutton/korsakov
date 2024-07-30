use crate::editor::{Editor, Mode};
use crossterm::{
    cursor::MoveTo,
    style::{Color, Print, ResetColor, SetBackgroundColor, SetForegroundColor},
    terminal::{Clear, ClearType},
    QueueableCommand,
};
use std::io::{self, Stdout, Write};

const BLACK: Color = Color::Rgb { r: 0, g: 0, b: 0 };

// TODO create renderable trait
pub fn render(e: &mut Editor) -> io::Result<()> {
    if e.dirty {
        render_buffer(e)?;
        e.dirty = false;
    };
    render_status_bar(e)?;
    e.stdout.flush()
}

fn render_buffer(e: &mut Editor) -> io::Result<&mut Stdout> {
    Ok(e.stdout
        .queue(Clear(ClearType::All))?
        .queue(MoveTo(0, 0))?
        .queue(Print(&e.buffers.get(e.active_buffer).unwrap().content))?)
}

fn render_status_bar(e: &mut Editor) -> io::Result<&mut Stdout> {
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

    let coords = format!(" {}:{} ", e.cursor.1, e.cursor.0);

    Ok(e.stdout
        // mode
        .queue(MoveTo(0, e.size.1))?
        .queue(SetBackgroundColor(bg))?
        .queue(SetForegroundColor(fg))?
        .queue(Print(text))?
        .queue(ResetColor)?
        // filename
        .queue(Print(" example.txt "))?
        // coordinates
        .queue(MoveTo(e.size.0 - coords.len() as u16, e.size.1))?
        .queue(SetBackgroundColor(bg))?
        .queue(SetForegroundColor(fg))?
        .queue(Print(coords))?
        .queue(ResetColor)?)
}
