%{
#include <stdio.h>
#include "calc.tab.h"
%}

digit [0-9]
id [a-z][a-z0-9]*
ws [ \t\n]

%%

"main()" {return(TMAIN); }
"{" {return(TOCB); }
"}" {return(TCCB); }
"int" {return(TINT); }
"float" {return(TFLOAT); }
"printvar" { return(TPRINTVAR); }
{digit}+"."{digit}+ { sscanf(yytext, "%f", &(yylval.float_val));
return TFLOATVAL; }
{digit}+ { sscanf(yytext, "%d", &(yylval.int_val));
return TINTVAL; }
"=" {return(TASSIGN); }
";" { return(TSEMICOLON); }
"+" { return(TADD); }
"*" { return(TMULT); }
{id} { yylval.variable_type.name = strdup(yytext); return TID; }
{ws} ;
. { fprintf(stderr, "Syntax error at line %d: ' %s '\n", yylineno, yytext); exit(EXIT_FAILURE); }

%%