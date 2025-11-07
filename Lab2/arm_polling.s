// 
.equ DISPLAYS_BASE_1, 0xff200020
.equ UART_DATA_REGISTER_ADDRESS, 0xff201000
.equ INCREMENT_UP_KEY, 77   // W
.equ INCREMENT_DOWN_KEY, 74 // D
.equ DISPLAYED_NUMBER_OFFSET_ADDRESS, 0xffffffff

.data

display_number: // The binary for the 7-segment-display to display the numbers in order
	.word 0b00111111 // 0
	.word 0b00000110 // 1
    .word 0b01011011 // 2
	.word 0b01001111 // 3
	.word 0b01100110 // 4
	.word 0b01101101 // 5
	.word 0b01111101 // 6
	.word 0b00000111 // 7
	.word 0b01111111 // 8
	.word 0b01101111 // 9
	.word 0b01110111 // A
    .word 0b01111100 // b
    .word 0b00111001 // C
    .word 0b01011110 // d
    .word 0b01111001 // E
    .word 0b01110001 // F

.text
.global _start

counter_increment:
/*
-------------------------------------------------------
Increments the displayed number
-------------------------------------------------------
Parameters:
  r0 - increment (Decrement is negative)
Uses: No registers altered by the function
-------------------------------------------------------
*/
    PUSH {r0, r4-r8, lr}
    LDR r4, =DISPLAYS_BASE_1
    LDR r5, =display_number
    LDR r6, =DISPLAYED_NUMBER_OFFSET_ADDRESS
    LDR r7, [r6]     // Load current displayed number offset

    MUL r0, r0, #4   // Convert increment into offset
    ADD r7, r7, r0   // New offset
    // MOV r7, r7 % 16  // Clamp offset to the range of possible numbers
    STR r7, [r6]     // Save new offset to memory

    MOV r8, [r5, r7] // The binary for the new number to display
    STR r4, [r8]     // Save new number binary to the 7-segment-display

    POP {r0, r4-r8, pc}

_start:
    LDR r4, =UART_DATA_REGISTER_ADDRESS
    LDR r5, =DISPLAYS_BASE_1
    LDR r6, =display_number
    MOV r7, #0

    _loop:
        // UART read
        LDR r8, [r4]                 // Read the data register
        ANDS r9, r8, #0x8000         // Check if data is valid, bit 15
        BEQ _loop                    // If not valid, loop
        AND r8, r8, #0x00ff          // Mask the read data bits 0-7
        
        ADD r7, r7, #4
        LDR r10, [r6, r7]
        STR r10, [r5]
        B _loop

_halt:
    B _halt