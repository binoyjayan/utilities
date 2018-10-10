/*###########################################################################*/
/*#                                                                         #*/
/*#     PPM2FB : PPM Image to Framebuffer Renderer                          #*/
/*#                                                                         #*/
/*#     Author: Binoy Jayan                                                 #*/
/*#     Date Written : March 15th, 2016                                     #*/
/*#                                                                         #*/
/*#     Description                                                         #*/
/*#     ------------                                                        #*/
/*#     This utility reads a PPM image in ASCII format and renders it       #*/
/*#     onto a framebuffer device                                           #*/
/*#                                                                         #*/
/*#     Before usage, a .ppm image has to be created using a photo editing  #*/
/*#     tool such as GIMP and adjusted using ppmquant                       #*/
/*#                                                                         #*/
/*#     NB: The ppm image has to be in 'P3' / 'P6' format.                  #*/
/*#         Pixels are represented in ASCII/Binary and maxcolors <= 255     #*/
/*#         Use ppmquant to adjust these preoperties in the image.          #*/
/*#                                                                         #*/
/*#     ppmquant may be found in package 'netpbm'                           #*/
/*#     sudo apt-get install netpbm                                         #*/
/*#                                                                         #*/
/*#                                                                         #*/
/*###########################################################################*/

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>

#define PPM_IMAGE_TYPE_P3 3
#define PPM_IMAGE_TYPE_P6 6

char image_type_str_p3[] = "P3";
char image_type_str_p6[] = "P6";

struct fb_t 
{
	struct fb_var_screeninfo vinfo;
	struct fb_fix_screeninfo finfo;
	long int screensize;
	char *fname;
	int fd;
	char *bp;
};

struct ppm_t
{
	int img_type;
	int maxcolors;
	int rows, cols;
	long int pixels;
	char *fname;
	FILE *fp;
};

struct fb_t * fb_open(char *fname)
{
	struct fb_t *fb;
	int fd;
	
	if((fd = open(fname, O_RDWR)) < 0) {
		perror(fname);
		errno = -ENOENT;
		goto nofbdev;
	}

	if((fb = calloc(1, sizeof(struct fb_t))) == NULL) {
		errno = -ENOMEM;
		perror(fname);
		goto nomem;
	}

	fb->fd = fd;

	// Get fixed screen information
	if (ioctl(fd, FBIOGET_FSCREENINFO, &fb->finfo) == -1) {
		perror("Error reading fixed information");
		goto readerr;
	}

	// Get variable screen information
	if (ioctl(fd, FBIOGET_VSCREENINFO, &fb->vinfo) == -1) {
		perror("Error reading variable information");
		goto readerr;
	}

