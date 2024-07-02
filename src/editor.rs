use crate::keymap::*;
use std::{io::{self, stdout, Result, Stdout, Write}, process::exit};
use crossterm::{cursor::{MoveDown, MoveLeft, MoveRight, MoveTo, MoveToRow, MoveUp, SetCursorStyle}, event::{read, Event, KeyCode}, style::{Color, Print, SetBackgroundColor}, terminal, QueueableCommand};
use terminal::{Clear, ClearType, EnterAlternateScreen};

pub enum Mode {
    Navigate,
    Insert,
    Visual,
    Command,
}

pub struct Position {
    /// The number of rows from the top of the buffer
    pub row: u16,
    /// The number of columns from the left of the buffer
    pub col: u16,
    /// The character offset from the beginning of the buffer
    pub offset: u16
}

pub struct Editor {
    mode: Mode,
    stdout: Stdout,
    text: String,
    cursor: Position,
    size: (u16, u16)
}

impl Editor {
    pub fn new() -> Result<Editor> {
        let mut stdout = stdout();

        terminal::enable_raw_mode()?;

        stdout
            .queue(EnterAlternateScreen)?
            .queue(Clear(ClearType::All))?
            .queue(SetCursorStyle::SteadyBlock)?
            .flush()?;

        Ok(Editor {
            stdout,
            mode: Mode::Navigate,
            text: String::new(),
            size: terminal::size()?,
            cursor: Position {
                row: 0,
                col: 0,
                offset: 0
            }
        })
    }

    /// Sets the input mode
    fn set_mode(&mut self, mode: Mode) {
        _ = match mode {
            Mode::Navigate => self.stdout.queue(SetCursorStyle::SteadyBlock),
            Mode::Insert => self.stdout.queue(SetCursorStyle::SteadyBar),
            Mode::Visual => self.stdout.queue(SetCursorStyle::SteadyBlock),
            Mode::Command => self.stdout.queue(SetCursorStyle::SteadyBar), 
        };
        self.mode = mode;
    }

    fn handle_insert_event(&mut self, event: Event) -> Result<()> {
        _ = match event {
            Event::Key(key) => match key.code {
                KeyCode::Esc => self.set_mode(Mode::Navigate),
                KeyCode::Char(ch) => {
                    self.stdout.queue(Print(ch))?;
                },
                KeyCode::Backspace => {
                    self.stdout
                        .queue(MoveLeft(1))?
                        .queue(Print(' '))?
                        .queue(MoveLeft(1))?;
                },
                _ => (),
            },
            _ => {}
        };
        Ok(())
    }

    fn handle_navigation_event(&mut self, event: Event) -> Result<()> {
        match event {
            Event::Key(key) => match key.code {
                KeyCode::Char(KEY_EXIT) => exit(0),
                KeyCode::Char(KEY_INSERT) => self.set_mode(Mode::Insert),
                KeyCode::Char(KEY_VISUAL) => self.set_mode(Mode::Visual),
                KeyCode::Char(KEY_COMMAND) => self.set_mode(Mode::Command),

                KeyCode::Char(KEY_APPEND) => {
                    self.set_mode(Mode::Insert);
                    self.stdout.queue(MoveRight(1))?;
                }
                KeyCode::Char(KEY_UP) => {
                    self.stdout.queue(MoveUp(1))?;
                },
                KeyCode::Char(KEY_DOWN) => {
                    self.stdout.queue(MoveDown(1))?;
                },
                KeyCode::Char(KEY_LEFT) => {
                    self.stdout.queue(MoveLeft(1))?;
                },
                KeyCode::Char(KEY_RIGHT) => {
                    self.stdout.queue(MoveRight(1))?;
                },
                KeyCode::Char('p') => {
                    self.stdout.queue(Print(self.text.as_str()))?;
                },
                _ => (),
            },
            _ => {}
        }
        Ok(())
    }

    fn handle_visual_event(&mut self, event: Event) -> io::Result<()> {
        match event {
            Event::Key(key) => match key.code {
                KeyCode::Esc | KeyCode::Char(KEY_VISUAL) => {
                    self.set_mode(Mode::Navigate);
                },
                KeyCode::Char(KEY_UP) => {
                    self.stdout.queue(MoveUp(1));
                },
                KeyCode::Char(KEY_DOWN) => {
                    self.stdout.queue(MoveDown(1));
                },
                KeyCode::Char(KEY_RIGHT) => {
                    self.stdout.queue(MoveRight(1));
                },
                KeyCode::Char(KEY_LEFT) => {
                    self.stdout.queue(MoveLeft(1));
                }
                _ => (),
            },
            _ => {}
        }
        Ok(())
    }

    fn handle_command_event(&mut self, event: Event) -> io::Result<()> {
        match event {
            Event::Key(key) => match key.code {
                KeyCode::Esc => self.set_mode(Mode::Navigate),
                _ => (),
            },
            _ => {}
        }
        Ok(())
    }

    /// begin event loop, listen and handle events
    pub fn listen(&mut self) -> io::Result<()> {
        loop {
            let event = read()?;

            _ = match self.mode {
                Mode::Insert => self.handle_insert_event(event),
                Mode::Navigate => self.handle_navigation_event(event),
                Mode::Visual => self.handle_visual_event(event),
                Mode::Command => self.handle_command_event(event)
            };

            self.stdout
                // status bar
                //.queue(MoveToRow(self.size.1))?
                //.queue(SetBackgroundColor(Color::Green))?
                //.queue(Print(match self.mode {
                //    Mode::Navigate=> "NAV",
                //    Mode::Insert => "INS",
                //    Mode::Visual => "VIS",
                //    Mode::Command => "COM"
                //}))?
                //.queue(MoveTo(self.cursor.col, self.cursor.row))?

                // submit
                .flush()?;
        }
    }
}
