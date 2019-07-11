    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x8000      # ans: $1=0x00008000
    syscall
    ori $2, $0, 0x1234      # ans: $2=0x00001234
    ori $2, $29, 0x0000     # ans: $2=0x0x00000008
    syscall
    ori $2, $3, 0x1234      # ans: $2=0x1234
    ori $2, $29, 0x0000     # ans: $2=0x00000008
    syscall
    ori $2, $29, 0x0000     # ans: $2=0x00000008

    .org 0x380
    # add epc
    mfc0 $30, $14          # ans: $30=pc
    addi $30, $30, 0x4     # ans: $30=pc+4
    mtc0 $30, $14
    # read exc code
    mfc0 $29, $13          # skip
    andi $29, $29, 0x007c  # skip
    srl $29, $29, 2        # ans: $29=0x00000008 syscall
    eret
    ori $3, $0, 0x4321
    