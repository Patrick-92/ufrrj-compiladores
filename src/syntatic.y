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
	string label; // nome da variável usada no cód. intermediário (ex: "t0")
	string type; // tipo no código intermediário (ex: "int")
	string transl; // código intermediário (ex: "int t11 = 1;")
};

typedef struct var_info {
	string type; // tipo da variável usada no cód. intermediário (ex: "int")
	string name; // nome da variável usada no cód. intermediário (ex: "t0")
} var_info;

string type1, type2, op, typeRes, value;
ifstream opMapFile, padraoMapFile;

map<string, string> opMap;
map<string, var_info> varMap;
map<string, string> padraoMap;
int tempGen = 0;

string getNextVar();

int yylex(void);
void yyerror(string);
%}

%token TK_PARAM
%token TK_NUM TK_CHAR TK_BOOL
%token TK_MAIN TK_ID TK_INT_TYPE TK_FLOAT_TYPE TK_CHAR_TYPE 
%token TK_DOUBLE_TYPE TK_LONG_TYPE TK_STRING_TYPE TK_BOOL_TYPE
%token TK_FIM TK_ERROR
%token TK_BREAK
%token TK_AND "and"
%token TK_OR "or"
%token TK_NOT "not"
%token TK_GTE ">="
%token TK_LTE "<="
%token TK_DIFFERENCE "!="
%token TK_EQUAL "=="

%start S

%left '+' '-'
%left '*' '/'
%left '<' '>' "<=" ">=" "!=" "=="
%left "and" "or" "not"

%%

