TARGET ?= mipsel-linux-gnu
CFLAGS ?= --std=c++14
VERILATOR ?= verilator
VERILATOR_FLAGS ?= -Wall -Wno-fatal -trace -CFLAGS $(CFLAGS)
INSTS ?= inst_ori.mem inst_andi.mem inst_j.mem inst_syscall.mem
TESTS ?= test_bit.mem test_jump.mem test_shift.mem test_move.mem test_arith.mem test_cp0.mem test_trap.mem test_store.mem test_load.mem test_mul.mem

# disable builtin rules
.SUFFIEXES:
.SECONDARY:

%.o: %.s
	$(TARGET)-as -mips32 -EB $^ -o $@

%.bin: %.o
	$(TARGET)-objcopy -O binary $^ -j .text $@

%.gen.s: %.o
	$(TARGET)-objdump -D $^ -M no-aliases,gpr-names=numeric > $@

%.mem: %.bin %.gen.s
	xxd -p $< | tr -d '\n' | fold -w8 > $@

.PHONY: clean
clean:
	rm -f *.bin *.o *.mem *.gen.s

.PHONY: all
all: $(INSTS) $(TESTS)