    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x8000     # ans: $1=0x00008000
    syscall
    ori $2, $0, 0x1234     # ans: $2=0x00001234

    .org 0x380
    # add epc
    mfc0 $30, $14          # ans: $30=0x00000004
    addi $30, $30, 0x4     # ans: $30=0x00000008
    mtc0 $30, $14
    # read exc code
    mfc0 $29, $13          # skip
    andi $29, $29, 0x007c  # skip
    srl $29, $29, 2        # ans: $29=0x00000008
    eret
    