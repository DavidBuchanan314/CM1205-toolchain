.586			; Recognise 80x86 instructions that use 32-bit
.MODEL FLAT, STDCALL	; Generate code for a flat memory model
.STACK 4096		; Reserve 4096 bytes for stack operations
option casemap:none	; Case sensitivity

include windows.inc	; Configure your assembler to use the correct include directory


; Macros to simplify IO:

READ_INPUT	MACRO	buf
	invoke	ReadConsoleA,
		inHandle,
		OFFSET buf,
		SIZEOF buf,
		OFFSET bytesRead,
		NULL
	ENDM

WRITE_OUTPUT	MACRO	buf, len
	invoke	WriteConsoleA,
		outHandle,
		buf,
		len,
		OFFSET bytesWritten,
		NULL
	ENDM

; For when the length is constant:
WRITE_CONST	MACRO	buf
	WRITE_OUTPUT	OFFSET buf, SIZEOF buf
	ENDM



.DATA
	
	promptMsg	BYTE	"Enter a temperature: "
	typeMsg		BYTE	"Would you like to convert to Celsius or Farenheit? [C/F]: "
	outputMsg	BYTE	0Dh, 0Ah, "Output: "
	exitMsg		BYTE	0Dh, 0Ah, "Press ENTER to do another conversion, or Ctrl+C to exit"
	CRLF		BYTE	0Dh, 0Ah
	CLS		BYTE	100 dup( 100 dup(' '), 0Dh, 0Ah )
	buf		BYTE	4096 dup(?) ; This length is slight overkill!
	bytesWritten	DWORD	?
	bytesRead	DWORD	?
	outHandle	DWORD	?
	inHandle	DWORD	?
	tmp		DWORD	?
	homeCursor	COORD	{0, 0}
	boxCursor	COORD	{2, 19}
	
	; these numeric constants are used for FPU instructions that don't
	; support immediate agruments
	TEN		REAL8	10.0
	THOUSAND	REAL8	1000.0
	NINE		REAL8	9.0
	FIVE		REAL8	5.0
	THIRTY_TWO	REAL8	32.0
	HALF		REAL8	0.5
	
	bannerMsg \
	DB	"                                                             ", 0Dh, 0Ah
	DB	"David Buchanan presents:                                     ", 0Dh, 0Ah
	DB	" _______                                  _                  ", 0Dh, 0Ah
	DB	"|__   __|                                | |                 ", 0Dh, 0Ah
	DB	"   | | ___ _ __ ___  _ __   ___ _ __ __ _| |_ _   _ _ __ ___ ", 0Dh, 0Ah
	DB	"   | |/ _ \ '_ ` _ \| '_ \ / _ \ '__/ _` | __| | | | '__/ _ \", 0Dh, 0Ah
	DB	"   | |  __/ | | | | | |_) |  __/ | | (_| | |_| |_| | | |  __/", 0Dh, 0Ah
	DB	"   |_|\___|_| |_| |_| .__/ \___|_|  \__,_|\__|\__,_|_|  \___|", 0Dh, 0Ah
	DB	"          _____     | |                  _                   ", 0Dh, 0Ah
	DB	"         / ____|    |_|                 | |                  ", 0Dh, 0Ah
	DB	"        | |     ___  _ ____   _____ _ __| |_ ___ _ __ TM     ", 0Dh, 0Ah
	DB	"        | |    / _ \| '_ \ \ / / _ \ '__| __/ _ \ '__|       ", 0Dh, 0Ah
	DB	"        | |___| (_) | | | \ V /  __/ |  | ||  __/ |          ", 0Dh, 0Ah
	DB	"         \_____\___/|_| |_|\_/ \___|_|   \__\___|_|          ", 0Dh, 0Ah
	DB	"                                                             ", 0Dh, 0Ah
	DB	"                                                             ", 0Dh, 0Ah
	DB	"                                                             ", 0Dh, 0Ah
	DB	" ___________________________________________________________ ", 0Dh, 0Ah
	DB	"|                                                           |", 0Dh, 0Ah
	DB	"|                                                           |", 0Dh, 0Ah
	msgBoxLower \ ; used when we need to redraw this section
	DB	"|___________________________________________________________|", 0Dh, 0Ah
	DB	"                                                             ", 0Dh, 0Ah
	; used to calculate the length of the banner, assumes linear allocation
	endMsgBox	BYTE	NULL
.CODE


main PROC
	
	; Acquire I/O handles
	INVOKE	GetStdHandle, STD_OUTPUT_HANDLE
	MOV	outHandle, eax
	INVOKE	GetStdHandle, STD_INPUT_HANDLE
	MOV	inHandle, eax
	
	; Ensure the FPU starts in a clean state, with round-to-nearest
	; mode enabled
	FNINIT
prompt:
	; Prompt the user for temperature input
	WRITE_CONST	CLS ; clear the screen (Why is this not part of the Windows API?!)
	INVOKE		SetConsoleCursorPosition, outHandle, homeCursor
	WRITE_OUTPUT	OFFSET bannerMsg, OFFSET endMsgBox - OFFSET bannerMsg
	INVOKE		SetConsoleCursorPosition, outHandle, boxCursor
	WRITE_CONST	promptMsg
	
	CALL	readfloat
	
	; redraw lower portion of the box
	WRITE_OUTPUT	OFFSET msgBoxLower, OFFSET endMsgBox - OFFSET msgBoxLower
	
