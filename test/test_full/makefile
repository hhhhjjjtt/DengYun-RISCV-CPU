# ---- Toolchain ----
AS      = riscv-none-elf-gcc
LD      = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy
OBJDUMP = riscv-none-elf-objdump
HEXDUMP = hexdump

# ---- Source directories ----
SRC_DIRS = rv32ui rv32um rv32mi

# ---- Flags ----
ARCH   = -march=rv32im_zicsr
ABI    = -mabi=ilp32
CFLAGS = $(ARCH) $(ABI) -I .
LDFLAGS = -T linker.ld -nostdlib -nostartfiles -Wl,--gc-sections,--no-relax

# ---- Sources / Targets ----
SRCS := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.S))
OBJS := $(SRCS:.S=.o)
ELFS := $(SRCS:.S=.elf)

MEM_DIR   := mem
INST_DIR  := $(MEM_DIR)/inst_rom
DATA_DIR  := $(MEM_DIR)/data_ram

# stems include the directory name
# e.g. rv32i/add.S -> rv32i/add
STEMS := $(SRCS:.S=)

INST_MEM := $(addprefix $(INST_DIR)/,$(addsuffix _inst_rom.mem,$(STEMS)))
DATA_MEM := $(addprefix $(DATA_DIR)/,$(addsuffix _data_ram.mem,$(STEMS)))

.SECONDARY: $(ELFS)

# Default
all: $(INST_MEM) $(DATA_MEM)

# ---- Build ----
%.o: %.S riscv_test.h test_macros.h
	$(AS) -c $(CFLAGS) -o $@ $<

%.elf: %.o linker.ld
	$(LD) $< $(LDFLAGS) -o $@

# ---- .text -> mem/inst_rom/<dir>/<name>_inst_rom.mem ----
$(INST_DIR)/%_inst_rom.mem: %.elf
	@mkdir -p $(dir $@)
	$(OBJCOPY) -O binary --only-section=.text $< $@.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $@.bin > $@
	@rm -f $@.bin
	@echo "Generated $@"

# ---- .data+.sdata -> mem/data_ram/<dir>/<name>_data_ram.mem ----
$(DATA_DIR)/%_data_ram.mem: %.elf
	@mkdir -p $(dir $@)
	$(OBJCOPY) -O binary --only-section=.data --only-section=.sdata $< $@.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $@.bin > $@
	@rm -f $@.bin
	@echo "Generated $@"

clean:
	rm -f $(OBJS) $(ELFS)
	rm -rf $(MEM_DIR)

.PHONY: all clean