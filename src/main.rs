mod editor;
mod keymap;

use editor::Editor;

fn main() {
    let mut editor = Editor::new().unwrap();
    _ = editor.listen();
}
