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

vector<string> decls;
map<string, string> opMap;
vector<map<string, var_info>> varMap;
map<string, string> padraoMap;
vector<int> stack;
int tempGen = 0;
int beginGen = 0;
int endGen = 0;
int beginGenLoop = 1;
int endGenLoop = 1;
int openBlock = 0;
int controlTiesContinue = 1;
int controlTiesBreak = 1;

string getNextVar();
string getCurrentVar();

string getBeginLabel();
string getPrevBeginLabel();
string getCurrentBeginLabel();

string getBeginLabelLoop();
string getPrevBeginLabelLoop ();
string getCurrentBeginLabelLoop ();
string getCurrentBeginLabelContinue();
void setBeginLabelLoop(int );

string getEndLabel();
string getEndLabelLoop();

string getCurrentEndLabel();
string getPrevEndLabelLoop ();
string getCurrentEndLabelLoop();
string getCurrentEndLabelLoopBreak();
void setEndLabelLoop(int );

void trueFlagOpenBlock();
void falseFlagOpenBlock();
int getFlagOpenBlock();

void pushContext();
void popContext();

var_info* findVar(string label);
void insertVar(string label, var_info info);
void insertGlobalVar(string label, var_info info);

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
%token TK_SWITCH "switch"
%token TK_CASE "case"
%token TK_DEFAULT "default"
%token TK_PRINT "print"
%token TK_ENDL "endl"
%token TK_INCREMENT "icmt"
%token TK_DECREMENT "dcmt"
%token TK_OPCOMPOUND_MORE_EQUAL "+="
%token TK_OPCOMPOUND_LESS_EQUAL "-="
%token TK_OPCOMPOUND_MULTIPLY_EQUAL "*="
%token TK_OPCOMPOUND_DIVIDE_EQUAL "/="
%token TK_QUESTION "?"
%token TK_EXPONENT "exp"
%token TK_CONTINUE "continue"
%token TK_BREAK_LOOP "break"
%token TK_GLOBAL "global"

%start S

%left '<' '>' "<=" ">=" "!=" "=="
%left '*' '/'
%left '+' '-'
%left "icmt" "dcmt"
%left "+=" "-=" "*=" "/="
%left "and" "or" "not"
%left "if" "elif" "else" "for" "while" "do" "switch"


%%
S			: PUSH_SCOPE T POP_SCOPE {
				$$.transl = $2.transl;
			};


T 			: TK_INT_TYPE TK_MAIN '(' ')' BLOCK {
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
				string begin = getBeginLabelLoop();
				string end = getEndLabelLoop();
				
				if(getFlagOpenBlock() == 1 && controlTiesContinue != beginGenLoop){
					setBeginLabelLoop(controlTiesContinue);
				}
				
				if(getFlagOpenBlock() == 1 && controlTiesBreak != endGenLoop){
					setEndLabelLoop(controlTiesBreak);
				}
				
				$$.transl = "";
				$$.label = "";
			}
			
