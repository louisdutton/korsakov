use crate::keymap::*;
use crate::render::render_status_line;
use std::{fmt, io::{stdin, stdout, Stdout, Write, Result}, process::exit};
use termion::{
    clear, color, cursor, event::{Event, Key}, input::TermRead, raw::{IntoRawMode, RawTerminal}, screen::{AlternateScreen, IntoAlternateScreen}, terminal_size
};

pub enum Mode {
    NAVIGATE,
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
    stdout: AlternateScreen<RawTerminal<Stdout>>,
    text: String,
    cursor: Position,
    size: (u16, u16)
}

impl Editor {
    pub fn new() -> Result<Editor> {
        let mut stdout = stdout()
                .into_raw_mode()?
                .into_alternate_screen()?;

        write!(stdout, "{}{}{}", 
            clear::All,
            cursor::Goto(1, 1),
            cursor::SteadyBlock
        )?;
        stdout.flush()?;

        Ok(Editor {
            stdout,
            mode: Mode::NAVIGATE,
            text: String::new(),
            size: terminal_size().unwrap(),
            cursor: Position {
                row: 0,
                col: 0,
                offset: 0
            }
        })
    }

    #[inline]
    fn write<T: fmt::Display>(&mut self, data: T) {
        write!(self.stdout, "{}", data).unwrap()
    }

    fn write_char(&mut self, ch: char) {
        self.text.push(ch);
        self.write(ch);
    }

    /// Sets the input mode
    fn set_mode(&mut self, mode: Mode) {
        match mode {
            Mode::NAVIGATE => self.write(cursor::SteadyBlock),
            Mode::Insert => self.write(cursor::SteadyBar),
            Mode::Visual => self.write(cursor::SteadyBlock),
            Mode::Command => self.write(cursor::SteadyBar), 
        };
        self.mode = mode;
    }

    fn handle_insert_event(&mut self, event: Event) {
        match event {
            Event::Key(key) => match key {
                Key::Esc => self.set_mode(Mode::NAVIGATE),
                Key::Char(ch) => self.write_char(ch),
                Key::Backspace => self.write("\u{8} \u{8}"),
                _ => (),
            },
            _ => {}
        }
    }

    fn handle_normal_event(&mut self, event: Event) {
        match event {
            Event::Key(key) => match key {
                Key::Char(KEY_EXIT) => exit(0),
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
        }
    }

    fn handle_visual_event(&mut self, event: Event) {
        match event {
            Event::Key(key) => match key {
                Key::Esc | Key::Char(KEY_VISUAL) => self.set_mode(Mode::NAVIGATE),
                Key::Char(KEY_UP) => self.write(cursor::Up(1)),
                Key::Char(KEY_DOWN) => self.write(cursor::Down(1)),
                Key::Char(KEY_RIGHT) => self.write(cursor::Right(1)),
                Key::Char(KEY_LEFT) => {
                    self.write(format!("{} {}", color::Bg(color::Black), cursor::Left(1)));
                }
                _ => (),
            },
            _ => {}
        }
    }

    fn handle_command_event(&mut self, event: Event) {
        match event {
            Event::Key(key) => match key {
                Key::Esc => self.set_mode(Mode::NAVIGATE),
                _ => (),
            },
            _ => {}
        }
    }

    /// begin event loop, listen and handle events
    pub fn listen(&mut self) {
        let stdin = stdin();
        for result in stdin.events() {
            let event = result.unwrap();
            match self.mode {
                Mode::Insert => self.handle_insert_event(event),
                Mode::NAVIGATE => self.handle_normal_event(event),
                Mode::Visual => self.handle_visual_event(event),
                Mode::Command => self.handle_command_event(event)
            }

            // render
            render_status_line(&self.mode, self.size.1, &self.cursor);
            _ = self.stdout.flush();
        }
    }
}
