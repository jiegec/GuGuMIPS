    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    lui $1, 0x8765       # ans: $1=0x87650000
    ori $1, $1, 0x4321   # ans: $1=0x87654321
    sw $1, 0x0($0)
    lw $2, 0x0($0)
    lb $2, 0x0($0)
    lb $2, 0x1($0)
    lb $2, 0x2($0)
    lb $2, 0x3($0)
    lbu $2, 0x0($0)
    lbu $2, 0x1($0)
    lbu $2, 0x2($0)
    lbu $2, 0x3($0)
    lh $2, 0x0($0)
    lh $2, 0x2($0)
    lhu $2, 0x0($0)
    lhu $2, 0x2($0)

    # load in delay slot
    lhu $2, 0x0($0)
    j end_1
    lhu $2, 0x2($0)
    ori $2, $0, 0

end_1:
    lh $2, 0x2($0)

    # arithmetic after load
    lhu $2, 0x0($0)
    ori $2, $2, 0x1234

    # branch after load
    lhu $2, 0x0($0)
    lhu $3, 0x0($0)
    beq $2, $3, end_2
    lhu $2, 0x2($0)
    ori $2, $0, 0

end_2:
    lh $2, 0x2($0)

    # register related
    lui $2, 0
    lh $3, 0x2($2)
    lh $2, 0x2($0)

    ori $1, $0, 1
    beqz $1, end_3
    lw $2, 0x0($0)
    lw $3, 0x0($0)
    bne $2, $3, end_3
    nop
    beq $1, $1, end_3
    lw $4, 0x0($0)
    ori $1, $0, 2

end_3:
    ori $1, $0, 3