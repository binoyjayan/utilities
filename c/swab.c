#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <arpa/inet.h>

uint16_t swap16(uint16_t num)
{
	// Swap endian (big to little) or (little to big)
	uint32_t b0, b1;

	b0 = (num & 0x00ff) << 8u;
	b1 = (num & 0xff00) >> 8u;

	return b0 | b1;
}
uint32_t swap32(uint32_t num)
{
	// Swap endian (big to little) or (little to big)
	uint32_t b0,b1,b2,b3;

	b0 = (num & 0x000000ff) << 24u;
	b1 = (num & 0x0000ff00) << 8u;
	b2 = (num & 0x00ff0000) >> 8u;
	b3 = (num & 0xff000000) >> 24u;

	return b0 | b1 | b2 | b3;
}

int main(int argc, char *argv[])
{
	uint32_t l1, l2;
	uint16_t s1, s2;
	unsigned int n;

	n = 0xDEADBEEF;

	if (argc > 1)
		n = atoi(argv[1]);

	l1 = (uint32_t) n;
	s1 = (uint16_t) n;

	l2 = swap32(l1);
	s2 = swap16(s1);

	printf("swap32(%8u [0x%-8x]) = %8u[0x%-8x]\n", l1, l1, l2, l2);
	printf("swap16(%8hu [0x%-8x]) = %8hu[0x%-8x]\n", s1, s1, s2, s2);

	return 0;
}
