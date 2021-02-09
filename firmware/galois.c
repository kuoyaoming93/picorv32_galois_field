#include "firmware.h"

#define COEFFS 8

int horner_test(void) 
{
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
    uint8_t result = horner(coeff, point);

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

    return 0;//result;
}


/* Add two numbers in the GF(2^8) finite field */
uint8_t gadd(uint8_t a, uint8_t b) {
	return a ^ b;
}

/* Multiply two numbers in the GF(2^8) finite field defined 
 * by the polynomial x^8 + x^4 + x^3 + x + 1 = 0
 * using the Russian Peasant Multiplication algorithm
 * (the other way being to do carry-less multiplication followed by a modular reduction)
 */
uint8_t gmul(uint8_t a, uint8_t b) {
	uint8_t p = 0; /* the product of the multiplication */
	while (a && b) {
            if (b & 1) /* if b is odd, then add the corresponding a to p (final product = sum of all a's corresponding to odd b's) */
                p ^= a; /* since we're in GF(2^m), addition is an XOR */

            if (a & 0x80) /* GF modulo: if a >= 128, then it will overflow when shifted left, so reduce */
                a = (a << 1) ^ 0x11b; /* XOR with the primitive polynomial x^8 + x^4 + x^3 + x + 1 (0b1_0001_1011) – you can change it but it must be irreducible */
            else
                a <<= 1; /* equivalent to a*2 */
            b >>= 1; /* equivalent to b // 2 */
	}
	return p;
}

uint8_t horner(uint8_t coeff[], uint8_t point)
{
    int i = 0;
    uint8_t bx[COEFFS+1];

    for (i = 0 ; i <= COEFFS; i++){
        if(i == 0)
            bx[0] = coeff[0];
        else 
            bx[i] = gadd(coeff[i], gmul(bx[i-1], point));
    }
    return bx[COEFFS];
}

