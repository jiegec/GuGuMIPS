TARGET ?= mipsel-linux-gnu
DATA ?= serial.coe bootloader.coe

# disable builtin rules
MAKEFLAGS += --no-builtin-rules
.SECONDARY:

.PHONY: all
all: $(DATA)

bootloader.c.o: bootloader.c
	$(TARGET)-gcc -c $^ -EL -o $@ -ffreestanding -mips32r2

bootloader.o: bootloader.c.o bootloader.s.o boot.lds
	$(TARGET)-ld -EL $^ -T boot.lds -o $@

%.s.o: %.s
	$(TARGET)-as -mips32 -EL $^ -o $@

%.o: %.s.o boot.lds
	$(TARGET)-ld -EL $^ -T boot.lds -o $@

%.bin: %.o
	$(TARGET)-objcopy -O binary $^ -j .text -j .rodata -j .data $@

%.gen.s: %.o
	$(TARGET)-objdump -D $^ -M no-aliases,gpr-names=numeric > $@

%.coe: %.bin %.gen.s
	echo 'memory_initialization_radix = 16;' > $@
	echo 'memory_initialization_vector = ' >> $@
	xxd -p $< | tr -d '\n' | fold -w8 | awk '{print substr($$0,7,2) substr($$0,5,2) substr($$0,3,2) substr($$0,1,2)}' >> $@


.PHONY: clean
clean:
	rm -f *.bin *.o *.coe *.gen.s *.s.o

