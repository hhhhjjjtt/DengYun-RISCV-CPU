#include "platform.h"
#include "uart.h"

void uart_init(uint32_t baud_div) {
    UART_BDIV = baud_div;
}

void uart_putchar(char c) {
    while (!(UART_STAT & UART_STAT_TX_IDLE))
        ;
    UART_TX = (uint8_t)c;
}

void uart_puts(const char *s) {
    while (*s)
        uart_putchar(*s++);
}

void uart_putln(const char *s) {
    uart_puts(s);
    uart_putchar('\n');
}

void uart_puthex(uint32_t v) {
    static const char digits[] = "0123456789abcdef";
    uart_putchar('0');
    uart_putchar('x');
    for (int i = 28; i >= 0; i -= 4)
        uart_putchar(digits[(v >> i) & 0xF]);
}

void uart_putu32(uint32_t v) {
    char buf[10];
    int n = 0;
    if (v == 0) { uart_putchar('0'); return; }
    while (v) { buf[n++] = (char)('0' + (v % 10)); v /= 10; }
    while (n > 0) uart_putchar(buf[--n]);
}

int uart_rx_ready(void) {
    return (UART_STAT & UART_STAT_RX_VALID) != 0;
}

char uart_getchar(void) {
    while (!uart_rx_ready())
        ;
    return (char)(UART_RX & 0xFF);
}
