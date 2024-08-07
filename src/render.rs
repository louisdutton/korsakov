use crate::editor::{Editor, Mode};
use crossterm::{
    cursor::MoveTo,
    style::{Color, Print, PrintStyledContent, Stylize},
    terminal::{Clear, ClearType},
    QueueableCommand,
};
use std::io::{self, Write};

const BLACK: Color = Color::Rgb { r: 0, g: 0, b: 0 };

pub fn render(e: &mut Editor) -> io::Result<()> {
    let buffer = e.get_active_buffer_mut();
    if buffer.dirty {
        render_buffer(e)?;
    }
    render_status_bar(e)?;
    e.stdout.flush()
}

fn render_buffer(e: &mut Editor) -> io::Result<()> {
    let buffer = e.buffers.get_mut(e.active_buffer).unwrap();
    let content = buffer.content.as_str();
    let content_len = content.len() as u16;

    e.stdout
        .queue(MoveTo(content_len, 0))?
        .queue(Clear(ClearType::UntilNewLine))?
        .queue(MoveTo(0, 0))?;

    match &buffer.selection {
        Some(selection) => {
            e.stdout
                .queue(Print(content.get(..selection.start as usize).unwrap()))?
                .queue(PrintStyledContent(
                    selection
                        .apply(content)
                        .expect("selection within content bounds")
                        .on_dark_grey(),
                ))?
                .queue(Print(content.get((selection.end as usize)..).unwrap()))?;
        }
        _ => {
            e.stdout.queue(Print(content))?;
        }
    }

    Ok(())
}

fn render_status_bar(e: &mut Editor) -> io::Result<()> {
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

    e.stdout
        // mode
        .queue(MoveTo(0, e.size.1))?
        .queue(PrintStyledContent(text.with(fg).on(bg)))?
        // filename
        .queue(Print(" example.txt "))?
        // coordinates
        .queue(MoveTo(e.size.0 - coords.len() as u16, e.size.1))?
        .queue(PrintStyledContent(coords.with(fg).on(bg)))?;
    Ok(())
}
