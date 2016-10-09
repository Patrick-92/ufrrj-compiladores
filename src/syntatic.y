%{
#include <iostream>
#include <string>
#include <sstream>
#include <map>

#define YYSTYPE attributes

using namespace std;

struct attributes {
	string label;
	string type;
	string transl;
};

int tempGen = 0;

string getNextVar();

int yylex(void);
void yyerror(string);
%}

%token TK_NUM
%token TK_MAIN TK_ID TK_INT_TYPE
%token TK_FIM TK_ERROR
%token TK_BREAK

%start S

%left '+' '-'
%left '*' '/'

%%

S 			: TK_INT_TYPE TK_MAIN '(' ')' BLOCK {
				cout << "/* Succinct lang */\n" << 
				"#include <iostream>\n#include <string.h>\n#include <stdio.h>\nint main(void) {\n" 
				<< $5.transl << "\treturn 0;\n}" << endl;
			}
			;

BLOCK		: '{' STATEMENTS '}' {
				$$.transl = $2.transl;
			}
			;

STATEMENTS	: STATEMENT STATEMENTS {
				$$.transl = $1.transl + "\n" + $2.transl;
			}
			|
			;

STATEMENT 	: E ';' {
				$$.transl = $1.transl;
			};

E 			: E '+' E {
				string var = getNextVar();
				
				$$.transl = $1.transl + $3.transl + 
					"\t" + var + " = " + $1.label + " + " + $3.label + ";\n";
				$$.label = var;
			}
			| E '-' E {
				string var = getNextVar();
				
				$$.transl = $1.transl + $3.transl + 
					"\t" + var + " = " + $1.label + " - " + $3.label + ";\n";
				$$.label = var;
			}
			| E '*' E {
				string var = getNextVar();
				
				$$.transl = $1.transl + $3.transl + 
					"\t" + var + " = " + $1.label + " * " + $3.label + ";\n";
				$$.label = var;
			}
			| E '/' E {
				string var = getNextVar();
				
				$$.transl = $1.transl + $3.transl + 
					"\t" + var + " = " + $1.label + " / " + $3.label + ";\n";
				$$.label = var;
			}
			| TK_NUM {
				string var = getNextVar();
				
				$$.transl = "\t" + $1.type + " " + var + " = " + $1.transl + ";\n";
				$$.label = var;
			}
			| TK_ID 
			;

%%

#include "lex.yy.c"

int yyparse();

int main( int argc, char* argv[] )
{
	yyparse();

	return 0;
}

void yyerror( string MSG )
{
	cout << MSG << endl;
	exit (0);
}

string getNextVar() {
    return "t" + to_string(tempGen++);
}