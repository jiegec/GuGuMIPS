    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x8000   # ans: $1=0x00008000
    ori $2, $0, 0x0800   # ans: $2=0x00000800
    movn $3, $2, $0
    movn $4, $2, $1      # ans: $4=0x00000800
    movn $5, $2, $0
    movz $6, $2, $0      # ans: $6=0x00000800
    mthi $1
    mtlo $2
    mflo $3              # ans: $3=0x00000800
    mfhi $4              # ans: $4=0x00008000
    mflo $5              # ans: $5=0x00000800