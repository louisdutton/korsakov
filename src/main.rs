mod actions;
mod editor;
mod render;

use std::{fs, io, path::Path};

use editor::Editor;

fn main() -> io::Result<()> {
    let text = fs::read_to_string(Path::new("./example.txt")).expect("Failed to read file");
    _ = Editor::new()?.set_text(text).listen()?;
    Ok(())
}
