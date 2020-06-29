#when a direction-changing command is executed, a path segment is created, when the next command is executed, this path segment ends, a new one is created
#-> vi tri ket thuc cua canh truoc la vi tri bat dau cua canh sau
.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xFFFF0014
.eqv KEY_CODE 0xFFFF0004 	# ASCII code from keyboard, 1 byte
.eqv KEY_READY 0xFFFF0000 	# =1 if has a new keycode ?
 				# Auto clear after lw
# Marsbot's Ports
.eqv HEADING 0xffff8010 # Integer: An angle between 0 and 359
 			# 0 : North (up)
 			# 90: East (right)
			# 180: South (down)
			# 270: West (left)
.eqv MOVING 0xffff8050 # Boolean: whether or not to move
.eqv LEAVETRACK 0xffff8020 # Boolean (0 or non-0):
 			# whether or not to leave a track
.eqv WHEREX 0xffff8030 # Integer: Current x-location of MarsBot
.eqv WHEREY 0xffff8040 # Integer: Current y-location of MarsBot

.data
#Control code
	go_cmd: .asciiz "1b4"
	stop_cmd: .asciiz "c68"
	left_cmd: .asciiz "444"
	right_cmd: .asciiz "666"
	leave_track_cmd: .asciiz "dad"
	untrack_cmd: .asciiz "cbc"
	back_cmd: .asciiz "999"
	WRONG_CODE_MSG: .asciiz "Wrong control code!"
#-------------------------------------------------------------------------------
	inputCode: .space 50		#input sring generated from the DigitalLabSim's keystrokes
	inputCodeLength: .word 0
	direction: .word 0
#---------------------------------------------------------
# path: stores the path segments of the marsbot
# Each segment (edge - canh) is a struture of 3 numbers: X coordinate, Y coordinate, and direction, each is a 'word' kind of data type
# -> {x, y, z} -> 12 bytes
# the first path segment is (0, 0, 0) (skipped = 0 0 0)
#--------------------------------------------------------- 
	path: .space 600
	totalPathSize: .word 12		#bytes, because the first is (0,0,0)
	
.text
main:
#enable interrupt for DigitalLabSim
	li $t0, IN_ADDRESS_HEXA_KEYBOARD
	li $t1, 0x80				
	sb $t1, 0($t0)
	
#MMIO:	
	li $k0, KEY_CODE
	li $k1, KEY_READY #ready -> 1, not ready -> 0
	
	#polling for MMIO keystroke
polling_loop: 
	nop
	Wait_for_keystroke:
	lw $t2, 0($k1)
	beq $t2, $zero, Wait_for_keystroke #not ready
	nop
	beq $t2, $zero, Wait_for_keystroke
	
	#->
	
	#Read Key
	lw $t3, 0($k0)
	beq $t3, 127, reset_state #'Del' pressed
	bne $t3, 10, polling_loop #'Enter' not pressed
	nop
	bne $t3, 10, polling_loop
	
#-------------------------------------------------------
# check_InputCode: check if the InputCode is in the available codes or not then decide what to do next
#-------------------------------------------------------
check_inputCode:
	la $t4, inputCodeLength
	lw $t4, 0($t4)
	bne $t4, 3, display_error_msg #Length code != 3

	la $s0, go_cmd
	jal check_if_equal_inputCode
	beq $s1, 1, go
	
	la $s0, stop_cmd
	jal check_if_equal_inputCode
	beq $s1, 1, stop
	
	la $s0, left_cmd
	jal check_if_equal_inputCode
	beq $s1, 1, goLeft
	
	la $s0, right_cmd
	jal check_if_equal_inputCode
	beq $s1, 1, goRight
	
	la $s0, leave_track_cmd
	jal check_if_equal_inputCode
	beq $s1, 1, track
	
	la $s0, untrack_cmd
	jal check_if_equal_inputCode
	beq $s1, 1, untrack
	
	la $s0, back_cmd
	jal check_if_equal_inputCode
	beq $s1, 1, goBack
	
	beq $s1, 0, display_error_msg
print_inputCode:
	li $v0, 4
	la $a0, inputCode
	syscall
	nop

reset_state: #continue
	jal clear_inputCode
	nop
	j polling_loop
	nop
	j polling_loop
