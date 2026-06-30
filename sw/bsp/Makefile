# DengYun-1 BSP Makefile
#
# Standalone usage (build from this directory):
#   make SRCS=../myproject/main.c TARGET=myapp
#
# Usage from a project subdirectory — project Makefile sets BSP_DIR then includes:
#   BSP_DIR = ../bsp
#   SRCS    = main.c
#   TARGET  = hello
#   include $(BSP_DIR)/Makefile

# ---- Toolchain ----
CC      = riscv-none-elf-gcc
OBJCOPY = riscv-none-elf-objcopy
HEXDUMP = hexdump

# ---- BSP location (override when including from a project) ----
BSP_DIR ?= $(CURDIR)

# ---- Compiler/linker flags ----
ARCH    = -march=rv32im_zicsr
ABI     = -mabi=ilp32
CFLAGS  = $(ARCH) $(ABI) -O2 -ffreestanding -fno-common \
          -Wall -Wextra -I$(BSP_DIR)/include
LDFLAGS = -T $(BSP_DIR)/linker.ld -nostdlib -nostartfiles \
          -Wl,--gc-sections,--no-relax

# ---- BSP sources (always linked in) ----
BSP_SRCS = $(BSP_DIR)/crt0.S $(BSP_DIR)/src/uart.c

# ---- Output paths (match program_loader.py expectations) ----
MEM_DIR ?= mem

# ---- Per-project overrides ----
TARGET  ?= app
SRCS    ?= main.c

# ---- Rules ----
.PHONY: all clean

all: $(MEM_DIR)/rom.mem $(MEM_DIR)/ram.mem

$(TARGET).elf: $(SRCS) $(BSP_SRCS) $(BSP_DIR)/linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRCS) $(BSP_SRCS)

# .text + .rodata → ROM image
$(MEM_DIR)/rom.mem: $(TARGET).elf
	@mkdir -p $(MEM_DIR)
	$(OBJCOPY) -O binary \
	    --only-section=.text --only-section=.rodata \
	    $< $(TARGET)_rom.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $(TARGET)_rom.bin > $@
	@rm -f $(TARGET)_rom.bin

# .data + .sdata → RAM image (empty if no initialized globals)
$(MEM_DIR)/ram.mem: $(TARGET).elf
	@mkdir -p $(MEM_DIR)
	$(OBJCOPY) -O binary \
	    --only-section=.data --only-section=.sdata \
	    $< $(TARGET)_ram.bin 2>/dev/null || true
	@touch $(TARGET)_ram.bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $(TARGET)_ram.bin > $@
	@rm -f $(TARGET)_ram.bin

clean:
	rm -f *.elf *.bin
	rm -rf $(MEM_DIR)
