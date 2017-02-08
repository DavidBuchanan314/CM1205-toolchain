MINGWARCH=i686
JWASMFLAGS=-I /usr/local/include/wininc/ -nologo -elf -zt1
LDFLAGS=-lkernel32 -luser32

all: hello.exe

run: hello.exe
	wine hello.exe

debug: hello.exe
	wineconsole --backend=curses gdb.exe hello.exe

hello.exe: hello.o
	$(MINGWARCH)-w64-mingw32-ld hello.o $(LDFLAGS) -o hello.exe	

hello.o: hello.s
	jwasm $(JWASMFLAGS) hello.s

clean:
	rm -f *.o *.exe