endmain:
#-----------------------------------------------------------
# PROC storePath:, store path of marsbot to path variable
# params[in]: 	direction variable
#		totalPathSize variable
# params[out]:
#-----------------------------------------------------------	
storePath:
	#backup
	addi $sp,$sp,4
	sw $t1, 0($sp)
	addi $sp,$sp,4
	sw $t2, 0($sp)
	addi $sp,$sp,4
	sw $t3, 0($sp)
	addi $sp,$sp,4
	sw $t4, 0($sp)
	addi $sp,$sp,4
	sw $s1, 0($sp)
	addi $sp,$sp,4
	sw $s2, 0($sp)
	addi $sp,$sp,4
	sw $s3, 0($sp)
	addi $sp,$sp,4
	sw $s4, 0($sp)
	
	#processing
	li $t1, WHEREX
	lw $s1, 0($t1)		#s1 = x	#prepare to store current x
	
	li $t2, WHEREY	
	lw $s2, 0($t2)		#s2 = y	#prepare to store current y
	
	la $s4, direction
	lw $s4, 0($s4)		#s4 = direction #prepare to store current direction
	
	la $t3, totalPathSize
	lw $s3, 0($t3)		#$s3 = totalPathSize (dv: byte)
	
	la $t4, path
	add $t4, $t4, $s3	#position to store
	
	sw $s1, 0($t4)		#store x
	sw $s2, 4($t4)		#store y
	sw $s4, 8($t4)		#store heading
	
	addi $s3, $s3, 12	#update totalPathSize
				#12 = 3 (word) x 4 (bytes)
	sw $s3, 0($t3)
	
	#restore
	lw $s4, 0($sp)
	addi $sp,$sp,-4
	lw $s3, 0($sp)
	addi $sp,$sp,-4
	lw $s2, 0($sp)
	addi $sp,$sp,-4
	lw $s1, 0($sp)
	addi $sp,$sp,-4
	lw $t4, 0($sp)
	addi $sp,$sp,-4
	lw $t3, 0($sp)
	addi $sp,$sp,-4
	lw $t2, 0($sp)
	addi $sp,$sp,-4
	lw $t1, 0($sp)
	addi $sp,$sp,-4
	
	jr $ra
	nop
	jr $ra
#-----------------------------------------------------------
# PROC goBack: command marsbot to go back
# params[in]: 	path, totalPathSize
# params[out]:
#-----------------------------------------------------------	
goBack:	la $s7, path
	la $s5, totalPathSize
	lw $s5, 0($s5)
	add $s7, $s7, $s5
begin:	addi $s5, $s5, -12 	#decrease totalPathSize, remove the last path segment
	
	addi $s7, $s7, -12	#Load the last path segment's information about x, y, direction
	lw $s6, 8($s7)		#Load byte 4-8, load the direction of the last segment
	addi $s6, $s6, 180	#calculate its opposite direction
	#sub $s6, $zero, $s6
	
	la $t8, direction	#load the reverted direction to $t8 and branch to ROTATE to make the Marsbot go in reverse
	sw $s6, 0($t8)
	jal ROTATE		#Revert the direction is done here
				#After finish reverting
go_to_first_point_of_edge:	
	lw $t9, 0($s7)		#Load the X coordinate of the last path segment
	li $t8, WHEREX		#Port WHEREX is chosen
	lw $t8, 0($t8)		#->$t8: the X coordinate of the marsbot at the moment

	bne $t8, $t9, go_to_first_point_of_edge
	
	#addi $s4, $t9, 20
	
	#bgt $t8, $s4, go_to_first_point_of_edge
	#nop
	#bgt $t8, $s4, go_to_first_point_of_edge
	#addi $s4, $t9, -20
	#blt $t8, $s4, go_to_first_point_of_edge
	#nop
	#blt $t8, $s4, go_to_first_point_of_edge
	
	lw $t9, 4($s7)		#Load the Y coordinate of the last path segment
	li $t8, WHEREY		#Port WHEREY is chosen
	lw $t8, 0($t8)		#->$t8: the Y coordinate of the marsbot at the moment
	
	bne $t8, $t9, go_to_first_point_of_edge
	
	#addi $s4, $t9, 20
	#bgt $t8, $s4, go_to_first_point_of_edge
	#nop
	#bgt $t8, $s4, go_to_first_point_of_edge
	#addi $s4, $t9, -20
	#blt $t8, $s4, go_to_first_point_of_edge
	#nop
	#blt $t8, $s4, go_to_first_point_of_edge
	
	beq $s5, 0, finish	#pathStack empty -> Done
	#nop
	#beq $s5, 0, finish
	
	j begin
	#nop
	#j goBack
	
