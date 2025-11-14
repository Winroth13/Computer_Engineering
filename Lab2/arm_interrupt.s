// Stack base addresses
.equ USER_MODE_STACK_BASE, 0x10000000		// Stack beginning
.equ SVC_MODE_STACK_BASE, 0x3FFFFFFF - 3    // Set SVC stack to top of DDR3 memory
.equ IRQ_MODE_STACK_BASE, 0xFFFFFFFF - 3    // Set IRQ stack to A9 onchip memory

// GIC Base addresses
.equ GIC_CPU_INTERFACE_BASE, 0xFFFEC100
.equ GIC_DISTRIBUTOR_BASE, 0xFFFED000

// Other I/O device base addresses
.equ DISPLAYS_BASE_1, 0xff200020            // Addess for 7-segment-displays 1-4
.equ UART_DATA_REGISTER, 0xff201000         // Adress for UART Data Register
.equ PARALLEL_PORTS_MASK, 0xff200058        // Adress for the parallel port mask bits
.equ PARALLEL_PORTS_EDGE, 0xff20005c        // Adress for the parallel port edge bits

// Configureable constants
.equ INCREMENT_KEY, 0x77                    // W
.equ DECREMENT_KEY, 0x73                    // S
.equ DISPLAYED_NUMBER, 0xc3fffff0           // The currently displayed number
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

.text       // Code section
.org 0x00   // Address of interrupt vector
    B _start            // reset vector
    B SERVICE_UND       // undefined instruction vector
    B SERVICE_SVC       // software interrrupt (supervisor call) vector
    B SERVICE_ABT_INST  // aborted prefetch vector
    B SERVICE_ABT_DATA  // aborted data vector
    .word 0             // unused vector
    B SERVICE_IRQ       // IRQ interrupt vector
    B SERVICE_FIQ       // FIQ interrupt vector

.text
.global _start
.global _start
_start:
    // 1. Set up stack pointers for IRQ and SVC processor modes
    MSR cpsr_c, #0b11010010         // change to IRQ mode with interrupts disabled
    LDR sp, =IRQ_MODE_STACK_BASE    // initiate IRQ mode stack

    MSR cpsr, #0b11010011           // change to supervisor mode, interrupts disabled
    LDR sp, =SVC_MODE_STACK_BASE    // initiate supervisor mode stack

    // 2. Configure the Generic Interrupt Controller (GIC). Using the given help function CONFIG_GIC.
    // r0: The Interrupt ID to enable (only one supported for now)
    MOV r0, #73         // UART Interrupt ID = 80
    BL CONFIG_GIC       // Configure the ARM GIC

    // Initialize push buttons with receive interrupts enabled
    LDR r4, =PARALLEL_PORTS_MASK
    MOV r5, #0b00000011         // Enable receive interrupts for push buttons
    STR r5, [r4]

    // 4. Change to the processor mode for the main program loop (for example supervisor mode)
    // 5. Enable the processor interrupts (IRQ in our case)
    MSR cpsr_c, #0b01010011     // IRQ unmasked, MODE = SVC

    // Reset the number displayed on the 7-segment display
    LDR r4, =DISPLAYED_NUMBER
    MOV r5, #0
    STR r5, [r4]
    BL update_display

_main:
    LDR r4, =UART_DATA_REGISTER
    LDR r5, =INCREMENT_KEY
    LDR r6, =DECREMENT_KEY

    _main_loop:
        // Read UART
        LDR r7, [r4]                // Read the data register
        ANDS r8, r7, #0x8000        // Check if data is valid, bit 15
        BEQ _main_loop                   // If not valid, loop
        AND r7, r7, #0x00ff         // Mask the read data bits 0-7
        
        // Increment display
        CMP r7, r5                  // Incremnet-key was pressed
        MOVEQ r0, #1                // Increment by one
        BLEQ increment_display
        CMP r7, r6                  // Decrement-key was pressed
        MOVEQ r0, #0xffffffff       // Decrement by one
        BLEQ increment_display
        B _main_loop

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

