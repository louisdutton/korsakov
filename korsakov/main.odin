package korsakov

import "buffer"
import "core:log"
import "core:os"
import "tty"

main :: proc() {
  context.logger = create_logger()
  defer destroy_logger()

  when ODIN_DEBUG {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)
    context.allocator = mem.tracking_allocator(&track)

    defer {
      for _, leak in track.allocation_map {
        log.errorf("%v leaked %m\n", leak.location, leak.size)
      }
      for bad_free in track.bad_free_array {
        log.errorf(
          "%v allocation %p was freed badly\n",
          bad_free.location,
          bad_free.memory,
        )
      }
    }
  }

  args := tty.parse_args()

  log.debug("mode: interactive")
  log.debug("hi there")
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
