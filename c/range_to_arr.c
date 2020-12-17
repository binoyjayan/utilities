#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define MAX_RANGE  64
#define DELIM_CPUS  ","
#define DELIM_RANGE ","

// Convert integer ranges 'n1-n2,n3-n4,n5' to an array of values
static int range_to_array(char range[], uint32_t arr[], int size) {
    int num = 0, num1, num2;
    char *str1, *str2, *token, *subtoken1, *subtoken2;
    char *saveptr1, *saveptr2;
    int j;

    for (j = 1, str1 = range; num < size; j++, str1 = NULL) {
        if (!(token = strtok_r (str1, ",", &saveptr1)))
            break;

        str2 = token;
        subtoken1 = strtok_r (str2, "-", &saveptr2);
        if (subtoken1) {
            subtoken2 = strtok_r (NULL, "-", &saveptr2);
            if (subtoken2) {
                // token contains a sub range like 'n1-n2'
                num1 = strtol(subtoken1, NULL, 10);
                num2 = strtol(subtoken2, NULL, 10);
                while (num1 <= num2 && num < size) {
                    arr[num++] = num1;
                    num1++;
                }
            } else {
                // token does not contain a sub range like 'n1-n2'
                if (num < size) 
                    arr[num++] = strtol(token, NULL, 10);
            }
        }
    }
    return num;
}


int main (int argc, char *argv[])
{
    int i, num;
    uint32_t arr[MAX_RANGE];
    if (argc != 2) {
        fprintf (stderr, "Usage: %s string\n", argv[0]);
        exit (EXIT_FAILURE);
    }
    num = range_to_array(argv[1], arr, sizeof(arr) / sizeof(arr[0]));
    for (i = 0; i < num ; i++) {
        printf ("%d: ----> %d\n", i, arr[i]);
    }
    return 0;
}