S 			: TK_INT_TYPE TK_MAIN '(' ')' BLOCK {
				cout << 
				"/* Succinct lang */" << endl <<
				"#include <iostream>" << endl <<
				"#include <string.h>" << endl <<
				"#include <stdio.h>" << endl <<
				"int main(void) {" << endl <<
				$5.transl << 
				"\treturn 0;\n}" << endl;
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

STATEMENT 	: EXPR ';' {
				$$.transl = $1.transl;
			}
			| ATTRIBUTION ';' {
				$$.transl = $1.transl;
			};
			
ATTRIBUTION	: TYPE TK_ID '=' EXPR {
				if (!varMap.count($2.label)) {
					if ($4.type == $1.transl) {
						$$.transl = $4.transl;
						
						varMap[$2.label] = {$1.transl, $4.label};
					} else {
						// throw compile error
						$$.type = "ERROR";
						$$.transl = "ERROR";
					}
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| TK_ID '=' EXPR {
				if (varMap.count($1.label)) {
					var_info info = varMap[$1.label];
					
					// se tipo da expr for igual a do id
					if (info.type == $3.type) {
						varMap[$1.label] = {info.type, $3.label};
						$$.type = $3.type;
						$$.transl = $3.transl;
						$$.label = $3.label;
					} else {
						string var = getNextVar();
						string resType = opMap[info.type + "=" + $3.type];
						
						// se conversão é permitida
						if (resType.size()) {
							$$.transl = $3.transl + "\t" + info.type + " " + 
								var + " = (" + info.type + ") " + $3.label + ";\n";
							$$.type = info.type;
							$$.label = var;
							
							varMap[$1.label] = {info.type, var};
						} else {
							// throw compile error
							$$.type = "ERROR";
							$$.transl = "ERROR";
						}
					}
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| TYPE TK_ID {
				if (!varMap.count($2.label)) {
					string var = getNextVar();
					
					varMap[$2.label] = {$1.transl, var};
					
					$$.transl = "\t" + $1.transl + " " + $2.label + " = " + 
						padraoMap[$1.transl] + ";\n";
					$$.label = var;
					$$.type = $1.transl;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			};

EXPR 		: EXPR '+' EXPR {
				string var = getNextVar();
				
				string resType = opMap[$1.type + "+" + $3.type];
				
				if (resType.size()) {
					$$.type = resType;
					$$.transl = $1.transl + $3.transl + 
						"\t" + $$.type + " " + var + " = " + $1.label + " + " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR '-' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "-" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " - " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR '*' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "*" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " * " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR '/' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "/" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " / " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR '<' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "<" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " < " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR '>' EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + ">" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " > " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR "<=" EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "<=" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " <= " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR ">=" EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + ">=" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " >= " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR "==" EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "==" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " == " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR "!=" EXPR {
				string var = getNextVar();
				
				$$.type = opMap[$1.type + "!=" + $3.type];
				$$.transl = $1.transl + $3.transl + 
					"\t" + $$.type + " " + var + " = " + $1.label + " != " + $3.label + ";\n";
				$$.label = var;
			}
			| EXPR "and" EXPR {
				string var = getNextVar();
				
				if($1.type == "bool" && $3.type == "bool"){
					$$.transl = $1.transl + $3.transl + 
						"\t" + $$.type + " " + var + " = " + $1.label + " && " + $3.label + ";\n";
					$$.label = var;
				}else{
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR "or" EXPR {
				string var = getNextVar();
				
				if($1.type == "bool" && $3.type == "bool"){
					$$.transl = $1.transl + $3.transl + 
						"\t" + $$.type + " " + var + " = " + $1.label + " || " + $3.label + ";\n";
					$$.label = var;
				}else{
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| "not" EXPR {
				string var = getNextVar();
				
				if($2.type == "bool"){
					$$.transl = $2.transl + 
						"\t" + $$.type + " " + var + " =  ! " + $2.label + ";\n";
					$$.label = var;
				}else{
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}	
			}
			| '(' TYPE ')' VALUE {
				string var = getNextVar();
				string type = opMap[$2.type + "cast" + $4.type];
				
				if (type.size()) {
					$$.type = type;
					$$.transl = $4.transl + 
						"\t" + $$.type + " " + var + " = (" + $2.transl + ") " + $4.label + ";\n";
					$$.label = var;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| VALUE {
				$$.transl = $1.transl;
				$$.label = $1.label;
				$$.type = $1.type;
			};
			
TYPE		: TK_INT_TYPE
			| TK_FLOAT_TYPE
			| TK_DOUBLE_TYPE
			| TK_LONG_TYPE
			| TK_CHAR_TYPE
			| TK_STRING_TYPE
			| TK_BOOL_TYPE
			;
			
VALUE		: TK_NUM {
				string var = getNextVar();
				
				$$.transl = "\t" + $1.type + " " + var + " = " + $1.label + ";\n";
				$$.label = var;
			}
			| TK_CHAR {
				string var = getNextVar();
				
				$$.transl = "\t" + $1.type + " " + var + " = " + $1.label + ";\n";
				$$.label = var;
			}
			| TK_BOOL {
				string var = getNextVar();
				
				$1.label = ($1.label == "true"? "1" : "0");
				
				$$.transl = "\tint " + var + " = " + $1.label + ";\n";
				$$.label = var;
			}
			| TK_ID {
				var_info varInfo = varMap[$1.label];
				
				if (varInfo.name.size()) {
					$$.type = varInfo.type;
					$$.label = varInfo.name;
					$$.transl = "";
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}

%%

#include "lex.yy.c"

int yyparse();

int main(int argc, char* argv[]) {
	opMapFile.open("util/opmap.dat");
	padraoMapFile.open("util/default.dat");
	
	if (opMapFile.is_open()) {
		while (opMapFile >> type1 >> op >> type2 >> typeRes) {
	    	opMap[type1 + op + type2] = typeRes;
		}
		
		opMapFile.close();
	} else {
		cout << "Unable to open operator map file";
	}
	
	if (padraoMapFile.is_open()) {
		while (padraoMapFile >> type1 >> value) {
	    	padraoMap[type1] = value;
		}
		
		padraoMapFile.close();
	} else {
		cout << "Unable to open default values file";
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