.data

	num: .word 10000
	guess: .word 500
	answer: .word 0
	Str: .asciiz "the answer is: "
.text
	main:
	
	lw $a0,num
	lw $t0,guess
	
	jal Newton
	
	# print str
	li $v0,4
	la $a0,Str
	syscall
	
	# print num
	li $v0,1
	lw $a0,answer
	syscall
	
	# exit
	li $v0,10
	syscall
	
	###########################################
	Newton:
	# $a0 = num
	# $t1 = x(n + 1) 	$t0 = x(n)
	
	Loop:
	# $s0 = num/x
	div $s0,$a0,$t0
	# $t1 = x + num/x
	add $t1,$t0,$s0
	# $t1 = $t1/2
	div $t1,$t1,2
	
	# if x(n) == x(n + 1) => Done
	beq $t0,$t1,Done
	
	# if x(n) == x(n + 1) - 1 => Done
	addi $t2,$t1,-1
	beq $t0,$t2,Done	
	
	# x(n) = x(n + 1)
	add $t0,$zero,$t1
	j Loop	
	
	Done:
	sw $t0,answer
	jr $ra
	
	
	