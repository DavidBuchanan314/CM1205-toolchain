.586			;Recognise 80x86 instructions that use 32-bit
.MODEL FLAT, STDCALL	;Generate code for a flat memory model
.STACK 4096		;Reserve 4096 bytes for stack operations

option casemap:none

include windows.inc
include kernel32.inc

.DATA
	msg		BYTE	"Hello, world!", 0Dh, 0Ah, 0
	dwWritten	DWORD	0
	hConsole	DWORD	0
	
.CODE
	main:		
			invoke	GetStdHandle, STD_OUTPUT_HANDLE
			mov	hConsole, eax;
			invoke	WriteConsoleA, hConsole, addr msg, sizeof msg, addr dwWritten, NULL
			invoke	ExitProcess, 0
END	main
