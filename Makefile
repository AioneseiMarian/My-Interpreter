all: clean interpreter 

interpreter: lexer.l interpreter.y
	bison -dv interpreter.y
	flex -o  lex.yy.c lexer.l
	gcc -o interpreter interpreter.tab.c lex.yy.c -lm -lfl

clean:
	rm -f interpreter lex.yy.c interpreter.tab.c interpreter.tab.h