%{
#include <stdio.h>
#include <string.h>
extern FILE* yyin;
extern int yylex();
extern int yylineno;
extern char* yytext;
void yyerror(const char* s);
void addID(char*name, int type);
struct symEntry* findID(char* name);
void freeSpace();

// Symbol table entry structure
struct symEntry {
    char* name;
    int type;
    void* address;
    int isInitialized;
    struct symEntry* next;
};

// Symbol table head and tail
struct symEntry* head = NULL;
struct symEntry* tail = NULL;

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
%left TADD
%left TMULT

%%

prog: TMAIN TOCB stmts TCCB
stmts: stmt TSEMICOLON stmts | 
stmt: TINT TID { // stmt -> int x
    struct symEntry* id = findID($2.name);
    if(id == NULL){
        addID($2.name, 0);
    }else{
        fprintf(stderr, "Line %d: variable %s is already been declared\n",yylineno, $2.name);
        YYABORT;
    }
}
| TFLOAT TID { // stmt -> float x
    struct symEntry* id = findID($2.name);
    if(id == NULL){
        addID($2.name, 1);
    }else{ // if the variable already exist
        fprintf(stderr, "Line %d: variable %s is already been declared\n",yylineno, $2.name);
        YYABORT;
    }
}
| TID TASSIGN expr { // stmt -> x = E
    struct symEntry* id = findID($1.name);
    if (id != NULL) { // if an entry exists
        if (id->type == $3.type) {
            if(id->type == 0){ // int
                *(int*)id->address = $3.value.int_val;
            }else{ // float
                *(float*)id->address = $3.value.float_val;
            }

            if(id->isInitialized == 0){ // mark as initialized if not already initialized
                id->isInitialized = 1;
            }
        } else { // missmatch of operands of assignment operator
            fprintf(stderr, "Line x: cannot assing type of '%s' to type of '%s'\n",$3.type == 0 ? "int" : "float", id->type == 0 ? "int" : "float");
            YYABORT;
        }
    } else { // using before declaring
        fprintf(stderr, "Line %d: variable %s is used but not declared\n",yylineno, $1.name);
        YYABORT;
    }
}
| TPRINTVAR TID { // stmt -> printvar x
    struct symEntry* id = findID($2.name);
    if (id != NULL) { // if an entry exists
        if(id->isInitialized == 0){ // can't print a variable before initialize it
            fprintf(stderr, "Line %d: variable %s is declared but not initialized\n",yylineno, $2.name);
            YYABORT;
        }else{
            if(id->type == 0){ // int
                printf("%d\n",*(int*)id->address);
            }else{ // float
                printf("%f\n",*(float*)id->address);
            }
        }
        
    }else{ // using before declaring
        fprintf(stderr, "Line %d: variable %s is used but not declared\n",yylineno, $2.name);
        YYABORT;
    }
}

expr: TINTVAL { // expr -> 3
    $$ = (struct exptr) { .type = 0, .value.int_val = $1 };
}
| TFLOATVAL { // expr -> 3.14
    $$ = (struct exptr) { .type = 1, .value.float_val = $1 };
}
| TID { // expr -> id
    struct symEntry* id = findID($1.name);
    if(id != NULL){ // if an entry exists
        if(id->isInitialized == 0){ // expression cannot be evaluated to an uninitialized identifier
            fprintf(stderr, "Line %d: variable %s is declared but not initialized\n",yylineno, $1.name);
            YYABORT;
        }else{
            if(id->type == 0){ // int 
                $$ = (struct exptr) { 
                    .type = id->type, 
                    .value.int_val = *(int*)id->address
                };
            }else{ // float
                $$ = (struct exptr) { 
                    .type = id->type, 
                    .value.float_val = *(float*)id->address
                };
            }
        }
    }else{ // using before declaring
        fprintf(stderr, "Line %d: variable %s is used but not declared\n",yylineno, $1.name);
        YYABORT;
    }
}
| expr TADD expr { // E + E
    if($1.type != $3.type){
        fprintf(stderr, "Line %d: invalid type of operands '%s' + '%s'\n",yylineno, $1.type == 0 ? "int" : "float", $3.type == 0 ? "int" : "float");
        YYABORT;
    }else{
        $$.type = $1.type;
        if($$.type == 0){
            $$.value.int_val = $1.value.int_val + $3.value.int_val;
        }else{
            $$.value.float_val = $1.value.float_val + $3.value.float_val;
        }
    }
}
| expr TMULT expr { // E * E
    if($1.type != $3.type){
        fprintf(stderr, "Line %d: invalid type of operands '%s' * '%s'\n",yylineno, $1.type == 0 ? "int" : "float", $3.type == 0 ? "int" : "float");
        YYABORT;
    }else{
        $$.type = $1.type;
        if($$.type == 0){
            $$.value.int_val = $1.value.int_val * $3.value.int_val;
        }else{
            $$.value.float_val = $1.value.float_val * $3.value.float_val;
        }
    }
}

%%

// indicates syntax errors occured because of no matching grammar rule
void yyerror(const char* s) {
    fprintf(stderr, "Syntax Error at line %d: %s\n", yylineno, s);
}

// function to add a new variable to the symbol table
void addID(char*name, int type){
    struct symEntry* newEntry = malloc(sizeof(struct symEntry));
    if(tail == NULL){ // if the symbol table is empty
        head = newEntry;
        tail = newEntry;
    }else{ // if not empty, directly jump to last entry and add the new one
        tail->next = newEntry;
        tail = tail->next;
        tail->next = NULL;
    }
    newEntry->name = strdup(name); // copying the name into the newEntry
    newEntry->type = type;
    newEntry->isInitialized = 0;
    newEntry->address = (type == 0) ? malloc(sizeof(int)) : malloc(sizeof(float));
}

// function to find an existing variable's address using symbol table
struct symEntry* findID(char* name){
    struct symEntry* start = head;
    struct symEntry* temp = start;
    while(temp != NULL && (strcmp(temp->name, name) != 0)){ 
        temp = temp->next;
    }
    return temp;
}

// function to free up the symbol table
void freeSpace(){
    struct symEntry* temp = head;
    while(temp != NULL){
        struct symEntry* pretemp = temp;
        temp = temp->next;
        free(pretemp);
    }
}

int main(int argc, char** argv) {
    // expecting an input file name as the argument
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
    
    // close the file
    fclose(inputFile);

    // Free up the space on symbol table
    freeSpace();

    return 0;
}