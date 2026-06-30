# ---- Toolchain ----
AS      = riscv-none-elf-gcc
LD      = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy
HEXDUMP = hexdump

# ---- Flags ----
ARCH    = -march=rv32im_zicsr
ABI     = -mabi=ilp32
CFLAGS  = $(ARCH) $(ABI)
LDFLAGS = -T linker.ld -nostdlib -nostartfiles -Wl,--gc-sections,--no-relax

MEM_DIR  := mem

# ---- Named targets — each builds to the canonical rom.mem / ram.mem ----
# pynq_top.v instantiates soc_top with ROM_FILE="rom.mem" / RAM_FILE="ram.mem",
# so these are the filenames Vivado must find.
#
# Usage:  make led_blink   or   make uart_simple
# Adding a new test: append its basename to TESTS.

TESTS := led_blink uart_simple

define BUILD_TEST
.PHONY: $(1)
$(1): src/$(1).S linker.ld
	@mkdir -p $(MEM_DIR)
	$(AS) -c $(CFLAGS) -o $(1).o src/$(1).S
	$(LD) $(1).o $(LDFLAGS) -o $(1).elf
	$(OBJCOPY) -O binary --only-section=.text $(1).elf $(1)_inst.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $(1)_inst.bin > $(MEM_DIR)/rom.mem
	@rm -f $(1)_inst.bin
	$(OBJCOPY) -O binary --only-section=.data --only-section=.sdata $(1).elf $(1)_data.bin 2>/dev/null || true
	@touch $(1)_data.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $(1)_data.bin > $(MEM_DIR)/ram.mem
	@rm -f $(1)_data.bin $(1).o $(1).elf
	@echo "Built $(1) -> $(MEM_DIR)/rom.mem + $(MEM_DIR)/ram.mem"
endef

$(foreach t,$(TESTS),$(eval $(call BUILD_TEST,$(t))))

# ---- Convenience ----
.PHONY: all clean list

all:
	@echo "Available tests: $(TESTS)"
	@echo "Usage: make <test_name>"

list:
	@echo $(TESTS)

clean:
	rm -f *.o *.elf *.bin
	rm -rf $(MEM_DIR)
