package korsakov

import "buffer"
import "core:container/intrusive/list"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "cst"
import ts "cst/treesitter"
import "tty"

main :: proc() {
  logger := create_logger()
  context.logger = logger
  defer destroy_logger()

  when ODIN_DEBUG {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)
    context.allocator = mem.tracking_allocator(&track)

    // nest a log allocator inside our existing tracking allocator
    la: log.Log_Allocator
    log.log_allocator_init(&la, .Debug, .Human)
    context.allocator = log.log_allocator(&la)

    // take control of tree-sitter allocations so we can track them
    compat: cst.Compat_Allocator
    cst.compat_allocator_init(&compat)
    cst.set_odin_allocator(cst.compat_allocator(&compat))

    defer {
      for _, leak in track.allocation_map {
        fmt.eprintf("%v leaked %m\n", leak.location, leak.size)
      }
      for bad_free in track.bad_free_array {
        fmt.eprintf(
          "%v allocation %p was freed badly\n",
          bad_free.location,
          bad_free.memory,
        )
      }
    }
  }

  // this should probably be in the editor lifecyle
  // but we need to pass the logger reference into that first
  // ideally the init should extract the logger from context rather
  // than explicitly passing
  cst.init(&logger)
  defer cst.fini()

  args := tty.parse_args()

  log.debug("mode: interactive")
  editor := editor_new()
  defer editor_destroy(&editor)

  init_buffer(args, &editor)
  editor_listen(&editor)
}

@(private = "file")
init_buffer :: proc(args: tty.Args, editor: ^Editor) {
  if len(args.filename) > 0 {
    if editor_load_file(editor, args.filename) != os.ERROR_NONE do panic("unable to load file")
  } else {
    editor_add_buffer(editor, buffer.new())
  }
}
