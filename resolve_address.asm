resolve_address:  # resolve_address ($a0=instr, $a1=pc_of_instr, $a2=label_map) => returns nothing

    lw $t0, 0($a0)      # t0 = instr.instruction_id
     
    beq $t0,5,branchaddr   # is it a branch instruction (beq=5,bne=6)
    beq $t0,6,branchaddr
    jr $ra   # return if not a branch instruction

    branchaddr:
        lw $t1, 32($a0) # t1 = instr.branch_label
        sll $t2,$t1,2   # calculate address of label_map[t1] as (label_map + 4 * instr.branch_label)
        addu $t2,$t2,$a2
        lw $t2, 0($t2)   # t2 = label_map[t1]

        addiu $t0,$a1,4  # PC+4
        subu $t0,$t2,$t0 # branchAddr = (label-(PC+4))/4
        sra  $t0,$t0,2  # make sure to use "sra" because branchAddr must be a signed number
        sw $t0, 16($a0)  # set the immediate to be branchAddr

    jr $ra
