%{
#include <string>
#include <sstream>

#define TK_ATK 1
#define TK_AMPERSAND 2
#define TK_BEGIN 3
#define TK_END 4
#define TK_MAIN 5
#define TK_RETURN 6
#define TK_BREAK 7
#define TK_ALL 8

int lines = 0;
%}

DIGIT		[0-9]
LOWER		[a-z]
UPPER		[A-Z]
LETTER		{LOWER}|{UPPER}
LOALPHA		{LOWER}|{DIGIT}
UPALPHA 	{UPPER}|{DIGIT}
ALPHA		{LETTER}|{DIGIT}
AMPERSAND	&

BREAK		\r?\n
INDENT		\s{4}|\t
SPACE		\s|\t

INT     	{DIGIT}+
FLOAT   	{DIGIT}+(\.{DIGIT}*)?([eE][\-\+]?{DIGIT}+)?[fF?]
DOUBLE		{DIGIT}+(\.{DIGIT}*)?([eE][\-\+]?{DIGIT}+)?[dD]
LONG		{DIGIT}+[lL]
CHAR		\'[^\'\n]\'c
STRING		\'[^\'\n]\'|\"[^\'\n]\"

ID          {ALPHA}*{LOALPHA}{ALPHA}*
CONST       [{UPALPHA}_\-]*{UPALPHA}[{UPALPHA}_\-]*

COMMBST	    "/*"
COMMBFN     "*/"
COMMB       {COMMBST}[^{COMMBFN}]*{COMMBFN}
COMML	    "//".*\n

%%

"\n"		{lines++;}
"="			{
				yylval.label = yytext;
				return TK_ATR;
			}
{AMPERSAND}	{
				yylval.label = yytext;
				yylval.traslation = yytext;
				return TK_AMPERSAND;
			}
":"			{
				yylval.label = yytext;
				yylval.translation = "{";
				return TK_BEGIN;
			}
"end"		{
				yylval.label = yytext;
				yylval.translation = "}";
			}
{SPACE}+	{}
{COMML}		{lines++;}
{COMMB}		{
				for (int i = 0; yytext[i]; yytext[i] == '\n'? i++ : *yytext++);
				lines += i;
			}
"main"		{return TK_MAIN;}
"return"	{
				yylval.label = yytext;
				yylval.traslation = yytext;
				return TK_RETURN;
			}
"break"		{
				yylval.label = yytext;
				yylval.traslation = yytext;
				return TK_BREAK;
			}
"all"		{
				yylval.label = yytext;
				yylval.traslation = yytext;
				return TK_ALL;
			}
"write"
"writeln"
"read"
"next"
"int"
"float"
"long"
"double"
"bool"
"str"
"void"
"if"
"elif"
"else"
"while"
"for"
"in"
[\(\)\{\}\[\];,:]	{return *yytext;}
"+"
"++"
"--"
"-"
"*"
"/"
"%"
"<"
">"
"<="
">="
"=="
"!="
"and"
"or"
"not"
"true"
"false"
{INT}
{LONG}
{FLOAT}
{DOUBLE}
{CHAR}
{STRING}
{ID}
.			{*yytext};

%%