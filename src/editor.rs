use crate::keymap::*;
use std::{fmt::{self}, io::{stdin, stdout, Stdout, Write}};
use termion::{
    clear, color, cursor, event::{Event, Key}, input::TermRead, raw::{IntoRawMode, RawTerminal}, screen::{AlternateScreen, IntoAlternateScreen}, terminal_size
};

enum Mode {
    Normal,
    Insert,
    Visual,
    Command,
}

struct Range {
    from: usize,
    to: usize,
    content: String
}

struct Position {
    /// The number of rows from the top of the buffer
    row: u32,
    /// The number of columns from the left of the buffer
    col: u32,
    /// The character offset from the beginning of the buffer
    offset: u32
}

struct Line {
    content: String
}

pub struct Editor {
    mode: Mode,
    stdout: AlternateScreen<RawTerminal<Stdout>>,
    text: String,
    line: String,
    selection: String,
    cursor: Position,
    size: (u16, u16)
}

impl Editor {
    pub fn new() -> Editor {
        Editor {
            mode: Mode::Normal,
            text: String::default(),
            selection: String::default(),
            line: String::default(),
            size: terminal_size().unwrap(),
            cursor: Position {
                row: 0,
                col: 0,
                offset: 0
            },
            stdout: stdout()
                .into_raw_mode()
                .unwrap()
                .into_alternate_screen()
                .unwrap()
        }
    }

    pub fn reset(&mut self) {
        self.write(format!(
            "{}{}{}",
            clear::All,
            cursor::Goto(1, 1),
            cursor::SteadyBlock)
        );
        self.stdout.flush().unwrap();
    }

    pub fn debug<T: fmt::Display>(&mut self, data: T) {
        write!(self.stdout, "{}", data).unwrap()
    }

    #[inline]
    fn write<T: fmt::Display>(&mut self, data: T) {
        write!(self.stdout, "{}", data).unwrap()
    }

    fn write_char(&mut self, ch: char) {
        self.text.push(ch);
        self.write(ch);
    }

    fn write_str(&mut self, str: &str) {
        self.text.push_str(str);
        self.write(str);
    }

    /// Sets the input mode
    fn set_mode(&mut self, mode: Mode) {
        match mode {
            Mode::Normal => self.write(cursor::SteadyBlock),
            Mode::Insert => self.write(cursor::SteadyBar),
            Mode::Visual => self.write(cursor::SteadyBlock),
            Mode::Command => self.write(cursor::SteadyBar), 
        };
        self.mode = mode;
    }

    pub fn listen(&mut self) {
        let stdin = stdin();
        for result in stdin.events() {
            let event = result.unwrap();
            match self.mode {
                Mode::Insert => match event {
                    Event::Key(key) => match key {
                        Key::Esc => self.set_mode(Mode::Normal),
                        Key::Char(ch) => self.write_char(ch),
                        Key::Backspace => self.write("\u{8} \u{8}"),
                        _ => (),
                    },
                    _ => {}
                },

                Mode::Normal => match event {
                    Event::Key(key) => match key {
                        Key::Char(KEY_EXIT) => break,
                        Key::Char(KEY_INSERT) => self.set_mode(Mode::Insert),
                        Key::Char(KEY_APPEND) => {
                            self.set_mode(Mode::Insert);
                            self.write(cursor::Right(1));
                        }
                        Key::Char(KEY_VISUAL) => self.set_mode(Mode::Visual),
                        Key::Char(KEY_COMMAND) => self.set_mode(Mode::Command),

                        Key::Char(KEY_UP) => self.write(cursor::Up(1)),
                        Key::Char(KEY_DOWN) => self.write(cursor::Down(1)),
                        Key::Char(KEY_LEFT) => self.write(cursor::Left(1)),
                        Key::Char(KEY_RIGHT) => self.write(cursor::Right(1)),

                        Key::Char('p') => {
                            let str = self.text.clone();
                            self.text.push_str(str.as_str());
                            self.write(str);
                        },
                        _ => (),
                    },
                    _ => {}
                },

                Mode::Visual => match event {
                    Event::Key(key) => match key {
                        Key::Esc | Key::Char(KEY_VISUAL) => self.set_mode(Mode::Normal),
                        Key::Char(KEY_UP) => self.write(cursor::Up(1)),
                        Key::Char(KEY_DOWN) => self.write(cursor::Down(1)),
                        Key::Char(KEY_RIGHT) => self.write(cursor::Right(1)),
                        Key::Char(KEY_LEFT) => {
                            self.write(format!("{} {}", color::Bg(color::Black), cursor::Left(1)));
                        }
                        _ => (),
                    },
                    _ => {}
                },

                Mode::Command => match event {
                    Event::Key(key) => match key {
                        Key::Esc => self.set_mode(Mode::Normal),
                        //Key::Char(c) => self.write(c),
                        //Key::Backspace => self.write("\u{8} \u{8}"),
                        _ => (),
                    },
                    _ => {}
                },
            }
            self.stdout.flush().unwrap();
        }
    }
}
