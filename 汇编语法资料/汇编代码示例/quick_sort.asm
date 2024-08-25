	.data
	
	array: .word 4,9,9,0,7,6,2,8
	Space: .asciiz " "
	Str: .ascii "The Result is:\n"
	
	.text
	

	
.globl main
	main:

	# quick_sort(0, 28)
	li $a0,0
	li $a1,28
	jal quick_sort
	
	# print Str
	jal print_str
	
	
	PrintArray:
	# print the array
	li $t0,0
	li $t1,32
	Print:
	jal print_int 		# print num
	addi $t0,$t0,4		# index++
	
	# print " "
	jal print_space
	
	bne $t0,$t1,Print
	
	# exit
	li $v0,10
	li $a0,0
	syscall
	
	##################################################################################
	quick_sort:			# 参数：start，end  按照要求会分别保存到寄存器 $a0 和 $a1 中
	slt $t3,$a1,$a0		# $t3 = ($a1 < $a0) <=> $t3 = (end < start)
	bne $t3,$zero,Exit	# if $t3 == 1 => 跳转至 Exit 标签（递归终止条件成立）
	
	addi $sp,$sp,-12	# 在堆栈上开辟 12字节 的大小
				#  _____________
	sw $a0,8($sp)		# |  a0(start)  |
	sw $a1,4($sp)		# |  a1(end)    |
	sw $ra,0($sp)		# |  ra         |  <- rsp
	
	addi $t0,$a0,0		# $t0 = $a0 = start
	addi $t1,$a1,0		# $t1 = $a1 = end
	
	lw $t2,array($t0) 	# $t2 = array[start]	
	addi $t0,$t0,4

	# $t0 = left  $t1 = right
	Loop:
	
	# if(left > right) break;
	slt $t3,$t1,$t0		# $t3 = $t1 < $t0 <=> $t3 = right < left
	bne $t3,$zero,End	# if $t3 == 1 (left > right) => 跳转至 End 标签（退出循环）
	
	lw $s0,array($t0)	# $s0 = array[left]
	lw $s1,array($t1)	# $s1 = array[right]

	slt $t3,$t2,$s0		# $t3 = $t2 < $s0 <=> $t3 = pivot < array[left]
	beq $t3,$zero,AddLeft	# if $t3 == 0 => 跳转至 AddLeft 标签
		
	slt $t3,$s1,$t2		# $t3 = $s1 < $t2 <=> $t3 = array[right] < pivot
	beq $t3,$zero,SubRight # if $t3 == 0 => 跳转至 SubRight 标签
	
	j Swap
	
	# if(array[left] <= pivot) => AddLeft
	AddLeft:
	addi $t0,$t0,4		# left++
	j Loop
		
	# if(array[right] >= pivot) => MinusRight
	SubRight:
	addi $t1,$t1,-4		# right--
	j Loop
	
	# array[right] <=> array[left]
	# left++ right--
	Swap:
	sw $s1,array($t0)
	sw $s0,array($t1)
	addi $t0,$t0,4
	addi $t1,$t1,-4	
	j Loop
	
	End:
	lw $s0,array($t0)	# $s0 = array[left]
	lw $s1,array($t1)	# $s1 = array[right]
	
	# array[right] <=> array[start]
	sw $t2,array($t1)
	lw $t4,8($sp)
	sw $s1,array($t4)

	# quick_sort(arr, start, right - 1);
	lw $a0,8($sp)
	lw $a1,4($sp)
	addi $a1,$t1,-4
	jal quick_sort
	
    	# quick_sort(arr, right + 1, end);
	lw $a0,8($sp)
	lw $a1,4($sp)
	addi $a0,$t1,4
	jal quick_sort
		
	# return rsp
	lw $a0,8($sp)
	lw $a1,4($sp)
	lw $ra,0($sp)
	addi $sp,$sp,12

	Exit:
	jr $ra			# jump to return address
	
	##################################################################################
	# print Str
	print_str:
	la $a0,Str
	li $v0,4
	syscall
	jr $ra
	
	##################################################################################
	# print Space
	print_space:
	la $a0,Space
	li $v0,4
	syscall
	jr $ra
	
	##################################################################################
	# print int
	print_int:
	lw $a0,array($t0)
	li $v0,1
	syscall
	jr $ra

