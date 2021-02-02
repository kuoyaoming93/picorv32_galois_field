#ifndef FIRMWARE_H
#define FIRMWARE_H

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

// irq.c
uint32_t *irq(uint32_t *regs, uint32_t irqs);

// print.c
void print_chr(char ch);
void print_str(const char *p);
void print_dec(unsigned int val);
void print_hex(unsigned int val, int digits);

// galois.c
uint8_t gadd(uint8_t a, uint8_t b);
uint8_t gmul(uint8_t a, uint8_t b);
uint8_t horner(uint8_t coeff[], uint8_t point);

#endif