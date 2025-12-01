package korsakov

import "buffer"
import "core:log"
import "core:slice"
import "core:strings"

Command :: struct {
  name:    string,
  handler: proc(editor: ^Editor, args: []string),
}

CommandRegistry :: struct {
  commands: [dynamic]Command,
}

// Creates a new command registry with default commands
command_registry_new :: proc() -> CommandRegistry {
  registry := CommandRegistry {
    commands = make([dynamic]Command),
  }

  // Register default commands
  command_register(&registry, "w", command_write)
  command_register(&registry, "write", command_write)
  command_register(&registry, "q", command_quit)
  command_register(&registry, "quit", command_quit)
  command_register(&registry, "wq", command_write_quit)

  return registry
}

// Destroys a command registry
command_registry_destroy :: proc(registry: ^CommandRegistry) {
  for command in registry.commands {
    delete(command.name)
  }
  delete(registry.commands)
}

// Registers a command in the registry
command_register :: proc(
  registry: ^CommandRegistry,
  name: string,
  handler: proc(editor: ^Editor, args: []string),
) {
  command := Command {
    name    = strings.clone(name),
    handler = handler,
  }
  append(&registry.commands, command)
}

// Executes a command by name
command_execute :: proc(
  registry: ^CommandRegistry,
  editor: ^Editor,
  command_line: string,
) {
  if len(command_line) == 0 do return

  // Parse command and arguments
  parts := strings.split(command_line, " ")
  defer delete(parts)

  if len(parts) == 0 do return

  command_name := parts[0]
  args := parts[1:]

  // Find and execute command
  for command in registry.commands {
    if command.name == command_name {
      command.handler(editor, args)
      return
    }
  }

  // Command not found
  log.errorf("Unknown command: %s\n", command_name)
}

// Default command implementations

// Write command - saves the current buffer
command_write :: proc(e: ^Editor, args: []string) {
  b := editor_active_buffer(e)
  if b == nil do return
  if err := buffer.write(b); err != 0 {
    log.errorf("Error saving file: %v\n", err)
    return
  }

  log.info("File saved")
}

// Quit command - exits the editor
command_quit :: proc(e: ^Editor, args: []string) {
  for &b in e.buffers {
    if b.modified {
      log.error("No write since last change (add ! to override)")
      return
    }
  }
  e.running = false
}

// Write and quit command - saves then exits
command_write_quit :: proc(e: ^Editor, args: []string) {
  command_write(e, args)
  command_quit(e, args)
}
