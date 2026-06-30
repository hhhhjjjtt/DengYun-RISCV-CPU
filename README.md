# DengYun-1 RISCV CPU
**DengYun-1** (**DY-1**) is a 32-bit RISC-V SoC written in Verilog, targeting FPGA deployment. The CPU core is a single-issue in-order 5-stage pipeline implementing RV32IM, backed by split L1 caches on an AXI4 interconnect. 

## Overview
![Overview](img/DengYun-1_SOC.png)

## Features
- **RV32IMZicsr** — base integer, multiply/divide, and privileged CSR instructions
- **5-stage pipeline**
- **Split L1 caches** — 2 KB 4-way set-associative with PLRU on both I and D caches; D-cache is write-back / write-allocate with dirty eviction before refill; hits served combinationally
- **AXI4 interconnect**
- **Trap and interrupt handling** — `ecall`, `ebreak`, `mret`; machine-mode timer and external interrupts gated by `mstatus.MIE`

## Testing
### Building
`cd test/test_full && make`\
Requires `riscv-none-elf-gcc`. Output lands in `test/test_full/mem/`.
### Vivado xsim
1. Add `rtl/src/*.v` to source directory and `rtl/tb/soc_top_tb_full.sv` to simulation directory.
2. Add generated `.mem` files to simulation directory
3. Run simulation

## Deploying on FPGA

**Tested board:** PYNQ-Z2 (Zynq xc7z020clg400-1). The SoC uses the PL only.

### Prerequisites
- Vivado 2024.x or later
- `riscv-none-elf-gcc` (for building firmware)
- Python 3 + `pyserial` (for `program_loader.py`)

### 1. Create the Vivado project
From the Vivado TCL console:

```tcl
source fpga/create_project.tcl
```
This creates a fresh project, adds all RTL sources, the XDC constraint file, and configures the clock wizard IP. Run once; afterwards open the generated project normally.

### 2. Build the bitstream

Use the Flow Navigator: **Generate Bitstream** (runs synthesis → implementation → bitstream automatically).

### 3. Load firmware

There are two ways to get firmware onto the board:

**A — Bake into bitstream (not recommended since re-synthesis is required on every firmware change)**

Build the firmware and place `rom.mem` + `ram.mem` where Vivado's synthesis can find them, then re-run synthesis + bitstream. Suitable for finalised programs.

**B — Runtime load via `program_loader.py` (recommended for development)**

The SoC includes a UART-based debug loader, with fixed baud rate of 115200. After programming the bitstream once, firmware can be updated in seconds without touching Vivado.

For example to build a simple assembly test:
```bash
# Assembly test
cd fpga/fpga_tests && make led_blink
```

To build a simple C project:
```bash
# C project (BSP)
cd sw/hello && make
```

Then, connect a USB-to-TTL adapter to the fpga board (defaulted as W9, Y8, W8) (3.3 V):

| Signal | Pin | Purpose |
|--------|-------------|---------|
| `i_debug_rx` | W9 | adapter TX → FPGA |
| `o_debug_tx` | Y8 | FPGA → adapter RX |
| `i_debug_en_n` | W8 | adapter RTS (active-low; idles high = run mode) |

Then load and run:

```bash
python program_loader.py <port_num> <mem_dir>
```

for example:

```bash
python program_loader.py COM3 fpga/fpga_tests/mem   # Windows
python program_loader.py /dev/ttyUSB0 sw/hello/mem  # Linux
```
The script holds the CPU in reset while writing, then releases it automatically.

### Default pin reference (PYNQ-Z2)

| Port | Pin | Function |
|------|-----|----------|
| `i_Clk` | H16 | 125 MHz board oscillator |
| `i_reset` | D19 | BTN0 (active-high) |
| `gpio_pins[0]` | R14 | LD0 |
| `gpio_pins[1]` | P14 | LD1 |
| `i_rx_serial` | Y18 | Application UART RX |
| `o_tx_serial` | W19 | Application UART TX |
| `i_debug_rx` | W9 | Debug loader RX |
| `o_debug_tx` | Y8 | Debug loader TX |
| `i_debug_en_n` | W8 | Debug enable, active-low |

Pin mapping can be adjusted in `fpga/constrs`

## Performance
[Placeholder — Add after Coremark test]

## Timeline
1. AXI4 bus (priority arbiter with DMA stub) + connect masters/slaves (✓)
3. Full SoC, assembly tests passing with new bus/cache (✓)
4. UART, GPIO, CLINT timer (✓)
5. FPGA synthesis, timing closure, blink/uart hello world (✓)
6. Program loader (✓)
7. C toolchain bring-up (✓)
8. Running Coremark performance check
---
9. Running RTOS
10. DMA (software-managed flush + non-cacheable region)
