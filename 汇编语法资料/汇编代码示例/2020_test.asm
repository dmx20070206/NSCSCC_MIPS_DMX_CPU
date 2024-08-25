.data

.text

	# 循环次数 1 -> 31111
	li $t1,0
	li $t2,0x31111
	
	Loop:
	
	add $a0,$zero,$t1
	jal Calculate
	
	addi $t1,$t1,1		# $t1++
	bne $t1,$t2,Loop	# if(t1 != t2) back
	
	sw $s5,0x80400000
	
	li $v0,10
	syscall
	
	
	Calculate:
	
	li $t0,0		# 重置计数器

	Shift:
	# 如果倒数第 i 位为 0，则答案 + (2 - i)
	addi $t0,$t0,1		# 计数器
	andi $s0,$a0,1		# 监测最后一位是否为1
	beq $s0,$zero,End	# 如果 $s0 == 0 退出循环
	srl $a0,$a0,1		# $a0 >> 1
	j Shift
	
	End:
	addi $s6,$s6,2		# $s6 += 2
	sub $s6,$s6,$t0		# $s6 -= i
	add $s5,$s5,$s6		# final answer
	jr $ra
