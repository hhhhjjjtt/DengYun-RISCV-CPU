RISCV_PREFIX ?= riscv-none-elf
CC      = $(RISCV_PREFIX)-gcc
OBJCOPY = $(RISCV_PREFIX)-objcopy
OBJDUMP = $(RISCV_PREFIX)-objdump

all: ROM_memory.elf riscvtest.mem

.INTERMEDIATE: ROM_memory.bin

ROM_memory.elf: ROM_memory.s linker.ld
	$(CC) -march=rv32im -mabi=ilp32 -nostdlib -nostartfiles -mno-relax -T linker.ld -o $@ ROM_memory.s

ROM_memory.bin: ROM_memory.elf
	$(OBJCOPY) -O binary $< $@

riscvtest.mem: ROM_memory.bin
	hexdump -v -e '1/4 "%08x" "\n"' $< > $@

ROM_memory.dump: ROM_memory.elf
	$(OBJDUMP) -d $< > $@

clean:
	rm -f ROM_memory.elf ROM_memory.bin ROM_memory.dump riscvtest.mem