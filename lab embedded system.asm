LDATA	EQU P0
EN	EQU P0.2
RS	EQU P0.0
WR	EQU	P0.1
TR0 BIT TCON.4
TF0 BIT TCON.5
G BIT P1.0
Y BIT P1.1
R BIT P1.3

	ORG 00H
	LCALL START

;*****************Main****************
	ORG 100H
START:
	ACALL INLCD 		;Initialize LCD
	MOV A,#1000B 		;Move cursor to 1st line – send high nibble
	ACALL CMD
	MOV A,#0000B 		;send low nibble
	ACALL CMD
	ACALL LDELAY 		;4.1 msec required for this command
	MOV DPTR,#ModeOp
	ACALL WSTR 		; Display String at ModeOp array
	
	MOV A,#1100B 		;Move cursor to 2nd line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	MOV DPTR,#ModeChoice
	ACALL WSTR 		;Display String at ModeChoice array


GetOperation:
	ACALL KEYPAD		;get the press key, store it in A
	CJNE A,#31H,MODEDEC	;Check if the key pressed is not '1' (it is not binary mode), Jump to the Decimal Mode and check if it is '2'
	MOV R5,A		;else
				;store the key pressed in R5 (to keep track of the Mode)
	ACALL BinaryIN		;And call Binary Mode, and get the first operand
	MOV 30H,A		;Store the first operand in 30H
	ACALL ChooseOpLCD	;chose the opration (NAND,NOR,XOR,XNOR)
				;and enter the second operan in location 31H
				;after all perform the operation, and display the result

	SJMP STOP		;Stop the program

MODEDEC:
	CJNE A,#32H,GetOperation	;if the key press to select the Mode is neither '2', back again and get a new key
	MOV R5,A			;store the Mode
	ACALL DecimalIN			;get the first operand (in decimal).
	MOV 30H,A			;store first operand in 30H
	ACALL ChooseOpLCD		;select operation + get second operand + perform operation + display result

	SJMP STOP			;Stop the program


STOP: SJMP $				;The stop point of the program (infinite loop).














	ORG 300H
;********PROCEDURES SECTIONS*********

;----Main Procedures----

InvalidLCD:
	MOV A,#1000B 		;Move cursor to 1st line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	MOV DPTR,#Invalid
	ACALL WSTR		;Display String at ModeOp array	
	AJMP STOP


;################Operation mode = Binary#######################
BinaryIN:
	ACALL ClearDisply	;Remove all previous displaies
	MOV A,#1000B 		;Move cursor to 1st line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	MOV DPTR,#InputB
	ACALL WSTR		;Display String at ModeOp array
	
	MOV R7,#9
	MOV R6,#0
	MOV P3,#0

REpeat:
	DJNZ R7,GetInputB	;Waits for Binary input
	MOV A,P3
	MOV R7,#4
	ACALL FlashG		;flsh the green light for 3 (4-1) times
	RET
GetInputB:
	MOV A,P3
	RL A
	MOV P3,A
	ACALL KEYPAD			;get input from keypad, store it in A
	MOV R1,A			;store the value of A
	MOV C,ACC.0
	MOV P3.0,C			;Store first bit to B.0, to check if the input is 1 or 0 (valid)
	ACALL WCHR			;print what is stored in A to LCD
	MOV A,R1			;Restore the value of A
	ANL A,#01001110B
	CJNE A,#00H,InvalidLCD
	SJMP REpeat	



;################Operation mode = Decimal#######################
DecimalIN:
	ACALL ClearDisply	;Remove all previous displaies
	MOV A,#1000B		;Move cursor to 1st line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	MOV DPTR,#InputD
	ACALL WSTR		;Display String at ModeOp array
	
	MOV R7,#3
	MOV R1,#50H
	CLR A
REpeat2:
	DJNZ R7,GetInputD
	MOV A,R6		
	MOV R7,#4		;|
	ACALL FlashG		;flash the green light for 3 times
	RET
GetInputD:
	MOV A,@R1
	SWAP A
	MOV @R1,A
	ACALL KEYPAD
	ACALL WCHR
	SUBB A,#30H
	MOV @R1,A
	ANL A,#11110000B
	CJNE A,#00H,REpeat2
	ACALL InvalidLCD	


