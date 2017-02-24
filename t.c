#include <stdio.h>
#include <string.h>

int main ()
{
  char str[] ="t3 = 2";
  char * pch;
  printf ("Splitting string \"%s\" into tokens:\n",str);
 pch = strtok (str,"t3 = ");

 //pch = strtok (pch,"= ");

  
printf ("%s\n",pch);

  return 0;
}