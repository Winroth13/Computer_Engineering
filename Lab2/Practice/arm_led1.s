.global _start
_start:
    LDR r0, =0xff200000  // LEDs address
    MOV r1, #3           // Bit 0 will turn on the rightmost LED
    STR r1, [r0]         // Write to LEDs data register   

_halt:
    B _halt