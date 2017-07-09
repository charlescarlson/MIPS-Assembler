mal_to_tal:  # mal_to_tal($a0=instr, $a1=buffer) => num instrs added
	addiu $sp,$sp,-8  # save $ra and $s7
	sw $ra, 0($sp)    #
	sw $s7, 4($sp)    #
	
	li $s7, 0      # s7 is a counter for number of instructions added
	lw $t0, 0($a0) # t0 = instr.instruction_id
	blt $t0,100,maybe_not_pseudo # not 100 blt or 101 bge
	
definitely_pseudo:
	# must be blt or bge
   	# slt
   	li $t0,8        #instruction_id
   	sw $t0, 0($a1) 
   	li $t0,1        #rd='$at'
   	sw $t0,4($a1)  
   	lw $t0,8($a0)   #rs=rs
   	sw $t0,8($a1)
   	lw $t0,12($a0)   #rt=rt
   	sw $t0,12($a1)
   	li $t0,0        #imm,ja,shift,branchlabel=0
   	sw $t0,16($a1)
   	sw $t0,20($a1)
   	sw $t0,24($a1)
   	sw $t0,32($a1)
   	lw $t0,28($a0)  #label_id of first TAL must be label_id of first MAL
   	sw $t0,28($a1)
   	addiu $a1,$a1,36  #increment buffer pointer
   	addiu $s7,$s7,1
   beq $t0,100,mal_tal_blt
   beq $t0,101,mal_tal_bge
   mal_tal_blt:
   	# bne
   	li $t0,6   #instruction_id=bne
   	j mal_tal_both_blt_bge
   mal_tal_bge:
   	li $t0,7   #instruction_id=beq
   	j mal_tal_both_blt_bge
   	
   mal_tal_both_blt_bge:
   	sw $t0, 0($a1)
   	li $t0,0    #rd,imm,ja,shift,label_id=0
   	sw $t0,4($a1)
   	sw $t0,16($a1)
   	sw $t0,20($a1)
   	sw $t0,24($a1)
   	sw $t0,28($a1)
   	li $t0, 1 #rs='$at'
   	sw $t0,8($a1) 
   	li $t0, 0 #rt='$zero'
   	sw $t0,12($a1) 
   	lw $t0,32($a0)  # branch_label TAL=branch_label MAL
   	sw $t0,32($a1) 
   	addiu $s7,$s7,1   #increment instruction counter
	j done_translating


maybe_not_pseudo:
	lw $t0, 16($a0)   # >16bit?    -2^15 <= imm <= (2^15)-1
	blt $t0, -32768, imm_too_large
	bge $t0, 32768, imm_too_large
	# imm is ok
	jal copy_instruction  # copy instrution into buffer ($a0, $a1 already set)
	addiu $s7,$s7,1       # increment instruction counter
	j done_translating    # finished
imm_too_large:
	# Generate three instructions: lui,ori followed by either "addu" or "or"
	
	#lui
	li $t0,9
	sw $t0, 0($a1)   # instruction_id = 9
	li $t0,0         # set unused fields to 0
	sw $t0,4($a1)   
	sw $t0,8($a1)
	sw $t0,20($a1)
	sw $t0,24($a1)
	sw $t0,32($a1)
	li $t0,1          # rt = $at
	sw $t0,12($a1)
	lw $t0, 16($a0)   # get upper immediate by...
	andi $t0,$t0,0xFFFF0000 # mask out the bottom 16 bits
	srl $t0,$t0,16 # shift right by 16 bits
	sw $t0,16($a1)
	lw $t0, 28($a0)   # lui is first generated instruction so take the label_id
	sw $t0, 28($a1)
	
	addiu $a1,$a1,36  # increment buffer pointer
	addiu $s7,$s7,1   # increment number of instructions
	
	#ori
	li $t0,10
	sw $t0,0($a1)    # instruction_id=10

	li $t0,0         # set unused fields to 0
	sw $t0,4($a1)
	sw $t0,20($a1)
	sw $t0,24($a1)
	sw $t0,32($a1)
	sw $t0,28($a1)
	li $t0,1         # rs = $at
	sw $t0,8($a1)
	sw $t0,12($a1)    # rt = $at
	
	addiu $a1,$a1,36  # increment buffer pointer
	addiu $s7,$s7,1   # increment number of instructions

	lw $t0, 0($a0)    # finally, figure out if we need to generate addu OR or
	                   # addiu -> addu, ori -> or
	beq $t0,1,generate_addu
	beq $t0,10,generate_or
	# should not reach here!
	
generate_addu:
	li $t0, 2
	sw $t0, 0($a1)
	j generate_rest_of_instr
generate_or:
	li $t0, 3
	sw $t0, 0($a1)
	j generate_rest_of_instr   # this jump not necessary, but I put it here in case we ever want to add more cases
	
generate_rest_of_instr:   
        lw $t0, 12($a0)     # rd = addiu's/ori's rt
        sw $t0, 4($a1)

	lw $t0, 8($a0) # rs = addiu's/ori's rs
	sw $t0, 8($a1)
	
	li $t0, 1    # rt = $at
	sw $t0, 12($a1)

	li $t0, 0        # set unused fields to 0
	sw $t0, 16($a1)
	sw $t0, 20($a1)
	sw $t0, 24($a1)
	sw $t0, 28($a1)
	sw $t0, 32($a1)
	

	addiu $s7,$s7,1  # increment number of instructions
	j done_translating

done_translating:
	move $v0,$s7
	
	lw $ra, 0($sp)
	lw $s7, 4($sp)
	addiu $sp,$sp,8
	jr $ra
###### End of mal_to_tal #########
	
	

memcpy:  # memcpy($a0=dest,$a1=src,$a2=n) => returns nothing
# uses recursion
	addiu $sp,$sp,-4    # save return address to stack
	sw $ra, 0($sp)
	
	beq $a2,$zero,memcpy_done  # n == 0?
	lb $t0,0($a1)
	sb $t0,0($a0)
	addiu $a0,$a0,1    # call memcpy(dest+1,src+1,n-1)
	addiu $a1,$a1,1
	addiu $a2,$a2,-1
	jal memcpy
memcpy_done:# handle the base case
	lw $ra, 0($sp)    # restore return address from stack
	addiu $sp,$sp,4
	jr $ra
# END OF memcpy
	
copy_instruction: #copy_instruction($a0=src,$a1=dest)
	addiu $sp,$sp,-4
	sw $ra,0($sp)
	
	move $t0,$a1    # call memcpy(dest,src,36)
	move $a1,$a0
	move $a0,$t0
	li $a2, 36
	jal memcpy
	
	lw $ra,0($sp)
	addiu $sp,$sp,4
	jr $ra
# END OF copy_instruction
