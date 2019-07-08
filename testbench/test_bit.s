    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x8000   # ans: $1=0x00008000
    ori $2, $0, 0x0800   # ans: $2=0x00000800
    lui $3, 0x1234       # ans: $3=0x12340000
    and $4, $1, $2       # ans: $4=0x00000000
    and $5, $1, $3       # ans: $5=0x00000000
    or $6, $1, $3        # ans: $6=0x12348000
    xor $7, $1, $3       # ans: $7=0x12348000
    xor $8, $1, $1       # ans: $8=0x00000000
    nor $9, $1, $1       # ans: $9=0xffff7fff
    andi $10, $1, 0x8888 # ans: $10=0x00008000
    xori $11, $1, 0x8888 # ans: $11=0x00000888
    lui $1, 0xf00f       # ans: $1=0xf00f0000
    ori $2, $1, 0xf000   # ans: $2=0xf00ff000
    and $3, $1, $2       # ans: $3=0xf00f0000
    xor $4, $1, $2       # ans: $4=0x0000f000
    nor $5, $3, $4       # ans: $5=0x0ff00fff
    or  $6, $5, $4       # ans: $6=0x0ff0ffff
    andi $6, $6, 0xff00  # ans: $6=0x0000ff00
    xori $6, $6, 0x0f0f  # ans: $6=0x0000f00f
    