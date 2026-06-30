#include "platform.h"
#include "uart.h"

int main(void) {
    uart_init(434);
    uart_puts("Hello World from DengYun-1!");

    GPIO_DIR        = 0x1;
    GPIO_OUT_DATA   = 0x0;

    while (1) {
        uint32_t t = CLINT_MTIME;
        while (CLINT_MTIME - t < CLK_HZ)   // wait 1 second
            ;
        GPIO_OUT_DATA ^= 0x1;
    }
}