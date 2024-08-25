.set noreorder
.set noat
.globl __start
.section text

__start:
.text
	# begin
	li $s5,0xfffff010
	sw $s5,0x10010000
	li $s5,0xfffff012
	sw $s5,0x10010004
	li $s5,0xfffff044
	sw $s5,0x10010008
	li $s5,0xfffff222
	sw $s5,0x1001000c
	li $s5,0xfffff032
	sw $s5,0x10010010
	li $s5,0xfffff013
	sw $s5,0x10010018
	li $s5,0xfffff014
	sw $s5,0x1001001c
	li $s5,0xfffff012
	sw $s5,0x10010020
	li $s5,0xfffff013
	sw $s5,0x10010024
	li $s5,0xfffff212
	sw $s5,0x10010028
	
	
	ori $s0,$zero,0x0	# curMax = 0
	lui $t2,0x1001		# beginAddr = 0x80400000
	lui $t5,0x1004		# targetAddr = 0x80700000
	lui $s1,0x000c		# sumTime = 0x000c0000
	ori $s3,$zero,0x0	# curTime = 0x0
	
	Loop:
	beq $s1,$s3,Exit	# Exit
	ori $zero,$zero,0 	# nop
	
	# take curNum
	lw $t0,0($t2)		# take num from memory
	
	# inc
	addiu $t2,$t2,0x4	# index++
	addiu $s3,$s3,0x1
	
	# update max
	sltu $s2,$s0,$t0	# if max < array[i]
	beq $s2,$zero,Loop	# if nax >= array[i] => goto loop
	ori $zero,$zero,0 	# nop
	addu $s0,$zero,$t0	# max = array[i]
	
	j Loop
	
	Exit:
	sw $s0,0($t5)		# answer
	# jr $ra
    	ori $zero,$zero,0 	# nop
    	
    	li $v0,10
    	syscall
