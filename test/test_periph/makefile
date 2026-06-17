# ---- Toolchain ----
AS      = riscv-none-elf-gcc
LD      = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy
HEXDUMP = hexdump

# ---- Source directories ----
SRC_DIRS = uart

# ---- Flags ----
ARCH    = -march=rv32im_zicsr
ABI     = -mabi=ilp32
CFLAGS  = $(ARCH) $(ABI)
LDFLAGS = -T linker.ld -nostdlib -nostartfiles -Wl,--gc-sections,--no-relax

# Search source dirs for .S and .o files so stems stay flat (no subdir prefix)
VPATH = $(SRC_DIRS)

# ---- Sources / Targets ----
SRCS      := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.S))
BASENAMES := $(notdir $(SRCS:.S=))
ELFS      := $(addsuffix .elf,$(BASENAMES))

MEM_DIR  := mem
INST_DIR := $(MEM_DIR)/inst_rom
DATA_DIR := $(MEM_DIR)/data_ram

INST_MEM := $(addprefix $(INST_DIR)/,$(addsuffix _inst_rom.mem,$(BASENAMES)))
DATA_MEM := $(addprefix $(DATA_DIR)/,$(addsuffix _data_ram.mem,$(BASENAMES)))

.SECONDARY: $(ELFS)

all: $(INST_MEM) $(DATA_MEM)

# ---- Build ----
%.o: %.S
	$(AS) -c $(CFLAGS) -o $@ $<

%.elf: %.o linker.ld
	$(LD) $< $(LDFLAGS) -o $@

# ---- .text -> mem/inst_rom/<name>_inst_rom.mem ----
$(INST_DIR)/%_inst_rom.mem: %.elf
	@mkdir -p $(dir $@)
	$(OBJCOPY) -O binary --only-section=.text $< $@.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $@.bin > $@
	@rm -f $@.bin
	@echo "Generated $@"

# ---- .data -> mem/data_ram/<name>_data_ram.mem ----
$(DATA_DIR)/%_data_ram.mem: %.elf
	@mkdir -p $(dir $@)
	$(OBJCOPY) -O binary --only-section=.data --only-section=.sdata $< $@.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $@.bin > $@
	@rm -f $@.bin
	@echo "Generated $@"

clean:
	rm -f *.o *.elf
	rm -rf $(MEM_DIR)

.PHONY: all clean
