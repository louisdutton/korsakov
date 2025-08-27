package tty

import "core:terminal/ansi"

sgr_reset :: proc() {write(ansi.CSI + ansi.RESET + ansi.SGR)} 	// resets all style manipulations
sgr_invert :: proc() {write(ansi.CSI + ansi.INVERT + ansi.SGR)} 	// inverts the foreground and background colors
