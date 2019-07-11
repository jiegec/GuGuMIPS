    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x1000     # ans: 0x00001000
    ori $2, $0, 0x1000     # ans: 0x00001000
    teq $1, $2             # trap
    tne $1, $2

    ori $1, $0, 0x2000
    tne $1, $2             # trap
    teq $1, $2

    teqi $1, 0x2000        # trap
    teqi $1, 0x3000
    tnei $1, 0x2000

    ori $1, $0, 0x3000

    tge $1, $2             # trap
    tgei $1, 0x2000        # trap
    tgeiu $1, 0x3000       # trap
    tgei $1, 0x4000

    ori $1, $0, 0x4000

    tlt $1, $2
    tltu $1, $2
    tlt $2, $1             # trap
    tltu $2, $1            # trap
    tltiu $1, 0x4000       # trap
    tltiu $1, 0x5000       # trap

    .org 0x380
    # add epc
    mfc0 $30, $14          # skip
    addi $30, $30, 0x4     # skip
    mtc0 $30, $14
    addi $3, $3, 0x1
    eret
    