/*
-------------------------------------------------------
Handles IRQ interrupts
-------------------------------------------------------
Uses: No registers altered by the function
-------------------------------------------------------
*/
SERVICE_IRQ:
    PUSH {r0-r5, lr}
    // 1. Read and acknowledge the interrupt at the GIC.
    //    Read the ICCIAR from the CPU Interface.
    LDR r4, =GIC_CPU_INTERFACE_BASE // 0xFFFEC100
    LDR r5, [r4, #0x0C]             // Read current Interrupt ID from ICCIAR

    /* 2. Check which device raised the interrupt */
    CMP r5, #73             // Push buttons Interrupt ID

    BNE _SERVICE_IRQ_DONE   // If not recognized, some error handling or just return from interrupt

    /*
        3. Handle the specific device interrupt
        and
        4. Acknowledge the specific device interrupt
    */
    BL push_buttons_interrupt_handler

    _SERVICE_IRQ_DONE:
        // 5. Inform the GIC that the interrupt is handled
        STR r5, [r4, #0x10]         // Write to ICCEOIR

        // 6. Return from interrupt
        POP {r0-r5, lr}
        SUBS pc, lr, #4             // Return to where program was interrupted

/*
-------------------------------------------------------
Handles push buttons interrupts
-------------------------------------------------------
Uses: No registers altered by the function
-------------------------------------------------------
*/
push_buttons_interrupt_handler:
    PUSH {r4-r7, lr}

    LDR r4, =PARALLEL_PORTS_EDGE
    LDR r5, [r4]

    _check_push_button_1:
        ANDS r6, r5, #0b00000001    // Check if push button 1 was pressed
        BEQ _check_push_button_2
        MOV r0, #1                  // Increment by one
        BL increment_display
        MOV r7, #0b00000001         // Reset edgecapure for push button 1
        STR r7, [r4]

    _check_push_button_2:
        ANDS r6, r5, #0b00000010    // Check if push button 2 was pressed
        BEQ _push_button_check_end
        MOV r0, #0xffffffff         // Decrement by one
        BL increment_display
        MOV r7, #0b00000010         // Reset edgecapure for push button 2
        STR r7, [r4]

    _push_button_check_end:
        POP {r4-r7, pc}

/*
-------------------------------------------------------
Unhandled interrupts
-------------------------------------------------------
*/
    /* Undefined instructions */
SERVICE_UND:
    B SERVICE_UND
    /* Software interrupts */
SERVICE_SVC:
    B SERVICE_SVC
    /* Aborted data reads */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
    /* Aborted instruction fetch */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
    /* FIQ */
SERVICE_FIQ:
    B SERVICE_FIQ

/*
-------------------------------------------------------
    HELP FUNCTION
-------------------------------------------------------
Configures the Generic Interrupt Controller (GIC)
-------------------------------------------------------
Arguments:
    R0: Interrupt ID
-------------------------------------------------------
*/
CONFIG_GIC:
    PUSH {lr}
    /*
        To configure a specific interrupt ID:
        1. set the target to cpu0 in the ICDIPTRn register
        2. enable the interrupt in the ICDISERn register
    */
    
    // CONFIG_INTERRUPT (int_ID (r0), CPU_target (r1));
    MOV r1, #1          // This field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

    // Configure the GIC CPU Interface
    LDR r0, =GIC_CPU_INTERFACE_BASE     // Base address of CPU Interface, 0xFFFEC100

    // Set Interrupt Priority Mask Register (ICCPMR)
    LDR r1, =0xFFFF     // Enable interrupts of all priorities levels
    STR r1, [r0, #0x04]

    // Set the enable bit in the CPU Interface Control Register (ICCICR)
    // This allows interrupts to be forwarded to the CPU(s)
    MOV r1, #1
    STR r1, [r0]

    // Set the enable bit in the Distributor Control Register (ICDDCR)
    // This enables forwarding of interrupts to the CPU Interface(s)
    LDR r0, =GIC_DISTRIBUTOR_BASE   // 0xFFFED000
    STR r1, [r0]
    POP {pc}


/*
-------------------------------------------------------
    HELP FUNCTION
-------------------------------------------------------
Configure registers in the GIC for an individual Interrupt ID.

We configure only the Interrupt Set Enable Registers (ICDISERn) and
Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
values are used for other registers in the GIC.
-------------------------------------------------------
Arguments:
    R0 = Interrupt ID, N
    R1 = CPU target
-------------------------------------------------------
*/
CONFIG_INTERRUPT:
    PUSH {r4-r5, lr}
    /*
        Configure Interrupt Set-Enable Registers (ICDISERn).
        reg_offset = (integer_div(N / 32) * 4
        value = 1 << (N mod 32)
    */
    LSR r4, r0, #3          // Calculate reg_offset
    BIC r4, r4, #3          // r4 = reg_offset
    LDR r2, =0xFFFED100     // Base address of ICDISERn
    ADD r4, r2, r4          // r4 = address of ICDISER
    AND r2, r0, #0x1F       // N mod 32
    MOV r5, #1              // Enable
    LSL r2, r5, r2          // r2 = value

    /* Using the register address in r4 and the value in r2 set
       the correct bit in the GIC register */
    LDR r3, [r4]            // Read current register value
    ORR r3, r3, r2          // Set the enable bit
    STR r3, [r4]            // Store the new register value

    /* Configure Interrupt Processor Targets Register (ICDIPTRn)
       reg_offset = integer_div(N / 4) * 4
       index = N mod 4 */
    BIC r4, r0, #3          // r4 = reg_offset
    LDR r2, =0xFFFED800     // Base address of ICDIPTRn
    ADD r4, r2, r4          // r4 = word address of ICDIPTR
    AND r2, r0, #0x3        // N mod 4
    ADD r4, r2, r4          // r4 = byte address in ICDIPTR

    /* Using register address in r4 and the value in r2 write to
       (only) the appropriate byte */
    STRB r1, [r4]
    POP {r4-r5, pc}