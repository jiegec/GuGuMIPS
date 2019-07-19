    .org 0x0
    .global __start
    .set noat
    .set noreorder
__start:
    li $1, 0x61
    li $2, 0xbfd00004

loop:
    sw $1, 0x0($2)
    j loop


    .org 0x380
    j __start
