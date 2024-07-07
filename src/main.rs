mod actions;
mod editor;
mod keymap;
mod render;

use editor::Editor;

fn main() {
    let mut editor = Editor::new().unwrap();
    _ = editor.start();
}
