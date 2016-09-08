%{
#include <stdio.h>
#include <stdlib.h>
%}

DIGIT	[0-9]
LOWER	[a-z]
UPPER	[A-Z]
LETTER	{LOWER}|{UPPER}
LOALPHA	{LOWER}|{DIGIT}
UPALPHA {UPPER}|{DIGIT}
ALPHA	{LETTER}|{DIGIT}

BREAK	\r?\n
INDENT	\s{4}|\t
SPACE   \s|\t

INT     {DIGIT}+
FLOAT   {DIGIT}+(\.{DIGIT}*)?([eE][\-\+]?{DIGIT}+)?[fF?]
DOUBLE  {DIGIT}+(\.{DIGIT}*)?([eE][\-\+]?{DIGIT}+)?[dD]
LONG    {DIGIT}+[lL]
CHAR    \'[^\'\n]\'c
STRING  \'[^\'\n]\'|\"[^\'\n]\"

ID          {ALPHA}*{LOALPHA}{ALPHA}*
CONST       [{UPALPHA}_\-]*{UPALPHA}[{UPALPHA}_\-]*

COMMBST	    "/*"
COMMBFN     "*/"
COMMB       {COMMBST}[^{COMMBFN}]*{COMMBFN}
COMMLST	    "//".*\n

%%

%%

void main()
{
	int val;/*, decimal = 0, hex = 0 , flo = 0;*/
	
	while(val = yylex()) {
		printf("%d\n", val);
		/*if (val == D) decimal++;
		if (val == H) hex++;	
		if (val == F) flo++;*/
	}

	/*printf("qtd. decimal = %d\nqtd. hex = %d\nqtd. flo = %d\n", decimal,hex,flo);*/
}