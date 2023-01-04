TITLE Designing Low-Level I/O Procedures     (template.asm)

; Author: James Cole
; Last Modified: 12/3/21
; Description: A program that gets 10 SDWORD values from a user. The program converts these initial
;	strings to numbers and then back to strings for the purposes of displaying them. Values are
;	passed to procedures on the stack using Base + Offset method. Array elements are accessed using register
;	indirect addressing. All user input data is validated to ensure that they are actual numbers between
;	the range of -2147483648 to 2147483647. In addition, the program calculates and displays the sum and
;	average of the user nums. I hope you enjoy reading through the code of the program I have fondly
;	nicknamed 'The Spaghetti Monster'


INCLUDE Irvine32.inc
;MACRO DEFINITIONS
mGetString		MACRO prompt:REQ, usrInputString1:REQ, usrInputCount1:REQ
;preserve registers
	push		edx 
	push		ecx
	push		eax

;write prompt
	mov			edx, prompt
	call		writestring
;call readstring
	mov			edx, usrInputString1 ;point to userinput to store value - saves string
	mov			ecx, INPUTBUFFERSIZE ;set the buffer size (n-1 chars + 1 null)
	call		readstring ;irvine sets usrInput (edx)
	mov			edi, usrInputCount1 ;setting reference
	mov			[edi], eax ;setting value ;save count of chars user entered. If count >= buffersize, will return buffersize -1
	
;restore registers
	pop			eax
	pop			ecx 
	pop			edx
ENDM

mDisplayString	MACRO inputString:REQ
;print string (call writestring)
	push		edx
	mov			edx, inputString
	call		writestring
	pop			edx
ENDM

;CONSTANT DEFINITION
INPUTBUFFERSIZE =	20

;VARIABLE DEFINITIONS
.data
intro1			BYTE	"Designing low-level I/O procedures",0
intro2			BYTE	"Written by: James Cole",0
instructions1	BYTE	"Please provide 10 signed decimal integers.",0
instructions2	BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",0
usrPrompt1		BYTE	"Please enter a signed number: ",0
usrPrompt2		BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,"Please try again: ",0
usrNumsTxt		BYTE	"You entered the following numbers:",13,10,0
sumTxt			BYTE	"The sum of these numbers is: ",0
avgTxt			BYTE	"The truncated average is: ",0
goodbyeTxt		BYTE	"Thanks for playing!",13,10,0
hiRange			BYTE	"2147483647",0
commaSpace		BYTE	", ",0

readValFlag		DWORD	1						;1 = success, 0 = failure
convertValFlag	DWORD	1
usrInputString	BYTE	INPUTBUFFERSIZE DUP(0) 
revInputString	BYTE	INPUTBUFFERSIZE DUP(0)
displayString	BYTE	INPUTBUFFERSIZE DUP(0)
rdisplayString  BYTE	INPUTBUFFERSIZE DUP(0)
dummyString		BYTE	INPUTBUFFERSIZE DUP(0)
usrInputNum		SDWORD	0						;-2147483648 to 2,147,483,647
sLength			DWORD	?
usrArray		SDWORD	10 DUP(?)
sumNum			SDWORD	0

.code
; ---------------------------------------------------------------------------------
; Name: main
;
; Calls procedures: readVal, writeVal. Retrieves numbers from user, prints numbers, displays sum,
;	displays average, completes program execution.
;
; Preconditions: Constants INPUTBUFFERSIZE must be set to a value greater than 1.
;
; Postconditions: N/A
;
; Receives: All of the global variables listed above. Also the global constant: INPUTBUFFERSIZE.
;
; Returns: None
; ---------------------------------------------------------------------------------
main PROC
;INTRO
	mov			edx, offset intro1
	call		writestring
	call		crlf
	mov			edx, offset intro2
	call		writestring
	call		crlf
	call		crlf

;INSTRUCTIONS
	mov			edx, offset instructions1
	call		writestring
	call		crlf
	mov			edx, offset instructions2
	call		writestring
	call		crlf
	call		crlf

;GET NUMBERS
	mov			ecx, lengthof usrArray
	mov			edi, offset usrArray
	mov			esi, offset usrInputNum
	_getNumbersLoop:
		mov			usrInputNum, 0
		;passing references on the stack
		push		offset hiRange			;40
		push		offset revInputString	;36
		push		offset readValFlag		;32
		push		offset usrInputNum		;28
		push		offset sLength			;24
		push		offset usrInputString	;20
		push		offset usrPrompt1		;16
		push		offset usrPrompt2		;12
		push		offset usrArray			;not needed
		call		readVal
		;eval success flag
		mov			eax, 1
		cmp			eax, readValFlag		;data validation
		jne			_getNumbersLoop ;fail - dont dec counter
		;success - put usrNum in usrArray
		mov			eax, [esi]
		mov			[edi], eax
		add			edi, type usrArray
	loop		_getNumbersLoop ;success - dec counter

