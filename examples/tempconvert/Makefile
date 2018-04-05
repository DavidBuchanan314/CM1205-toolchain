MINGWARCH := i686
JWASMFLAGS := -I /usr/local/include/wininc/ -nologo -elf -zt1
LDFLAGS := -lkernel32 -luser32

TARGET := tempconvert

.PHONY: run debug debug2 clean

all: $(TARGET).exe

run: $(TARGET).exe
	wine $(TARGET).exe

debug: $(TARGET).exe
	wineconsole --backend=curses gdb.exe $(TARGET).exe

debug2: $(TARGET).exe
	wine $(TARGET).exe & sleep 1 && sudo gdb -p $$! -ex go $(TARGET).exe

%.exe: %.o
	$(MINGWARCH)-w64-mingw32-ld $< $(LDFLAGS) -o $@

%.o: %.s
	jwasm $(JWASMFLAGS) $<

clean:
	rm -f *.o *.exe
