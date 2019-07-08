TARGET ?= mipsel-linux-gnu
CFLAGS ?= --std=c++14
VERILATOR ?= verilator
VERILATOR_FLAGS ?= -Wall -Wno-fatal -trace -CFLAGS $(CFLAGS)

# disable builtin rules
.SUFFIEXES:
.SECONDARY:

%.o: %.s
	$(TARGET)-as -mips32 -EB $^ -o $@

%.bin: %.o
	$(TARGET)-objcopy -O binary $^ -j .text $@

%.gen.s: %.o
	$(TARGET)-objdump -D $^ > $@

%.mem: %.bin %.gen.s
	xxd -p $< | tr -d '\n' | fold -w8 > $@

clean:
	rm -f *.bin *.o *.mem *.gen.s

all: inst_ori.mem inst_andi.mem inst_j.mem test_bit.mem