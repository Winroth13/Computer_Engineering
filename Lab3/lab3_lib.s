.data
    inBuf:      .space  64
    outBuf:     .space  64
    inBufPos:   .long   0
    outBufPos:  .long   0

.text
.global inImage
inImage:
    # Fix segment alignment
    pushq $0

    # Get inBuffer
    movq $inBuf, %rdi
    # Max buffer size
    movq $64, %rsi
    # Input from the keyboard
    movq stdin, %rdx
    # Gets input until max buffer size or Newline
    call fgets

    # Reset inBuff index
    movl $0, (inBufPos)

    # Remove segment alignment
    addq $8, %rsp
    ret

.global getInt
getInt:
    # Save the register values
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # Retreve inBuffer
    leaq inBuf, %r12

    # Initialize register
    movq $0, %rax
    movq $0, %r10

    _getIntCheckBuf:
        # Retreve index
        movl inBufPos, %r13d
        # If the next char is Newline, the inBuffer is empty
        movb (%r12, %r13, 1), %r14b
        cmpb $0x0a, %r14b
        jne _getIntCheckBlanc

        # Save value and fix segment alignment
        pushq %rax
        pushq %r10
        pushq $0
        # Renew inBuffer
        call inImage
        # Retreve value and remove segment alignment
        addq $8, %rsp
        popq %rax
        popq %r10

        jmp _getIntCheckBuf

    _getIntCheckBlanc:
        # Check if blanc
        cmpb $' ', %r14b
        jne _getIntCheckPlus

        # Increment inBuff index
        incl inBufPos
        movl inBufPos, %r13d

        # Get next char
        movb (%r12, %r13, 1), %r14b

        # Recheck blanc
        jmp _getIntCheckBlanc

    _getIntCheckPlus:
        # Check if plus sign
        cmpb $'+', %r14b
        jne _getIntCheckMinus

        # Increment index
        incl inBufPos
        jmp _getIntLoop

    _getIntCheckMinus:
        # Check if minus sign
        cmpb $'-', %r14b
        jne _getIntLoop

        # Increment index
        incl inBufPos
        movq $1, %r10

    _getIntLoop:
        # Get next char
        movl inBufPos, %r13d
        movb (%r12, %r13, 1), %r14b

        # Check if char is not a digit
        cmpb $'0', %r14b
        jl _getIntInvertCheck
        cmpb $'9', %r14b
        jg _getIntInvertCheck

        # Convert to char to number
        movzbq %r14b, %r15
        subq $'0', %r15
        # Append digit to the end of the number
        imul $10, %rax
        addq %r15, %rax

        # Increment index
        incl inBufPos

        # Repeat
        jmp _getIntLoop

    _getIntInvertCheck:
        # Check if the there was a minus sign
        cmpq $1, %r10
        jne _getIntEnd

        # Negate the returned value
        negq %rax

    _getIntEnd:
        # Retrive values of registers
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        ret

.global getText
getText:
    # Save the register values
    pushq %r12
    pushq %r13

    # Store away the input and retreve inBuffer and index
    movq %rdi, %r12
    movq %rsi, %r13
    leaq inBuf, %r14
    movq $0, %rax

    _getTextCheckBuf:
        # Retreve index
        movl inBufPos, %r15d
        # If the next char is Newline, the inBuffer is empty
        movb (%r14, %r15, 1), %r8b
        cmpb $0x0a, %r8b
        jne _getTextCheckBlanc

        # Save value and fix segment alignment
        pushq %rax
        pushq %r8
        pushq $0
        # Renew inBuffer
        call inImage
        # Retreve value and remove segment alignment
        addq $8, %rsp
        popq %r8
        popq %rax

        jmp _getTextCheckBuf

    _getTextCheckBlanc:
        # Check if blanc
        cmpb $' ', %r8b
        jne _getTextNextChar

        # Increment inBuff index
        incl inBufPos
        movl inBufPos, %r15d

        # Get next char
        movb (%r14, %r15, 1), %r8b

        # Recheck blanc
        jmp _getTextCheckBlanc
    
    _getTextNextChar:
        # Get next inBuffer index
        movl inBufPos, %r15d

        # Put next inBuffer char in target buffer
        movq (%r14, %r15, 1), %r9
        movb %r9b, (%r12, %rax, 1)

        # Increment inBuffer and target buffer index
        incl inBufPos
        incl %eax

        # If max requested chars have been retreved
        cmpl %r13d, %eax
        je _getTextEnd

        # If no more chars in inBuffer
        cmpb $0, (%r14, %r15, 1)
        je _getTextEnd

        jmp _getTextNextChar

    _getTextEnd:
        # Retrive values of registers
        popq %r13
        popq %r12
        ret

.global getInPos
getInPos:
    # Return current inBuffer index
    movl (outBufPos), %eax
    ret

.global setInPos
setInPos:
    # If negative
    cmpl $0, %edi
    jl _setInPosNegative

    # If input is less than or equal to max, use input value
    cmpl $62, %edi
    jle _setInPosEnd

    # Otherwise, treat as max
    movl $62, %edi
    jmp _setInPosEnd

    _setInPosNegative:
        # Treat as zero
        movl $0, %edi
        jmp _setInPosEnd

    _setInPosEnd:
        # Set inBufferPos
        movl %edi, (inBufPos)
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

    # Retrive value of r12 and remove segment alignment
    popq %r12
    ret

.global putInt
putInt:
    # Save register values and fix segment alignment
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
        popq %r14
        popq %r13
        popq %r12
        ret

.global putText
putText:
    # Save values of registers and fix segment alignment
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
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
        popq %r15
        popq %r14
        popq %r13
        popq %r12
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
    # Return current outBuffer index
    movl (outBufPos), %eax
    ret

.global setOutPos
setOutPos:
    # If negative
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

