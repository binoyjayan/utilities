/*
 * Utility to extract html table values from an html document and
 * copy them into a csv file.
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#define MAX_VALUE (1024 * 32)
#define WHITE_SPACES " \t\n"
#define HTML_SPECIAL "<>/"

char *html_trim(char *str)
{
	char *p;

	while(*str == ' ')
		str++;

	p = str;
	while(*p && *p != ' ')
		p++;
	*p = '\0';

	return str;
}

int html_stricmp(const char *s1, const char *s2)
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

static bool is_one_of(char ch, char *chars)
{
	int i, n = strlen(chars);
	for(i = 0; i < n; i++) {
		if(ch == chars[i])
			return true;
	}
	return false;
}

static int html_skip_spaces(FILE *fp, char *spaces)
{
	char ch = '\0';
	while((ch = fgetc(fp)) != EOF) {
		if(!is_one_of(ch, spaces)) {
			ungetc(ch, fp);
			break;
		}
	}
	return (int) ch;
}

static int html_copy_until(FILE *fp, char *str, char *delim)
{
	int i = 0;
	char ch = '\0';
	while((ch = fgetc(fp)) != EOF) {
		if(is_one_of(ch, delim)) {
			ungetc(ch, fp);
			break;
		}
		if(str)
			str[i++] = ch;
	}
	if(str)
		str[i] = '\0';
	return (int) ch;
}

int html_gettag(FILE *fp, char *str, bool *open_tag)
{
	int i = 0, ch = '\0';
	bool single_tag = false;

	*open_tag = false;
	html_copy_until(fp, NULL, "<"); getc(fp);
	ch = getc(fp);
	if(ch != '/') {
		ungetc(ch, fp);
	} else {
		single_tag = true;
	}
	html_copy_until(fp, str, HTML_SPECIAL);
	ch = getc(fp);
	if(ch == '/') {
		html_copy_until(fp, NULL, ">");
		ch = getc(fp);
	}
	if(!single_tag)
		*open_tag = true;
	return ch;
}

int html_getval(FILE *fp, char *str)
{
	bool is_open_tag;
	char ch, *tag, tagstr[256];

	do {
		ch = fgetc(fp);
		ungetc(ch, fp);
		if(ch != '<') {
			break;
		}
		// If tag comes as part of Value
		ch = html_gettag(fp, tagstr, &is_open_tag);
		tag = html_trim(tagstr);
		if(!is_open_tag)
			break;
	} while(ch != EOF);

	return html_copy_until(fp, str, HTML_SPECIAL);
}

// process contents of the tag 'table'
int html_process_table(FILE *fp1, FILE *fp2)
{
	int column_num;
	bool is_open_tag;
	char ch = '\0', *tag, tagstr[256];
	char *val = malloc(MAX_VALUE);

	do {
		html_skip_spaces(fp1, WHITE_SPACES);
		ch = html_gettag(fp1, tagstr, &is_open_tag);
		tag = html_trim(tagstr);
		if(!is_open_tag && html_stricmp(tag, "table") == 0) {
			printf("</TAG:%s>\n", tag);
			break;
		}

		if(html_stricmp(tag, "td") == 0) {
			column_num++;
			if(is_open_tag) {
				// printf("<TAG:%s>", tag);
				ch = html_getval(fp1, val);
				if(column_num == 1)
					fprintf(fp2, "\"%s\"", val);
				else
					fprintf(fp2, ",\"%s\"", val);
			} else {
				// printf("</TAG:%s>", tag);
				html_skip_spaces(fp1, WHITE_SPACES);
			}
		} else if(html_stricmp(tag, "tr") == 0) {
			column_num = 0;
			if(is_open_tag) {
				//printf("<TAG:%s>\n", tag);
			} else {
				// printf("</TAG:%s>\n", tag);
				fprintf(fp2, "\n");
			}
		} else {
			// ch = html_getval(fp1, NULL);
			ch = html_copy_until(fp1, NULL, HTML_SPECIAL);
		}
	} while(ch != EOF);

	free(val);
	return ch;
}

int html_process(FILE *fp1, FILE *fp2)
{
	bool is_open_tag;
	char ch = '\0', *tag, tagstr[256];

	do {
		html_skip_spaces(fp1, WHITE_SPACES);
		ch = html_gettag(fp1, tagstr, &is_open_tag);
		tag = html_trim(tagstr);
		if(html_stricmp(tag, "table") == 0) {
			if(is_open_tag) {
				printf("<TAG:%s>\n", tag);
				ch = html_process_table(fp1, fp2);
			} else {
				printf("\n");
			}
		} else if(*tag != '\0'){
			if(is_open_tag) {
				ch = html_getval(fp1, NULL);
				printf("<TAG:%s>\n", tag);
			} else {
				printf("</TAG:%s>\n", tag);
			}
		}
	} while(ch != EOF);

	return ch;
}

int main(int argc, char *argv[])
{
	FILE *fp1, *fp2, *file;

	if(argc !=3)
	{
		printf("Usage: %s <htmlfile1> <csv file>\n", argv[0]);
		return 1;
	}

	//opea html file
	if((fp1 = fopen(argv[1], "r")) == NULL)
	{
		printf("Error in opening \'%s\'\n", argv[1]);
		return 2;
	}
	//open csv file for writing
	if((fp2 = fopen(argv[2], "w")) == NULL)
        {
                printf("Error in opening \'%s\'\n", argv[2]);
		fclose(fp1);
                return 3;
        }

	html_process(fp1, fp2);

	fclose(fp1);
	fclose(fp2);
	return 0;	
}
