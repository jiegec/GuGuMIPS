    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x1234      # ans: $1=0x00001234
    mtc0 $1, $11, 0x0       # write to compare
    mfc0 $2, $11, 0x0       # ans: $2=0x00001234
    mfc0 $3, $11, 0x0       # ans: $3=0x00001234
    