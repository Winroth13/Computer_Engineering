.data
    inBuf:      .space  64
    outBuf:     .space  64
    inBufPos:   .quad   0
    outBufPos:  .quad   0

.text
inImage:
    movq $inBuf, %rdi   # Get inBuffer
    movq $64, %rsi      # Max buffer size
    movq stdin, %rdx    # Input from the keyboard
    call fgets          # Gets inupt until max buffer size or newline

    ret

getInt:
    ret

getText:
    ret

getInPos:
    ret

setInPos:
    ret

outImage:
    ret

putInt:
    ret

putText:
    mov %rdi, ($outBuf, $outBufPos, 4)

    ret

putChar:
    ret

getOutPos:
    ret

setOutPos:
    ret