finish:	jal STOP
	la $t8, direction
	add $s6, $zero, $zero
	sw $s6, 0($t8)		#update heading
	la $t8, totalPathSize
	sw $s5, 0($t8)		#update totalPathSize = 0
	jal ROTATE
	j print_inputCode

#-----------------------------------------------------------
# track: command marsbot to track and print control code
#-----------------------------------------------------------	
track: 	jal TRACK
	j print_inputCode
#-----------------------------------------------------------
# untrack: command marsbot to untrack and print control code
# param[in] none
#-----------------------------------------------------------	
untrack: jal UNTRACK
	 j print_inputCode
#-----------------------------------------------------------
# go, command marsbot to go and print control code
#-----------------------------------------------------------	
go: 	
	jal GO
	j print_inputCode
#-----------------------------------------------------------
# stop procedure, control marsbot to stop and print control code
# params[in]:
#-----------------------------------------------------------	
stop: 	jal STOP
	j print_inputCode
#-----------------------------------------------------------
# PROC goRight, control marsbot to go left and print control code
# param[in] 
# param[out] 
#-----------------------------------------------------------	
goRight:
	#backup
	addi $sp,$sp,4
	sw $s5, 0($sp)
	addi $sp,$sp,4
	sw $s6, 0($sp)
	#restore
	la $s5, direction
	lw $s6, 0($s5)	#$s6 is heading at now
	addi $s6, $s6, 90 #increase heading by 90*
	sw $s6, 0($s5) # update direction
	#restore
	lw $s6, 0($sp)
	addi $sp,$sp,-4
	lw $s5, 0($sp)
	addi $sp,$sp,-4
	
	jal storePath
	jal ROTATE
	j print_inputCode	
#-----------------------------------------------------------
# PROC goLeft, control marsbot to go left and print control code
# param[in] 
# param[out] 
#-----------------------------------------------------------	
goLeft:	
	#backup
	addi $sp,$sp,4
	sw $s5, 0($sp)
	addi $sp,$sp,4
	sw $s6, 0($sp)
	#processing
	la $s5, direction
	lw $s6, 0($s5)	#$s6 is heading at now
	addi $s6, $s6, -90 #increase heading by 90*
	sw $s6, 0($s5) # update direction
	#restore
	lw $s6, 0($sp)
	addi $sp,$sp,-4
	lw $s5, 0($sp)
	addi $sp,$sp,-4
	
	jal storePath
	jal ROTATE
	j print_inputCode				
#-----------------------------------------------------------
# PROC clearInputCode: remove inputCode string
#				inputCode = "", makes all char of inputCode become '\0'
# params[in]:
# params[out]:
#-----------------------------------------------------------						
clear_inputCode:
	#backup
	addi $sp,$sp,4
	sw $t1, 0($sp)
	addi $sp,$sp,4
	sw $t2, 0($sp)
	addi $sp,$sp,4
	sw $s1, 0($sp)
	addi $sp,$sp,4
	sw $t3, 0($sp)
	addi $sp,$sp,4
	sw $s2, 0($sp)
	
	#processing
	la $s2, inputCodeLength
	lw $t3, 0($s2)					#$t3 = inputCodeLength
	addi $t1, $zero, -1				#$t1 = -1 = i
	addi $t2, $zero, 0				#$t2 = '\0'
	la $s1, inputCode
	addi $s1, $s1, -1
	for_loop_to_remove:
		addi $t1, $t1, 1			#i++
	
		add $s1, $s1, 1				#$s1 = inputCode + i
		sb $t2, 0($s1)				#inputCode[i] = '\0'
				
		bne $t1, $t3, for_loop_to_remove	#if $t1 <=3 continue loop
		nop
		bne $t1, $t3, for_loop_to_remove
		
	add $t3, $zero, $zero			
	sw $t3, 0($s2)					#inputCodeLength = 0
		
	#restore
	lw $s2, 0($sp)
	addi $sp,$sp,-4
	lw $t3, 0($sp)
	addi $sp,$sp,-4
	lw $s1, 0($sp)
	addi $sp,$sp,-4
	lw $t2, 0($sp)
	addi $sp,$sp,-4
	lw $t1, 0($sp)
	addi $sp,$sp,-4
	
	jr $ra
	nop
	jr $ra

