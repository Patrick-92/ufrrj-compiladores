%{
#include <iostream>
#include <string>
#include <sstream>
#include <map>
#include <fstream>
#include <vector>

#define YYSTYPE attributes

using namespace std;

struct attributes {
	string label;
	string type;
	string transl;
};

typedef struct var_info {
	string type;
	string name;
} var_info;

string type1, type2, op, typeRes;
ifstream opMapFile;

map<string, string> opMap;
map<string, var_info> varMap;
int tempGen = 0;

string getNextVar();

int yylex(void);
void yyerror(string);
%}

%token TK_NUM
%token TK_MAIN TK_ID TK_INT TK_FLOAT TK_DOUBLE TK_LONG TK_CHAR TK_STRING
%token TK_FIM TK_ERROR
%token TK_BREAK

%start S

%left '+' '-'
%left '*' '/'

%%

S 			: TK_INT TK_MAIN '(' ')' BLOCK {
				cout << "/* Succinct lang */\n" << 
				"#include <iostream>\n#include <string.h>\n#include <stdio.h>\nint main(void) {\n" 
				<< $5.transl << "\treturn 0;\n}" << endl;
			};

BLOCK		: '{' STATEMENTS '}' {
				$$.transl = $2.transl;
			};

STATEMENTS	: STATEMENT STATEMENTS {
				$$.transl = $1.transl + "\n" + $2.transl;
			}
			| STATEMENT {
				$$.transl = $1.transl + "\n";
			};

STATEMENT 	: E ';' {
				$$.transl = $1.transl;
			}
			| ATTRIBUTION ';' {
				$$.transl = $1.transl;
			};
			
ATTRIBUTION	: TYPE TK_ID '=' E {
				if ($4.type == $1.transl) {
					$$.transl = $4.transl;
					
					varMap[$2.label] = {$1.transl, $4.label};
				} else {
					// handle conversion or throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}

E 			: E '+' E {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "+" + $2.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " + " + $3.label + ";\n";
				$$.label = var;
			}
			| E '-' E {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "-" + $2.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " - " + $3.label + ";\n";
				$$.label = var;
			}
			| E '*' E {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "*" + $2.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " * " + $3.label + ";\n";
				$$.label = var;
			}
			| E '/' E {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "/" + $2.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " / " + $3.label + ";\n";
				$$.label = var;
			}
			| TK_NUM {
				string var = getNextVar();
				
				$$.transl = "\t" + $1.type + " " + var + " = " + $1.label + ";\n";
				$$.label = var;
			}
			| TK_ID {
				var_info varInfo = varMap[$1.label];
				
				if (varInfo.name.size()) {
					$$.type = varInfo.type;
					$$.label = varInfo.name;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			};
			
TYPE		: TK_INT
			| TK_FLOAT
			| TK_DOUBLE
			| TK_LONG
			| TK_CHAR
			| TK_STRING
			;

%%

#include "lex.yy.c"

int yyparse();

int main( int argc, char* argv[] ) {
	opMapFile.open("util/opmap.dat");
	
	if (opMapFile.is_open()) {
		while (opMapFile >> type1 >> op >> type2 >> typeRes) {
	    	opMap[type1 + op + type2] = typeRes;
		}
		
		opMapFile.close();
	} else {
		cout << "Unable to open operator map file";
	}

	yyparse();

	return 0;
}

void yyerror( string MSG ) {
	cout << MSG << endl;
	exit (0);
}

string getNextVar() {
    return "t" + to_string(tempGen++);
}