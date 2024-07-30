mod actions;
mod buffer;
mod editor;
mod render;

use buffer::Buffer;
use clap::{command, Parser};
use std::{
    fs,
    io::{self},
    path::Path,
};

use editor::Editor;

#[derive(Parser)]
#[command(name = "korsakov")]
#[command(bin_name = "kors")]
#[command(version, about, long_about = None)]
/// Korsakov: A speedy little text editor for the terminal.
struct Args {
    /// The target filename
    filename: Option<String>,
}

fn main() -> io::Result<()> {
    let args = Args::parse();
    let mut buffer = Buffer::new(String::new(), String::new());

    if let Some(file) = args.filename {
        buffer.name = file.clone();
        if let Ok(text) = fs::read_to_string(Path::new(&file)) {
            buffer.content = text;
        }
    }

    Editor::new()?.add_buffer(buffer).listen()
}
