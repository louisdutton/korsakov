use std::io::{stdin, stdout, Write};
use termion::{
    color::{Green, Red},
    event::{Event, Key},
    input::{MouseTerminal, TermRead},
    raw::IntoRawMode,
    screen::IntoAlternateScreen,
};

enum Mode {
    Normal,
    Insert,
    Visual,
    Command,
}

fn main() {
    let stdin = stdin();
    let mut stdout = MouseTerminal::from(
        stdout()
            .into_raw_mode()
            .unwrap()
            .into_alternate_screen()
            .unwrap(),
    );

    write!(
        stdout,
        "{}{}{}",
        termion::clear::All,
        termion::cursor::Goto(1, 1),
        termion::cursor::SteadyBlock
    )
    .unwrap();
    stdout.flush().unwrap();

    let mut mode = Mode::Normal;

    for result in stdin.events() {
        let evt = result.unwrap();
        match mode {
            Mode::Insert => match evt {
                Event::Key(key) => match key {
                    Key::Esc => {
                        mode = Mode::Normal;
                        write!(stdout, "{}", termion::cursor::SteadyBlock).unwrap();
                    }
                    Key::Char(c) => write!(stdout, "{}", c).unwrap(),
                    Key::Backspace => write!(stdout, "\u{8} \u{8}").unwrap(),
                    _ => (),
                },
                _ => {}
            },
            Mode::Normal => match evt {
                Event::Key(key) => match key {
                    Key::Char('q') => break,
                    Key::Char('i') => {
                        mode = Mode::Insert;
                        write!(stdout, "{}", termion::cursor::SteadyBar).unwrap();
                    }
                    Key::Char('v') => {
                        mode = Mode::Visual;
                        write!(stdout, "{}", termion::cursor::SteadyBlock).unwrap();
                    }
                    Key::Char('h') => write!(stdout, "{}", termion::cursor::Left(1)).unwrap(),
                    Key::Char('j') => write!(stdout, "{}", termion::cursor::Down(1)).unwrap(),
                    Key::Char('k') => write!(stdout, "{}", termion::cursor::Up(1)).unwrap(),
                    Key::Char('l') => write!(stdout, "{}", termion::cursor::Right(1)).unwrap(),
                    _ => (),
                },
                _ => {}
            },
            Mode::Visual => match evt {
                Event::Key(key) => match key {
                    Key::Esc => {
                        mode = Mode::Normal;
                        write!(stdout, "{}", termion::cursor::SteadyBlock).unwrap();
                    }
                    Key::Char('h') => {
                        write!(
                            stdout,
                            "{}{} {}",
                            termion::cursor::Left(1),
                            termion::color::Bg(Red),
                            termion::cursor::Left(1),
                        )
                        .unwrap();
                    }
                    Key::Char('j') => write!(stdout, "{}", termion::cursor::Down(1)).unwrap(),
                    Key::Char('k') => write!(stdout, "{}", termion::cursor::Up(1)).unwrap(),
                    Key::Char('l') => write!(stdout, "{}", termion::cursor::Right(1)).unwrap(),
                    _ => (),
                },
                _ => {}
            },
            _ => {}
        }
        stdout.flush().unwrap();
    }
}
