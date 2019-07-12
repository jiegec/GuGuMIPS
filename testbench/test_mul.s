    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0xffff  # ans: $1=0x0000ffff
    sll $1, $1, 16      # ans: $1=0xffff0000
    ori $1, $1, 0xfffb  # ans: $1=0xfffffffb
    ori $2, $0, 6       # ans: $2=0x00000006
    mul $3, $1, $2      # ans: $3=0xffffffe2
    mult $1, $2
    mfhi $4             # ans: $4=0xffffffff
    mflo $5             # ans: $5=0xffffffe2
    multu $1, $2
    mfhi $4             # ans: $4=0x00000005
    mflo $5             # ans: $5=0xffffffe2