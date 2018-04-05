.586			;Recognise 80x86 instructions that use 32-bit
.MODEL FLAT, STDCALL	;Generate code for a flat memory model
.STACK 4096		;Reserve 4096 bytes for stack operations

option casemap:none

include windows.inc

.DATA
	msg_cap		BYTE	"Test Program", 0
	msg_txt		BYTE	"Hello, world!", 0
	
.CODE
	main:		
			invoke	MessageBoxA, NULL, addr msg_txt, addr msg_cap, MB_OK
			invoke	ExitProcess, 0
END	main
