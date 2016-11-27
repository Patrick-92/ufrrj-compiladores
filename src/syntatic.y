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
	string endif;
};

typedef struct var_info {
	string type; // tipo da variável usada no cód. intermediário (ex: "int")
	string name; // nome da variável usada no cód. intermediário (ex: "t0")
} var_info;

string type1, type2, op, typeRes, value;
ifstream opMapFile, padraoMapFile;

vector<string> decls;
map<string, string> opMap;
vector<map<string, var_info>> varMap;
map<string, string> padraoMap;
int tempGen = 0;
int beginGen = 0;
int endGen = 0;

string getNextVar();
string getBeginLabel();
string getEndLabel();
string getCurrentEndLabel();

void pushContext();
void popContext();

var_info* findVar(string label);
void insertVar(string label, var_info info);

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
%token TK_IF "if"
%token TK_ELIF "elif"
%token TK_ELSE "else"
%token TK_WHILE "while"
%token TK_DO "do"
%token TK_FOR "for"
%token TK_PRINT "print"
%token TK_ENDL "endl"

%start S

%left '<' '>' "<=" ">=" "!=" "=="
%left '+' '-'
%left '*' '/'
%left "and" "or" "not"
%left "if" "elif" "else" "for"

%%

S 			: TK_INT_TYPE TK_MAIN '(' ')' BLOCK {
				cout << 
				"/* Nebulous */" << endl <<
				"#include <iostream>" << endl <<
				"#include <string.h>" << endl <<
				"#include <stdio.h>" << endl <<
				"int main(void) {" << endl;
				
				for (string decl : decls) {
					cout << decl << endl;
				}
				
				cout << endl <<
				$5.transl << 
				"\treturn 0;\n}" << endl;
			};
			
PUSH_SCOPE: {
				pushContext();
				
				$$.transl = "";
				$$.label = "";
			}
			
POP_SCOPE:	{
				popContext();
				
				$$.transl = "";
				$$.label = "";
			}

BLOCK		:  PUSH_SCOPE '{' STATEMENTS '}' POP_SCOPE {
				$$.transl = $3.transl;
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
			}
			| CONDITIONAL {
				$$.transl = $1.transl;
			}
			| PRINT ';' {
				$$.transl = $1.transl;
			}
			| { $$.transl = ""; }
			;

