#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include "version.h"

#define PID_FILE "/tmp/app.pid"

void print_version()
{
	char version[256];
	project_version(version, sizeof(version));
	printf("Version:%s\n", version);
}

void handle_int(int n)
{
	project_cleanup(PID_FILE);
	putchar('\n');
	exit(0);
}

int main(int argc, char *argv[])
{
	int i;

	if (argc < 2) {
		printf("Usage: %s -v : Display version\n", argv[0]);
		printf("Usage: %s -r : Run the program\n", argv[0]);
		return 0;
	}

	if(strcmp(argv[1], "-v")  == 0) {
		print_version();
		return 0;
	}

	signal(SIGINT, handle_int);
	if(project_init(PID_FILE) < 0)
		return -1;

	printf("Running...");
	for(i = 0; i < 300; i++) {
		putchar('.'); fflush(stdout);
		sleep(5);
	}
	project_cleanup(PID_FILE);
	return 0;
}

