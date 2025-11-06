

// Symbolic constants
.equ LEDS_BASE, 0xff200000
.equ SWITCHES_BASE, 0xff200040
.equ PUSH_BUTTONS_BASE, 0xff200050
.equ DISPLAYS_BASE_1, 0xff200020
.equ DISPLAYS_BASE_2, 0xff200030

.global _start
_start:
    LDR r0, =DISPLAYS_BASE_1    // Base address for display 0-3
    MOV r2, #0b00000001         // Binary value to write
    STR r2, [r0]                // Write to the display

    LDR r1, =DISPLAYS_BASE_2    // Base address for display 4-5
    MOV r2, #0x7f               // Hexadecimal value to write
    LSL r2, r2, #8              // Shift left 8 bits
    STR r2, [r1]                // Write to the display
    
    LDR r2, [r0]
    LSL r2, r2, #8
    STR r2, [r0]

_halt:
    B _halt

