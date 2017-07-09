translate_instruction: # translate_instruction($a0=instr) => MIPS instruction encoded in 32 bits
    addiu $sp,$sp,12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s7, 8($sp)

    move $s0,$a0  # s0 = instr; I want to save the address of Instruction across function calls
    addu $a0,$zero,$zero  # start with result = 0x00000000; I'm just using the a0 register because I'm calling some helper functions later
    lw $t0, 0($s0)  # case statements for instr.instruction_id
    beq $t0,5,beq
    beq $t0,6,bne
    beq $t0,2,addu
    beq $t0,8,slt
    beq $t0,9,lui
    beq $t0,10,ori
    j fail_unrecognized_instr_id

# a1 = opcode, s7 = func, then jump to itype for I-type or rtype for R-type
    beq:                  
        li $a1, 0x4  
        j itype
    bne:
        li $a1, 0x5
        j itype
                
    addu:
        li $a1, 0
        li $s7, 0x21
        j rtype
    slt:
        li $a1, 0
        li $s7, 0x2A
        j rtype
    lui:
        li $a1, 0xF
        j itype
    ori:
        li $a1, 0xD
        j itype

    itype:
        jal set_opcode    # a0 = set_opcode(a0,a1)    recall a1 opcode was set in the switch cases above
        move $a0, $v0     #

        lw $a1, 8($s0)    # a0 = set_rs(a0, instr.rs)
        jal set_rs        #
        move $a0, $v0     #

        lw $a1, 12($s0)   # a0 = set_rt(a0, instr.rt)
        jal set_rt        #
        move $a0, $v0     #

        lw $a1, 16($s0)   # v0 = set_imm(a0, instr.imm)
        jal set_imm       #

        j translate_instr_done

    rtype:
        jal set_opcode  # a0 = set_opcode(a0,a1)
        move $a0, $v0   #

        lw $a1, 4($s0)  # a0 = set_rd(a0, instr.rd)
        jal set_rd      #
        move $a0, $v0   #

        lw $a1, 8($s0)  # a0 = set_rs(a0, instr.rs)
        jal set_rs      # 
        move $a0, $v0   # 

        lw $a1, 12($s0) # a0 = set_rt(a0, instr.rt)
        jal set_rt      #
        move $a0, $v0   #

        lw $a1, 24($s0) # a0 = set_shamt(a0, instr.shift_amount)
        jal set_shamt   #
        move $a0, $v0   #

        move $a1, $s7   # a0 = set_func(a0, s7)    recall s7 func was set above in switch cases
        jal set_func    #

        j translate_instr_done   # j not needed here, but I left it in case we add another case in the future
        
    translate_instr_done:
        lw $s7, 8($sp)
        lw $s0, 4($sp)
        lw $ra, 0($sp)
        addiu $sp,$sp,12
        jr $ra
### END translate_instruction ###

## Helper functions for setting different parts of the 32-bit instruction

set_opcode: # set_opcode(instr, opcode) => returns the new instruction with the bits set
	sll $t0, $a1, 26   # setup opcode [31:26]
	or $v0, $t0, $a0  # set bits 
	jr $ra

set_rd: # set_rd(instr, rd)
	sll $t0, $a1, 11   # setup rd [15:11]
	or $v0, $t0, $a0   
	jr $ra

set_rs: # set_rs(instr, rs)
	sll $t0, $a1, 21   # setup rs [25:21]
	or $v0, $t0, $a0   
	jr $ra
	
set_rt: # set_rs(instr, rt)
	sll $t0, $a1, 16   # setup rt [20:16]
	or $v0, $t0, $a0   
	jr $ra

set_shamt: # set_shamt(instr, shamt)
	sll $t0, $a1, 6  # setup shamt [10:6]
	or $v0, $t0, $a0
	jr $ra

set_func: # set_func(instr, func)
	or $v0, $a0, $a1
	jr $ra

set_imm: # set_imm(instr, imm)
	andi $a1,$a1,0xFFFF
	or $v0, $a0, $a1
	jr $ra
