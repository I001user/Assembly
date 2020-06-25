#Nguyen Tri Hung_20176773

# string: pop\n					when user input '\n' is automatically added
#strinList: poppop\nkik\npo\npop\nttttt\n	stringList's tokens are separted by '\n'
.data
	
	string: 	.space	31
	stringList: 	.space	1001
	MESSAGE: 	.asciiz "Input a string <= 30 characters"
	STRING_TOO_LONG_MSG:	.asciiz "String is too long. Try again!"
	IS_PALINDROME_MSG: 	.asciiz "The string is a palindrome"
	IS_NOT_PALINDROME_MSG: 	.asciiz "The string is not a palindrome"
	EXISTED_IN_MEMORY_MSG: 	.asciiz "The string is already stored in the memory"
	STORED_MSG: 		.asciiz "The string is stored!"
	CONFIRM_MSG: 		.asciiz "Do you want to continue?\n"	
	MEMORY_FULL_MSG: 	.asciiz "Not enough memory to store your input! Exit the program."
.text
main:
	li $v0, 54
	la $a0, MESSAGE
	la $a1, string
	la $a2, 31
	syscall
	
	beq $a1, 0, stringLength	#OK
	beq $a1, -2, exit		#Cancel
	beq $a1, -3, isPalindrome	#OK but nodata
	beq $a1, -4, stringTooLong	#String length exceeds the pre-set max length

#---------------------------------------------------------------------
#procedure stringLength
#@brief		calculate the length of a string
#@param[in]	string: the input string
#@return	$s1: the length of string
#		$s2: the pointer to the last non-null character in the string (address of the last non-null char in the string)
#---------------------------------------------------------------------	
stringLength:
	li $t0, 0
	la $a0, string
	
	loop_stringLength:	
	lb $t1, 0($a0) 				#loop starts
	beq $t1, 0, done_stringLength		#go to done if "\0", "\n" is calulated to the length
	addi $t0, $t0, 1
	addi $a0, $a0, 1
	j loop_stringLength
	
done_stringLength:
	addi $s1, $t0, 0			#$t0 is considered as a temporary register and $s1 is a register for saved result
	addi $s2, $a0, -2			#save the pointer that point to the last character (that is not "\n") in the string

#---------------------------------------------------------------------
#procedure checkPalindrome
#@biref		check if the string is a Palindrome or not
#@param[in]	string: the input string
#		$s2: the pointer to the last non-null character in the string
#@return	returns nothing, just goes to isPalindrome or isNotPalindrome
#---------------------------------------------------------------------
checkPalindrome:
	li $t0, 0
	la $a0, string
	addi $a1 , $s2, 0
	
	loop_checkPalindrome:
	ble $a1, $a0, isPalindrome
	lb $t1, 0($a0)
	lb $t2, 0($a1)
	bne $t1, $t2, isNotPalindrome
	addi $a0, $a0, 1
	addi $a1, $a1, -1
	j loop_checkPalindrome
	
isPalindrome:
	li $v0, 55
	la $a0, IS_PALINDROME_MSG
	syscall
	j checkInMemory
	
isNotPalindrome:
	li $v0, 55
	la $a0, IS_NOT_PALINDROME_MSG
	syscall
	j confirm
	
#---------------------------------------------------------------------
#procedure checkInMemory
#@brief		check if the Palindrome is stored or not, if not, store it to stringList
#@param[in]	string:	the input string
#		stringList: used to store the Palindrome, is the concatenation of all different
#			    Palindromes that the user typed in
#---------------------------------------------------------------------
checkInMemory:
	la $a0, string
	la $a1, stringList
	
	loop_checkInMemory:
	lb $t1, 0($a0)					#string[i]
	beq $t1, 0, equal				#similar from the first character to the last (null) character of string-> equal
	lb $t2, 0($a1)					#stringList[j+i]
	beq $t2, 0, traverseStringList 			#end of stringList, find no duplicate -> jump to traverseStringList to prepare to store the string to the memory
	bne $t1, $t2, notEqual				#a different character -> not equal
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	j loop_checkInMemory
	
	equal:						#string equals to a token of the stringList -> existed, do not save
	li $v0, 55
	la $a0, EXISTED_IN_MEMORY_MSG
	syscall
	j confirm
	
	notEqual:
		la $a0, string				#reset pointer to string
		loop_notEqual:				#loop begins
		beq $t2, 10, backTo_loopCheckInMemory	#encounter '\n' -> prepare for a new token in stringList
		addi $a1, $a1, 1			
		lb $t2, 0($a1)
		#beq $t2, 0, traverseStringList
		j loop_notEqual
		backTo_loopCheckInMemory:
		addi $a1, $a1, 1			#move the pointer in stringList to the next position
		j loop_checkInMemory			#jump back to compare string to anther token of stringList

