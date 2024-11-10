package korsakov

import "core:encoding/ansi"

// utf-8 char codes
BACKSPACE :: 0x08
DELETE :: 0x7F
ESCAPE :: 0x1B

QUIT :: 'q'
CLEAR_TO_END_OF_LINE :: ansi.CSI + ansi.EL

// ansi extra
DECSCUSR :: ansi.ESC + ansi.CSI
DECSCUSR_BLOCK :: DECSCUSR + "2 q"
DECSCUSR_UNDERLINE :: DECSCUSR + "4 q"
DECSCUSR_BAR :: DECSCUSR + "6 q"
