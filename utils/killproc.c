
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/stat.h>
#include <linux/limits.h>

#define MAX_LINE  (PATH_MAX + 1024)
#define DELIMIT   " \n"
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

char buf[MAX_LINE];
char *uarr[64] = { "", "^u0_" };
int  uarr_n = 1;
char *str_except[] = { "", "com.android.systemui", "bash", "sh", "ps" };

static int exception(char *pname)
{
	int i, r, n;
	for(i = 0, r = 1; i < ARRAY_SIZE(str_except) && r; i++) {
		if (!str_except[i] || !(n = strlen(str_except[i])))
			continue;

		r = strncmp(str_except[i], pname, n);
	}
	return !r;
}

static int matchuser(char *uname)
{
	int i, r;

	for(i = 0, r = 1; i < uarr_n && r; i++) {
		if (uarr[i][0] == '^')
			r = strncmp(uarr[i] + 1, uname, strlen(uarr[i]) - 1);
		else
			r = strncmp(uarr[i], uname, strlen(uarr[i]));
	}
	return !r;
}

int killall_procs(char *argv[])
{
	FILE *fp;
	int pid, i, cnt = 0, tot = 0;
	char *uname, *spid, *pname, *sptr;

	fp = popen("ps -ef", "r");
	if (fp == NULL) {
		perror(argv[0]);
		return 1;
	}

	// skip the header line
	if (fgets(buf, MAX_LINE, fp) == NULL)
		goto end;

	for (; fgets(buf, MAX_LINE, fp) != NULL; tot++) {
		uname = strtok_r(buf, DELIMIT, &sptr);
		spid = strtok_r(NULL, DELIMIT, &sptr);
		i = 0;
		for (; i < 6 && (pname = strtok_r(NULL, DELIMIT, &sptr)); i++);

		if (matchuser(uname) && !exception(pname)) {
			cnt++;
			pid = (int) strtol(spid, &sptr, 10);
			printf("%-12s %-8s %s\n",
				uname, spid, pname);
			// kill(pid, 9);
		}
		
	}
	printf("Killed %d/%d process(es)\n", cnt, tot);
end:
	return pclose(fp);
}


int main(int argc, char *argv[])
{
	if(argc < 2) {
		printf("Usage: %s username\n", argv[0]);
		return 1;
	}
	str_except[0] = argv[0]; 
	uarr[0] = argv[1];
	return killall_procs(argv);
}

