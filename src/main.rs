mod actions;
mod editor;
mod render;

use std::{fs, path::Path};

use editor::Editor;

fn main() {
    let text = fs::read_to_string(Path::new("./example.txt")).expect("Failed to read file");
    let mut editor = Editor::new().expect("Failed to initialise editor");
    editor.text = text;
    editor.start().expect("Failed to start editor event loop")
}
