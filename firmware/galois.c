#include "firmware.h"

#define COEFFS 8

#define MAIN_NOT_EMPTY
//#define PRINT_LOG
//#define CUSTOM_CODES

int horner_test(void) 
{
#ifdef MAIN_NOT_EMPTY
    uint8_t coeff[COEFFS+1]; //= {255, 55, 22, 13, 64, 152, 30, 220, 110};
    coeff[0] = 255;
    coeff[1] = 55;
    coeff[2] = 22;
    coeff[3] = 13;
    coeff[4] = 64;
    coeff[5] = 152;
    coeff[6] = 30;
    coeff[7] = 220;
    coeff[8] = 110;

    uint8_t point = 43 * 2;
    uint16_t poly_rec = 0x11b;
    uint8_t result = horner8(coeff, point, poly_rec);

#ifdef PRINT_LOG
    print_str("Algoritmo de Horner\n");
    print_str("-------------------\n\n");
    print_str("Los coeficientes del polinomio de grado 8 son: ");
    int i = 0;
    for(i=0; i <= COEFFS; i++){
        print_dec(coeff[i]);
        print_str(" ");
    }
        
    print_str("\n");
    print_str("Se evalua en el punto ");
    print_dec(point);
    print_str("\n");

    print_str("Resultado: ");
    print_dec(result);
    print_str("\n");

    print_str("\n");
    print_str("Multiplicacion: ");
    print_dec(point*result);
    print_str("\n");
#endif
#endif
    return 0;
}


/* Add two numbers in the GF(2^8) finite field */
uint8_t gadd8(uint8_t a, uint8_t b) {
	return a ^ b;
}

/* Multiply two numbers in the GF(2^8) finite field defined 
 * by the polynomial x^8 + x^4 + x^3 + x + 1 = 0
 * using the Russian Peasant Multiplication algorithm
 * (the other way being to do carry-less multiplication followed by a modular reduction)
 */
uint8_t gmul8(uint8_t a, uint8_t b, uint16_t poly_rec) {
	uint8_t p = 0; /* the product of the multiplication */
	while (a && b) {
            if (b & 1) /* if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's) */
                p ^= a; /* since we're in GF(2^m), addition is an XOR */

            if (a & 0x80) /* GF modulo: if a >= 128, then it will overflow when shifted left, so reduce */
                a = (a << 1) ^ poly_rec; /* XOR with the primitive polynomial x^8 + x^4 + x^3 + x + 1 (0b1_0001_1011) – you can change it but it must be irreducible */
            else
                a <<= 1; /* equivalent to a*2 */
            b >>= 1; /* equivalent to b // 2 */
	}
	return p;
}

uint8_t horner8(uint8_t coeff[], uint8_t point, uint16_t poly_rec)
{
    int i = 0;
    uint8_t bx[COEFFS+1];
    uint32_t imm_result_h, imm_result;
    uint32_t mult_result;

    for (i = 0 ; i <= COEFFS; i++){
        if(i == 0)
            bx[0] = coeff[0];
        
#ifndef CUSTOM_CODES
        else 
            bx[i] = gadd8(coeff[i], gmul8(bx[i-1], point, poly_rec));
#else       
            asm volatile
            (   
                "gfwidth   %[z], %[x], %[y]\n\t"
                : [z] "=r" ((uint32_t)imm_result_h)
                : [x] "r" ((uint32_t)8), [y] "r" ((uint32_t)poly_rec)
            );  
            asm volatile
            (   
                "clmulh   %[z], %[x], %[y]\n\t"
                : [z] "=r" ((uint32_t)imm_result_h)
                : [x] "r" ((uint32_t)bx[i-1]), [y] "r" ((uint32_t)point)
            );  
            asm volatile
            (   
                "clmul   %[z], %[x], %[y]\n\t"
                : [z] "=r" ((uint32_t)imm_result)
                : [x] "r" ((uint32_t)bx[i-1]), [y] "r" ((uint32_t)point)
            );  
            asm volatile
            (   
                "gfred   %[z], %[x], %[y]\n\t"
                : [z] "=r" ((uint32_t)mult_result)
                : [x] "r" ((uint32_t)imm_result_h), [y] "r" ((uint32_t)imm_result)
            );  
            bx[i] = gadd8(coeff[i], mult_result);
#endif
    }
    return bx[COEFFS];
}

