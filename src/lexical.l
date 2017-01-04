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
CHAR		\'[^\'\n]\'
STRING		\'[^\'\n]+\'|\"[^\'\n]+\"
BOOL        "true"|"false"

ID          {ALPHA}*{LOALPHA}{ALPHA}*
CONST       [{UPALPHA}_\-]*{UPPER}[{UPALPHA}_\-*]

PARAM {ID}|({INT}|{FLOAT}|{DOUBLE})

COMMBST	    "/*"
COMMBFN     "*/"
COMMB       {COMMBST}[^{COMMBFN}]*{COMMBFN}
COMML	    "//".*\n

%%

{SPACE} 	{}

"main"		{ return TK_MAIN; }

"int"		{ yylval.transl = yytext; return TK_INT_TYPE; }
"float"		{ yylval.transl = yytext; return TK_FLOAT_TYPE; }
"double"	{ yylval.transl = yytext; return TK_DOUBLE_TYPE; }
"long"		{ yylval.transl = yytext; return TK_LONG_TYPE; }
"char"		{ yylval.transl = yytext; return TK_CHAR_TYPE; }
"string"	{ yylval.transl = yytext; return TK_STRING_TYPE; }
"bool"      { yylval.transl = yytext; return TK_BOOL_TYPE; }

[(){}[\];,]	{ return *yytext; }

[+\-*/=><]	{ return *yytext; }

"=="        { return TK_EQUAL; }
"!="        { return TK_DIFFERENCE; }
">="        { return TK_GTE; }
"<="        { return TK_LTE; }
"and"       { return TK_AND; }
"or"        { return TK_OR; }
"not"       { return TK_NOT; }

"+="        { return TK_OPCOMPOUND_MORE_EQUAL; }
"-="        { return TK_OPCOMPOUND_LESS_EQUAL; }
"*="        { return TK_OPCOMPOUND_MULTIPLY_EQUAL; }
"/="        { return TK_OPCOMPOUND_DIVIDE_EQUAL; }
"?"        { return TK_QUESTION; }

"print"     { return TK_PRINT; }
"endl"      { return TK_ENDL; }

"if"        { return TK_IF; }
"else"      { return TK_ELSE; }
"while"     { return TK_WHILE; }
"do"        { return TK_DO; }
"for"       { return TK_FOR; }
"continue"  { return TK_CONTINUE; }
"break"     { return TK_BREAK; }

"icmt"      { return TK_INCREMENT; }
"dcmt"      { return TK_DECREMENT; }

{INT}		{
    yylval.transl = "";
    yylval.label = yytext;
    yylval.type = "int";
    return TK_NUM;
}

{DOUBLE}    { 
    yylval.transl = "";
    yylval.label = yytext;
    yylval.type = "double";
    return TK_NUM;
}

{FLOAT}     { 
    yylval.transl = "";
    yylval.label = yytext;
    yylval.type = "float";
    return TK_NUM;
}

{CHAR}      {
    yylval.transl = "";
    yylval.label = yytext;
    yylval.type = "char";
    return TK_CHAR;
}

{BOOL}      {
    yylval.transl = "";
    yylval.label = yytext;
    yylval.type = "bool";
    return TK_BOOL;
}

{ID}		{ yylval.label = yytext; return TK_ID; }

{PARAM}     { yylval.label = yytext; return TK_PARAM; }

{BREAK}		{}

.			{ *yytext; }

%%