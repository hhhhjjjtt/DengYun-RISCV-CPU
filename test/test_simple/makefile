RISCV_PREFIX ?= riscv-none-elf
CC      = $(RISCV_PREFIX)-gcc
OBJCOPY = $(RISCV_PREFIX)-objcopy
OBJDUMP = $(RISCV_PREFIX)-objdump

all: ROM_memory.elf ROM_memory.bin ROM_memory.dump riscvtest.mem

ROM_memory.elf: ROM_memory.s linker.ld
	$(CC) -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -mno-relax -T linker.ld -o $@ ROM_memory.s

ROM_memory.bin: ROM_memory.elf
	$(OBJCOPY) -O binary $< $@

ROM_memory.dump: ROM_memory.elf
	$(OBJDUMP) -d $< > $@

riscvtest.mem: ROM_memory.bin
	hexdump -v -e '1/4 "%08x" "\n"' $< > $@

clean:
	rm -f ROM_memory.elf ROM_memory.bin ROM_memory.dump riscvtest.mem