#-------------------------------------------------------
# PROC check_if_equal_InputCode: check if the command is equal to the inputCode or not
# params[in]: $s0 - the command code that is gonna be compared
# params[out]: $s1 - the result: 1:true, 0:false
#-------------------------------------------------------
check_if_equal_inputCode:
	#backup
	addi $sp,$sp,4
	sw $a0, 0($sp)
	addi $sp,$sp,4
	sw $t0, 0($sp)
	addi $sp,$sp,4
	sw $t1, 0($sp)
	addi $sp,$sp,4
	sw $t2, 0($sp)
		
	#processing
	la $a0, inputCode
	
	li $t0, 0
	check_equal_loop:
	beq $t0, 3, is_equal
	lb $t1, 0($a0)
	lb $t2, 0($s0)
	bne $t1, $t2, is_not_equal
	addi $t0, $t0, 1
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j check_equal_loop
	
	is_equal:
	#restore
	lw $t1, 0($sp)
	addi $sp,$sp,-4
	lw $s1, 0($sp)
	addi $sp,$sp,-4
	lw $t2, 0($sp)
	addi $sp,$sp,-4
	lw $t3, 0($sp)
	addi $sp,$sp,-4
	
	li $s1, 1
	jr $ra
	nop
	jr $ra
	
	is_not_equal:
	#restore
	lw $t1, 0($sp)
	addi $sp,$sp,-4
	lw $s1, 0($sp)
	addi $sp,$sp,-4
	lw $t2, 0($sp)
	addi $sp,$sp,-4
	lw $t3, 0($sp)
	addi $sp,$sp,-4
	
	li $s1, 0
	jr $ra
	nop
	jr $ra
	
#-------------------------------------------------------
# PROC display_error_msg: display error message
# params[in]: 
# params[out]: 
#-------------------------------------------------------
display_error_msg:
	li $v0, 4
	la $a0, inputCode
	syscall
	nop
	
	li $v0, 55
	la $a0, WRONG_CODE_MSG
	syscall
	nop
	nop
	j reset_state
	nop
	j reset_state

#-----------------------------------------------------------
# PROC GO: marsbot run? = 1 (running)
# params[in]:
# params[out]:
#-----------------------------------------------------------
GO: 	#backup
	addi $sp,$sp,4
	sw $at,0($sp)
	addi $sp,$sp,4
	sw $k0,0($sp)
	#processing
	li $at, MOVING # change MOVING port
 	addi $t8, $zero,1 # to logic 1,
	sb $t8, 0($at) # to start running	
	#restore
	lw $t8, 0($sp)
	addi $sp,$sp,-4
	lw $at, 0($sp)
	addi $sp,$sp,-4
	
	jr $ra
	nop
	jr $ra
#-----------------------------------------------------------
# PROC STOP: marsbot run? = 0 ( stop running)
# params[in]:
# params[out]:
#-----------------------------------------------------------
STOP: 	#backup
	addi $sp,$sp,4
	sw $at,0($sp)
	#processing
	li $at, MOVING # change MOVING port to 0
	sb $zero, 0($at) # to stop
	#restore
	lw $at, 0($sp)
	addi $sp,$sp,-4
	
	jr $ra
	nop
	jr $ra
#-----------------------------------------------------------
# PROC TRACK: start drawing trail
# param[in]:
# params[out]:
#-----------------------------------------------------------
TRACK: 	#backup
	addi $sp,$sp,4
	sw $at,0($sp)
	addi $sp,$sp,4
	sw $k0,0($sp)
	#processing
	li $at, LEAVETRACK # change LEAVETRACK port
	addi $k0, $zero,1 # to logic 1,
 	sb $k0, 0($at) # to start tracking
 	#restore
	lw $k0, 0($sp)
	addi $sp,$sp,-4
	lw $at, 0($sp)
	addi $sp,$sp,-4
	
 	jr $ra
	nop
	jr $ra
