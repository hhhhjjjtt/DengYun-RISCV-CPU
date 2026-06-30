#ifndef PLATFORM_H
#define PLATFORM_H

#include <stdint.h>

#define REG32(addr)  (*(volatile uint32_t *)(uintptr_t)(addr))

/* ---- System clock ---- */
#define CLK_HZ      50000000u   /* FCLK_CLK0 from Zynq clk_wiz_0 */

/* ---- Memory map ---- */
#define ROM_BASE    0x00000u
#define ROM_SIZE    0x10000u
#define RAM_BASE    0x10000u
#define RAM_SIZE    0x10000u

/* ---- Peripheral bases ---- */
#define PLIC_BASE   0x20000u
#define UART_BASE   0x21000u
#define GPIO_BASE   0x22000u
#define SPI_BASE    0x23000u
#define CLINT_BASE  0x24000u

/* ---- PLIC ---- */
#define PLIC_ENABLE     REG32(PLIC_BASE + 0x00)  /* interrupt enable bitmap */
#define PLIC_PENDING    REG32(PLIC_BASE + 0x04)  /* pending bits (read-only) */
#define PLIC_CLAIM      REG32(PLIC_BASE + 0x08)  /* claim: returns source ID */
#define PLIC_COMPLETE   REG32(PLIC_BASE + 0x0C)  /* complete: write source ID */

/* PLIC interrupt source IDs */
#define PLIC_SRC_UART_RX   0u
#define PLIC_SRC_UART_TX   1u
#define PLIC_SRC_GPIO      2u

/* ---- UART ---- */
#define UART_TX     REG32(UART_BASE + 0x00)  /* write: transmit byte */
#define UART_RX     REG32(UART_BASE + 0x04)  /* read:  received byte (clears rx_valid) */
#define UART_STAT   REG32(UART_BASE + 0x08)  /* [0]=tx_idle, [1]=rx_valid */
#define UART_BDIV   REG32(UART_BASE + 0x0C)  /* baud divisor: clk_hz / baud_rate */

#define UART_STAT_TX_IDLE   (1u << 0)
#define UART_STAT_RX_VALID  (1u << 1)

/* ---- GPIO ---- */
#define GPIO_OUT_DATA   REG32(GPIO_BASE + 0x00)  /* output data (for DIR[n]=1 pins) */
#define GPIO_IN_DATA    REG32(GPIO_BASE + 0x04)  /* sampled input data (read-only) */
#define GPIO_DIR        REG32(GPIO_BASE + 0x08)  /* direction: 1=output, 0=input */
#define GPIO_INT_EN     REG32(GPIO_BASE + 0x0C)  /* falling-edge interrupt enable */
#define GPIO_INT_STATE  REG32(GPIO_BASE + 0x10)  /* pending interrupts; W1C */

/* ---- CLINT ---- */
#define CLINT_MTIME     REG32(CLINT_BASE + 0x00)  /* free-running timer */
#define CLINT_MTIMECMP  REG32(CLINT_BASE + 0x04)  /* timer compare; write to arm */

#endif /* PLATFORM_H */
