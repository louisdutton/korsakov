use crate::{
    actions::{exec, Action},
    buffer::Buffer,
    render::render,
};
use crossterm::{
    cursor::{MoveTo, SetCursorStyle},
    event::{read, Event, KeyCode},
    terminal, ExecutableCommand, QueueableCommand,
};
use std::{
    collections::HashMap,
    io::{self, stdout, Result, Stdout, Write},
};
use terminal::{Clear, ClearType, EnterAlternateScreen};

#[derive(Debug, PartialEq, Copy, Clone)]
pub enum Mode {
    Navigate,
    Insert,
    Visual,
    Command,
}

#[derive(Debug)]
pub struct Editor {
    pub mode: Mode,
    pub stdout: Stdout,
    pub buffers: Vec<Buffer>,
    pub active_buffer: usize,
    pub cursor: (u16, u16),
    pub size: (u16, u16),
    nmap: HashMap<KeyCode, Action>,
    imap: HashMap<KeyCode, Action>,
}

impl Editor {
    pub fn new() -> Result<Editor> {
        let mut stdout = stdout();
        terminal::enable_raw_mode()?;
        stdout
            .queue(EnterAlternateScreen)?
            .queue(Clear(ClearType::All))?
            .queue(SetCursorStyle::SteadyBlock)?
            .queue(MoveTo(0, 0))?
            .flush()?;

        Ok(Editor {
            stdout,
            mode: Mode::Navigate,
            active_buffer: 0,
            buffers: Vec::new(),
            size: terminal::size()?,
            cursor: (0, 0),
            nmap: HashMap::from([
                (KeyCode::Char('k'), Action::CursorUp(1)),
                (KeyCode::Char('j'), Action::CursorDown(1)),
                (KeyCode::Char('h'), Action::CursorLeft(1)),
                (KeyCode::Char('l'), Action::CursorRight(1)),
                (KeyCode::Char('H'), Action::CursorLineStart),
                (KeyCode::Char('L'), Action::CursorLineEnd),
                (KeyCode::Char('K'), Action::CursorBufferStart),
                (KeyCode::Char('J'), Action::CursorBufferEnd),
                (KeyCode::Char('p'), Action::Paste),
                (KeyCode::Char('q'), Action::Quit),
                (KeyCode::Char('x'), Action::Delete),
                (KeyCode::Char('i'), Action::SetMode(Mode::Insert)),
                (
                    KeyCode::Char('I'),
                    Action::Chain(vec![Action::SetMode(Mode::Insert), Action::CursorLineStart]),
                ),
                (
                    KeyCode::Char('a'),
                    Action::Chain(vec![Action::SetMode(Mode::Insert), Action::CursorRight(1)]),
                ),
                (
                    KeyCode::Char('A'),
                    Action::Chain(vec![Action::SetMode(Mode::Insert), Action::CursorLineEnd]),
                ),
            ]),
            imap: HashMap::from([(
                KeyCode::Esc,
                Action::Chain(vec![Action::SetMode(Mode::Navigate), Action::CursorLeft(1)]),
            )]),
        })
    }

    /// Sets the input mode
    pub fn set_mode(&mut self, mode: Mode) -> io::Result<()> {
        match mode {
            Mode::Navigate => self.stdout.queue(SetCursorStyle::SteadyBlock)?,
            Mode::Insert => self.stdout.queue(SetCursorStyle::SteadyBar)?,
            Mode::Visual => self.stdout.queue(SetCursorStyle::SteadyBlock)?,
            Mode::Command => self.stdout.queue(SetCursorStyle::SteadyBar)?,
        };
        self.mode = mode;
        Ok(())
    }

    /// Adds a new buffer to the editor session
    pub fn add_buffer(&mut self, buffer: Buffer) -> &mut Self {
        self.buffers.push(buffer);
        return self;
    }

    /// Sets the text content and dirties the buffer
    pub fn set_text(&mut self, index: usize, text: String) -> &mut Self {
        if let Some(buffer) = self.buffers.get_mut(index) {
            buffer.content = text;
            buffer.dirty = true;
            render(self).unwrap();
        }
        return self;
    }

    /// Begins event loop, listen for and handle events
    pub fn listen(&mut self) -> io::Result<()> {
        loop {
            self.stdout.execute(MoveTo(self.cursor.0, self.cursor.1))?;

            // TODO use poll to allow for async operations
            match read()? {
                Event::Resize(cols, rows) => self.size = (cols, rows),
                Event::Key(key) => {
                    let result =
                        match self.mode {
                            Mode::Insert => self.imap.get(&key.code).cloned().or_else(|| match key
                                .code
                            {
                                KeyCode::Char(ch) => Some(Action::Input(ch)),
                                KeyCode::Backspace => Some(Action::Backspace),
                                _ => None,
                            }),
                            Mode::Navigate => self.nmap.get(&key.code).cloned(),
                            Mode::Visual => None,
                            Mode::Command => None,
                        };

                    if let Some(action) = result {
                        exec(self, action)?;
                    }
                }
                _ => {}
            }

            render(self)?;
        }
    }
}
