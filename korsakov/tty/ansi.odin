package tty

import "core:terminal/ansi"


alt_screen_enable :: proc() {write(ansi.CSI + "?1049h")}   // Use alternate screen buffer
alt_screen_disable :: proc() {write(ansi.CSI + "?1049l")}   // Use normal screen buffer and restore cursor

clear_line :: proc() {write(ansi.CSI + ansi.EL)}   // Clears to end of line
clear_screen :: proc() {write(ansi.CSI + "2" + ansi.ED)}   // Clears the entire viewport

line_wrap_enable :: proc() {write(ansi.CSI + ansi.DECAWM_ON)}
line_wrap_disable :: proc() {write(ansi.CSI + ansi.DECAWM_OFF)}
