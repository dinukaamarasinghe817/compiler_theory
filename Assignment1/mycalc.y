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
    void* address;
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
%left TOK_MUL
%left TOK_ADD

%%

prog: TMAIN TOCB stmts TCCB
stmts: stmt TSEMICOLON stmts | 
stmt: TINT TID {
    symTable[sym_count].name = strdup($2.name);
    symTable[sym_count].type = 0;
    symTable[sym_count].address = malloc(sizeof(int));
    $2.type = 0;
    sym_count++;
    //printf("after declaring %d\n",$2.type);
}
| TFLOAT TID {
    symTable[sym_count].name = strdup($2.name);
    symTable[sym_count].type = 1;
    symTable[sym_count].address = malloc(sizeof(float));
    $2.type = 1;
    sym_count++;
    //printf("after declaring %d\n",$2.type);
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
            //$1.type = $3.type;
            if(symTable[index].type == 0){
                *(int*)symTable[index].address = $3.value.int_val;
            }else{
                *(float*)symTable[index].address = $3.value.float_val;
            }
        } else {
            fprintf(stderr, "Line x: cannot assing type of %d to type of %d\n",$3.type, symTable[index].type);
        }
    } else {
        fprintf(stderr, "Line x: %s is used but is not declared\n", $1.name);
    }
    //printf("variable type after assigning %d\n",$1.type);
    //printf("expression type after assigning %d\n",$3.type);
    //printf("value after assigning %d\n",*(int*)symTable[index].address);
}
| TPRINTVAR TID {
    int found = 0;
    int index = -1;
    for (int i = 0; i < sym_count; i++) {
        if (strcmp(symTable[i].name, $2.name) == 0) {
            found = 1;
            index = i;
            break;
        }
    }

    if (found) {
        // printf("this is type when printing %s : %d\n",$2.name,$2.type);
        // printf("this is value when printing %s : %d\n",$2.name,$2.value.int_val);
        if(symTable[index].type == 0){
            printf("%d\n",*(int*)symTable[index].address);
        }else{
            printf("%f\n",*(float*)symTable[index].address);
        }
    }else{
        printf("variable %s has been used but not declared",$2.name);
    }
}

expr: TINTVAL {
    $$ = (struct exptr) { .type = 0, .value.int_val = $1 };
    //printf("vlaue of intvlaue %d\n",$1);
    //printf("type of expressionvlaue %d\n",$$.type);
    //printf("value of expressionvlaue %d\n",$$.value.int_val);
}
| TFLOATVAL {
    $$ = (struct exptr) { .type = 1, .value.float_val = $1 };
    //printf("vlaue of intvlaue %f\n",$1);
    //printf("type of expressionvlaue %d\n",$$.type);
    //printf("value of expressionvlaue %f\n",$$.value.float_val);
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
                .value.int_val = *(int*)symTable[index].address
            };
        }else{
            $$ = (struct exptr) { 
                .type = symTable[index].type, 
                .value.float_val = *(float*)symTable[index].address
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

    // Free memory in the symbol table
    for (int i = 0; i < sym_count; i++) {
        free(symTable[i].address);
    }
    return 0;
}


