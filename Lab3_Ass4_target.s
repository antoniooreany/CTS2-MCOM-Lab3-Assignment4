###############################################
# MCOM-Labor: Vorlage fuer Assemblerprogramm
# Edition History:
# 28-04-2009: Getting Started - ms
# 12-03-2014: Stack organization changed - ms
###############################################

###############################################
# Definition von symbolen Konstanten
###############################################
	#.equ PUSH_r9_1, subi sp, sp, 4
	#.equ PUSH_r9_2, stw r9, (sp)
	#.equ POP_r9_1, ldw r9, (sp)
	#.equ POP_r9_2, addi sp, sp, 4
	.equ STACK_SIZE, 0x400	# stack size
	.equ PERIODL_ADDR, 0xFF202008
	.equ PERIODH_ADDR, 0xFF20200C
	.equ CONTROL_ADDR, 0xFF202004
	.equ STATUS_ADDR, 0xFF202000
###############################################
# DATA SECTION
# assumption: 12 kByte data section (0 - 0x2fff)
# stack is located in data section and starts
# directly behind used data items at address
# STACK_END.
# Stack is growing downwards. Stack size
# is given by STACK_SIZE. A full descending
# stack is used, accordingly first stack item
# is stored at address STACK_END+(STACKSIZE).
###############################################	
	.data
TST_PAK1:
	.word 0x11112222	# test data

STACK_END:
	.skip STACK_SIZE	# stack area filled with 0

###############################################
# TEXT SECTION
# Executable code follows
###############################################
	.global _start
	.text
_start:
	#######################################
	# stack setup:
	# HAVE Care: By default JNiosEmu sets stack pointer sp = 0x40000.
	# That stack is not used here, because SoPC does not support
	# such an address range. I. e. you should ignore the STACK
	# section in JNiosEmu's memory window.
	
	movia	sp, STACK_END		# load data section's start address
	addi	sp, sp, STACK_SIZE	# stack start position should
					# begin at end of section
START:
###############################################
main:
	movi r7, 0b1111		# write parameter to switch LED0-LED3 on
	call write_LED		# write_LED(r7)
	
	movia r15, 20		# r15 <- 20 = 2ms
	call wait		# wait(r15)
	
	movi r7, 0b0011		# write parameter to switch LED0-LED1 on
	call write_LED		# write_LED(r15)
	
	movia r15, 80		# r15 <- 80 = 8 ms
	call wait		# wait(r15)
	
	beq r0, r0, main	# while(true) goto main
###############################################
wait:
	subi sp, sp, 4		# PUSH_r15_1
	stw r15, (sp)		# PUSH_r15_2
	
	muli r15, r15, 10000	# modify r15 to make it as int parameter for init_timer() with step 0.1ms 

	subi sp, sp, 4		# PUSH_r31_1 (before calling the 2nd level subrotines)
	stw r31, (sp)		# PUSH_r31_2 (before calling the 2nd level subrotines)

	call init_timer		# call init_timer(r15)
	call wait_timer		# call wait_timer()
	
	ldw r31, (sp)		# POP_r31_1 (after calling the 2nd level subrotines)
	addi sp, sp, 4		# POP_r31_2 (after calling the 2nd level subrotines)	
	
	ldw r15, (sp)		# POP_r15_1
	addi sp, sp, 4		# POP_r15_2	
ret
###############################################
init_timer:
	subi sp, sp, 4		# PUSH_r2_1
	stw r2, (sp)		# PUSH_r2_2
	
	subi sp, sp, 4		# PUSH_r15_1
	stw r15, (sp)		# PUSH_r15_2
	
	movia r2, PERIODL_ADDR	# PERIODL_ADDR -> r2
	sth r15, (r2)		# r15L -> periodl 
	movia r2, PERIODH_ADDR	# PERIODH_ADDR -> r2
	srli r15, r15, 16	# shift right by 16 bits TODO: ?Or by 15 bits?
	sth r15, (r2)		# r15H -> periodh
	
	ldw r15, (sp)		# POP_r15_1
	addi sp, sp, 4		# POP_r15_2
	
	ldw r2, (sp)		# POP_r2_1
	addi sp, sp, 4		# POP_r2_2 
ret
###############################################
wait_timer:
	subi sp, sp, 4		# PUSH_r2_1
	stw r2, (sp)		# PUSH_r2_2
	
	subi sp, sp, 4		# PUSH_r15_1
	stw r15, (sp)		# PUSH_r15_2
	
	movia r2, CONTROL_ADDR	# CONTROL_ADDR -> r2
	ldw r15, (r2)		# content of control -> r15
	ori r15, r15, 0b0100	# mask 2nd bit of the content of control (r15||0b0100 -> r15)
	stw r15, (r2)		# start timer(masked content of control -> control)
	movia r2, STATUS_ADDR	# STATUS_ADDR -> r2
	stw r0, (r2)		# control <- 0 for explicit clear the timeout-bit
WHILE:
	movia r2, STATUS_ADDR	# STATUS_ADDR -> r2
	ldw r15, (r2)		# status -> r15
	andi r15, r15, 0b0001	# mask the content of the status
	beq r15, r0, WHILE	# if timer is not expired(masked status == 0), check again
				# the timer has expired(masked status != 0)
				
	ldw r15, (sp)		# POP_r15_1
	addi sp, sp, 4		# POP_r15_2				
				
	ldw r2, (sp)		# POP_r2_1
	addi sp, sp, 4		# POP_r2_2
ret
###############################################
write_LED:
	subi sp, sp, 4		# PUSH_r9_1
	stw r9, (sp)		# PUSH_r9_2
	
	movia r9, 0xFF200000	# r9 <- 0xFF200000=output_register_address
	stw r7, (r9)		# r7 -> (r9) COUNTER -> output_register
	
	ldw r9, (sp)		# POP_r9_1
	addi sp, sp, 4		# POP_r9_2
ret
###############################################
endloop:
	br endloop		# that's it
###############################################
	.end





	
