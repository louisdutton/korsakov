package korsakov

import "core:os"
import "core:strings"

queue :: proc(args: ..string) {
	os.write_string(os.stdout, strings.concatenate(args))
}

flush :: proc() {
	os.flush(os.stdout)
}