#-----------------------------------------------------------
# PROC UNTRACK: stop drawing trail
# params[in]:
# params[out]:
#-----------------------------------------------------------
UNTRACK:#backup
	addi $sp,$sp,4
	sw $at,0($sp)
	#processing
	li $at, LEAVETRACK # change LEAVETRACK port to 0
 	sb $zero, 0($at) # to stop drawing tail
 	#restore
	lw $at, 0($sp)
	addi $sp,$sp,-4
	
 	jr $ra
	nop
	jr $ra
#-----------------------------------------------------------
# PROC ROTATE: take in the angle/direction variable and proceed to turn the Marsbot to that angle/direction
# params[in] direction variable, store heading at present
# params[out]
#-----------------------------------------------------------
ROTATE: 
	#backup
	addi $sp,$sp,4
	sw $t1,0($sp)
	addi $sp,$sp,4
	sw $t2,0($sp)
	addi $sp,$sp,4
	sw $t3,0($sp)
	#processing
	#set content in direction to HEADING
	li $t1, HEADING # change HEADING port
	la $t2, direction
	lw $t3, 0($t2) 	# $t3 is heading at now
 	sw $t3, 0($t1) # to rotate robot
 	#restore
 	lw $t3, 0($sp)
	addi $sp,$sp,-4
	lw $t2, 0($sp)
	addi $sp,$sp,-4
	lw $t1, 0($sp)
	addi $sp,$sp,-4
	
 	jr $ra
	nop
	jr $ra	
	
#-------------------------------------------------------------------------------------------------------
#					INTERRUPT PROCESSING
#-------------------------------------------------------------------------------------------------------
.ktext 0x80000180
#-------------------------------------------------------
# SAVE the current REG FILE to stack
#-------------------------------------------------------
	#backup: 
	addi $sp,$sp,4		#Backup for interrupt
	sw $ra,0($sp)
	addi $sp,$sp,4
	sw $v0,0($sp)
	addi $sp,$sp,4
	sw $v1,0($sp)
	addi $sp,$sp,4
	sw $t0,0($sp)
	addi $sp,$sp,4
	sw $t1,0($sp)
	addi $sp,$sp,4
	sw $at,0($sp)
	addi $sp,$sp,4
	sw $s0,0($sp)
	addi $sp,$sp,4
	sw $s1,0($sp)
	addi $sp,$sp,4
	sw $s2,0($sp)
	addi $sp,$sp,4
	sw $s3,0($sp)
#-------------------------------------------------------
# Processing
#-------------------------------------------------------
	#define input & output port
	li $v0, IN_ADDRESS_HEXA_KEYBOARD
	li $v1, OUT_ADDRESS_HEXA_KEYBOARD
	#row_1:
	li $t0, 0x81 			#row 1 is chosen
	sb $t0, 0($v0) 			#Scan with row 1 as input of user to DigitalLabSim
	lbu $t1, 0($v1) 			#get code from output of DigitalLabSim
	bne $t1, $0, key_to_char	#If there's key pressed -> $a0 != 0 -> key_to_char
	#row_2:
	li $t0, 0x82			#$t0: row
	sb $t0, 0($v0)			#t0: input to DigitalLabSim
	lbu $t1, 0($v1)			#t2: output from DigitalLabSim
	bne $t1, $0, key_to_char
	#row_3:
	li $t0, 0x84
	sb $t0, 0($v0)
	lbu $t1, 0($v1)
	bne $t1, $0, key_to_char
	#row_4:
	li $t0, 0x88
	sb $t0, 0($v0)
	lbu $t1, 0($v1)
	bne $t1, $0, key_to_char
	
