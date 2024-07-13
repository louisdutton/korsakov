mod actions;
mod editor;
mod render;

use clap::{command, Parser};
use std::{fs, io, path::Path};

use editor::Editor;

#[derive(Parser)]
#[command(name = "korsakov")]
#[command(bin_name = "kors")]
#[command(version, about, long_about = None)]
/// Korsakov: A speedy little text editor for the terminal.
struct Args {
    /// The target file path
    file: String,
}

fn main() -> io::Result<()> {
    let args = Args::parse();
    let mut editor = Editor::new()?;

    if !args.file.is_empty() {
        if let Ok(text) = fs::read_to_string(Path::new(&args.file)) {
            editor.set_text(text);
        }
    }

    editor.listen()?;
    Ok(())
}
