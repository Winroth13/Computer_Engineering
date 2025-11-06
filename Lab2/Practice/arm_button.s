// Symbolic constants
.equ LEDS_BASE, 0xff200000
.equ SWITCHES_BASE, 0xff200040
.equ PUSH_BUTTONS_BASE, 0xff200050

.global _start
_start:
    LDR r0, =PUSH_BUTTONS_BASE   // Base button address
    LDR r1, =LEDS_BASE       // Base LED address

    _loop:
        LDR r2, [r0]         // Read button value
        STR r2, [r1]         // Write to LED registers
        B _loop

_halt:
    B _halt