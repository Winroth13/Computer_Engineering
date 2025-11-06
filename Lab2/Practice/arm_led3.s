.equ LEDS_BASE, 0xff200000  // Symbolic constant

.global _start
_start:
    LDR r0, =LEDS_BASE   // LEDs address
    MOV r1, #0b1000      // Bit 0 will turn on the rightmost LED
    STR r1, [r0]         // Write to LEDs data register

    LDR r2, [r0]         // Read LEDs data register, should be same as written
_halt:
    B _halt