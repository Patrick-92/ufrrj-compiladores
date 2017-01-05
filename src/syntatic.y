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
int endGenLoop = 0;
bool openBlock = false;

string getNextVar();
string getBeginLabel();
string getCurrentBeginLabel();
string getEndLabel();
string getEndLabelLoop();
string getCurrentEndLabel();
string getCurrentEndLabelLoop();
void trueFlagOpenBlock();
void falseFlagOpenBlock();
bool getFlagOpenBlock();

void pushContext();
void popContext();

var_info* findVar(string label);
void insertVar(string label, var_info info);

int yylex(void);
void yyerror(string);
%}

%token TK_PARAM
%token TK_NUM TK_CHAR TK_STRING TK_BOOL
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
%token TK_INCREMENT "icmt"
%token TK_DECREMENT "dcmt"
%token TK_OPCOMPOUND_MORE_EQUAL "+="
%token TK_OPCOMPOUND_LESS_EQUAL "-="
%token TK_OPCOMPOUND_MULTIPLY_EQUAL "*="
%token TK_OPCOMPOUND_DIVIDE_EQUAL "/="
%token TK_QUESTION "?"
%token TK_CONTINUE "continue"
%token TK_BREAK_LOOP "break"

%start S

%left '<' '>' "<=" ">=" "!=" "=="
%left '*' '/'
%left '+' '-'
%left "icmt" "dcmt"
%left "+=" "-=" "*=" "/="
%left "and" "or" "not"
%left "continue" "break"
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

RAISE_FALG	: {
				trueFlagOpenBlock();
				
				$$.transl = "";
				$$.label = "";
			}
			
