
#include<stdio.h>
#include<string.h>

#define TRUE 1
#define BUFFER_SIZE 200

char str1[BUFFER_SIZE], str2[BUFFER_SIZE];

int stricmp(const char *s1, const char *s2)
{
	char f, l;

	do 
	{
		f = ((*s1 <= 'Z') && (*s1 >= 'A')) ? *s1 + 'a' - 'A' : *s1;
		l = ((*s2 <= 'Z') && (*s2 >= 'A')) ? *s2 + 'a' - 'A' : *s2;
		s1++;
		s2++;
	}while ((f) && (f == l));

	return (int) (f - l);
}



int main(int argc, char *argv[])
{
	int count = 0, line_number = 0;
	int file_end = 0;

	int n;

	FILE *fp1, *fp2, *file;

	if(argc !=3 )
	{
		printf("Usage: %s <file 1> <file 2>\n", argv[0]);
		return 1;
	}

	//open first file for reading.

	if((fp1 = fopen(argv[1], "r")) == NULL)
	{
		printf("Error in opening \'%s\'\n", argv[1]);
		return 2;
	}
	
	//open second file for reading.
	if((fp2 = fopen(argv[2], "r")) == NULL)
        {
                printf("Error in opening \'%s\'\n", argv[2]);
		fclose(fp1);
                return 3;
        }
		
	printf("\nComparing \'%s\' and \'%s\' for differences...\n\n", argv[1], argv[2]);
	
	//Read from both files, one line at a time and compare


	
	while(TRUE)	
	{
		line_number++;
		if(fgets(str1, BUFFER_SIZE, fp1) == NULL)
		{
			file_end = 1;
			printf("The file \'%s\' has come to an end.\n", argv[1]);
			break;
		}
		if(fgets(str2, BUFFER_SIZE, fp2) == NULL)
                {
                        file_end = 2;
			printf("The file \'%s\' has come to an end.\n", argv[2]);
			
                        break;
                }
		
		
		//remove trailing endline characters
		n = strlen(str1) - 1;
		if(str1[n] == '\n')
			str1[n] = '\0';
		n = strlen(str2) - 1;
		if(str2[n] == '\n')
			str2[n] = '\0';

		if(stricmp(str1, str2) != 0)
		{
			//if not equal
			printf("%-3d: %s(%s)\n", line_number, str1, argv[1]);
			printf("   : %s(%s)\n\n", str2, argv[2]);
			count++;
		}
			
	}
	switch(file_end)
	{
		case 1:
			file = fp2;
			break;
		case 2:
			file = fp1;
			break;
	
	}
	printf("-----------------------------------------------------\n");

	if(fgets(str1, BUFFER_SIZE, file) != NULL)
	{
		printf("\nRemaining lines of file \'%s\'\n", file_end==1?argv[2]:argv[1]);
		printf("%-3d: %s\n", line_number, str1);
	}

	while(fgets(str1, BUFFER_SIZE, file) != NULL)
	{
		line_number++;
		printf("%-3d: %s", line_number, str1);
		
		count++;
	}

	printf("\nFound %d differences...\n", count);

	fclose(fp1);
	fclose(fp2);
	return 0;	
}
