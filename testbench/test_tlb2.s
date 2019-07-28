    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    la   $10, 0x12340000 # ans: $10=0x12340000
    # FPN1=0x0000, FPN2=0x2000
    la   $11, 0x2        # ans: $11=0x00000002
    la   $12, 0x82       # ans: $12=0x00000082
    # $10 = VPN2, $11 = FPN1, $12 = FPN2
    mtc0 $10, $10       # entry_hi
    mtc0 $11, $2        # entry_lo0
    mtc0 $12, $3        # entry_lo1
    mtc0 $0, $0         # index
    tlbwr
    nop
    nop
    nop

    tlbp
    nop
    nop
    nop
    mfc0 $1, $0         # index
    bgez $1, good
    nop
    ori $1, $0, 0x4321

good:
    ori $1, $0, 0x1234