;PRINT NUMBERS
	call		crlf
	mov			edx, offset usrNumsTxt
	call		writestring
	mov			ecx, lengthof usrArray
	mov			esi, offset usrArray
	_displayNumbersLoop:
		;get value
		mov			eax, [esi]
		add			esi, type usrArray
		;passing numerical value, string references on the stack
		push		offset dummyString
		push		offset displayString
		push		offset rdisplayString
		push		eax
		call		writeVal
		;eval if ecx === 1, if so, don't print commaSpace (ie Last number)
		cmp			ecx, 1
		je			_skipCommaPrint
		mov			edx, offset commaSpace
		call		writestring
		_skipCommaPrint:
	loop		_displayNumbersLoop

;DISPLAY SUM
	call		crlf
	mov			edx, offset sumTxt
	call		writestring
	mov			esi, offset usrArray
	mov			ecx, 10
	_addValsLoop:
		mov			eax, [esi]
		add			sumNum, eax
		add			esi, type usrArray
	loop		_addValsLoop
	mov			eax, sumNum
	push		offset dummyString
	push		offset displayString
	push		offset rdisplayString
	push		eax
	call		writeVal

_displayAvg:
	call		crlf
	mov			edx, offset avgTxt
	call		writestring
	xor			edx, edx
	mov			ebx, 10
	mov			eax, sumNum
	cdq
	IDIV		ebx
	push		offset dummyString
	push		offset displayString
	push		offset rdisplayString
	push		eax
	call		writeVal

_displayGoodbye:
	call		crlf
	call		crlf
	mov			edx, offset goodbyeTxt
	call		writestring

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: readVal
;
; Retrieves 10 strings (represented as numbers) from user by using mGetString macro. Validates those 
;	those strings to ensure that they are valid numbers and are within SDWORD range. Then converts each
;	string to a number and stores it in an output parameter by reference.
;
; Preconditions: References to the following global variables must be pushed to the stack in this order 
;	prior to calling readVal: hiRange, revInputString, readValFlag, usrInputNum, sLength, usrInputString,
;	usrPrompt1, usrPrompt2, usrArray. Additionally, usrInputNum should be set to 0 in main procedure to 
;	ensure functionality.
;
; Postconditions: None - all registers preserved.   
;
; Receives: references to: hiRange, revInputString, readValFlag, usrInputNum, sLength, usrInputString,
;	usrPrompt1, usrPrompt2, usrArray.
;
; Returns: populates the global variable usrInputNum with a numeric representation derived from the user
;	inputted string. Also sets or clears the boolean global variable readValFlag which represents if the
;	user inputted a valid number string.
; ---------------------------------------------------------------------------------
readVal PROC
	push		ebp
	mov			ebp, esp
	;preserve registers
	pushad

	;invoke mGetString to get user input (string of digits) - pass prompt
	mov			eax, 1
	mov			ebx, [ebp + 32] ;cmp EAX to readvalFlag
	mov			ebx, [ebx]
	cmp			eax, ebx ;cmp EAX to readvalFlag
	jne			_errorMacro
	mGetString	[ebp + 16], [ebp + 20], [ebp + 24]  ;usrPrompt1, usrInputString, sLength
	jmp			_setFlag
	_errorMacro:
	mGetString	[ebp + 12], [ebp + 20], [ebp + 24]
	_setFlag:
	mov			edi, [ebp + 32]
	mov			eax, 1
	mov			[edi], eax ;resetting flag incase it was changed on last proc execution

	;CHECK FOR NO INPUT
	mov			esi, [ebp + 24]
	mov			eax, [esi]
	cmp			eax, 0
	je			_setFalseFlag

	;Setting a validation string value to default ("2147483647")
	;uses the string "2147483647" to compare an edge case later on
	mov			edi, [ebp + 40]
	add			edi, 9 ;9 bytes into string
	xor			eax, eax
	mov			al, 55
	mov			[edi], al ;ascii value for '7'
	
