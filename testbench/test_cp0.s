    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x1234      # ans: $1=0x00001234
    mtc0 $1, $11, 0x0       # write to compare
    mfc0 $2, $11, 0x0       # ans: $2=0x00001234
    mfc0 $3, $11, 0x0       # ans: $3=0x00001234
    
    lui $1, 0x8000          # ans: $1=0x80000000
    lui $2, 0xbfc0          # ans: $2=0xbfc00000
    ori $2, $2, 0x0200      # ans: $2=0xbfc00200
    sw $2, 0($1)            # ans: [0x0,4]=0xbfc00200
    lw $3, 0($1)            # ans: $3=0xbfc00200
    lw $1, 0($1)            # ans: $1=0xbfc00200
    mtc0 $3, $14            # set epc
    eret
    lui $3, 0x4321

    .org 0x200
    lui $3, 0x1234          # ans: $3=0x12340000
