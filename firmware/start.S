// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#define ENABLE_HORNER

	.section .text
	.global horner_test

reset_vec:
	j start


/* Main program
 **********************************/

start:

	/* set stack pointer */
	lui sp,(128*1024)>>12

	/* set gp and tp */
	lui gp, %hi(0xdeadbeef)
	addi gp, gp, %lo(0xdeadbeef)
	addi tp, gp, 0

#ifdef ENABLE_HORNER
	/* call sieve C code */
	jal ra,horner_test
#endif

	li a0, 0x20000000
	li a1, 123456789
	sw a1,0(a0)

	/* trap */
	ebreak


