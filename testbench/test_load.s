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
    