#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>

int strtollong(char *str, long long *num)
{
        char *end;

        *num = strtoll(str, &end, 10);
        switch(end[0])
        {
        case 'g':
        case 'G':
                *num *= 1024;
        case 'm':
        case 'M':
                *num *= 1024;
        case 'k':
        case 'K':
                *num *= 1024;
                end++;
        }

        if (end == str || *end != '\0')
                return errno ? errno: -1;
        return 0;
}

int main(int argc, char *argv[])
{
	int r;
	long long n;

	n = r = 0;
	if (argc > 1)
		r = strtollong(argv[1], &n);
	else
		printf("Usage: %s <integer>\n", argv[0]);

	printf("n=%llu, r=%d\n", n, r);
}
