#ifndef CSR_H
#define CSR_H

#include <stdint.h>

/* Read a CSR */
#define csrr(reg) \
    ({ uint32_t _v; __asm__ volatile("csrr %0, " #reg : "=r"(_v)); _v; })

/* Write a CSR */
#define csrw(reg, val) \
    __asm__ volatile("csrw " #reg ", %0" :: "r"((uint32_t)(val)))

/* Set bits in a CSR */
#define csrs(reg, bits) \
    __asm__ volatile("csrs " #reg ", %0" :: "r"((uint32_t)(bits)))

/* Clear bits in a CSR */
#define csrc(reg, bits) \
    __asm__ volatile("csrc " #reg ", %0" :: "r"((uint32_t)(bits)))

/* Convenience wrappers for common operations */
#define mstatus_mie_enable()   csrs(mstatus, 8)   /* global interrupt enable */
#define mstatus_mie_disable()  csrc(mstatus, 8)

/* mie bit positions */
#define MIE_MTIE   (1u << 7)   /* machine timer interrupt enable */
#define MIE_MEIE   (1u << 11)  /* machine external interrupt enable */

#endif /* CSR_H */
