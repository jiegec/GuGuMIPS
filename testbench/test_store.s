    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    lui $1, 0x1234       # ans: $1=0x12340000
    ori $1, $1, 0x5678   # ans: $1=0x12345678
    sw $1, 0x0($0)
    sw $1, 0x4($0)
    sh $1, 0x2($0)
    sb $1, 0x0($0)
    sb $1, 0x1($0)
    sb $1, 0x3($0)
    sw $1, 0x8($0)

    ori $2, $0, 0x9999   # ans: $2=0x00009999