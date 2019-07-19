TARGET ?= mipsel-linux-gnu
DATA ?= serial.coe bootloader.coe

# disable builtin rules
MAKEFLAGS += --no-builtin-rules
.SECONDARY:

%.s.o: %.s
	$(TARGET)-as -mips32 -EB $^ -o $@

%.o: %.s.o
	$(TARGET)-ld -EB $^ boot.lds -o $@

%.bin: %.o
	$(TARGET)-objcopy -O binary $^ -j .text $@

%.gen.s: %.o
	$(TARGET)-objdump -D $^ -M no-aliases,gpr-names=numeric > $@

%.coe: %.bin %.gen.s
	echo 'memory_initialization_radix = 16;' > $@
	echo 'memory_initialization_vector = ' >> $@
	xxd -p $< | tr -d '\n' | fold -w8 >> $@

.PHONY: all
all: $(DATA)

.PHONY: clean
clean:
	rm -f *.bin *.o *.coe *.gen.s *.s.o

