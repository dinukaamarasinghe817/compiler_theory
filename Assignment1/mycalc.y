%{
#include <stdio.h>
#include <string.h>
extern FILE* yyin;
extern int yylex();
extern int yylineno;
extern char* yytext;
void yyerror(const char* s);

// Symbol table entry structure
struct symEntry {
    char* name;
    int type;
};

// Symbol table
struct symEntry symTable[100];
int sym_count = 0;
%}

%token TMAIN TINT TFLOAT TPRINTVAR TOCB TCCB
%token TFLOATVAL TINTVAL TID
%token TASSIGN TSEMICOLON TADD TMULT

/*all possible types*/
%union{
int int_val;
float float_val;
struct{
    int type;
    union{
        int int_val;
        float float_val;
        } value;
    char* name;
    } variable_type;
struct exptr{
    int type;
    union{
        int int_val;
        float float_val;
        } value;
    } expr_type;
}

%type <float_val> TFLOATVAL
%type <int_val> TINTVAL
%type <variable_type> TID
%type <expr_type> expr


/*left associative*/
%left TOK_MUL TOK_DIV
%left TOK_ADD TOK_SUB

%%

prog: TMAIN TOCB stmts TCCB
stmts: stmt TSEMICOLON stmts | 
stmt: TINT TID {
    symTable[sym_count].name = strdup($2.name);
    symTable[sym_count].type = 0;
    $2.type = 0;
    sym_count++;
}
| TFLOAT TID {
    symTable[sym_count].name = strdup($2.name);
    symTable[sym_count].type = 1;
    $2.type = 1;
    sym_count++;
}
| TID TASSIGN expr {
    int found = 0;
    int index = -1;
    for (int i = 0; i < sym_count; i++) {
        if (strcmp(symTable[i].name, $1.name) == 0) {
            found = 1;
            index = i;
            break;
        }
    }

    if (found) {
        if (symTable[index].type == $3.type) {
            if(symTable[index].type == 0){
                $1.value.int_val = $3.value.int_val;
                printf("type %d\n",$3.type);
            }else{
                $1.value.float_val = $3.value.float_val;
            }
        } else {
            fprintf(stderr, "Line x: cannot assing type of %d to type of %d\n",$3.type, symTable[index].type);
        }
    } else {
        fprintf(stderr, "Line x: %s is used but is not declared\n", $1.name);
    }

}
| TPRINTVAR TID {
    printf("this is type when printing %d",$2.type);
    if($2.type == 0){
        printf("%d\n",$2.value.int_val);
    }else{
        printf("%f\n",$2.value.float_val);
    }
}

expr: TINTVAL {
    $$ = (struct exptr) { .type = 0, .value.int_val = $1 };
}
| TFLOATVAL {
    $$ = (struct exptr) { .type = 1, .value.float_val = $1 };
}
| TID {
    int found = 0;
    int index = -1;
    for (int i = 0; i < sym_count; i++) {
        if (strcmp(symTable[i].name, $1.name) == 0 && symTable[i].type == $1.type) {
            found = 1;
            index = i;
            break;
        }
    }

    if(found){
        if(symTable[index].type == 0){
            $$ = (struct exptr) { 
                .type = symTable[index].type, 
                .value.int_val = $1.value.int_val
            };
        }else{
            $$ = (struct exptr) { 
                .type = symTable[index].type, 
                .value.float_val = $1.value.float_val
            };
        }
        printf("type here %d",$1.type);
    }else{
        fprintf(stderr, "Line x: %s is used but is not declared\n", $1.name);
    }
}
| expr TADD expr { 
    $$.type = $1.type;
    $$.value.int_val = $1.value.int_val + $3.value.int_val;
    $$.value.float_val = $1.value.float_val + $3.value.float_val;
}
| expr TMULT expr {
    $$.type = $1.type;
    $$.value.int_val = $1.value.int_val * $3.value.int_val;
    $$.value.float_val = $1.value.float_val * $3.value.float_val;
}

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax Error at line %d: %s\n", yylineno, s);
}

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    
    FILE* inputFile = fopen(argv[1], "r");
    if (!inputFile) {
        fprintf(stderr, "Error opening input file: %s\n", argv[1]);
        return 1;
    }
    
    yyin = inputFile;
    yyparse();
    
    fclose(inputFile);
    return 0;
}