;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;-----------------------Start of ChooseOpLCD Prosdure-----------------------
;---------------------------------------------------------------------------
ChooseOpLCD:

	MOV A,#1000B		;Move cursor to 1st line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	MOV DPTR,#OpChoice
	ACALL WSTR		;Display String at OpChoice array
	
	MOV A,#1100B		;Move cursor to 2nd line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	MOV DPTR,#OpChoice2
	ACALL WSTR		;Display String at OpChoice2 array




Isit:
	MOV P3,30H
	ACALL KEYPAD
	CJNE A,#'A',IsitB
	CLR P0.0
	CLR P0.1
	SJMP OPSELECTED
IsitB:
	CJNE A,#'B',IsitC
	SETB P0.0
	CLR P0.1
	SJMP OPSELECTED
IsitC:
	CJNE A,#'C',IsitD
	CLR P0.0
	SETB P0.1
	SJMP OPSELECTED
IsitD:
	CJNE A,#'D',Isit
	SETB P0.0
	SETB P0.1
	SJMP OPSELECTED

OPSELECTED:
	MOV R7,#4
	ACALL FlashG		;flash the green light for 3 times
	ACALL CALLREIN
	RET

;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;------------------------End of ChooseOpLCD Prosdure------------------------
;---------------------------------------------------------------------------


CALLREIN:
	CJNE R5,#31H,ItisDec
	ACALL BinaryIN
	MOV 31H,A

	MOV A,#1000B		;Move cursor to 1st line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	MOV DPTR,#Output
	ACALL WSTR		;Display String at Output array
	
	MOV A,#1100B		;Move cursor to 2nd line – send high nibble
	ACALL CMD
	MOV A,#0000B		;send low nibble
	ACALL CMD
	ACALL LDELAY		;4.1 msec required for this command
	


	ACALL Operation		;Perform the selected operation
				;Call phase 1 of the project
	MOV R7,#9
	MOV A,32H
	ACALL OUTPUTLCD
	
	RET
ItisDec:
	ACALL DecimalIN
	MOV 31,A
	ACALL Operation
	MOV A,40H
	MOV R7,#3
	ACALL OUTPUTLCD
	RET

OUTPUTLCD:
	DJNZ R7,DISPNEXT
DELAY3:
	MOV R5,#100
LP1:
	ACALL DELAY ;Wait for 3 secs
	DJNZ R5,LP1 
	RET 

DISPNEXT:
	
	MOV R6,A
	RL A
	ANL A,#00000001B
	ADD A,#30H
	ACALL WCHR
	MOV A,R6
	
	SJMP OUTPUTLCD

FlashG:
	CLR G			;turn the green light on
	ACALL DELAY50		;wait for a moment
	SETB G			;turn the green light off
	ACALL DELAY50		;wait for a moment
	DJNZ R7,FlashG		;repet the green light flashing until the initial value of R7 becomes zero
	RET
	
DELAY50:
	MOV R6,#20
DE:
	DJNZ R6,DE2
	RET
DE2:
	ACALL DELAY
	SJMP DE




















;----start of Phase 1----
;The next piece of code is
;the code that deal with the input
;and do the needed calculation(logical
; calculation).
;######################
;The switch input is stored in P0.0, and P0.1
;P0.0=0 & P0.1=0 >>> A)NAND
;P0.0=1 & P0.1=0 >>> B)NOR
;P0.0=0 & P0.1=1 >>> C)XOR
;P0.0=1 & P0.1=1 >>> D)XNOR
;The operands are stored in location 30H and 31H
;Then the result will be stored in 32H

Operation:
	MOV R0,#30H
	MOV A,@R0		;get the value stored in address 30H
	MOV R2,A		;move the operand to R2

	INC R0			;point to the second operand
	MOV A,@R0		;get The second operand
				;Now the operands are in A and R2



	JB P0.0,aP00is1		;continue if P0.0=0
	JB P0.1,aP01is1		;continue if P0.0=0 and P0.1=0
;#############
;P0.0=0, P0.1=0
;NAND
	ANL A,R2		;A has A(and)R2
	CPL A			;A has A(nand)R2
	SJMP EndOfOperation

