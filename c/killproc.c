
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <linux/limits.h>

#define MAX_LINE  (PATH_MAX + 1024)
#define DELIMIT   " \n"
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#define SHELL "/system/bin/sh"

char buf[MAX_LINE];
char *uarr[64] = { "", "^u0_" };
int  uarr_n = 1;
char *str_except[] = { "", "com.android.systemui", "bash", "sh", "ps" };

typedef struct pinfo {
    FILE         *file;
    pid_t         pid;
    struct pinfo *next;
} pinfo;

static pinfo *plist = NULL;

FILE* xopen(const char *command, const char *mode)
{
    int fd[2];
    pinfo *cur, *old;

    if (mode[0] != 'r' && mode[0] != 'w') {
        errno = EINVAL;
        return NULL;
    }

    if (mode[1] != 0) {
        errno = EINVAL;
        return NULL;
    }

    if (pipe(fd)) {
        return NULL;
    }

    cur = (pinfo *) malloc(sizeof(pinfo));
    if (! cur) {
        errno = ENOMEM;
        return NULL;
    }

    cur->pid = fork();
    switch (cur->pid) {

    case -1:                    /* fork() failed */
        close(fd[0]);
        close(fd[1]);
        free(cur);
        return NULL;

    case 0:                     /* child */
        for (old = plist; old; old = old->next) {
            close(fileno(old->file));
        }

        if (mode[0] == 'r') {
            dup2(fd[1], STDOUT_FILENO);
        } else {
            dup2(fd[0], STDIN_FILENO);
        }
        close(fd[0]);   /* close other pipe fds */
        close(fd[1]);

        execl(SHELL, "sh", "-c", command, (char *) NULL);
        _exit(1);

    default:                    /* parent */
        if (mode[0] == 'r') {
            close(fd[1]);
            if (!(cur->file = fdopen(fd[0], mode))) {
                close(fd[0]);
            }
        } else {
            close(fd[0]);
            if (!(cur->file = fdopen(fd[1], mode))) {
                close(fd[1]);
            }
        }
        cur->next = plist;
        plist = cur;
    }

    return cur->file;
}

int xclose(FILE *file)
{
    pinfo *last, *cur;
    int status;
    pid_t pid;

    /* search for an entry in the list of open pipes */

    for (last = NULL, cur = plist; cur; last = cur, cur = cur->next) {
        if (cur->file == file) break;
    }
    if (! cur) {
        errno = EINVAL;
        return -1;
    }

    /* remove entry from the list */

    if (last) {
        last->next = cur->next;
    } else {
        plist = cur->next;
    }

    /* close stream and wait for process termination */
    fclose(file);
    do {
        pid = waitpid(cur->pid, &status, 0);
    } while (pid == -1 && errno == EINTR);

    /* release the entry for the now closed pipe */

    free(cur);

    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }
    errno = ECHILD;
    return -1;
}

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

	fp = xopen("ps -ef", "r");
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
	return xclose(fp);
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

