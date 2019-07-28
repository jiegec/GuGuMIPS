    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    lui $1, 0x8765       # ans: $1=0x87650000
    ori $1, $1, 0x4321   # ans: $1=0x87654321
    lui $5, 0xa000       # ans: $5=0xa0000000
    sw $1, 0x0($5)
    lw $2, 0x0($5)
    lb $2, 0x0($5)
    lb $2, 0x1($5)
    lb $2, 0x2($5)
    lb $2, 0x3($5)
    lbu $2, 0x0($5)
    lbu $2, 0x1($5)
    lbu $2, 0x2($5)
    lbu $2, 0x3($5)
    lh $2, 0x0($5)
    lh $2, 0x2($5)
    lhu $2, 0x0($5)
    lhu $2, 0x2($5)

    # load in delay slot
    lhu $2, 0x0($5)
    j end_1
    lhu $2, 0x2($5)
    ori $2, $0, 0

end_1:
    lh $2, 0x2($5)

    # arithmetic after load
    lhu $2, 0x0($5)
    ori $2, $2, 0x1234

    # branch after load
    lhu $2, 0x0($5)
    lhu $3, 0x0($5)
    beq $2, $3, end_2
    lhu $2, 0x2($5)
    ori $2, $0, 0

end_2:
    lh $2, 0x2($5)

    # register related
    lui $2, 0xa000
    lh $3, 0x2($2)
    lh $2, 0x2($5)

    # more complicated
    ori $1, $0, 1
    beqz $1, end_3
    lw $2, 0x0($5)
    lw $3, 0x0($5)
    bne $2, $3, end_3
    nop
    beq $1, $1, end_3
    lw $4, 0x0($5)
    ori $1, $0, 2

end_3:
    ori $1, $0, 3