package korsakov

import "core:os"
import "core:strings"

queue :: proc(args: ..string) {
	os.write_string(os.stdout, strings.concatenate(args))
}

exec :: proc(args: ..string) {
	queue(..args)
	flush()
}

flush :: proc() {
	os.flush(os.stdout)
}
