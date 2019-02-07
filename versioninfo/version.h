#ifndef __VERSION_INFO_H
#define __VERSION_INFO_H
#ifndef VERSION_INFO
#define VERSION_INFO "UNKNOWN_VERSION"
#endif
#include <stdio.h>
#include <string.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

static void project_version(char *str, int n)
{
	memcpy(str, VERSION_INFO, n);
}

static int project_read_pid(char *file)
{
	int fd, n = -1;
	char pid[16];

	if((fd = open(file, O_RDONLY)) < 0) {
		perror(file);
	} else {
		n = read(fd, pid, sizeof(pid));
		pid[n] = '\0';
		close(fd);
		n = strtol(pid, NULL, 10);
	}
	return n;
}

static int project_write_pid(char *file, int pid)
{
	int fd, n;
	char str[16];

	printf("creating pid [%d] file %s\n", pid, file);
	if((fd = open(file, O_CREAT | O_WRONLY, 0660)) < 0) {
		perror(file);
		return -1;
	}

	n = snprintf(str, sizeof(str), "%d\n", pid);
	write(fd, str, n);
	return 0;
}

static int project_init(char *file)
{
	int pid, oldpid, r = -1;
	struct stat s;

	pid = getpid();
	if (stat(file, &s) < 0) {
		r = project_write_pid(file, pid);
	} else {
		if((oldpid = project_read_pid(file)) < 0)
			return -1;
		printf("found pid [%d] file %s\n", oldpid, file);
		if(kill(oldpid, 0) < 0) {
			r = project_write_pid(file, pid);
		} else {
			printf("Process [pid:%d] running!\n", oldpid);
		}
	}
	return r;
}

static int project_cleanup(char *file)
{
	return remove(file);
}

#endif
