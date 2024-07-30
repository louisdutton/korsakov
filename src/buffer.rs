#[derive(Debug)]
pub struct Buffer {
    pub name: String,
    pub content: String,
    pub dirty: bool,
}

impl Buffer {
    pub fn new(name: String, content: String) -> Self {
        Buffer {
            name,
            content,
            dirty: false,
        }
    }
}
