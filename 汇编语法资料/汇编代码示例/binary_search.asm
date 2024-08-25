.data

	Str: .asciiz "the result is: "
	array: .word 1,3,4,5,6,7,8,9
	target: .word 5
	answer: .word -1
	
.text

	main:
	
	# $s0 = target
	lw $s0,target
	# $s1 = answer
	li $s1,-1
	
	li $a0,0
	li $a1,28
	jal binary_search
	
	li $v0,4
	la $a0,Str
	syscall
	
	li $v0,1
	div $s1,$s1,4
	add $a0,$zero,$s1
	syscall
	
	li $v0,10
	syscall
	
	#################################################################
	binary_search:
	
	# 开辟堆栈空间，存储返回地址
	addi $sp,$sp,-4
	sw $ra,0($sp)
	
	# left = $a0
	# right = $a1
	
	# $t2 分支判断寄存器
	# if left > right
	slt $t2,$a1,$a0			# $t2 = ($a1 < $a0) <=> $t2 = right < left
	bne $t2,$zero,Exit		# if right < ledt => Exit
	
	# mid = $t0
	div $a0,$a0,4
	div $a1,$a1,4
	add $t0,$a0,$a1
	div $t0,$t0,2
	
	mul $t0,$t0,4
	mul $a0,$a0,4
	mul $a1,$a1,4
	
	lw $t3,array($t0)
	
	slt $t2,$s0,$t3			# $t2 = ($s0 < array[$t0]) <=> $t2 = target < array[mid]
	bne $t2,$zero,Better_right	# if target < array[mid] => Better_right
	
	slt $t2,$t3,$s0			# $t2 = (array[$t0] < $s0) <=> $t2 = array[mid] < target 
	bne $t2,$zero,Litter_left	# if target > array[mid] => Liiter_left
	
	beq $t3,$s0,Find_answer	# if target == array[mid] => Find_answer
	
	Better_right:
	addi $a1,$t0,-4			# right = mid - 1
	jal binary_search		# search(left, mid - 1)
	
	Litter_left:
	addi $a0,$t0,4			# left = mid + 1
	jal binary_search		# search(mid + 1, right)
	
	Find_answer:
	add $s1,$zero,$t0
	
	Exit:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
	
