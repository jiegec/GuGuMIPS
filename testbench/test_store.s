    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    lui $1, 0x1234       # ans: $1=0x12340000
    ori $1, $1, 0x5678   # ans: $1=0x12345678
    lui $2, 0xa000       # ans: $2=0xa0000000
    sw $1, 0x0($2)
    sw $1, 0x4($2)
    sh $1, 0x2($2)
    sb $1, 0x0($2)
    sb $1, 0x1($2)
    sb $1, 0x3($2)
    sw $1, 0x8($2)

    addiu $2, $2, 0x4
    sw $2, 0x0($2)
    addiu $2, $2, 0x4
    sw $2, 0x0($2)
    lw $2, -0x4($2)
    sw $1, 0x4($2)

    ori $2, $0, 0x9999   # ans: $2=0x00009999