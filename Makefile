all: 
	flex lexical.c
	gcc lex.yy.c -o lexical.l -lfl

#%: %.cc
#	g++ -std=c++11 $< -o $@

#%: %.c
#	gcc $< -o $@

	