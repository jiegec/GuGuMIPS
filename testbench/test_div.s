    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    ori $1, $0, 0xffff
    sll $1, $1, 16
    ori $1, $1, 0xfff1
    ori $2, $0, 0x11
    div $zero, $1, $2
    mfhi $3
    mflo $4
    divu $zero, $1, $2
    mfhi $3
    mflo $4
    div $zero, $2, $1
    mfhi $3
    mflo $4

    b delayslot
    div $zero, $1, $2
    ori $1, $0, 0xffff

delayslot:
    mfhi $3
    mflo $4