;convert the string of ascii digits to its numeric value. Must Validate.

	;reverse string
	mov			ecx, [ebp + 24]
	mov			ecx, [ecx] ;initialize counter
	mov			esi, [ebp + 20] 
	add			esi, ecx ;esi points to end of input string
	dec			esi		;reduce pointer manually to get past null byte and into string
	mov			edi, [ebp + 36] ;edi points to beginning of revinputstring
	mov			eax, 0    
	_revLoop: ;reversing user string so it is easier to do math (in my head)
		std
		lodsb
		cld
		stosb
		loop			_revLoop

	mov			ecx, [ebp + 24]
	mov			ecx, [ecx] ;initialize counter
	mov			ebx, ecx  ;dup for math calc
	mov			esi, [ebp + 36] ;edi points to beginning of revinputstring

	
	;Validates each char within the string to ensure it is a number char or + or - char
	_validateLoop:		;validate and add up the numbers

		cld
		xor			eax, eax
		lodsb			;puts byte in AL
		cmp			ecx, 1   ;if last iteration
		jne			_notLastIteration
		;if last iteration also allow for '-' or '+' chars
		cmp			al, 43
		je			_rangeValidation
		cmp			al,	45
		je			_negativeNum
		cmp			al, 48
		jb			_notANumber
		cmp			al, 57
		ja			_notANumber
		jmp			_mathCalc

		_notLastIteration:
		;verify each char is a between 48-57 inclusive
		cmp			al, 48
		jb			_notANumber
		cmp			al, 57
		ja			_notANumber

		_mathCalc:
		;subject 48 from each number
		sub			al, 48			;get the digit


		;multiply that number by 10s
		;ebx - ecx = Z, 10^Z = 10s
		push		ebx		;push sLength
		sub			ebx, ecx ;ebx containts 10s exponent
		cmp			ebx, 0
		je			_addToUserNum ;do not need to multiple first number by anything
		push		ecx		;preserve outer loop counter
		mov			ecx, ebx ;set new counter
		mov			edx, 0
		push		eax		;save digit
		mov			ebx, 10
		mov			eax, 1
		_exponentLoop:
			mul			ebx
			loop		_exponentLoop
		;need to mul  edx, al
		mov			edx, eax
		pop			eax
		mov			ebx, eax
		mov			eax, edx
		mul			ebx  ;eax contains 10s * digit
		pop			ecx   
		_addToUserNum:

		push		esi
		push		edi

		;add product to usrInputNum [ebp + 28]
		mov			edi, [ebp + 28]
		mov			esi, [ebp + 28]
		mov			ebx, [esi]
		add			eax, ebx
		mov			[edi], eax  
		pop			edi
		pop			esi
		pop			ebx
	loop		_validateLoop
	jmp			_rangeValidation
	
	_notANumber:
	jmp			_setFalseFlag
	
	_negativeNum:
	mov			edi, [ebp + 28]
	mov			esi, [ebp + 28]
	mov			eax, [esi]
	mov			ebx, -1
	imul		ebx
	mov			[edi], eax

	_rangeValidation:
	mov			esi, [ebp + 24]
	mov			eax, [esi]
	cmp			eax, 12
	jae			_setFalseFlag
	cmp			eax, 9
	jbe			_exit
	cmp			eax, 11
	je			_checkForSign11
	cmp			eax, 10
	je			_checkForSign10

	_checkForSign11: ;"2147483647"
	;if sign -> _hardCheck
	;if no sign -> _setFalseFlag
	mov			esi, [ebp + 20]
	xor			ebx, ebx
	mov			bl, [esi]
	cmp			bl, 43
	je			_hardCheckWSign
	cmp			bl, 45
	je			_hardCheckWSign
	jmp			_setFalseFlag

	_checkForSign10:
	;if sign -> _exit
	;if no sign -> _hardCheck
	mov			esi, [ebp + 20]
	mov			eax, [esi]
	cmp			al, 43
	je			_exit
	cmp			al, 45
	je			_exit
	jmp			_hardCheckNoSign

	;if userString is 10 number chars long, check each char against the SDWORD limits (as a string)
	_hardCheckNoSign:
	;set counter and both esis
	mov			esi, [ebp + 40] ;limit
	mov			edx, esi
	mov			esi, [ebp + 24]
	mov			ecx, [esi]
	mov			esi, [ebp + 20] ;usrString
	_noSignLoop:
		cld
		xor			eax, eax
		lodsb
		xor			ebx, ebx
		mov			bl, al
		push		esi
		xor			eax, eax
		mov			esi, edx
		lodsb
		mov			edx, esi    ;preserving 2nd esi
		pop			esi
		cmp			bl, al  ;bl=usr, al=limit
		ja			_setFalseFlag
		cmp			bl, al
		jb			_exit
	loop		_noSignLoop
	jmp			_exit

	;if userString is 10 number chars long with a sign char, 
	;check each char against the SDWORD limits (as a string)
	_hardCheckWSign:
	;set counter and both esis
	mov			esi, [ebp + 40] ;limit
	mov			edx, esi
	mov			esi, [ebp + 24]
	mov			ecx, [esi]
	sub			ecx, 1
	mov			esi, [ebp + 20] ;usrString
	add			esi, 1
	_signLoop:
		;CODE FOR FINAL DIGIT
		cmp			ecx, 1
		jne			_notLastIter
		push		esi ;preserve from previous iter
		;check what sign
		mov			esi, [ebp + 20]
		push		eax
		xor			eax, eax
		mov			al, [esi] 
		cmp			al, 43 ;if positive
		je			_resume
		;so its negative....
		;set final char to 8
		mov			edi, [ebp + 40]
		add			edi, 9 ;9 bytes into string
		xor			eax, eax
		mov			al, 56
		mov			[edi], al ;ascii value for '8'
		_resume:
		pop			eax
		pop			esi
		;CODE FOR FINAL DIGIT
		_notLastIter:
		cld
		xor			eax, eax
		lodsb
		xor			ebx, ebx
		mov			bl, al ;bl contains first char of usrStringd
		push		esi
		xor			eax, eax
		mov			esi, edx
		lodsb
		mov			edx, esi    ;preserving 2nd esi
		pop			esi
		cmp			bl, al  ;bl=usr, al=limit
		ja			_setFalseFlag
		cmp			bl, al
		jb			_exit
	loop		_signLoop
	jmp			_exit

	_setFalseFlag:
	mov			edi, [ebp + 32]
	mov			eax, 0
	mov			[edi], eax
	jmp			_exit	

	_exit:
	;preserve registers
	popad
	pop			ebp
	ret			36