LOWER_FLAG	: {
				falseFlagOpenBlock();
				
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
			| DECLARATION ';' {
				$$.transl = $1.transl;
			}
			| ATTRIBUTION ';' {
				$$.transl = $1.transl;
			}
			| ATTRIBUTION_CONDITIONAL ';' {
				$$.transl = $1.transl;
			}
			| CONDITIONAL {
				$$.transl = $1.transl;
			}
			| LOOP_CONTROL_MECHANISMS ';' {
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
			| "while" '(' EXPR ')' RAISE_FALG BLOCK LOWER_FLAG {
				if($3.type == "bool"){
					string var = getNextVar();
					string begin = getBeginLabel();
					string end = getEndLabelLoop();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $3.transl + 
						//"\t" + $3.label + " = !" + $3.label + ";\n" +
						begin + ":\t" + var + " = !" + $3.label + ";\n" + 
						"\tif (" + var + ") goto " + end + ";\n" +
						$6.transl +
						"\tgoto " + begin + ";\n" +
						"\t" + end + ":\n";
				}else{
					yyerror("Variável " + $3.label + "com o tipo " + $3.type + "não é booleano\n");
				}
			}
			| "do" RAISE_FALG BLOCK LOWER_FLAG "while" '(' EXPR ')' ';' {
				if($7.type == "bool"){
					string begin = getBeginLabel();
					string end = getEndLabelLoop();
					string var = getNextVar();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $7.transl +
						"\t" + begin + ":\t" + var + " = !" + $7.label + ";\n" + 
						//"\t" + begin + ":\n" +
						$3.transl +
						"\tif (" + var + ") goto " + begin + ";\n";
				}else{
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| "for" '(' PUSH_SCOPE RAISE_FALG ATTRIBUTION  EXPR  ATTRIBUTION ')' BLOCK LOWER_FLAG POP_SCOPE {
				if($6.type == "bool"){
					string var = getNextVar();
					string begin = getBeginLabel();
					string end = getEndLabelLoop();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $5.transl + "\n" +
					begin + ":"  +
					$6.transl + "\t" + var + "= !" + $6.label + ";\n" +
					"\tif " + '(' + var + ") goto " + end + ";\n" +
					$9.transl + 
					$7.transl +
					"\tgoto " + begin + ";\n" +
					"\t" + end + ":\n";
					
				}else{
					yyerror("Variável " + $6.label + " com o tipo " + $6.type + " não é booleano\n");
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
			
LOOP_CONTROL_MECHANISMS : "continue" {
							bool flag = getFlagOpenBlock();
							
							if(flag == true){
								string begin = getCurrentBeginLabel();
								$$.transl = "\tgoto " + begin + ";\n";	
							} else {
								yyerror("Mecanismo de controle de laço (continue) fora de um laço!");
							}
						}
						| "break" {
							bool flag = getFlagOpenBlock();
							
							if(flag == true){
								string end = getCurrentEndLabelLoop();
								$$.transl = "\tgoto " + end + ";\n";
							} else {
								yyerror("Mecanismo de controle de laço (break) fora de um laço!");
							}
						}
						;
		
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
			| INCREMENT {
				$$.transl = $1.transl;
			}
			| DECREMENT {
				$$.transl = $1.transl;
			}
			| OP_COMPOUND {
				$$.transl = $1.transl;
			}
			;
			
ATTRIBUTION_CONDITIONAL : TK_ID '=' '(' EXPR ')' "?" TK_ID TK_ID {
				var_info* info = findVar($1.label);
				var_info* info2 = findVar($7.label);
				var_info* info3 = findVar($8.label);
				
				if($4.type == "bool"){
					if(info != nullptr && info2 != nullptr && info3 != nullptr){
						string var = getNextVar();
						string endif = getEndLabel();
						string endelse = getEndLabel();
						
						decls.push_back("\tint " + var + ";");
						
						$$.transl = $4.transl +
						"\t" + var + " = !" + $4.label + ";\n" +
						"\tif (" + var + ") goto " + endif + ";\n" +
						"\t" + info->name + " = " + info2->name + ";\n" +
						"\tgoto " + endelse + ";\n" +
						"\t" + endif + ":" +
						"\t" + info->name + " = " + info3->name + ";\n" +
						"\t" + endelse + ":\n";
					} else {
						yyerror("Variável " + $1.label + ", ou " + $7.label = ", ou " + $8.label + " inexistente !");
					}
				} else {
					yyerror("Expressão condicional não retorna valor booleano !");
				}
			};

DECLARATION : TYPE TK_ID {
				var_info* info = findVar($2.label);
				
				if (info == nullptr) {
					string var = getNextVar();
					
					insertVar($2.label, {$1.transl, var});
					
					decls.push_back("\t" + $1.transl + " " + var + ";");
					
					// tá inserindo o tipo \/ ($1.transl): tirar!
					$$.transl = "\t" + var + " = " + 
						padraoMap[$1.transl] + ";\n";
					$$.label = var;
					$$.type = $1.transl;
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			};
			
INCREMENT	: "icmt" TK_ID {
				var_info* info = findVar($2.label);
				
				if (info != nullptr){
					if (info->type == "int"){
						$$.label = info->name;
						$$.type = info->type;
						$$.transl = 
						"\t" + info->name + " = " + info->name + " + 1;\n";
					}else{
						yyerror("Tipo da variável " + $2.label + " não é inteiro !");
					}
				}else{
					yyerror("Variável" + $2.label + " inexistente !");
				}
			}
			| TK_ID "icmt" {
				var_info* info = findVar($1.label);
				
				if(info != nullptr){
					if(info->type == "int"){
						string var = getNextVar();
						
						decls.push_back("\tint " + var + ";");
						
						$$.label = info->name;
						$$.type = info->type;
						$$.transl = "\t" + var + " = " + info->name + " + 1;\n" +
						"\t" + info->name + " = " + var + ";\n";
					}else{
						yyerror("Tipo da variável " + $2.label + " não é inteiro !");
					}
				}else{
					yyerror("Variável" + $2.label + " inexistente !");
				}
			}
			;
			
DECREMENT	: "dcmt" TK_ID {
				var_info* info = findVar($2.label);
				
				if (info != nullptr){
					if (info->type == "int"){
						$$.label = info->name;
						$$.type = info->type;
						$$.transl =
						"\t" + info->name + " = " + info->name + " - 1;\n";
					}else{
						yyerror("Tipo da variável " + $2.label + " não é inteiro !");
					}
				}else{
					yyerror("Variável" + $2.label + " inexistente !");
				}
			}
			| TK_ID "dcmt" {
				var_info* info = findVar($1.label);
				
				if(info != nullptr){
					if(info->type == "int"){
						string var = getNextVar();
						
						decls.push_back("\tint " + var + ";");
						
						$$.label = info->name;
						$$.type = info->type;
						$$.transl = "\t" + var + " = " + info->name + " - 1;\n" +
						"\t" + info->name + " = " + var + ";\n";
					}else{
						yyerror("Tipo da variável " + $2.label + " não é inteiro !");
					}
				}else{
					yyerror("Variável" + $2.label + " inexistente !");
				}
			}
			;
			
OP_COMPOUND : TK_ID "+=" TK_NUM {
				var_info* info = findVar($1.label);
				
				if(info != nullptr){
					if(info->type == $3.type){
						$$.type = info->type;
						$$.label = info->name;
						$$.transl = $1.transl + $3.transl +
						"\t" + info->name + " = " + info->name + " + " + $3.label + ";\n";
					}else{
						yyerror("Tipo da variável " + $1.label + " diferente do valor '" + $3.label + "' acrescido!");
					}
				}else{
					yyerror("Variável" + $1.label + " inexistente !");
				}
			}
			| TK_ID "-=" TK_NUM {
				var_info* info = findVar($1.label);
				
				if(info != nullptr){
					if(info->type == $3.type){
						$$.type = info->type;
						$$.label = info->name;
						$$.transl = $1.transl + $3.transl +
						"\t" + info->name + " = " + info->name + " - " + $3.label + ";\n";
					}else{
						yyerror("Tipo da variável " + $1.label + " diferente do valor '" + $3.label + "' acrescido!");
					}
				}else{
					yyerror("Variável" + $1.label + " inexistente !");
				}
			}
			| TK_ID "*=" TK_NUM {
				var_info* info = findVar($1.label);
				
				if(info != nullptr){
					if(info->type == $3.type){
						$$.type = info->type;
						$$.label = info->name;
						$$.transl = $1.transl + $3.transl +
						"\t" + info->name + " = " + info->name + " * " + $3.label + ";\n";
					}else{
						yyerror("Tipo da variável " + $1.label + " diferente do valor '" + $3.label + "' acrescido!");
					}
				}else{
					yyerror("Variável" + $1.label + " inexistente !");
				}
			}
			| TK_ID "/=" TK_NUM {
				var_info* info = findVar($1.label);
				
				if(info != nullptr){
					if(info->type == $3.type){
						$$.type = info->type;
						$$.label = info->name;
						$$.transl = $1.transl + $3.transl +
						"\t" + info->name + " = " + info->name + " / " + $3.label + ";\n";
					}else{
						yyerror("Tipo da variável " + $1.label + " diferente do valor '" + $3.label + "' acrescido!");
					}
				}else{
					yyerror("Variável" + $1.label + " inexistente !");
				}
			}
			;

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
				string value = $1.label;
				
				decls.push_back("\t" + $1.type + " " + var + ";");
				$$.transl = "\t" + var + " = " + value + ";\n";
				$$.label = var;
			}
			| TK_STRING {
				string var = getNextVar();
				string value = $1.label;
				
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

string getCurrentBeginLabel() {
	return "BEGIN" + to_string(beginGen);
}

string getEndLabel() {
	return "END" + to_string(endGen++);
}

string getEndLabelLoop() {
	return "ENDLOOP" + to_string(endGenLoop++);
}

string getCurrentEndLabel() {
	return "END" + to_string(endGen);
}

string getCurrentEndLabelLoop() {
	return "ENDLOOP" + to_string(endGenLoop);
}

void trueFlagOpenBlock () {
	openBlock = true;
}

void falseFlagOpenBlock () {
	openBlock = false;
}

bool getFlagOpenBlock () {
	return openBlock;
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