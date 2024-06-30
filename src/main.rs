mod editor;
mod keymap;

use editor::Editor;

fn main() {
    let mut editor = Editor::new();
    editor.reset();
    editor.listen();
}
