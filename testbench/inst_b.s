	.org 0x0
	.global _start
	.set noat
_start:
	ori $1, $0, 0x8000  # ans: $1=0x00008000
    b skip
    nop
	ori $1, $0, 0x0800

skip:
	ori $1, $0, 0x0080  # ans: $1=0x00008080

    # delay slot
    b last
	ori $1, $0, 0x0001  # ans: $1=0x00008081
	ori $1, $0, 0xffff

last:
	ori $1, $0, 0x0008  # ans: $1=0x00008089
    