retry:
	; Prompt the user for conversion type
	WRITE_CONST	typeMsg
	
	; Read the user's choice
	READ_INPUT	buf
	
	MOV	AL, buf ; Just check the first character
	
	; Convert to upper case, for case insensitivity
	AND	AL, 11011111b
	
	CMP	AL, 'C'
	JNE	skipc
	CALL	f2c
	JMP	done
skipc:
	CMP	AL, 'F'
	JNE	retry ; Repeat the question on invalid input
	CALL	c2f
	
done:
	WRITE_CONST	outputMsg
	CALL	printfloat
	WRITE_CONST	CRLF
	
	WRITE_CONST	exitMsg
	READ_INPUT	buf ; wait for the user to hit enter
	JMP	prompt ; Restart the program (Ctrl+C to exit)
	
main ENDP


f2c PROC ; Farenheit to Celsius
	
	FSUB	THIRTY_TWO
	FMUL	FIVE
	FDIV	NINE
	RET
	
f2c ENDP


c2f PROC ; Celsius to Farenheit
	
	FMUL	NINE
	FDIV	FIVE
	FADD	THIRTY_TWO
	RET
	
c2f ENDP


; read a floating point number from stdin, and stores it in the ST(0)
; FPU register
readfloat PROC
	
	READ_INPUT buf
	
	MOV	ECX, bytesRead
	MOV	ESI, OFFSET buf
	XOR	EAX, EAX
	XOR	EBX, EBX ; EBX = 1, used to store the sign of the input
	INC	EBX
	FLDZ
	CLD
	
	parseloop:
		LODSB
		CMP	AL, 0Ah
		JE	parsedone ; end on carriage return
		
		CMP	AL, '-' ; if a '-' is encountered, flip the sign
		JNE	ispositive
		IMUL	EBX, -1
		
	ispositive:
		CMP	AL, '.'
		JE	decimal
		CMP	AL, '0'
		JL	parseloop ; skip over if less than '0'
		CMP	AL, '9'
		JG	parseloop ; skip over if greater than '9'
		
		FMUL	TEN
		SUB	AL, '0'
		MOV	tmp, EAX
		FIADD	tmp
		
		JMP	parseloop
		
	decimal: ; works backwards from the end until the next decimal
		STD
		MOV	ESI, OFFSET buf
		ADD	ESI, bytesRead
		DEC	ESI
		FLDZ
	decimalloop:
		LODSB
		CMP	AL, '.'
		JE	decimaldone
		CMP	AL, '0'
		JL	decimalloop ; skip over if less than '0'
		CMP	AL, '9'
		JG	decimalloop ; skip over if greater than '9'
		
		SUB	AL, '0'
		MOV	tmp, EAX
		FIADD	tmp
		FDIV	TEN
		
		JMP	decimalloop
	
decimaldone:
	FADDP ; add the integer and fractional components together
	CLD
	
parsedone:
	MOV	tmp, EBX ; apply the sign
	FIMUL	tmp
	RET
	
readfloat ENDP


printfloat PROC
	
	LOCAL	isPositive :BYTE
	
	MOV	EDI, (OFFSET buf)+(SIZEOF buf)-1 ; points to the end of the buffer
	XOR	ECX, ECX ; keep a count of how many bytes written
	
	FMUL	THOUSAND ; Gives us 3 decimal places of precision
	FLDZ
	FCOMP
	FSTSW	AX
	AND	AH, 1 ; isolate C0 status bit
	MOV	isPositive, AH
	FABS		; Ensure the working value is always positive
	FADD	HALF	; the first digit should be rounded to the nearest integer
	FLD	TEN
	
	STD ; We will be working backwards from the end of the string
	
	decodeloop:
		FLD	ST(1)
		FPREM
		FSUB	HALF	; Hack to round down without fiddling with FPU regs
		FISTP	tmp	; This instruction is likely very slow
		
		; sometimes the FPU does not finish calculating the remainder,
		; for some unknown reason, so in this case we assume the result
		; should be 0.
		FSTSW	AX
		AND	AH, 4 ; C2 status bit
		JE	noerror
		MOV	tmp, 0
	noerror:
		
		MOV	EAX, tmp	; Convert to ascii
		ADD	AL, '0'
		STOSB			; Add to buffer
		
		FDIV	ST(1), ST(0)    ; Divide the working value by ten
		INC	ECX
		CMP	ECX, 3
		JNE	skipdp
		MOV	AL, '.'
		STOSB
		INC	ECX
	skipdp:
		CMP	ECX, 5
		; This ensures leading zeroes are printed for values less than 1
		JL	decodeloop
		FLD1
		FCOMP	ST(2)
		FSTSW	AX
		AND	AH, 1
		JNE	decodeloop ; Loop if working value >= 1?
	
	FINIT ; Put the FPU back in a clean state
	
	CMP	isPositive, 0
	JNE	skipneg
	MOV	AL, '-'
	STOSB
	INC	ECX
skipneg:
	
	CLD	; Without this, the Windows API will break, because it sucks.
	INC	EDI
	WRITE_OUTPUT EDI, ECX
	RET
	
printfloat ENDP


END main