ReadVal	ENDP

; ---------------------------------------------------------------------------------
; Name: writeVal
;
; Converts a numeric SDWORD value that is passed into the procedure by value to a string of ascii characters.
;	Also invokes the macro mDisplayString to print the ascii representation of the SDWORD value to output.
;
; Preconditions: References to the following global variables must be pushed to the stack in this order 
;	prior to calling writeVal: dummyString, displayString, rdisplayString. Additionally, the numeric value
;	must be passed by value last.
;
; Postconditions: All registers preserved. displayString and rdisplayString are changed at the end of the 
;	of the procedure but are reset at the beginning of the procedure.
;
; Receives: references to: dummyString, displayString, rdisplayString. Also receives a number value from
;	usrArray. Receives global constant INPUTBUFFERSIZE.
;
; Returns: None - only displays information.
; ---------------------------------------------------------------------------------
writeVal	PROC
	push	ebp
	mov		ebp, esp
	pushad
;clear rdisplayString 
	cld
	mov			ecx, INPUTBUFFERSIZE ;set counter
	mov			esi, [ebp + 20] ;dummy
	mov			edi, [ebp + 12] ;rDisplayString
	rep			movsb
;clear displayString 
	cld
	mov			ecx, INPUTBUFFERSIZE ;set counter
	mov			esi, [ebp + 20] ;dummy
	mov			edi, [ebp + 16] ;displayString
	rep			movsb

;convert numeric SDWORD value to string of ascii digits
	xor			ecx, ecx
	mov			edi, [ebp + 12] ;pointer to revString
	mov			eax, [ebp + 8] ;eax has the num value
	xor			ebx, ebx
	cmp			eax, 0
	jge			_revStringConversionLoop
	;set negative value flag
	mov			ecx, 1 ;negative value = true	

	_revStringConversionLoop:
		xor			edx, edx
		push		ebx
		mov			ebx, 10
		cdq
		IDIV		ebx
		pop			ebx
		push		eax
		xor			eax, eax
		mov			eax, edx ;move remainder into eax
		cmp			ecx, 1 ;check negative flag
		jne			_skipNegative 
		push		ebx
		mov			ebx, -1
		IMUL		ebx ;converts digit to positive (will add negative sign at the end)
		pop			ebx
		_skipNegative:
		add			al, 48 ;converting to ascii
		add			ebx, 1 ;ebx keeping track of string length
		stosb
		pop			eax
		cmp			eax, 0 ;last number?
		jne			_revStringConversionLoop

	cmp			ecx, 1
	jne			_skipSignAppend
	xor			eax, eax
	mov			al, 45
	add			ebx, 1
	stosb
	_skipSignAppend:

	;reverse string
	mov			ecx, ebx
	mov			esi, [ebp + 12] 
	add			esi, ecx ;ESI points to the last char in the stringf
	dec			esi		;reduce pointer manually to get past null byte and into string
	mov			edi, [ebp + 16] ;edi points to beginning of DisplayString
	mov			eax, 0    
	_revLoop: ;reversing string
		std
		lodsb
		cld
		stosb
		loop			_revLoop

;PRINT STRING
	mDisplayString [ebp + 16]

	popad
	pop			ebp
	ret			16
writeVal	ENDP

END main
