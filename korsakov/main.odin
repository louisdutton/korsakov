package korsakov

import "buffer"
import "core:log"
import "core:os"
import "tty"

main :: proc() {
	log.info("starting program")
	args := tty.parse_args()
	context.logger = log.create_console_logger(.Debug, {.Level, .Terminal_Color})
	defer log.destroy_console_logger(context.logger)

	if len(args.headless) > 0 {
		log.debug("mode: headess")
		editor := editor_new_headless()
		defer editor_destroy(&editor)

		init_buffer(args, &editor)
		editor_eval(&editor, args.headless)
	} else {
		log.debug("mode: interactive")
		editor := editor_new()
		defer editor_destroy(&editor)

		init_buffer(args, &editor)
		editor_listen(&editor)
	}
}

@(private = "file")
init_buffer :: proc(args: tty.Args, editor: ^Editor) {
	if len(args.filename) > 0 {
		if editor_load_file(editor, args.filename) != os.ERROR_NONE do panic("unable to load file")
	} else {
		editor_add_buffer(editor, buffer.new())
	}
}
