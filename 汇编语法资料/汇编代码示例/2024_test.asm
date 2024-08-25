.set noreorder
.set noat
.globl __start
.section text

__start:
.text
	li $s0,0		# 当前的最大值
	li $t2,0x80400000	# 存储起始地址
	li $s1,0x300000		# 存储遍历次数
	li $s3,0x0		# 存储当前遍历次数
	
	Loop:
	beq $s1,$s3,Exit	# 如果遍历完成，退出循环
	ori $zero,$zero,0 	# nop
	
	# 取出当前元素
	lw $t0,($t2)		# 遍历当前元素
	
	# 偏移值递增
	addi $s3,$s3,1
	addi $t2,$t2,1
	
	# 如果更大则更新答案
	slt $s2,$s0,$t0		# if max < array[i]
	beq $s2,$zero,Loop	# if max >= array[i] => goto loop
	ori $zero,$zero,0 	# nop
	add $s0,$zero,$t0	# max = array[i]
	
	j Loop
	
	Exit:
	sw $s0,0x80700000	# 存储答案
	jr $ra
    	ori $zero,$zero,0 	# nop
