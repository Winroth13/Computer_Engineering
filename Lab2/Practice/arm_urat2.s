// Symbolic constants
.equ UART_BASE, 0xff201000
.equ UART_DATA_REGISTER_ADDRESS, 0xff201000
.equ UART_CONTROL_REGISTER_ADDRESS, 0xff201004

.data

.text
.global _start
_start:
    // UART read
    LDR r0, =UART_DATA_REGISTER_ADDRESS

    _loop:
        LDR r1, [r0]                // Read the data register
        ANDS r2, r1, #0x8000         // Check if data is valid, bit 15
        BEQ _loop                  // If not valid, loop
        AND r1, r1, #0x00ff          // Mask the read data bits 0-7
        
        STR r1, [r0]
        B _loop

_halt:
    B _halt

