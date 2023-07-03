# EXECUTE THESE COMMANDS
flex –l mycalc.l 
bison -dv mycalc.y 
gcc -o mycalc mycalc.tab.c lex.yy.c –lfl

# THEN RUN
./mycalc input
