    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0x8000   # ans: $1=0x00008000
    ori $2, $0, 0x0800   # ans: $2=0x00000800
    movn $3, $2, $0
    movn $4, $2, $1      # ans: $4=0x00000800
    movn $5, $2, $0
    movz $6, $2, $0      # ans: $6=0x00000800
    mthi $1
    mtlo $2
    mflo $3              # ans: $3=0x00000800
    mfhi $4              # ans: $4=0x00008000
    mflo $5              # ans: $5=0x00000800

    lui $1, 0xf00f       # ans: $1=0xf00f0000
    lui $2, 0x5555       # ans: $2=0x55550000
    ori $3, $2, 0xaaaa   # ans: $3=0x5555aaaa

    movz $3, $1, $3
    ori  $3, $3, 0x0000  # ans: $3=0x5555aaaa

    movz $3, $1, $0      # ans: $3=0xf00f0000

    movn $3, $2, $2      # ans: $3=0x55550000
    movn $3, $1, $0
    ori  $3, $3, 0x0000  # ans: $3=0x55550000

    lui $3, 0xffac       # ans: $3=0xffac0000
    mthi $3 
    mthi $2
    mthi $1
    mfhi $4              # ans: $4=0xf00f0000

    mtlo $1
    mtlo $2
    mtlo $3
    mflo $5              # ans: $5=0xffac0000
    mfhi $5              # ans: $5=0xf00f0000