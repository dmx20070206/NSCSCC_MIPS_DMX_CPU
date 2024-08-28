.set noreorder
.set noat
.globl __start
.section text

__start:
.text
	# begin
	ori $t1,$zero,0x0 	# offset = 0
	ori $s0,$zero,0x0	# curMax = 0
	lui $t2,0x8050		# beginAddr = 0x80400000
	lui $t5,0x8070		# targetAddr = 0x80700000
	lui $s1,0x0002		# sumTime = 0x000c0000
	ori $s3,$zero,0x0	# curTime = 0x0
	
	Loop:
	beq $s1,$s3,Exit	# Exit
	ori $zero,$zero,0 	# nop
	
	# take curNum
	addu $t3,$t2,$t1	# curAddr
	lw $t0,0($t3)		# take num from memory
	
	# inc
	addiu $t1,$t1,0x4	# index++
	addiu $s3,$s3,0x1
	
	# update max
	sltu $s2,$s0,$t0	# if max < array[i]
	beq $s2,$zero,Loop	# if nax >= array[i] => goto loop
	ori $zero,$zero,0 	# nop
	addu $s0,$zero,$t0	# max = array[i]
	
	j Loop
	
	Exit:
	sw $s0,0($t5)		# answer
	jr $ra
    	ori $zero,$zero,0 	# nop
