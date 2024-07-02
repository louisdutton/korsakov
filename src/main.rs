mod editor;
mod keymap;
mod actions;

use editor::Editor;

fn main() {
    let mut editor = Editor::new().unwrap();
    _ = editor.start();
}
