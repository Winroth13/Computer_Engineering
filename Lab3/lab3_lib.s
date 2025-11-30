.data
    inBuf:      .space  64
    outBuf:     .space  64
    inBufPos:   .long   0
    outBufPos:  .long   0

.text
.global inImage
inImage:
    # Get inBuffer
    movq inBuf, %rdi
    # Max buffer size
    movq $64, %rsi
    # Input from the keyboard
    movq stdin, %rdx
    # Gets inupt until max buffer size or newline
    call fgets

    ret

.global getInt
getInt:
    ret

.global getText
getText:
    ret

.global getInPos
getInPos:
    ret

.global setInPos
setInPos:
    ret

.global outImage
outImage:
    # Save the value of r12 and fix segment alignment
    pushq %r12

    leaq outBufPos, %r12
    movl (%r12), %r8d
    leaq outBuf, %r9

    # Add NULL cahracter to end of buffer
    movb $0, (%r9, %r8, 1)

    # Output buffer content
    leaq outBuf, %rdi
    call puts

    # Reset buffer content
    movq $0, (%r12)

    # Set r12 back to original value and remove segment alignment
    popq %r12
    ret

.global putInt
putInt:
    # Save the values and fix segment alignment
    pushq %r12
    pushq %r13
    pushq %r14

    # Gets outBufferPos and outBuffer addresses
    leaq outBufPos, %r12
    leaq outBuf, %r13

    # The number will have to be in rax for the later divisions
    movq %rdi, %rax

    # Check if negative
    cmpq $0, %rax
    jge _putIntConvertDigit

    # Gets next buffer index
    movl (%r12d), %r14d
    # Add - if negative
    movb $'-', (%r13, %r14, 1)
    # Increments buffer index
    incl (%r12d)

    # Converts number into positive version
    negq %rax

    _putIntConvertDigit:
        # NULL at the end of pushed digits
        pushq $0
        movq $10, %r11
    _putIntNextDigit:
        # Sign extend rax to rdx + rax
        cqto
        # rdx + rax / 10 => rax = Quotent, rdx = Modulus
        divq %r11
        # Convert to ascii
        addq $'0', %rdx
        # Push to stack, lowest to highest
        pushq %rdx

        # Repeat until quotent is 0
        cmpq $0, %rax
        jne _putIntNextDigit
    
    _putIntWriteDigit:
        # Get digits, highest to lowest
        popq %rax
        # NULL means all digits written
        cmpq $0, %rax
        je _putIntEnd

        # Gets next buffer index
        movl (%r12d), %r14d
        # Adds digit to outBuffer
        movb %al, (%r13, %r14, 1)
        # Increments buffer index
        incl (%r12d)

        # Prints and empites the outBuffer if it is full
        cmpl $63, (%r12d)
        jne _putIntWriteDigit
        call  outImage
        jmp _putIntWriteDigit

    _putIntEnd:
        # Retrive values of registers and remove segment alignment
        popq %r12
        popq %r13
        popq %r14
        ret

.global putText
putText:
    # Save values of registers and fix segment alignment
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    #pushq $0
    
    leaq outBufPos, %r12
    leaq outBuf, %r13

    _putTextNextChar:
        # Gets next char and outBuffer index
        movzbq (%rdi), %r14
        movl (%r12d), %r15d

        # Checks if end of text
        cmpb $0, %r14b
        je  _putTextEnd

        # Adds the char to the outBuffer
        movb %r14b, (%r13, %r15, 1)

        # Increment both buffer position and active address counter
        incl (%r12d)
        addq $1, %rdi

        # Prints and empites the outBuffer if it is full
        cmpl $63, (%r12d)
        jne _putTextNextChar
        # Save input, also fixes segment alignment
        pushq %rdi
        call  outImage
        popq %rdi
        jmp _putTextNextChar

    _putTextEnd:
        # Retrive values of registers
        popq %r12
        popq %r13
        popq %r14
        popq %r15
        ret

.global putChar
putChar:
    # Fix segment alignment
    pushq $0

    # Gets next outBufferPos and outBuffer
    leaq outBufPos, %r8
    movl (%r8), %r9d
    leaq outBuf, %r10

    # Adds the char to the outBuffer and increments its current position
    movb %dil, (%r10, %r9, 1)
    incl (%r8d)

    # Prints and empites the outBuffer if it is full
    cmpl $63, (%r8d)
    jne _putCharEnd
    call  outImage

    _putCharEnd:
        # Remove segment alignment
        addq $8, %rsp
        ret

.global getOutPos
getOutPos:
    # Return current puffer index
    movl (outBufPos), %eax
    ret

.global setOutPos
setOutPos:
    # If probably meant to be negative
    cmpl $0, %edi
    jl _setOutPosNegative

    # If input is less than or equal to max, use input value
    cmpl $62, %edi
    jle _setOutPosEnd

    # Otherwise, treat as max
    movl $62, %edi
    jmp _setOutPosEnd
    
    _setOutPosNegative:
        # Treat as zero
        movl $0, %edi
        jmp _setOutPosEnd

    _setOutPosEnd:
        # Set outBufferPos
        movl %edi, (outBufPos)
        ret

