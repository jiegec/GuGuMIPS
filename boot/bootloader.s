    .org 0x0
    .global __start
    .set noat
    .set noreorder
__start:
    # NO BOOT FAIL
    li $a0, 0x4E
    jal WRITESERIAL
    nop
    li $a0, 0x4F
    jal WRITESERIAL
    nop
    li $a0, 0x20
    jal WRITESERIAL
    nop
    li $a0, 0x42
    jal WRITESERIAL
    nop
    li $a0, 0x4F
    jal WRITESERIAL
    nop
    li $a0, 0x4F
    jal WRITESERIAL
    nop
    li $a0, 0x54
    jal WRITESERIAL
    nop
    li $a0, 0x20
    jal WRITESERIAL
    nop
    li $a0, 0x46
    jal WRITESERIAL
    nop
    li $a0, 0x41
    jal WRITESERIAL
    nop
    li $a0, 0x49
    jal WRITESERIAL
    nop
    li $a0, 0x4C
    jal WRITESERIAL
    nop
    li $a0, 0x0D
    jal WRITESERIAL
    nop
    li $a0, 0x0A
    jal WRITESERIAL
    nop

read_length:
    jal READSERIAL
    nop
    or $s0, $zero, $v0
    andi $s0, $s0, 0xFF
    jal READSERIAL
    nop
    or $s1, $zero, $v0
    andi $s1, $s1, 0xFF
    jal READSERIAL
    nop
    or $s2, $zero, $v0
    andi $s2, $s2, 0xFF
    jal READSERIAL
    nop
    or $s3, $zero, $v0
    andi $s3, $s3, 0xFF

    or $s7, $zero, $s3
    sll $s7, $s7, 8
    or $s7, $s7, $s2
    sll $s7, $s7, 8
    or $s7, $s7, $s1
    sll $s7, $s7, 8
    or $s7, $s7, $s0

    # LEN
    li $a0, 0x4C
    jal WRITESERIAL
    nop
    li $a0, 0x45
    jal WRITESERIAL
    nop
    li $a0, 0x4E
    jal WRITESERIAL
    nop
    li $a0, 0x0D
    jal WRITESERIAL
    nop
    li $a0, 0x0A
    jal WRITESERIAL
    nop

read_data:
    li $s6, 0x80000000
    add $s6, $s6, $s7
    li $s5, 0x80000000

read_data_loop:
    jal READSERIAL
    nop
    sb $v0, 0($s5)
    addi $s5, $s5, 1
    bne $s5, $s6, read_data_loop
    nop

boot:
    # BOOT
    li $a0, 0x42
    jal WRITESERIAL
    nop
    li $a0, 0x4F
    jal WRITESERIAL
    nop
    li $a0, 0x4F
    jal WRITESERIAL
    nop
    li $a0, 0x54
    jal WRITESERIAL
    nop
    li $a0, 0x0D
    jal WRITESERIAL
    nop
    li $a0, 0x0A
    jal WRITESERIAL
    nop
    li $s5, 0x80000000
    jr $s5
    nop

halt:
    li $a0, 0x48
    jal WRITESERIAL
    nop
    li $a0, 0x41
    jal WRITESERIAL
    nop
    li $a0, 0x4C
    jal WRITESERIAL
    nop
    li $a0, 0x54
    jal WRITESERIAL
    nop
    li $a0, 0x0D
    jal WRITESERIAL
    nop
    li $a0, 0x0A

end:
    j end
    nop

WRITESERIAL: # arg: $a0
    li $t1, 0xBFD00008
.TESTW:
    lb $t0, 0($t1)
    andi $t0, $t0, 0x0008
    beq $t0, $zero, .WSERIAL
    nop
    j .TESTW
    nop
.WSERIAL:
    li $t1, 0xBFD00004
    sb $a0, 0($t1)
    jr $ra
    nop

READSERIAL: # ret: $v0
    li $t1, 0xBFD00008
.TESTR:
    lb $t0, 0($t1)
    andi $t0, $t0, 0x0001
    bne $t0, $zero, .RSERIAL
    nop
    j .TESTR
    nop
.RSERIAL:
    li $t1, 0xBFD00000
    lb $v0, 0($t1)
    jr $ra
    nop

    .org 0x380
    j halt