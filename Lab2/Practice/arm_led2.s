.equ LEDS_BASE, 0xff200000  // Symbolic constant

.global _start
_start:
    LDR r0, =LEDS_BASE   // LEDs address
    MOV r1, #0x1c        // Bit 4 turns on LED 4 (the fifth LED from the right)
    STR r1, [r0]         // Write to LEDs data register
    EOR r1, #0x10        // Toggle the LED
    STR r1, [r0]         // Write to LEDs data register

_halt:
    B _halt