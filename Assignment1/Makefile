all: run

run: calc
	@./calc input

calc: calc.tab.c lex.yy.c
	@gcc -o calc calc.tab.c lex.yy.c -lfl

calc.tab.c: calc.y
	@bison -dv calc.y

lex.yy.c: calc.l
	@flex -l calc.l

clean:
	@rm -f calc.tab.c calc.tab.h lex.yy.c calc.output calc