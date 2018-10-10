
char s[3000];
main(int argc, char *argv[])
{
	if(argc != 3)
	{
		printf("Usage : %s <no:>  <message>\n", argv[0]);
		return 1;
	}
	system("mesg y");
	sprintf(s, "echo %s | write.orig cb206mc%03d", argv[2], atoi(argv[1]));
	system(s);
	return 0;
}
