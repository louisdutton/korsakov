package main

import "src"
import "core:fmt"

main :: proc() {
    fmt.println("Testing basic Korsakov functionality...")
    
    // Test creating an editor
    editor := src.editor_new_headless() or_return
    defer src.editor_destroy(&editor)
    
    // Test creating a buffer
    buffer := src.buffer_new()
    src.editor_add_buffer(&editor, buffer)
    
    fmt.println("Basic test completed successfully!")
}