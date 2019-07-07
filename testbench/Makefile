TARGET ?= mipsel-linux-gnu
CFLAGS ?= --std=c++14
VERILATOR ?= verilator
VERILATOR_FLAGS ?= -Wall -Wno-fatal -trace -CFLAGS $(CFLAGS)

# disable builtin rules
.SUFFIEXES:

%.o: %.s
	$(TARGET)-as -mips32 -EB $^ -o $@

%.bin: %.o
	$(TARGET)-objcopy -O binary $^ -j .text $@

%.mem: %.bin
	xxd -p $^ | tr -d '\n' | fold -w8 > $@

clean:
	rm -f *.bin *.o *.mem