LOWER_FLAG	: {
				falseFlagOpenBlock();
				string begin = getPrevBeginLabelLoop();
				string end = getPrevEndLabelLoop();
				controlTiesContinue++;
				controlTiesBreak++;
				
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
						endif + ":\n" +
						$6.transl;
					
				} else {
					// throw compile error
					yyerror("Condicional não é um booleano");
				}
			}
			| RAISE_FALG "while" '(' EXPR ')' BLOCK LOWER_FLAG{
				if($4.type == "bool"){
					string var = getNextVar();
					string begin = getCurrentBeginLabelLoop();
					string end = getCurrentEndLabelLoop();
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $4.transl +
						begin + ":\t" + var + " = !" + $4.label + ";\n" + 
						"\tif (" + var + ") goto " + end + ";\n" +
						$6.transl +
						"\tgoto " + begin + ";\n" +
						"\t" + end + ":\n";
				}else{
					yyerror("Variável " + $4.label + "com o tipo " + $4.type + "não é booleano\n");
				}
			}
			| RAISE_FALG "do" BLOCK "while" '(' EXPR ')' ';' LOWER_FLAG{
				if($6.type == "bool"){
					string begin = getCurrentBeginLabelLoop();
					string end = getCurrentEndLabelLoop();
					string var = getNextVar();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $6.transl +
						"\t" + begin + ":\t" + var + " = !" + $6.label + ";\n" + 
						//"\t" + begin + ":\n" +
						$3.transl +
						"\tif (" + var + ") goto " + begin + ";\n";
				}else{
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| RAISE_FALG "for" '(' PUSH_SCOPE ATTRIBUTION  EXPR  ATTRIBUTION ')' BLOCK LOWER_FLAG POP_SCOPE {
				if($6.type == "bool"){
					string var = getNextVar();
					string begin = getCurrentBeginLabelLoop();
					string end = getCurrentEndLabelLoop();
					
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
					yyerror("Variável " + $6.label + " com o tipo " + $6.type + " não é um booleano\n");
				}
			}
			| RAISE_FALG "switch" '(' EXPR ')' '{' CASE '}' {
				if($4.type == "int"){
					string var = getNextVar();
					string begin = getBeginLabelLoop();
					
					$$.transl = $4.transl + 
					"\t" + begin + ":\n" +
					$7.transl;
				}else {
					yyerror("Variável " + $4.label + " com o tipo " + $4.type + "não é um inteiro\n");
				}
			};
			
ELSE		: "elif" '(' EXPR ')' BLOCK ELSE {
				if ($3.type == "bool") {
					string var = getNextVar();
					string endif = getEndLabel();
					
					decls.push_back("\tint " + var + ";");
					
					$$.transl = $3.transl + 
						"\t" + var + " = !" + $3.label + ";\n" +
						"\tif (" + var + ") goto " + endif + ";\n" +
						$5.transl +
						endif + ":\n" +
						$6.transl;
					
				} else {
					// throw compile error
					yyerror("Condicional não é um booleano");
				}
			}
			| "else" BLOCK {
				
				string endelse = getEndLabel();
				string endif = getCurrentEndLabel();
				
				$$.transl = $2.transl /*+ 
					"\tgoto " + endelse + ";\n" +
						endif + ":" + $2.transl +
						"\n" + endelse + ":"*/;
			}
			;
			
CASE		: "case" EXPR BLOCK CASE {
				if ($2.type == "int") {
					string varCase = getCurrentVar();
					string endif = getEndLabel();
					
					$$.transl = $2.transl +
					"\tif (" + varCase + " != " + $2.label + " ) goto " + endif + ";\n" +
					$3.transl +
					"\t" + endif + ":\n" +
					$4.transl;
				} else {
					yyerror("Valor inserido não é um inteiro\n");
				}
			}
			| "default" BLOCK LOWER_FLAG{
				string endSwitch = getEndLabelLoop();
				
				$$.transl = $2.transl +
				"\t"+ endSwitch +";\n";
			}
			| { 
				string endSwitch = getEndLabelLoop();
				
				$$.transl = "\t" + endSwitch + "\n"; 
			}
			;
			
LOOP_CONTROL_MECHANISMS : "continue" {
							int flag = getFlagOpenBlock();
							
							if(flag >= 1){
								string begin = getCurrentBeginLabelContinue();
								$$.transl = "\tgoto " + begin + ";\n";
							} else {
								yyerror("Mecanismo de controle de laço (continue) fora de um laço!");
							}
						}
						| "break" {
							int flag = getFlagOpenBlock();
							
							if(flag >= 1){
								
								string end = getCurrentEndLabelLoopBreak();
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
					if ($1.label == "string") {
						if ($4.type == $1.transl) {
							$$.transl = $4.transl + "\tstrcpy(" + $2.transl + "," + $4.transl + ");\n";;
						
							insertVar($2.label, {$1.transl, $4.label});
						} else {
							// throw compile error
							$$.type = "ERROR";
							$$.transl = "ERROR";
						}
					} else {
						if ($4.type == $1.transl) {
							$$.transl = $4.transl;
						
							insertVar($2.label, {$1.transl, $4.label});
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
			| TK_GLOBAL TYPE TK_ID '=' EXPR {
				var_info* info = findVar($3.label);
	
				if (info == nullptr) {
					if ($4.type == $2.transl) {
						$$.transl = $5.transl;
						
						insertGlobalVar($3.label, {$2.transl, $5.label});
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
						if(info->type == "string"){
							$$.type = $3.type;
							$$.transl = $3.transl + "\tstrcpy(" + info->name + "," + $3.label + ");\n";
							$$.label = $3.label;
						} else {
							$$.type = $3.type;
							$$.transl = $3.transl + "\t" + info->name + " = " + $3.label + ";\n";
							$$.label = $3.label;
						}
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
							$$.transl = "ERROR1";
						}
					}
				} else {
					// throw compile error
					$$.type = "ERROR2";
					$$.transl = "ERROR2";
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
					
					if($1.transl == "string"){
						decls.push_back("\tchar " + var + "[10000];");
						
						$$.transl = "\tstrcpy(" + var + "," + padraoMap[$1.transl] + ");\n";
						
						$$.label = var;
						$$.type = $1.transl;
					}else {
						decls.push_back("\t" + $1.transl + " " + var + ";");
						
						// tá inserindo o tipo \/ ($1.transl): tirar!
						$$.transl = "\t" + var + " = " + 
							padraoMap[$1.transl] + ";\n";
						$$.label = var;
						$$.type = $1.transl;

					}
				} else {
					// throw compile error
					$$.type = "ERROR";
					$$.transl = "ERROR";
				}
			}
			| TK_GLOBAL TYPE TK_ID {
				var_info* info = findVar($3.label);
				
				if (info == nullptr) {
					string var = getNextVar();
					
					insertGlobalVar($3.label, {$2.transl, var});
					
					decls.push_back("\t" + $2.transl + " " + var + ";");
					
					// tá inserindo o tipo \/ ($1.transl): tirar!
					$$.transl = "\t" + var + " = " + 
						padraoMap[$2.transl] + ";\n";
					$$.label = var;
					$$.type = $2.transl;
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
					
					if ($3.type == "string") {
						$$.type = "char";
						$$.transl += "\tstrcat(" + $1.label + "," + $3.label + ");\n";
						$$.label = $1.label;
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
			| EXPR "exp" EXPR {
				string var = getNextVar();
				string var2 = getNextVar();
				string resType = opMap[$1.type + "exp" + $3.type];
				string begin = getBeginLabel();
				string end = getEndLabel();
				
				if (resType.size()) {
					$$.transl = $3.transl;
					
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
					decls.push_back("\t" + $$.type + " " + var2 + ";");
					
					$$.transl += "\tif (" + var2 + " > " + $3.label + ") goto " + end + ";\n" +
						"\n\t" + $1.label + " = " + $1.label + " * " + $1.label + ";\n" +
						"\t" + var2 + " = " + var2 + " + 1;\n" +
						"\n\tgoto " + begin + ";\n" +
						"\t" + end + ":\n" +
						"\t" + var + " = " + $1.label + ";\n";
						
					$$.label = var;
				} else {
					yyerror("Tipo" + $1.type + " ou " + $3.type + "não possuem conversão implícita");
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
				
				decls.push_back("\tchar " + var +"[10000];");
				$$.transl = "\tstrcpy(" + var + "," + value + ");\n";
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
			;

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

//Incrementa o valor para variáveis do código intermediário
string getNextVar() {
    return "t" + to_string(tempGen++);
}

//Verifica qual o valor atual da variável do código intermediário
string getCurrentVar() {
    return "t" + to_string(tempGen);
}

//Incrementa o valor do label BEGIN
string getBeginLabel() {
	return "BEGIN" + to_string(beginGen++);
}

//Decrementa o valor do label BEGIN
string getPrevBeginLabel () {
	return "BEGIN" + to_string(beginGen--);
}

//Verifica qual o valor atual do label BEGIN
string getCurrentBeginLabel() {
	return "BEGIN" + to_string(beginGen);
}

//-------------------------------------------------------

//Incrementa o valor do label BEGINLOOP
string getBeginLabelLoop() {
	return "BEGINLOOP" + to_string(beginGenLoop++);
}

//Decrementa o valor do label BEGINLOOP
string getPrevBeginLabelLoop () {
	return "BEGINLOOP" + to_string(beginGenLoop--);
}

//Verifica qual o valor atual do label BEGINLOOP
string getCurrentBeginLabelLoop () {
	return "BEGINLOOP" + to_string(beginGenLoop);
}

void setBeginLabelLoop(int update) {
	beginGenLoop = update;
}

//Decrementa 1 para adequação do valor do goto para o label BEGIN
string getCurrentBeginLabelContinue () {
	int temp = beginGenLoop;
	temp--;
	return "BEGINLOOP" + to_string(temp);
}

//Incrementa o valor do label END
string getEndLabel() {
	return "END" + to_string(endGen++);
}

//Verifica qual o valor atual do label END
string getCurrentEndLabel() {
	return "END" + to_string(endGen);
}

//Incrementa o valor do label ENDLOOP
string getEndLabelLoop() {
	return "ENDLOOP" + to_string(endGenLoop++);
}

//Decrementa o valor do do label ENDLOOP
string getPrevEndLabelLoop () {
	return "ENDLOOP" + to_string(endGenLoop--);
}

//Verifica qual o valor atual do label ENDLOOP
string getCurrentEndLabelLoop() {
	return "ENDLOOP" + to_string(endGenLoop);
}

void setEndLabelLoop(int update) {
	endGenLoop = update;
}

//Decrementa 1 para adequação do valor do goto para o label ENDLOOP
string getCurrentEndLabelLoopBreak() {
	int temp = endGenLoop;
	temp--;
	return "ENDLOOP" + to_string(temp);
}

//Incrementa a variável flag de controle de laço
void trueFlagOpenBlock () {
	openBlock += 1;
}

//Decrementa a variável flag de controle de laço
void falseFlagOpenBlock () {
	openBlock -= 1;
}

//Verifica qual o valor atual da variável flag
int getFlagOpenBlock () {
	return openBlock;
}

//Pesquisa variável na pilha de contexto
var_info* findVar(string label) {
	for (int i = varMap.size() - 1; i >= 0; i--) {
		if (varMap[i].count(label)) {
			return &varMap[i][label];
		}
	}
	
	return nullptr;
}

//Insere variável no contexto atual
void insertVar(string label, var_info info) {
	varMap[varMap.size() - 1][label] = info;
}

//Insere uma variável global no primeiro contexto
void insertGlobalVar(string label, var_info info) {
	varMap[0][label] = info;
}

//Empilha Contexto
void pushContext() {
	map<string, var_info> newContext;
	varMap.push_back(newContext);
}

//Desempilha Contexto
void popContext() {
	varMap.pop_back();
}