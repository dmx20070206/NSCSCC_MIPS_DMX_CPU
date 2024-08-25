.data
	a: .word 20
	b: .word 1
	answer: .word -1
	Str: .asciiz "the answer is: "

.text

	lw $t0,a
	lw $t1,b
	
	Loop:
	slt $s0,$t0,$t1		# $s0 = $t0 < $t1 <=> a < b
	bne $s0,$zero,Exit
	
	# while(a >= b)
	sub $t0,$t0,$t1
	j Loop
	
	Exit:
	sw $t0,answer
	
	li $v0,4
	la $a0,Str
	syscall
	
	li $v0,1
	lw $a0,answer
	syscall
	
	li $v0,10
	syscall
