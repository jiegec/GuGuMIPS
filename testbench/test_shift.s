	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
    lui $1, 0x8000       # ans: $1=0x80000000
    ori $1, $1, 0x8000   # ans: $1=0x80008000
    sll $3, $1, 1        # ans: $3=0x00010000
    srl $3, $1, 1        # ans: $3=0x40004000
    sra $3, $1, 1        # ans: $3=0xc0004000

    ori $2, $0, 0x1      # ans: $2=0x00000001
    sllv $3, $1, $2      # ans: $3=0x00010000
    srlv $3, $1, $2      # ans: $3=0x40004000
    srav $3, $1, $2      # ans: $3=0xc0004000