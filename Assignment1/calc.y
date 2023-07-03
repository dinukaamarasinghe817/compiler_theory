%{
#include <stdio.h>
#include <string.h>
extern FILE* yyin;
extern int yylex();
extern int yylineno;
extern char* yytext;
void yyerror(const char* s);
int findRecord(const char* name);

// Symbol table entry structure
struct symEntry {
    char* name;
    int type;
    void* address;
};

// Symbol table
struct symEntry symTable[100];

int sym_count = 0;
int indexer = -1;

%}

%token TMAIN TINT TFLOAT TPRINTVAR TOCB TCCB
%token TFLOATVAL TINTVAL TID
%token TASSIGN TSEMICOLON TADD TMULT

/*all possible types*/
%union{
int int_val;
float float_val;
struct{
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
    sym_count++;
}
| TFLOAT TID {
    symTable[sym_count].name = strdup($2.name);
    symTable[sym_count].type = 1;
    symTable[sym_count].address = malloc(sizeof(float));
    sym_count++;
}
| TID TASSIGN expr {
    if (findRecord($1.name)) {
        if (symTable[indexer].type == $3.type) {
            if(symTable[indexer].type == 0){
                *(int*)symTable[indexer].address = $3.value.int_val;
            }else{
                *(float*)symTable[indexer].address = $3.value.float_val;
            }
        } else {
            fprintf(stderr, "Line x: cannot assing type of '%s' to type of '%s'\n",$3.type == 0 ? "int" : "float", symTable[indexer].type == 0 ? "int" : "float");
        }
    } else {
        fprintf(stderr, "Line %d: %s is used but is not declared\n",yylineno, $1.name);
    }
}
| TPRINTVAR TID {
    if (findRecord($2.name)) {
        if(symTable[indexer].type == 0){
            printf("%d\n",*(int*)symTable[indexer].address);
        }else{
            printf("%f\n",*(float*)symTable[indexer].address);
        }
    }else{
        fprintf(stderr, "Line %d: %s is used but is not declared\n",yylineno, $2.name);
    }
}

expr: TINTVAL {
    $$ = (struct exptr) { .type = 0, .value.int_val = $1 };
}
| TFLOATVAL {
    $$ = (struct exptr) { .type = 1, .value.float_val = $1 };
}
| TID {
    if(findRecord($1.name)){
        if(symTable[indexer].type == 0){
            $$ = (struct exptr) { 
                .type = symTable[indexer].type, 
                .value.int_val = *(int*)symTable[indexer].address
            };
        }else{
            $$ = (struct exptr) { 
                .type = symTable[indexer].type, 
                .value.float_val = *(float*)symTable[indexer].address
            };
        }
    }else{
        fprintf(stderr, "Line %d: %s is used but is not declared\n",yylineno, $1.name);
    }
}
| expr TADD expr { // E + E
    if($1.type != $3.type){
        fprintf(stderr, "Line %d: invalid type of operands '%s' + '%s'\n",yylineno, $1.type == 0 ? "int" : "float", $3.type == 0 ? "int" : "float");
    }else{
        $$.type = $1.type;
        $$.value.int_val = $1.value.int_val + $3.value.int_val;
        $$.value.float_val = $1.value.float_val + $3.value.float_val;
    }
}
| expr TMULT expr { // E * E
    if($1.type != $3.type){
        fprintf(stderr, "Line %d: invalid type of operands '%s' * '%s'\n",yylineno, $1.type == 0 ? "int" : "float", $3.type == 0 ? "int" : "float");
    }else{
        $$.type = $1.type;
        $$.value.int_val = $1.value.int_val * $3.value.int_val;
        $$.value.float_val = $1.value.float_val * $3.value.float_val;
    }
}

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax Error at line %d: %s\n", yylineno, s);
}

int findRecord(const char* name) {
    for (int i = 0; i < sym_count; i++) {
        if (strcmp(symTable[i].name, name) == 0) {
            indexer = i;
            return 1;
        }
    }
    return 0;
}

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    
    // open the file
    FILE* inputFile = fopen(argv[1], "r");
    if (!inputFile) {
        fprintf(stderr, "Error opening input file: %s\n", argv[1]);
        return 1;
    }
    
    yyin = inputFile;
    yyparse();
    
    fclose(inputFile);

    // Free up the space on symbol table
    for (int i = 0; i < sym_count; i++) {
        free(symTable[i].address);
    }
    return 0;
}