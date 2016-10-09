%{
#include <string>
%}

/*
ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
ID {LETRA}({LETRA}|{NUM})*
*/

DIGIT		[0-9]
LOWER		[a-z]
UPPER		[A-Z]
LETTER		{LOWER}|{UPPER}
LOALPHA		{LOWER}|{DIGIT}
UPALPHA 	{UPPER}|{DIGIT}
ALPHA		{LETTER}|{DIGIT}
AMPERSAND	&

BREAK		\r?\n
INDENT		" "{4}|\t
/*Alterei o regex do espaço para qualquer quantidade de espaço*/
SPACE		[" "]{1,3}

INT     	{DIGIT}+
FLOAT   	{DIGIT}+(\.{DIGIT}*)?([eE][\-\+]?{DIGIT}+)?[fF]
DOUBLE		{DIGIT}+(\.{DIGIT}*)?([eE][\-\+]?{DIGIT}+)?[dD]?
LONG		{DIGIT}+[lL]
CHAR		\'[^\'\n]\'c
STRING		\'[^\'\n]\'|\"[^\'\n]\"

ID          {ALPHA}*{LOALPHA}{ALPHA}*
CONST       [{UPALPHA}_\-]*{UPPER}[{UPALPHA}_\-*]

COMMBST	    "/*"
COMMBFN     "*/"
COMMB       {COMMBST}[^{COMMBFN}]*{COMMBFN}
COMML	    "//".*\n

%%

{SPACE} 	{}

"main"		{ return TK_MAIN; }

"int"		{ return TK_INT_TYPE; }

[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

{INT}		{
    yylval.transl = yytext;
    yylval.type = "int";
    return TK_NUM;
}

{DOUBLE}    { 
    yylval.transl = yytext;
    yylval.type = "double";
    return TK_NUM;
}

{FLOAT}     { 
    yylval.transl = yytext;
    yylval.type = "float";
    return TK_NUM;
}

{ID}		{ yylval.label = yytext; return TK_ID; }

{BREAK}		{}

.			{ *yytext; }

%%