// 
.equ STACK_BASE, 0x10000000		                  // stack beginning
.equ DISPLAYS_BASE_1, 0xff200020                  // Addess for 7-segment-displays 1-4
.equ UART_DATA_REGISTER_ADDRESS, 0xff201000       // Adress for UART Data Register
.equ INCREMENT_KEY, 0x77                          // W
.equ DECREMENT_KEY, 0x73                          // S
.equ DISPLAYED_NUMBER_OFFSET_ADDRESS, 0xfffffff0  // The offset for the currently displayed number

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

update_display:
/*
-------------------------------------------------------
Updates the displayed number
-------------------------------------------------------
Parameters: None
Uses: No registers altered by the function
-------------------------------------------------------
*/
    push {r4-r8, lr}
    LDR r4, =DISPLAYS_BASE_1
    LDR r5, =display_number
    LDR r6, =DISPLAYED_NUMBER_OFFSET_ADDRESS

    LDR r7, [r6]     // Load current displayed number offset
    LDR r8, [r5, r7] // The binary for the new number to display
    STR r8, [r4]     // Save new number binary to the 7-segment-display

    pop {r4-r8, pc}

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
    PUSH {r0, r4-r6, lr}
    LDR r4, =DISPLAYED_NUMBER_OFFSET_ADDRESS
    LDR r5, [r4]     // Load current displayed number offset

    MOV r6, #4       // How much to offset per increment
    MUL r0, r0, r6   // Convert increment into offset
    ADD r5, r5, r0   // New offset

    STR r5, [r4]     // Save new offset to memory

    BL update_display

    POP {r0, r4-r6, pc}

_start:
    LDR sp, =STACK_BASE
    LDR r5, =UART_DATA_REGISTER_ADDRESS
    LDR r6, =INCREMENT_KEY
    LDR r7, =DECREMENT_KEY
    LDR r8, =DISPLAYED_NUMBER_OFFSET_ADDRESS
    MOV r9, #0
    STR r9, [r8] // Reset displayed number offset
    
    BL update_display

    _loop:
        // Read UART
        LDR r10, [r5]                // Read the data register
        ANDS r11, r10, #0x8000       // Check if data is valid, bit 15
        BEQ _loop                    // If not valid, loop
        AND r10, r10, #0x00ff        // Mask the read data bits 0-7
        
        // Increment display
        CMP r10, r6                  // Incremnet-key was pressed
        MOVEQ r0, #1                 // Increment by one
        BLEQ increment_display
        CMP r10, r7                  // Decrement-key was pressed
        MOVEQ r0, #0xffffffff        // Decrement by one
        BLEQ increment_display
        B _loop

_halt:
    B _halt