;End of NAND
;#############
aP00is1:
	JB P0.1,bP01is1		;continue if P0.0=1 and P0.1=0
;#############
;P0.0=1, P0.1=0
;NOR
	ORL A,R2		;A has A(or)R2
	CPL A			;A has A(nor)R2
	SJMP EndOfOperation

;end of NOR
;#############
aP01is1:
;#############
;P0.0=0, P0.1=1
;XOR
	XRL A,R2		;A has A(XOR)R2
	SJMP EndOfOperation

;end of XOR
;#############
bP01is1:
;#############
;P0.0=1, P0.1=1
;XNOR
	XRL A,R2		;A has A(XOR)R2
	CPL A			;A has A(XNOR)R2
	SJMP EndOfOperation

;end of XNOR
;#############

EndOfOperation:
	MOV 32H,A		;store A in 32H(the resualt)	

	RET			;assuming this phase is a sub-routine
;----end of Phase 1----
























;----start of Phase 2----
;-----LCD Initialization Procedure starts here-----
INLCD:	
	MOV R7,#20
WAIT:
	ACALL LDELAY ;Step 1
	DJNZ R7,WAIT
	MOV P0,#00000111B ; Initialise 3 control signals=1
	MOV A,#0011B ;Step 2
	ACALL CMD
	ACALL LDELAY ;Step 3
	MOV A,#0011B ;Step 4
	ACALL CMD
	MOV A,#0011B ;Step 5
	ACALL CMD
	MOV A,#0010B ;Step 6
	ACALL CMD
	MOV A,#0010B ;Step 7 – send high nibble
	ACALL CMD
	MOV A,#1000B ; send low nibble
	ACALL CMD
	MOV A,#0000B ;Step 8 – Turn off display – send high nibble
	ACALL CMD
	MOV A,#1000B ; send low nibble
	ACALL CMD
	MOV A,#0 ;Step 9 - Clear Display – send high nibble
	ACALL CMD
	MOV A,#0001B ; send low nibble
	ACALL CMD
	ACALL LDELAY ; 4.1 msec required for this command
	MOV A,#0000B ; Step 10 - Set cursor Move RIGHT - send high nibble
	ACALL CMD
	MOV A,#0110B ; send low nibble
	ACALL CMD
	MOV A,#0000B ;Step 11 – send high nibble
	ACALL CMD ;Turn ON Display, Cursor ON, Blink Cursor
	MOV A,#1111B ; send low nibble
	ACALL CMD
	RET
;----End of LCD initialization-----
;----Subroutine to write COMMAND in A to the LCD-------
CMD:
	CLR RS ;RS = 0 command write
	ACALL COMMON
	RET
;----Subroutine to write character in A to the LCD-------
WCHR:
	SETB RS ;RS = 1 data write
	MOV B,A 
	SWAP A ; Move higher nibble to lower nibble
	ACALL COMMON ; write operation
	MOV A,B
	ACALL COMMON
	RET
;-----Common operation for CHAR write and COMMAND write
COMMON:
	CLR WR
	SWAP A ; Move Lower nibble to higher nibble
	ANL A,#11110000B
	ANL P0,#00000111B
	ORL P0,A
	SETB EN
	CLR EN
	ACALL LDELAY
	RET
;----Subroutine to write A STRING character by character-------
WSTR:
	PUSH ACC
CONT1:
	CLR A
	MOVC A,@A+DPTR ; move character to A
	JZ EXIT1
	ACALL WCHR ; call procedure to write a CHAR
	INC DPTR ; get next character
	AJMP CONT1 ; go to CONT1
EXIT1:
	POP ACC ; restore A
	RET
;------------˜5.4msec DELAY-------------------------------------------
LDELAY:
	PUSH 0
	PUSH 1 ; save register1.
	MOV R1,#20
CON4: 
	MOV R0,#250
	DJNZ R0,$
	DJNZ R1,CON4
	POP 1
	POP 0
	RET
STR1: STRZ 'Good!display is working' ; message to be displayed.


