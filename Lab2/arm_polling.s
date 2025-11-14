// Constants
.equ STACK_BASE, 0x10000000		            // Stack beginning
.equ DISPLAYS_BASE_1, 0xff200020            // Addess for 7-segment-displays 1-4
.equ UART_DATA_REGISTER, 0xff201000         // Adress for UART Data Register
.equ INCREMENT_KEY, 0x77                    // W
.equ DECREMENT_KEY, 0x73                    // S
.equ DISPLAYED_NUMBER, 0xfffffff0           // The currently displayed number
.equ NUMBER_BASE, 16                        // The number base to use for the display

.data

display_binary: // The binary for the 7-segment-display to display the numbers in order
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

update_display:
/*
-------------------------------------------------------
Updates the displayed number
-------------------------------------------------------
Parameters: None
Uses: No registers altered by the function
-------------------------------------------------------
*/
    push {r4-r9, lr}
    LDR r4, =DISPLAYS_BASE_1
    LDR r5, =display_binary
    LDR r6, =DISPLAYED_NUMBER

    LDR r7, [r6]        // Load current displayed number
    MOV r8, #4          // Offset between numbers
    MUL r7, r8          // Turn number into offset
    LDR r9, [r5, r7]    // The binary for the new number to display
    STR r9, [r4]        // Save new number binary to the 7-segment-display

    pop {r4-r9, pc}

increment_display:
/*
-------------------------------------------------------
Increments the displayed number
-------------------------------------------------------
Parameters:
  r0 - increment (Decrement is negative)
Uses: No registers altered by the function
-------------------------------------------------------
*/
    PUSH {r0, r4-r7, lr}
    LDR r4, =DISPLAYED_NUMBER
    LDR r5, [r4]                // Load current displayed number offset
    LDR r6, =NUMBER_BASE

    ADD r5, r5, r0              // New number to display

    _underflow_loop:
        CMP r5, #0              // If lower than 0
        ADDLT r5, r6            // Increase by number base
        BLT _underflow_loop     // Until within number base
    
    _overflow_loop:
        CMP r5, r6              // If higher than highest allowed number
        SUBGE r5, r6            // Decrease by number base
        BGE _overflow_loop      // Until within number base

    STR r5, [r4]                // Save new number to memory

    BL update_display

    POP {r0, r4-r7, pc}

_start:
    LDR sp, =STACK_BASE
    LDR r4, =UART_DATA_REGISTER
    LDR r5, =INCREMENT_KEY
    LDR r6, =DECREMENT_KEY
    LDR r7, =DISPLAYED_NUMBER
    MOV r8, #0
    STR r8, [r7]        // Reset displayed number
    
    BL update_display

    _loop:
        // Read UART
        LDR r9, [r4]                // Read the data register
        ANDS r10, r9, #0x8000       // Check if data is valid, bit 15
        BEQ _loop                   // If not valid, loop
        AND r9, r9, #0x00ff         // Mask the read data bits 0-7
        
        // Increment display
        CMP r9, r5                  // Incremnet-key was pressed
        MOVEQ r0, #1                // Increment by one
        BLEQ increment_display
        CMP r9, r6                  // Decrement-key was pressed
        MOVEQ r0, #0xffffffff       // Decrement by one
        BLEQ increment_display
        B _loop

_halt:
    B _halt