#include <stdio.h>
#include <stdlib.h>

void DieWithError(char *errorMessage) {
	fprintf(stderr, "%s", errorMessage);
	exit(1);
}

