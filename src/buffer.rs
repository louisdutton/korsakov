#[derive(Debug)]
pub struct Selection {
    pub start: u16,
    pub end: u16,
}

#[derive(Debug)]
pub struct Buffer {
    pub name: String,
    pub content: String,
    pub dirty: bool,
    pub selection: Option<Selection>,
}

impl Buffer {
    pub fn new(name: String, content: String) -> Self {
        Buffer {
            name,
            content,
            selection: None,
            dirty: false,
        }
    }
}
