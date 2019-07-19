    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    li $1, 0x61
    li $2, 0xbfd00000

loop:
    sw $1, 0x0($2)
    j loop