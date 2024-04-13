package terminal

import "core:os"
import "core:strings"

Args :: struct {
	filename: string,
	headless: string,
}

/// Parses command line arguments
parse_args :: proc() -> Args {
	args := Args{}

	if len(os.args) > 1 {
		for i := 1; i < len(os.args); i += 1 {
			arg := os.args[i]

			if strings.has_prefix(arg, "--headless") {
				if i + 1 < len(os.args) {
					args.headless = os.args[i + 1]
					i += 1
				}
			} else if !strings.has_prefix(arg, "-") {
				args.filename = arg
			}
		}
	}

	return args
}
