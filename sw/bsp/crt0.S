/* crt0.S — C runtime startup for DengYun-1 SoC
 *
 * program_loader.py writes .data initial values directly to RAM (0x10000+)
 * before releasing the CPU, so no ROM→RAM copy is needed here.
 * We only need to zero .bss and call main().
 */

    .section .text.start
    .global _start

_start:
    la   sp, _stack_top

    /* zero .bss */
    la   t0, _bss_start
    la   t1, _bss_end
.Lbss_loop:
    bgeu t0, t1, .Lbss_done
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    .Lbss_loop
.Lbss_done:

    call main

.Lhalt:
    j    .Lhalt