#---------------------------------------------------------------------
#procedure traverseStringList
#@brief		traverse to the last(null) character of stringList to continue to add a new Palindrome to it
#@param[in]	stringList: used to store the Palindrome, is the concatenation of all different
#			    Palindromes that the user typed in
#@return	$s3: the pointer to the last character (null) of the stringList
#		memoryFull: if the memory full then make exit the program
#---------------------------------------------------------------------	
traverseStringList:
	la $a0, stringList
	li $t0, 0 #length of StringList
	
	loop_traverseStringList:
	lb $t1, 0($a0)
	beq $t1, 0, done_traverseStringList		#encounter '\0'
	addi $a0, $a0, 1
	addi $t0, $t0, 1
	add $t2, $t0, $s1
	li $t3, 1000
	blt $t3, $t2 memoryFull				#if stringList's length + string's length > 1000 -> not enough memory
	j loop_traverseStringList
		
		memoryFull:
		li $v0, 55
		la $a0, MEMORY_FULL_MSG
		syscall
		j exit
		
done_traverseStringList:
	addi $s3, $a0, 0				#save the pointer that points to the last character (which is "\0") in the stringList

#---------------------------------------------------------------------
#procedure storeToMemory
#@brief		store the Palindrome to the stringList
#@paramp[in]	string: the input string
#		$s3: the pointer to the last character (null) of the stringList
#---------------------------------------------------------------------	
storeToMemory:
li $t2, 0			#i=0
la $a1, string

	loop_storeToMemory:
	add $t1, $t2, $a1		#$t1 = adress of string[i]
	lb $t3, 0($t1)			#$t3 value at $t1 = string[i]
	add $t4, $t2, $s3		#$t4: the address of stringList[last+i]
	sb $t3, 0($t4)			#$stringList[last+i] = string[i]
	beq $t3, 0, done_storeToMemory	#'\0' -> done, store ca '\n'
	nop
	addi $t2, $t2, 1
	j loop_storeToMemory
	nop
	
done_storeToMemory:
	#add '\0' to the end of stringList to identify that it ends (Actually dont need this, but I feel inadequate not to do so) 
	addi $t2, $t2,1
	add $t4, $t2, $s3 	#$t4: the address of stringList[last+i]
	li $t5, 0		
	sb $t5, 0($t4)		#stringList[last] = '\0'
	
	#Inform user that the string is saved to the memory
	li $v0, 55
	la $a0, STORED_MSG
	syscall
	
	#Print stringList for debugging
	li $v0, 4
	la $a0, stringList
	syscall
#---------------------------------------------------------------------
#procedure confirm
#@brief		give user option to continue or stop the program
#---------------------------------------------------------------------	
confirm:
	li $v0, 50
	la $a0, CONFIRM_MSG
	syscall
	beq $a0, 0, main	#Press Yes
	beq $a0, 1, exit	#Press No
	beq $a0, 2, exit	#Press Cancel
#---------------------------------------------------------------------
#procedure stringTooLong
#@brief		make the user input again if the input string exceeds the pre-set max length
#---------------------------------------------------------------------	
stringTooLong:
	li $v0, 50
	la $a0, STRING_TOO_LONG_MSG
	syscall
	beq $a0, $zero, main
#exit the program
exit:
	
	
	
	
	
	
