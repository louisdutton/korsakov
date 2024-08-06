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

impl Selection {
    /// Returns a substring of the provided content based on the current bounds of the selection.
    pub fn apply<'a>(&self, content: &'a str) -> Option<&'a str> {
        content.get((self.start as usize)..(self.end as usize))
    }
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
