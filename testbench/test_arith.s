	.org 0x0
	.global _start
	.set noat
	.set noreorder
_start:
    # add/sub
	lui $1, 0x8000       # ans: $1=0x80000000
	ori $1, 0x0010       # ans: $1=0x80000010
	lui $2, 0x8000       # ans: $2=0x80000000
	ori $2, 0x0001       # ans: $2=0x80000001

	addu $3, $2, $1      # ans: $3=0x00000011
	ori $1, $1, 0x0000   # ans: $1=0x80000010
	ori $1, $1, 0xffff   # ans: $1=0x8000ffff

	sub $3, $1, $3       # ans: $3=0x8000ffee
	subu $3, $3, $2      # ans: $3=0x0000ffed

	addi $3, $3, 0x0002  # ans: $3=0x0000ffef
	ori $3, $0, 0x0000   # ans: $3=0x00000000
	addiu $3, $3, 0x8000 # ans: $3=0xffff8000

	lui $1, 0x7fff       # ans: $1=0x7fff0000
	ori $2, $0, 0x0000   # ans: $2=0x00000000
	lui $2, 0xff00       # ans: $2=0xff000000
	ori $2, $2, 0x0000   # ans: $2=0xff000000

    # TODO: CLO/CLZ

	# TODO: MUL*

    # TODO: MADD/MSUB

	# compare
	lui   $1, 0xffff     # ans: $1=0xffff0000
	slt   $2, $1, $0     # ans: $2=0x00000001
	slt   $2, $1, $1     # ans: $2=0x00000000
	sltu  $2, $1, $0     # ans: $2=0x00000000
	slti  $2, $1, 0x8001 # ans: $2=0x00000001
	sltiu $2, $1, 0x8001 # ans: $2=0x00000001
	ori   $1, $1, 0xf000 # ans: $1=0xfffff000
	sltiu $2, $1, 0x8001 # ans: $2=0x00000000