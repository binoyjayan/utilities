
#include <stdio.h>
#include "bootimg.h"
#include <sys/stat.h>

#define SIG_SIZE 512
#define MAX_BUF  2048

char buf[MAX_BUF];

int hexdump(char *buf, int size)
{
	int i;
	for(i = 0; i < size; i++) {
		printf("0x%02x ", (unsigned char) buf[i]);
	}
	printf("\n");
}
int main(int argc, char *argv[])
{
	FILE *fp;
	int bytes;

	if(argc < 2) {
		printf("Usage: %s <boot.img> <bytes>\n", argv[0]);
		return 1;
	}

	fp = fopen(argv[1], "r");
	
	if(argc > 2)
		bytes = atoi(argv[2]);

	if(fp == NULL) {
		perror(argv[1]);
		return 2;
	}

	printf("Hexdump {%d} bytes :\n", bytes);
	hexdump(buf, bytes);
	fclose(fp);
	return 0;
}


