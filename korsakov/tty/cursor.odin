package tty

import "core:fmt"
import "core:terminal/ansi"

cursor_move :: proc(x, y: int) {fmt.printf(ansi.CSI + "%d;%dH", y + 1, x + 1)} 	// moves cursor to specific position
cursor_show :: proc() {write(ansi.CSI + ansi.DECTCEM_SHOW)} 	// show the cursor
cursor_hide :: proc() {write(ansi.CSI + ansi.DECTCEM_HIDE)} 	// hide the cursor
cursor_block :: proc() {write(ansi.CSI + "2 q")} 	// set cursor style to BLOCK
cursor_underline :: proc() {write(ansi.CSI + "4 q")} 	// set cursor style to UNDERLINE
cursor_line :: proc() {write(ansi.CSI + "6 q")} 	// set cursor style to LINE
