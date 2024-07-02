use std::{collections::HashMap, io::{self, stdout, Result, Stdout, Write}};
use crossterm::{cursor::{MoveTo, SetCursorStyle}, event::{read, Event, KeyCode}, style::{Color, Print, ResetColor, SetBackgroundColor, SetForegroundColor}, terminal, ExecutableCommand, QueueableCommand};
use terminal::{Clear, ClearType, EnterAlternateScreen};
use crate::actions::{exec, Action};

#[derive(Debug, PartialEq, Copy, Clone)]
pub enum Mode {
    Navigate,
    Insert,
    Visual,
    Command,
}

pub struct Editor {
    mode: Mode,
    pub stdout: Stdout,
    pub text: String,
    pub cursor: (u16, u16),
    pub size: (u16, u16),
    nmap: HashMap<KeyCode, Action>,
    imap: HashMap<KeyCode, Action>
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
            text: String::new(),
            size: terminal::size()?,
            cursor: (0, 0),
            nmap: HashMap::from([
                (KeyCode::Char('k'), Action::MoveUp(1)),
                (KeyCode::Char('j'), Action::MoveDown(1)),
                (KeyCode::Char('h'), Action::MoveLeft(1)),
                (KeyCode::Char('l'), Action::MoveRight(1)),
                (KeyCode::Char('p'), Action::Paste),
                (KeyCode::Char('q'), Action::Quit),
                (KeyCode::Char('x'), Action::Delete),
                (KeyCode::Char('i'), Action::SetMode(Mode::Insert)),
            ]),
            imap: HashMap::from([
                (KeyCode::Esc, Action::SetMode(Mode::Navigate)),
            ])
        })
    }

    /// Sets the input mode
    pub fn set_mode(&mut self, mode: Mode) -> io::Result<()> {
        _ = match mode {
            Mode::Navigate => {
                self.stdout.queue(SetCursorStyle::SteadyBlock)?;
                if self.mode == Mode::Insert {
                    exec(self, Action::MoveLeft(1))?;
                }
            },
            Mode::Insert => {
                self.stdout.queue(SetCursorStyle::SteadyBar)?;
            },
            Mode::Visual => {
                self.stdout.queue(SetCursorStyle::SteadyBlock)?;
            },
            Mode::Command => {
                self.stdout.queue(SetCursorStyle::SteadyBar)?;
            }, 
        };
        self.mode = mode;
        Ok(())
    }


    /// Begins event loop, listen for and handle events
    pub fn start(&mut self) -> io::Result<()> {
        loop {
            self.stdout.execute(MoveTo(self.cursor.0, self.cursor.1))?;

            match read()? {
                Event::Resize(cols, rows) => self.size = (cols, rows),
                Event::Key(key) => {
                    let result = match self.mode {
                        Mode::Insert => match self.imap.get(&key.code) {
                            Some(action) => Some(*action),
                            None => match key.code {
                                KeyCode::Char(ch) => Some(Action::Input(ch)),
                                KeyCode::Backspace => Some(Action::Backspace),
                                _ => None
                            }
                        },
                        Mode::Navigate => match self.nmap.get(&key.code) {
                            Some(action) => Some(*action),
                            None => None
                        },
                        Mode::Visual => None,
                        Mode::Command => None,
                    };

                    if let Some(action) = result {
                        exec(self, action)?;
                    }
                },
                _ => {}
            }

            self.render()?;
        }
    }

    /// Renders all TUI elements.
    pub fn render(&mut self) -> Result<()> {
        let fg: Color;
        let bg: Color;
        let text: &str;

        match self.mode {
            Mode::Insert => {
                fg = Color::Black;
                bg = Color::Green;
                text = " INS "
            },
            Mode::Navigate => {
                fg = Color::Black;
                bg = Color::Blue;
                text = " NAV "
            },
            Mode::Visual => {
                fg = Color::Black;
                bg = Color::Magenta;
                text = " VIS "
            },
            Mode::Command => {
                fg = Color::Black;
                bg = Color::Yellow;
                text = " CMD "
            },
        }

        self.stdout
            // status bar
            .queue(MoveTo(0, self.size.1))?
            .queue(SetBackgroundColor(bg))?
            .queue(SetForegroundColor(fg))?
            .queue(Print(text))?
            .queue(ResetColor)?
            .queue(MoveTo(self.cursor.0, self.cursor.1))?

            // submit
            .flush()
    }
}
