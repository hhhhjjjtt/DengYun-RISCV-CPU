# led_blink.S

#define GPIO_BASE       0x22000
#define CLINT_BASE      0x24000

#define GPIO_OUT_DATA   0x00
#define GPIO_DIR        0x08
#define GPIO_INT_STATE  0x10

#define MTIME           0x00

#define TOGGLE_CYCLES   50000000

    .section .text
    .global _start

_start:
    li   sp, 0x20000

    /* configure GPIO: pin 0 = output */
    li   t0, GPIO_BASE
    li   t1, 0x1
    sw   t1, GPIO_DIR(t0)

    /* clear INT_STATE (flush any X from floating pin during IOBUF setup) */
    li   t1, -1
    sw   t1, GPIO_INT_STATE(t0)

    /* start with LED off */
    sw   zero, GPIO_OUT_DATA(t0)

    /* pre-load toggle period into s2 to avoid reloading inside the loop */
    li   s2, TOGGLE_CYCLES

    /* capture initial mtime */
    li   t0, CLINT_BASE
    lw   s0, MTIME(t0)          /* s0 = last_toggle_time */

    li   s1, 0                   /* s1 = current LED state */

blink_loop:
    /* poll mtime until 1 second has elapsed */
    li   t0, CLINT_BASE
    lw   t1, MTIME(t0)          /* t1 = current mtime */
    sub  t2, t1, s0             /* t2 = elapsed cycles (wraps safely) */
    bltu t2, s2, blink_loop     /* keep waiting if elapsed < TOGGLE_CYCLES */

    /* 1 second elapsed: update reference time */
    mv   s0, t1

    /* toggle LED state and write to GPIO */
    xori s1, s1, 1
    li   t0, GPIO_BASE
    sw   s1, GPIO_OUT_DATA(t0)

    j    blink_loop