ClearDisply:
	;Clear the display
	MOV A,#0000B ; High 4-bits
	ACALL CMD
	MOV A,#0001B ; Low 4-bits
	ACALL CMD
	RET


;----end of Phase 2----














;----start of Phase 3----
;This subroutine detects the key pressed on the keypad, gets the ASCII code from the lookup table and stores
;the code in the Accumulator A
;P2.0 - P2.3 connected to row, P2.4 - P2.7 connected to columns
KEYPAD:
	MOV P2,#11110000B ;make bits P2.4 - P2.7 input (columns)
K1:
	MOV P2,#11110000B ;ground all rows
	MOV A,P2 ;read all col. (ensure all keys open)
	ANL A,#11110000B ;masked unused bits
	CJNE A,#11110000B,K1 ;check till all keys released
K2:
	ACALL DELAY
	MOV A,P2 ;see if any key is pressed
	ANL A,#11110000B ;mask unused bits
	CJNE A,#11110000B,OVER ;key pressed, await closure
	SJMP K2 ;check if key pressed
OVER:
	ACALL DELAY
	MOV A,P2 ;check key closure
	ANL A,#11110000B ;mask unused bits
	CJNE A,#11110000B,OVER1 ;key pressed, find row
	SJMP K2 ;if none keep polling
OVER1:
	MOV P2,#11111110B ;ground row 0
	MOV A,P2 ;read all columns
	ANL A,#11110000B ;mask unused bits
	CJNE A,#11110000B,ROW_0 ;key row 0, find the col.
	MOV P2,#11111101B ;ground row 1
	MOV A,P2 ;read all columns
	ANL A,#11110000B ;mask unused bits  
	CJNE A,#11110000B,ROW_1 ;keyrow 1, find the col.
	MOV P2,#11111011B ;ground row 2
	MOV A,P2 ;read all columns
	ANL A,#11110000B ;mask unused bits
	CJNE A,#11110000B,ROW_2 ;key row 2, find the col.
	MOV P2,#11110111B ;ground row 3
	MOV A,P2 ;read all columns
	ANL A,#11110000B ;mask unused bits
	CJNE A,#11110000B,ROW_3 ;keyrow 3, find the col.
	LJMP K2	;if none, false input, repeat
ROW_0:
	MOV DPTR,#KCODE0 ;set DPTR=start of row 0
	SJMP FIND ;find col. key belongs to
ROW_1: 
	MOV DPTR,#KCODE1 ;set DPTR=start of row 1
	SJMP FIND ;find col. key belongs to
ROW_2: 
	MOV DPTR,#KCODE2 ;set DPTR=start of row 2
	SJMP FIND ;find col. key belongs to
ROW_3: 
	MOV DPTR,#KCODE3 ;set DPTR=start of row 3
FIND:
	SWAP A ;exchange low and high nibble
FIND1:
	RRC A ;see if any CY bit low
	JNC MATCH ;if zero, get the ASCII code	
	INC DPTR ;point to next col. address
	SJMP FIND1 ;keep searching
MATCH:
	CLR A ;set A=0 (match is found)
	MOVC A,@A+DPTR ;get ASCII code from table
	RET 
DELAY:
	MOV TMOD,#00000001B
	MOV TL0,#0CAH ; Timer0, 30msec delay
	MOV TH0,#27H
	SETB TR0
BACK:
	JNB	TF0,BACK
	CLR TR0
	CLR TF0
	RET 
;----end of Phase 3----









;**************Constants**************

;****LCD Text fields****

ModeOp:		STRZ "Choose operation mode   "
Modechoice: STRZ "1) Binary  2) Decimal   "
InputB:		STRZ "Input Binary: "
InputD:		STRZ "Input Decimal: "
OpChoice:	STRZ "Choose an operation     "
OpChoice2:	STRZ "A)nandB)norC)xorD)xnor  "
Invalid:	STRZ "Invalid input           "
Output:		STRZ "Output:                 "

;****Keypad mapping****
KCODE0: DB '1','2','3','A' ;Row0 ASCII codes
KCODE1: DB '4','5','6','B' ;Row1 
KCODE2: DB '7','8','9','C' ;Row2
KCODE3: DB '*','0','#','D' ;Row3

;-------------END--------------------
END
