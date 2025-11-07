// 
.equ DISPLAYS_BASE_1, 0xff200020
.equ UART_DATA_REGISTER_ADDRESS, 0xff201000

.data

display_number:
	.word 0b00111111 // 0
	.word 0b00110000 // 1
    .word 0b01011011 // 2
	.word 0b01111001 // 3
	.word 0b01110010 // 4
	.word 0b01101101 // 5
	.word 0b01111101 // 6
	.word 0b00110001 // 7
	.word 0b01111111 // 8
	.word 0b01101111 // 9
	.word 0b01110111 // A
    .word 0b01111100 // b
    .word 0b00111001 // C
    .word 0b01011110 // d
    .word 0b01111011 // e
    .word 0b01110001 // F

.text
.global _start
// counter_increment:
/*
-------------------------------------------------------
Increments the display
-------------------------------------------------------
Parameters:
  r0 - address of string 
Uses: No registers altered by the function
-------------------------------------------------------
*/

_start:
    // UART read
    LDR r4, =UART_DATA_REGISTER_ADDRESS
    LDR r5, =DISPLAYS_BASE_1
    LDR r6, =display_number
    //STR r7, [r6]

    _loop:
        LDR r7, [r4]                 // Read the data register
        ANDS r8, r7, #0x8000         // Check if data is valid, bit 15
        BEQ _loop                    // If not valid, loop
        AND r7, r7, #0x00ff          // Mask the read data bits 0-7
        
        //ADD r6, r5, #4
        //LDR r9, [r7, r6]
        //STR r9, [r5]
        B _loop

_halt:
    B _halt