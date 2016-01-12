
/*
 * Boot image information
 * Author : Binoy Jayan
 * Date Written: 04-28-2016
 *
*/

#include <stdio.h>
#include "bootimg.h"
#include <sys/stat.h>

#define SIGNATURE_SIZE 2048
#define ROUND_TO_PAGE(x,y) (((x) + (y)) & (~(y)))

#define SIG_SIZE 512
#define PAGE_SIZE 2048
#define MAX_BUF   (2048+32)
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
	struct boot_img_hdr *h;
	int ids = 1, i;
	int tot_size_calc, tot_size_file;
	FILE *fp;
	struct stat st;
	int ker_act, ram_act, page_mask;
	int sig, sig_bytes = SIG_SIZE;

	if(argc < 2) {
		printf("Usage: %s <boot.img> [number of IDs to display] [signature bytes]\n", argv[0]);
		return 1;
	}

	fp = fopen(argv[1], "r");
	
	if(argc > 2)
		ids = atoi(argv[2]);

	if(argc > 3)
		sig_bytes = atoi(argv[3]);

	if(fp == NULL) {
		perror(argv[1]);
		return 2;
	}
	
	fstat(fileno(fp), &st);
	tot_size_file = st.st_size;

	//fread((void *)&h, sizeof(struct boot_img_hdr), 1, fp);
	fread(buf, PAGE_SIZE, 1, fp);
	h = (struct boot_img_hdr*) buf;

	page_mask = h->page_size - 1;
	ker_act = ROUND_TO_PAGE(h->kernel_size,  page_mask);
	ram_act = ROUND_TO_PAGE(h->ramdisk_size,  page_mask);
	tot_size_calc = PAGE_SIZE + ker_act + ram_act;

	printf("Header size        : %lu [%d]\n", sizeof(struct boot_img_hdr), PAGE_SIZE);
	printf("magic              : %s\n", h->magic);
	printf("kernel_size        : %u [0x%x]\n", h->kernel_size, h->kernel_size);
	printf("kernel_size        : %u [0x%x] (Aligned)\n", ker_act, ker_act);
	printf("kernel_addr        : 0x%x\n", h->kernel_addr);

	printf("ramdisk_size       : %u [0x%x]\n", h->ramdisk_size, h->ramdisk_size);
	printf("ramdisk_size       : %u [0x%x] (Aligned)\n", ram_act, ram_act);
	printf("ramdisk_addr       : 0x%x\n", h->ramdisk_addr);

	printf("second_size        : %u\n", h->second_size);
	printf("second_addr        : 0x%x\n", h->second_addr);

	printf("tags_addr          : 0x%x\n", h->tags_addr);
	printf("page_size          : %u\n", h->page_size);

	printf("dt_size            : %u\n", h->dt_size);
	printf("unused             : %u\n", h->unused);

	printf("name               : %s\n", h->name);
	printf("cmdline            : %s\n", h->cmdline);

	printf("ids                : ");
	/* timestamp / checksum / sha1 / etc */
	for(i=0; i < ids; i++) {
		printf("0x%08x ", h->id[i]);
	}
	printf("\n");
	
	printf("Total size         : %d [%d + %d + %d]\n", 
					tot_size_calc, 
					PAGE_SIZE,
					ker_act,
					ram_act);

	printf("Total file size    : %u\n", tot_size_file);
	sig = tot_size_file - tot_size_calc;
	printf("Difference in size : %u\n", sig);

	if(sig > 0) {
		printf("Seeking to %d\n", tot_size_calc);
		fseek(fp, tot_size_calc, SEEK_SET);
		fread(buf, sig_bytes, 1, fp);
		printf("Digital signature dump:\n");
		hexdump(buf, sig_bytes);
	} else {
		printf("Signature not found\n");
	}
	
	fclose(fp);
	return 0;
}


