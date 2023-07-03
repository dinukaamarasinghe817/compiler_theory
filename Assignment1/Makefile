all: mycalc

mycalc: mycalc.tab.c lex.yy.c
	gcc -o mycalc mycalc.tab.c lex.yy.c -lfl

mycalc.tab.c: mycalc.y
	bison -dv mycalc.y

lex.yy.c: mycalc.l
	flex -l mycalc.l

clean:
	rm -f mycalc.tab.c mycalc.tab.h lex.yy.c mycalc.output mycalc