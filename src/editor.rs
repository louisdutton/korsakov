use std::{collections::HashMap, io::{self, stdout, Result, Stdout, Write}, process::exit};
use crossterm::{cursor::{MoveLeft, MoveTo, MoveToRow, SetCursorStyle}, event::{read, Event, KeyCode}, style::{Color, Print, ResetColor, SetBackgroundColor, SetForegroundColor}, terminal, ExecutableCommand, QueueableCommand};
use terminal::{Clear, ClearType, EnterAlternateScreen};


#[derive(Debug, PartialEq, Copy, Clone)]
enum Action {
    MoveUp,
    MoveDown,
    MoveLeft,
    MoveRight,

    Paste,

    SetMode(Mode),
    Quit
}

#[derive(Debug, PartialEq, Copy, Clone)]
pub enum Mode {
    Navigate,
    Insert,
    Visual,
    Command,
}

#[derive(Debug)]
pub struct Vec2 {
    pub x: u16,
    pub y: u16,
}

impl Vec2 {
    fn new(x: u16, y: u16) -> Vec2 {
        Vec2 { x, y }
    }
}

pub struct Editor {
    mode: Mode,
    stdout: Stdout,
    text: String,
    cursor: Vec2,
    size: (u16, u16),
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
            .flush()?;

        Ok(Editor {
            stdout,
            mode: Mode::Navigate,
            text: String::new(),
            size: terminal::size()?,
            cursor: Vec2::new(0, 0),
            nmap: HashMap::from([
                (KeyCode::Char('k'), Action::MoveUp),
                (KeyCode::Char('j'), Action::MoveDown),
                (KeyCode::Char('h'), Action::MoveLeft),
                (KeyCode::Char('l'), Action::MoveRight),
                (KeyCode::Char('p'), Action::Paste),
                (KeyCode::Char('q'), Action::Quit),
                (KeyCode::Char('i'), Action::SetMode(Mode::Insert)),
            ]),
            imap: HashMap::from([
                (KeyCode::Esc, Action::SetMode(Mode::Navigate)),
            ])
        })
    }

    /// Sets the input mode
    fn set_mode(&mut self, mode: Mode) -> io::Result<()> {
        _ = match mode {
            Mode::Navigate => {
                self.stdout.queue(SetCursorStyle::SteadyBlock)?;
                if mode == Mode::Insert {
                   self.stdout.queue(MoveLeft(1))?;
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

    fn handle_action(&mut self, action: Action) -> io::Result<()> {
        _ = match action {
            Action::MoveUp => {
                if self.cursor.y > 0 {
                    self.cursor.y -= 1;
                }
            },
            Action::MoveDown => {
                if self.cursor.y < self.size.1 - 1 {
                    self.cursor.y += 1;
                }
            },
            Action::MoveLeft => {
                if self.cursor.x > 0 {
                    self.cursor.x -= 1;
                }
            },
            Action::MoveRight => {
                if self.cursor.x < self.size.0 - 1  {
                    self.cursor.x += 1;
                }
            },
            Action::SetMode(mode) => {
                self.set_mode(mode)?
            },
            Action::Paste => {
                self.stdout.queue(Print(self.text.as_str()))?;
            },
            Action::Quit => {
                exit(1)
            }
        };
        Ok(())
    }

    fn handle_insert_event(&mut self, event: Event) -> Result<()> {
        _ = match event {
            Event::Key(key) => match key.code {
                KeyCode::Esc => {
                    _ = self.set_mode(Mode::Navigate);
                    self.stdout.queue(MoveLeft(1))?;
                },
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

    /// begin event loop, listen and handle events
    pub fn listen(&mut self) -> io::Result<()> {
        loop {
            self.stdout.execute(MoveTo(self.cursor.x, self.cursor.y))?;

            let event = read()?;

            match event {
                Event::Resize(cols, rows) => self.size = (cols, rows),
                Event::Key(key) => {
                    match match self.mode {
                        Mode::Insert => self.imap.get(&key.code),
                        Mode::Navigate => self.nmap.get(&key.code),
                        Mode::Visual => None,
                        Mode::Command => None,
                    } {
                        Some(action) => self.handle_action(*action).unwrap(),
                        None => {}
                    }
                },
                _ => {}
            }

            self.stdout
                // status bar
                .queue(MoveTo(0, self.size.1))?
                .queue(SetBackgroundColor(Color::Green))?
                .queue(SetForegroundColor(Color::Black))?
                .queue(Print(match self.mode {
                    Mode::Navigate => " NAV ",
                    Mode::Insert => " INS ",
                    Mode::Visual => " VIS ",
                    Mode::Command => " COM "
                }))?
                .queue(ResetColor)?
                .queue(MoveTo(self.cursor.x, self.cursor.y))?

                // submit
                .flush()?;
        }
    }
}
