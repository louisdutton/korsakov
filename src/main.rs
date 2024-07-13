mod actions;
mod editor;
mod render;

use std::{fs, io, path::Path};

use editor::Editor;

fn main() -> io::Result<()> {
    _ = Editor::new()?
        .set_text(fs::read_to_string(Path::new("./example.txt"))?)
        .listen()?;
    Ok(())
}
