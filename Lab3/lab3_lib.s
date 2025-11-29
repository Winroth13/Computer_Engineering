.data
    inBuf:      .space  64
    outBuf:     .space  64
    inBufPos:   .quad   0
    outBufPos:  .quad   0

.text
.global inImage
inImage:
    # Get inBuffer
    movq $inBuf, %rdi
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
    movq (%r12), %r8
    leaq outBuf, %r9

    # Add NULL cahracter to end of buffer
    movb $0, (%r9, %r8, 4)

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
    ret

.global putText
putText:
    # Save values of registers and fix segment alignment
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    pushq $0
    
    leaq outBufPos, %r12
    leaq outBuf, %r13

    _putTextWriteChar:
        # Gets next char and outBuffer index
        movzbq (%rdi), %r14
        movq (%r12), %r15

        # Checks if end of text
        cmpb $0, %r14b
        je  _putTextEnd

        # Adds the char to the outBuffer
        movb %r14b, (%r13, %r15, 1)

        # Increment both buffer position and active address counter
        incq (%r12)
        addq $1, %rdi

        # Prints and empites the outBuffer if it is full
        cmpq $63, (%r12)
        jne _putTextWriteChar
        call  outImage
        jmp _putTextWriteChar

    _putTextEnd:
        # Retrive values of registers and remove segment alignment
        addq $8, %rsp
        popq %r12
        popq %r13
        popq %r14
        popq %r15
        ret

.global putChar
putChar:
    # Fix segment alignment
    pushq $0

    leaq outBufPos, %r8
    movq (%r8), %r9
    leaq outBuf, %r10

    # Adds the char to the outBuffer and increments its current position
    movb %dil, (%r10, %r9, 1)
    incq (%r8)

    # Prints and empites the outBuffer if it is full
    cmpq $63, (%r8)
    jne _putCharEnd
    call  outImage

    _putCharEnd:
        # Remove segment alignment
        addq $8, %rsp
        ret

.global getOutPos
getOutPos:
    ret

.global setOutPos
setOutPos:
    ret
