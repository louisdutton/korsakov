package korsakov

import "cli"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"


main :: proc() {
	fmt.println("Starting Korsakov editor...")
	args := args.parse_args()

	fmt.printf("Arguments: filename='%s', headless='%s'\n", args.filename, args.headless)

	if len(args.headless) > 0 {
		fmt.println("Running in headless mode")
		// Run in headless mode for testing
		editor, err := editor_new_headless()
		if err != os.ERROR_NONE {
			fmt.printf("Failed to create headless editor: %v\n", err)
			return
		}
		defer editor_destroy(&editor)

		if len(args.filename) > 0 {
			if load_err := editor_load_file(&editor, args.filename); load_err != os.ERROR_NONE {
				fmt.printf("Failed to load file '%s': %v\n", args.filename, load_err)
			}
		} else {
			// Create empty buffer if no filename provided
			editor_add_buffer(&editor, buffer_new())
		}

		if eval_err := editor_eval(&editor, args.headless); eval_err != os.ERROR_NONE {
			fmt.printf("Error in headless evaluation: %v\n", eval_err)
		}
	} else {
		fmt.println("Running in interactive mode")
		// Run in normal interactive mode
		editor, err := editor_new()
		if err != os.ERROR_NONE {
			fmt.printf("Failed to create editor: %v\n", err)
			return
		}
		defer editor_destroy(&editor)

		if len(args.filename) > 0 {
			if load_err := editor_load_file(&editor, args.filename); load_err != os.ERROR_NONE {
				fmt.printf("Failed to load file '%s': %v\n", args.filename, load_err)
			}
		} else {
			// Create empty buffer if no filename provided
			editor_add_buffer(&editor, buffer_new())
		}

		if listen_err := editor_listen(&editor); listen_err != os.ERROR_NONE {
			fmt.printf("Error in editor loop: %v\n", listen_err)
		}
	}

	fmt.println("Korsakov editor finished.")
}
