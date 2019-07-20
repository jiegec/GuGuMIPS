    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x007F   # ans: $1=0x0000007f
    seb $2, $1           # ans: $2=0x0000007f
    seh $2, $1           # ans: $2=0x0000007f
    ori $1, $0, 0x0080   # ans: $1=0x00000080
    seb $2, $1           # ans: $2=0xffffff80
    seh $2, $1           # ans: $2=0x00000080
    ori $1, $0, 0x807F   # ans: $1=0x0000807f
    seb $2, $1           # ans: $2=0x0000007f
    seh $2, $1           # ans: $2=0xffff807f
    