CONDITIONAL : "if" '(' EXPR ')' BLOCK {
				if($3.type == "bool"){
					string end = getEndLabel();
					string var = getNextVar();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $3.transl + 
						"\t" + var + " = !" + $3.label + ";\n" +
						"\tif (" + var + ") goto " + end + ";\n" +
						$5.transl +
						"\t" + end + ":";
				}else{
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| "if" '(' EXPR ')' BLOCK ELSE {
				if ($3.type == "bool") {
					string var = getNextVar();
					string endif = getEndLabel();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $3.transl + 
						"\t" + var + " = !" + $3.label + ";\n" +
						"\tif (" + var + ") goto " + endif + ";\n" +
						$5.transl +
						$6.transl;
					
				} else {
					// throw compile error
					yyerror("Condicional não é um booleano");
				}
			}
			| "while" '(' EXPR ')' BLOCK {
				if($3.type == "bool"){
					string var = getNextVar();
					string begin = getBeginLabel();
					string end = getEndLabel();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $3.transl + 
						//"\t" + $3.label + " = !" + $3.label + ";\n" +
						begin + ":\t" + var + " = !" + $3.label + ";\n" + 
						"\tif (" + var + ") goto " + end + ";\n" +
						$5.transl +
						"\tgoto " + begin + ";\n" +
						"\t" + end + ":\n";
				}else{
					yyerror("Variável " + $3.label + "com o tipo " + $3.type + "não é booleano\n");
				}
			}
			| "do" BLOCK "while" '(' EXPR ')' ';' {
				if($5.type == "bool"){
					string begin = getBeginLabel();
					string end = getEndLabel();
					string var = getNextVar();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $5.transl +
						"\t" + begin + ":\t" + var + " = !" + $5.label + ";\n" + 
						//"\t" + begin + ":\n" +
						$2.transl +
						"\tif (" + var + ") goto " + begin + ";\n";
				}else{
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| "for" '(' PUSH_SCOPE ATTRIBUTION  EXPR  ATTRIBUTION ')' BLOCK POP_SCOPE {
				if($5.type == "bool"){
					string var = getNextVar();
					string begin = getBeginLabel();
					string end = getEndLabel();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $4.transl + "\n" +
					begin + ":"  +
					$5.transl + "\t" + var + "= !" + $5.label + ";\n" +
					"\tif " + '(' + var + ") goto " + end + ";\n" +
					$8.transl + 
					$6.transl +
					"\tgoto " + begin + ";\n" +
					"\t" + end + ":\n";
				}else{
					yyerror("Variável " + $5.label + " com o tipo " + $5.type + " não é booleano\n");
				}
			};
			
ELSE		: "else" BLOCK {
				
				string endelse = getEndLabel();
				string endif = getCurrentEndLabel();
				
				$$.transl = $2.transl + 
					"\tgoto " + endelse + ";\n" +
						endif + ":" + $2.transl +
						"\n" + endelse + ":";
			};
		
PRINT		: "print" PRINT_ARGS {
				$$.transl = "\tstd::cout" + $2.transl + ";\n";
			};
		
PRINT_ARGS	: PRINT_ARG PRINT_ARGS {
				$$.transl = $1.transl + $2.transl;
			}
			| PRINT_ARG { $$.transl = $1.transl; };
			
PRINT_ARG	: EXPR { $$.transl = " << " + $1.label; }
			| TK_ENDL { $$.transl = " << std::endl"; }
			;
			
ATTRIBUTION	: TYPE TK_ID '=' EXPR {
				var_info* info = findVar($2.label);
	
				if (info == nullptr) {
					if ($4.type == $1.transl) {
						$$.transl = $4.transl;
						
						insertVar($2.label, {$1.transl, $4.label});
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
				var_info* info = findVar($1.label);
				
				if (info != nullptr) {
					// se tipo da expr for igual a do id
					if (info->type == $3.type) {
						$$.type = $3.type;
						$$.transl = $3.transl + "\t" + info->name + " = " + $3.label + ";\n";
						$$.label = $3.label;
					} else {
						string var = getNextVar();
						string resType = opMap[info->type + "=" + $3.type];
						
						// se conversão é permitida
						if (resType.size()) {
							$$.transl = $3.transl + "\t" + info->type + " " + 
								var + " = (" + info->type + ") " + $3.label + ";\n\t" +
								info->name + " = " + var + ";\n";
							$$.type = info->type;
							$$.label = var;
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
				var_info* info = findVar($2.label);
				
				if (info == nullptr) {
					string var = getNextVar();
					
					insertVar($2.label, {$1.transl, var});
					
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
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
					
					$$.type = resType;
					decls.push_back("\t" + $$.type + " " + var + ";");
					$$.transl += "\t" + var + " = " + 
						$1.label + " + " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR '-' EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + "-" + $3.type];
				
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
					
					$$.type = resType;
					decls.push_back("\t" + $$.type + " " + var + ";");
					$$.transl += "\t" + var + " = " + 
						$1.label + " - " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR '*' EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + "*" + $3.type];
			
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
					
					$$.type = resType;
					decls.push_back("\t" + $$.type + " " + var + ";");
					$$.transl += "\t" + var + " = " + 
						$1.label + " * " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR '/' EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + "/" + $3.type];
			
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
					
					$$.type = resType;
					decls.push_back("\t" + $$.type + " " + var + ";");
					$$.transl += "\t" + var + " = " + 
						$1.label + " / " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR '<' EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + "<" + $3.type];
				
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
				
					$$.type = "bool";
					decls.push_back("\tint " + var + ";");
					$$.transl += "\t" + var + " = " + 
						$1.label + " < " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR '>' EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + ">" + $3.type];
				
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
				
					$$.type = "bool";
					decls.push_back("\tint " + var + ";");
					$$.transl += "\t" + var + " = " + 
						$1.label + " > " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}

			}
			| EXPR "<=" EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + "<=" + $3.type];
				
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
				
					$$.type = "bool";
					decls.push_back("\tint " + var + ";");
					$$.transl += "\t" + var + " = " + 
						$1.label + " <= " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR ">=" EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + ">=" + $3.type];
				
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
				
					$$.type = "bool";
					decls.push_back("\tint " + var + ";");
					$$.transl = $1.transl + $3.transl + 
						"\t" + var + " = " + $1.label + " >= " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR "==" EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + "==" + $3.type];
				
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
				
					$$.type = "bool";
					decls.push_back("\tint " + var + ";");
					$$.transl = $1.transl + $3.transl + 
						"\t" + var + " = " + $1.label + " == " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR "!=" EXPR {
				string var = getNextVar();
				string resType = opMap[$1.type + "!=" + $3.type];
				
				if (resType.size()) {
					$$.transl = $1.transl + $3.transl;
					
					if ($1.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $1.label + ";\n";
						
						$1.label = var1;
					}
					
					if ($3.type != resType) {
						string var1 = getNextVar();
						decls.push_back("\t" + resType + " " + var1 + ";");
						$$.transl += "\t" + var1 + " = (" + 
							resType + ") " + $3.label + "\n";
						
						$3.label = var1;
					}
				
					$$.type = "bool";
					decls.push_back("\tint " + var + ";");
					$$.transl = $1.transl + $3.transl + 
						"\t" + var + " = " + $1.label + " !== " + $3.label + ";\n";
					$$.label = var;
				} else {
					// throw compiler error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| EXPR "and" EXPR {
				string var = getNextVar();
				
				if($1.type == "bool" && $3.type == "bool"){
					decls.push_back("\t" + $$.type + " " + var + ";");
					$$.transl = $1.transl + $3.transl + 
						"\t" + var + " = " + $1.label + " && " + $3.label + ";\n";
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
					decls.push_back("\t" + $$.type + " " + var + ";");
					$$.transl = $1.transl + $3.transl + 
						"\t" + var + " = " + $1.label + " || " + $3.label + ";\n";
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
					decls.push_back("\t" + $$.type + " " + var + ";");
					$$.transl = $2.transl + 
						"\t" + var + " =  ! " + $2.label + ";\n";
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
				string value = $1.label;
				
				if ($1.type == "float") {
					value = to_string(stof(value));
				} else if ($1.type == "double") {
					value = to_string(stod(value));
				} else if ($1.type == "long") {
					value = to_string(stol(value));
				}
				
				decls.push_back("\t" + $1.type + " " + var + ";");
				$$.transl = "\t" + var + " = " + value + ";\n";
				$$.label = var;
			}
			| TK_CHAR {
				string var = getNextVar();
				
				decls.push_back("\t" + $1.type + " " + var + ";");
				$$.transl = "\t" + var + " = " + value + ";\n";
				$$.label = var;
			}
			| TK_BOOL {
				string var = getNextVar();
				
				$1.label = ($1.label == "true"? "1" : "0");
				
				decls.push_back("\tint " + var + ";");
				$$.transl = "\t" + var + " = " + value + ";\n";
				$$.label = var;
			}
			| TK_ID {
				var_info* varInfo = findVar($1.label);
				
				if (varInfo != nullptr) {
					$$.type = varInfo->type;
					$$.label = varInfo->name;
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

string getBeginLabel() {
	return "BEGIN" + to_string(beginGen++);
}

string getEndLabel() {
	return "END" + to_string(endGen++);
}

string getCurrentEndLabel(){
	return "END" + to_string(endGen);
}

var_info* findVar(string label) {
	for (int i = varMap.size() - 1; i >= 0; i--) {
		if (varMap[i].count(label)) {
			return &varMap[i][label];
		}
	}
	
	return nullptr;
}

void insertVar(string label, var_info info) {
	varMap[varMap.size() - 1][label] = info;
}

void pushContext() {
	map<string, var_info> newContext;
	varMap.push_back(newContext);
}

void popContext() {
	varMap.pop_back();
}