	fb->screensize = (long int) fb->vinfo.xres * fb->vinfo.yres * fb->vinfo.bits_per_pixel / 8;
	fb->bp = (char *) mmap(0, fb->screensize, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
	if(fb->bp == NULL) {
		perror("Error: failed to map framebuffer device to memory");
		goto readerr;
	}
	fb->fname = fname;
	return fb;

readerr:
	free(fb);
nomem:
	close(fd);
nofbdev:
	errno = -ENODEV;
	return NULL;
}
void fb_close(struct fb_t *fb)
{
	if(fb == NULL)
		return;

	munmap(fb->bp, fb->screensize);
	close(fb->fd);
	free(fb);
}
void fb_putpixel(struct fb_t *fb, int x, int y, int r, int g, int b)
{
	long int loc;

	if(fb == NULL)
		return;

	loc = (y+fb->vinfo.yoffset) * fb->finfo.line_length + (x+fb->vinfo.xoffset) * fb->vinfo.bits_per_pixel/8;
	
	if (fb->vinfo.bits_per_pixel == 32) { //32bpp
		*(fb->bp + loc) = b;
		*(fb->bp + loc + 1) = g;
		*(fb->bp + loc + 2) = r;
		*(fb->bp + loc + 3) = 0; //Opaque
	} else { // Assume 16bpp
		unsigned short int t;
		t = r << 11 | g << 5 | b;
		*((unsigned short int*) (fb->bp + loc)) = t;
	}
}

void fb_display(struct fb_t *fb)
{
     printf("Framebuffer device : %s\n", fb->fname);
     printf("Screen resolution  : %d x %d\n", fb->vinfo.xres, fb->vinfo.yres);
     printf("Bits per Pixel     : %d\n", fb->vinfo.bits_per_pixel);
     printf("vinfo:xoffset      : %d\n", fb->vinfo.xoffset);
     printf("vinfo:yoffset      : %d\n", fb->vinfo.yoffset);
     printf("finfo:line_length  : %d\n", fb->finfo.line_length);
     printf("Screensize         : %ld\n", fb->screensize);
}

int ppm_open(char *fname, struct ppm_t *ppm)
{
	char c;
	int ret = 0;
	char buf[5];
	if((ppm->fp = fopen(fname, "r")) == NULL) {
		perror(fname);
		ret = -1;
		goto errnofile;
	}
	fgets(buf, sizeof(buf), ppm->fp);
	buf[2] = 0;
	// If neither of the formats P3 and P6
	if(strncmp(buf, "P3", 2) == 0) 
		ppm->img_type = PPM_IMAGE_TYPE_P3;
	else if (strncmp(buf, "P6", 2) == 0)
		ppm->img_type = PPM_IMAGE_TYPE_P6;
	else {
		printf("Invalid Image format - %s\n", buf);
		ret = -2;
		goto err_invalid;
	}
	ppm->rows = ppm_getint_ascii(ppm);
	ppm->cols = ppm_getint_ascii(ppm);
	ppm->maxcolors = ppm_getint_ascii(ppm);
	
	// Read line feeds at the end
	while ((c = fgetc(ppm->fp)) == '\n');
	ungetc(c, ppm->fp);

	if(ppm->rows < 0 || ppm->cols < 0) {
		printf("Invalid header information for Image. (%d * %d)\n", ppm->rows, ppm->cols);
		ret = -2;
		goto err_invalid;
	}
	if(ppm->maxcolors < 0 || ppm->maxcolors > 255) {
		printf("Unsupported max colors (%d) in image '%s'. Use values (0-255)\n", 
			ppm->maxcolors, fname);
		ret = -3;
		goto err_invalid;
	}
	ppm->fname = fname;
	ppm->pixels = (long int) ppm->rows * ppm->cols;
	return ret;

err_invalid:
	fclose(ppm->fp);
errnofile:
	return ret;
}

void ppm_close(struct ppm_t *ppm)
{
	fclose(ppm->fp);
}

char * ppm_image_type_str(struct ppm_t *ppm)
{
	switch(ppm->img_type) {
	case PPM_IMAGE_TYPE_P3:
		return "P3 (ASCII mode)"; 
	case PPM_IMAGE_TYPE_P6:
		return "P6 (Binary mode)";
	}
	return "??";
}
void ppm_display(struct ppm_t *ppm)
{
	printf("Image file       : %s\n", ppm->fname);
	printf("PPM Image type   : %s\n", ppm_image_type_str(ppm));
	printf("Image Resolution : %d x %d\n", ppm->rows, ppm->cols);
	printf("Max colors       : %d\n", ppm->maxcolors);
	printf("Total pixels     : %ld\n", ppm->pixels);
}

static inline int ppm_getint_binary(struct ppm_t *ppm)
{
	unsigned char num = -1;
	int elements;
	// Read a byte representing a single color component of a pixel
	elements = fread(&num, 1, 1, ppm->fp);
	//printf("%d(%d).", num, elements);

	if (elements > 0)
		return (int) num;
	else
		return -1;
}

int ppm_getint_ascii(struct ppm_t *ppm)
{
	char c;
	int num = -1;
	while ((c = fgetc(ppm->fp)) != EOF) {
		if (c == '#') {
			while ((c = fgetc(ppm->fp)) != EOF) 
				if (c == '\n')
					break;
		} else if(c >= '0' && c <= '9') {
			ungetc(c, ppm->fp);
			fscanf(ppm->fp, "%d", &num);
			break;
		}
	}
	return num;
}

int ppm_getpixel(struct ppm_t *ppm, int *r, int *g, int *b)
{
	if (ppm->img_type == PPM_IMAGE_TYPE_P3) {
		*r = ppm_getint_ascii(ppm);
		*g = ppm_getint_ascii(ppm);
		*b = ppm_getint_ascii(ppm);
	} else if (ppm->img_type == PPM_IMAGE_TYPE_P6) {
		*r = ppm_getint_binary(ppm);
		*g = ppm_getint_binary(ppm);
		*b = ppm_getint_binary(ppm);
	}

	if(*r < 0 || *g < 0 || *b < 0)
		return -1;
}

int render(struct fb_t *fb, struct ppm_t *ppm, int xorg, int yorg)
{
	int x, y, r, g, b;
	int pixel_count = 0;
	
	for (y = 0; y < ppm->rows; y++) {
		for (x = 0; x < ppm->rows; x++) {
			
			if (ppm_getpixel(ppm, &r, &g, &b) < 0) {
				printf("Unexpected EOF of ppm image. Only %d pixels found\n", pixel_count);
				return -1;
			}
			pixel_count++;
	
			//TODO: Remove this print and uncomment the function	
			if(pixel_count <= 10)
				printf("fb_putpixel(fb, %d, %d, %d, %d, %d)\n", xorg+x, yorg+y, r, g, b);
			// fb_putpixel(fb, xorg+x, yorg+y, r, g, b);
		}
	}
	printf("...\n");
	printf("Rendered %d pixels\n", pixel_count);
	return 0;
}

int main(int argc, char *argv[])
{
	struct ppm_t ppm;
	struct fb_t *fb;

	if(argc < 3)
	{
		printf("Usage: %s <fb dev> <ppm image>\n", argv[0]);
		return 1;
	}

	//TODO: Uncomment
	//if((fb = fb_open(argv[1])) == NULL)
	//	return 2;
	//fb_display(fb);

	if(ppm_open(argv[2], &ppm))
		return 3;

	ppm_display(&ppm);
	render(NULL, &ppm, 0, 0);

	//TODO: Uncomment
	//fb_close(fb);
	ppm_close(&ppm);
}


