#ifndef UART_H
#define UART_H

#include <stdint.h>

/* Set baud rate divisor: clk_hz / baud_rate.
 * At 50 MHz: 115200 baud → divisor 434. */
void uart_init(uint32_t baud_div);

/* Blocking single-byte transmit (spins until TX idle). */
void uart_putchar(char c);

/* Transmit a null-terminated string. */
void uart_puts(const char *s);

/* uart_puts followed by '\n'. */
void uart_putln(const char *s);

/* Print v as "0x" + 8 hex digits (no newline). */
void uart_puthex(uint32_t v);

/* Print v as unsigned decimal (no newline). */
void uart_putu32(uint32_t v);

/* Returns non-zero if a received byte is waiting. */
int uart_rx_ready(void);

/* Blocking single-byte receive (spins until rx_valid). */
char uart_getchar(void);

#endif /* UART_H */
