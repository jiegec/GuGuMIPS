	.org 0x0
	.global _start
	.set noat
_start:
	ori $1, $0, 0x8000  # ans: $1=0x00008000
	ori $2, $0, 0x0800  # ans: $2=0x00000800
    lui $3, 0x1234      # ans: $3=0x12340000
    and $4, $1, $2      # ans: $4=0x00000000
    and $5, $1, $3      # ans: $5=0x00000000
    or $6, $1, $3       # ans: $6=0x12348000
    xor $7, $1, $3      # ans: $7=0x12348000
    xor $8, $1, $1      # ans: $8=0x00000000
    nor $9, $1, $1      # ans: $9=0xffff7fff
    