    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $1, 0x9999  # ans: $1=0x00009999
    andi $1, $1, 0x8999  # ans: $1=0x00008999
    andi $2, $1, 0xffff  # ans: $2=0x00008999
    andi $1, $1, 0x8899  # ans: $1=0x00008899
    andi $1, $1, 0x8889  # ans: $1=0x00008889
    andi $1, $1, 0x8888  # ans: $1=0x00008888
    andi $1, $1, 0x0888  # ans: $1=0x00000888
    andi $1, $1, 0x0800  # ans: $1=0x00000800
    andi $1, $1, 0x0000  # ans: $1=0x00000000