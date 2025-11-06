// Symbolic constants
.equ LEDS_BASE, 0xff200000
.equ SWITCHES_BASE, 0xff200040

.global _start
_start:
    LDR r0, =SWITCHES_BASE   // Base switch address
    LDR r1, =LEDS_BASE       // Base LED address

    _loop:
        LDR r2, [r0]         // Read switches value
        STR r2, [r1]         // Write to LED registers
        B _loop

_halt:
    B _halt