#-------------------------------------------------------
# key_to_char: convert the matched pressed key from hex-code to char to add to inputCode.
#-------------------------------------------------------
key_to_char:
	beq $t1, 0x11, key_0
	beq $t1, 0x21, key_1
	beq $t1, 0x41, key_2
	beq $t1, 0x81, key_3
	beq $t1, 0x12, key_4
	beq $t1, 0x22, key_5
	beq $t1, 0x42, key_6
	beq $t1, 0x82, key_7
	beq $t1, 0x14, key_8
	beq $t1, 0x24, key_9
	beq $t1, 0x44, key_a
	beq $t1, 0x84, key_b
	beq $t1, 0x18, key_c
	beq $t1, 0x28, key_d
	beq $t1, 0x48, key_e
	beq $t1, 0x88, key_f
	
key_0:	li $s0, '0'
	j add_to_inputCode
key_1:	li $s0, '1'
	j add_to_inputCode
	
key_2:	li $s0, '2'
	j add_to_inputCode
key_3:	li $s0, '3'
	j add_to_inputCode
key_4:	li $s0, '4'
	j add_to_inputCode
key_5:	li $s0, '5'
	j add_to_inputCode
key_6:	li $s0, '6'
	j add_to_inputCode
key_7:	li $s0, '7'
	j add_to_inputCode
key_8:	li $s0, '8'
	j add_to_inputCode
key_9:	li $s0, '9'
	j add_to_inputCode
key_a:	li $s0, 'a'
	j add_to_inputCode
key_b:	li $s0, 'b'
	j add_to_inputCode
key_c:	li $s0, 'c'
	j add_to_inputCode
key_d:	li $s0, 'd'
	j add_to_inputCode
key_e:	li $s0, 'e'
	j add_to_inputCode
key_f:	li $s0, 'f'
	j add_to_inputCode
	
#-------------------------------------------------------
# add_to_inputCode: add the converted key char to the string inputCode.
#-------------------------------------------------------
	add_to_inputCode:
	la $s1, inputCode
	
	la $s2, inputCodeLength	#Find the address of the inputCodeLength variable
	lw $s3, 0($s2)		#And load its value to $s3 -> $s3 = len(inputCode)
	
	add $s1, $s1, $s3	#traverse right to the last char ('\n' or if the first time, '\0') of the inputCode 
				#string because when we calculate length we omitted '\n' (or if the first time, we have nothing) ->inputCode = 1b\n length = 2 (or if the first time, inputCode = '' -> length=0)
				#->inputCode[3] = '\n' -> we are preparing to replace '\n' with the key pressed in the
				#DigitalLabSim and then add '\n' again at the end, next to it
				#-> $s1 = inputCode[last], 0($s1) = '\n'	
	sb $s0, 0($s1)		#inputCode[last]=(content of)$s0
	
	addi $s1, $s1, 1	#move to new last of inputCodeLength
	li $s0, 10		#(content of)$s0 = '\n'
	sb $s0, 0($s1)		#inputCodeLength[new last] = '\n'
	
	addi $s3, $s3, 1	#length++
	sw $s3, 0($s2)		# store the value of length to inputCodeLength 
#--------------------------------------------------------
# next_pc: move out of interrupt handling program
#--------------------------------------------------------
next_pc:					#next_pc
	mfc0 $at, $14 # $at <= Coproc0.$14 = Coproc0.epc
	addi $at, $at, 4 # $at = $at + 4 (next instruction)
	mtc0 $at, $14 # Coproc0.$14 = Coproc0.epc <= $at
#--------------------------------------------------------
# RESTORE the REG FILE from STACK
#--------------------------------------------------------
	#restore:					
	lw $s3, 0($sp)			#restore interrupt
	addi $sp,$sp,-4
	lw $s2, 0($sp)
	addi $sp,$sp,-4
	lw $s1, 0($sp)
	addi $sp,$sp,-4
	lw $s0, 0($sp)
	addi $sp,$sp,-4
	lw $at, 0($sp)
	addi $sp,$sp,-4
	lw $t1, 0($sp)
	addi $sp,$sp,-4
	lw $t0, 0($sp)
	addi $sp,$sp,-4
	lw $v1, 0($sp)
	addi $sp,$sp,-4
	lw $v0, 0($sp)
	addi $sp,$sp,-4
	lw $ra, 0($sp)
	addi $sp,$sp,-4
return: eret # Return from exception
	
