all: 
	clear
	flex -o bin/lex.yy.c src/lexical.l
	yacc -o bin/y.tab.c -d src/syntatic.y
	g++ bin/y.tab.c -o bin/output -Iinclude/ -lfl -std=c++11

	./bin/output < examples/code1.su

	