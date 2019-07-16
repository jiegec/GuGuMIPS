    .org 0x0
    .global _start
    .set noat
    .set noreorder
_start:
    lui $1, 0xffff     # ans: $1=0xffff0000

    # unaligned load
    lw $1, 0x1($0)
    lw $1, 0x2($0)
    lw $1, 0x3($0)
    lh $1, 0x1($0)
    lh $1, 0x3($0)

    # unaligned store
    sw $1, 0x1($0)
    sw $1, 0x2($0)
    sw $1, 0x3($0)
    sh $1, 0x1($0)
    sh $1, 0x3($0)

    ori $1, $1, 0xffff  # ans: $1=0xffffffff

    # unaligned instruction fetch
    mtc0 $1, $14
    eret

    ori $1, $1, 0xffff  # ans: $1=0x0000ffff

    .org 0x380
    # add epc
    mfc0 $30, $14          # skip
    addi $30, $30, 0x4     # skip
    mtc0 $30, $14
    # read exc code
    mfc0 $29, $13          # skip
    andi $29, $29, 0x007c  # skip
    srl $29, $29, 2        # ans: $29=ExcCode
    # read bad vaddr
    mfc0 $28, $8           # ans: $28=BadVAddr
    beq $28, $1, end
    nop
    eret
    
end:
    ori $3, $0, 0x4321