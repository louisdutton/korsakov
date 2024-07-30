use std::io::{self, Stdout};

use crossterm::{
    cursor::MoveTo,
    style::Print,
    terminal::{Clear, ClearType},
    QueueableCommand,
};

use crate::render::Renderable;

#[derive(Debug)]
pub struct Buffer {
    pub name: String,
    pub content: String,
    pub dirty: bool,
}

impl Buffer {
    pub fn new(name: String, content: String) -> Self {
        Buffer {
            name,
            content,
            dirty: false,
        }
    }
}

impl Renderable for Buffer {
    fn render(&mut self, stdout: &mut Stdout) -> io::Result<()> {
        if !self.dirty {
            return Ok(());
        }
        stdout
            .queue(Clear(ClearType::All))?
            .queue(MoveTo(0, 0))?
            .queue(Print(&self.content))?;
        self.dirty = false;
        Ok(())
    }
}
