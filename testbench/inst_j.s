    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x8000  # ans: $1=0x00008000
    j skip
    nop
    ori $1, $1, 0x0800

skip:
    ori $1, $1, 0x0080  # ans: $1=0x00008080

    # delay slot
    j last
    ori $1, $1, 0x0001  # ans: $1=0x00008081
    ori $1, $1, 0xffff

last:
    ori $1, $1, 0x0008  # ans: $1=0x00008089
    
    # delay slot
    j jump
    ori $1, $0, 0x0001  # ans: $1=0x00000001
    ori $1, $0, 0x0002

jump:
    j jump2
    ori $1, $0, 0x0003  # ans: $1=0x00000003
    ori $1, $0, 0x0004

jump2:
    ori $1, $0, 0x0005  # ans: $1=0x00000005