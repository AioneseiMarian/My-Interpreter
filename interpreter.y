%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "variables.h"
#include "statement.h"

#define OUTPUT_STREAM stdout

extern int lineNo;
extern int colNo;




void yyerror(const char* s);
int yylex(void);
ExpressionResult evaluateExpression(Expression* expr);
void assignValueToVariable(Variable* var, ExpressionResult* result);
void executeBlock(Block* block);
int evaluateWhileCondition(Condition* cond);
void executeDeclaration(char* varName, int varType, Expression* initialValue);
void executeAssignment(char* varName, Expression* value);
void executePrint(Expression* value);
void executeRead(char* varName);
Condition *evaluateCondition(Expression* left, int operator, Expression* right);
void printConditionResult(Condition* cond);



void addFunction(Function* func);
void executeFunctionCall(char* funcName, ListNode* arguments, int argCount);
Function* findFunction(char* name);
void checkDivisionByZero(int divisor);
void enterScope();
void exitScope();
%}

%union {
    int ival;
    float fval;
    double dval;
    char* sval;
    struct Expression* expr;
    struct Condition* cond; 
    struct Block* block;  
    struct Statement* stmt;
    struct ListNode* lNode;
}

%token TOK_PROGRAM_END
%token TOK_INT TOK_FLOAT TOK_DOUBLE
%token TOK_CAST_INT TOK_CAST_FLOAT TOK_CAST_DOUBLE
%token TOK_MAIN TOK_IF TOK_ELSE TOK_WHILE
%token TOK_EXECUTE TOK_READ TOK_PRINT TOK_CALL
%token TOK_FUNC TOK_RETURN TOK_BEGIN TOK_END
%token TOK_PLUS TOK_MINUS TOK_MULT TOK_DIV
%token TOK_ASSIGN TOK_SEP TOK_OPARAN TOK_CPARAN
%token TOK_LT TOK_GT TOK_EQ TOK_NEQ TOK_LE TOK_GE 
%token TOK_LACC TOK_RACC TOK_COMMENT
%token <ival> TOK_INT_VAL 
%token <fval> TOK_FLOAT_VAL
%token <dval> TOK_DOUBLE_VAL
%token <sval> TOK_ID TOK_STRING
%token TOK_ERROR

%type <lNode> params param param_list argument_list arguments
%type <ival> type TOK_CAST
%type <expr> expression term 
%type <cond> condition           
%type <block> block block_func
%type <stmt> statement statements declaration assignment if_statement while_statement print_statement read_statement function_call return_statement

%left TOK_PLUS TOK_MINUS
%left TOK_MULT TOK_DIV

%%

program: functions main TOK_PROGRAM_END
       ;

functions: /* empty */
        | functions function
        ;

function: TOK_FUNC TOK_ID TOK_OPARAN params TOK_CPARAN block_func
        {
            Function* func = malloc(sizeof(Function));
            func->name = strdup($2);
            func->paramsList = $4;
            func->block = $6;
            addFunction(func);
        }
        ;

params: /* empty */{ $$ = NULL; }
      | param_list{ $$ = $1; }
      ;

param_list: param{
            $$ = $1;
            $1->next = NULL;
}
         | param TOK_SEP param_list
         {
            $1->next = $3;
            $$ = $1;
         }
         ;

param: type TOK_ID
     {
            ListNode* node = malloc(sizeof(ListNode));

            Variable* var = malloc(sizeof(Variable));
            var->name = strdup($2);
            var->type = $1;

            node->value = var;
            node->next = NULL;
            $$ = node;
            //TO DO NU ARE SCOPE
     }
     ;


main: TOK_MAIN block { executeBlock($2);}
    ;

block: TOK_BEGIN 
     { 

     }
     statements TOK_END
     {  
        $$ = malloc(sizeof(Block));
        $$->scopeLevel = currentScope;
        $$->firstStmt = $3;
        $$->stmtCount = 0;

        Statement* current = $3;
        while (current != NULL) {
            $$->stmtCount++;
            current = current->next;
        }

     }
     ;

block_func: TOK_BEGIN 
     { 

     }
     statements TOK_END
     {  
        $$ = malloc(sizeof(Block));
        $$->scopeLevel = currentScope;
        $$->firstStmt = $3;
        $$->stmtCount = 0;

        Statement* current = $3;
        while (current != NULL) {
            $$->stmtCount++;
            current = current->next;
        }

     }
     ;

statements:  statement statements {$$ = $1; $1->next = $2; }
          | statement {$$ = $1; $1->next = NULL; }
          ;

statement: declaration TOK_SEP      { $$ = $1; }
         | assignment TOK_SEP       { $$ = $1; }
         | if_statement             { $$ = $1; }
         | while_statement          { $$ = $1; }
         | print_statement TOK_SEP  { $$ = $1; }
         | read_statement TOK_SEP   { $$ = $1; }
         | function_call TOK_SEP    { $$ = $1; }
        //  | return_statement TOK_SEP { $$ = $1; }
         | TOK_COMMENT              { $$ = malloc(sizeof(Statement)); $$->type = STMT_COMMENT; }
         | block                    { $$ = malloc(sizeof(Statement)); $$->type = STMT_BLOCK; $$->data.block = $1; }
         ;



declaration: type TOK_ID 
        {
            $$ = malloc(sizeof(Statement));
            if($$ == NULL) {
                yyerror("Eroare la alocare");
                exit(1);
            }
            // printf("Alocare pentru declarare variabila %s de tip %d\n", $2, $1);
            $$->type = STMT_DECLARATION;
            $$->data.declaration.varName = strdup($2);
            $$->data.declaration.varType = $1;
            $$->data.declaration.initialValue = NULL;
            $$->next = NULL;
            // printf("Declarare variabilă %s de tip %d\n", $2, $1);

            // Variable* var = malloc(sizeof(Variable));
            // var->name = strdup($2);
            // var->type = $1;
            // var->scope = currentScope;
            // addVariable(var);
        }
          | type TOK_ID TOK_ASSIGN expression
        {
            $$ = malloc(sizeof(Statement));
            if($$ == NULL) {
                yyerror("Eroare la alocare");
                exit(1);
            }
            // printf("Alocare pentru declarare variabila %s de tip %d\n", $2, $1);
            $$->type = STMT_DECLARATION;
            $$->data.declaration.varName = strdup($2);
            $$->data.declaration.varType = $1;
            $$->data.declaration.initialValue = $4;
            $$->next = NULL;
            // printf("Declarare variabilă %s de tip %d cu valoare inițială\n", $2, $1);

            // Variable* var = malloc(sizeof(Variable));
            // var->name = strdup($2);
            // var->type = $1;
            // ExpressionResult result = evaluateExpression($4);
            // switch($1) {
            //     case 0: var->value.ival = result.value.ival; break;
            //     case 1: var->value.fval = result.value.fval; break;
            //     case 2: var->value.dval = result.value.dval; break;
            // }
            // var->scope = currentScope;
            // addVariable(var);
        }
          ;

type: TOK_INT { $$ = 0; }
    | TOK_FLOAT { $$ = 1; }
    | TOK_DOUBLE { $$ = 2; }
    ;

assignment: TOK_ID TOK_ASSIGN expression
         {
            $$ = malloc(sizeof(Statement));
            if($$ == NULL) {
                yyerror("Eroare la alocare");
                exit(1);
            }
            $$->type = STMT_ASSIGNMENT;
            $$->data.assignment.varName = strdup($1);
            $$->data.assignment.value = $3;
            $$->next = NULL;
         }
         ;

expression: term { $$ = $1; }
         | expression TOK_PLUS expression   { $$ = malloc(sizeof(Expression)); $$->type = EXPR_OPERATION; $$->oper = TOK_PLUS; $$->left = $1; $$->right = $3; }
         | expression TOK_MINUS expression  { $$ = malloc(sizeof(Expression)); $$->type = EXPR_OPERATION; $$->oper = TOK_MINUS; $$->left = $1; $$->right = $3; }
         | expression TOK_MULT expression   { $$ = malloc(sizeof(Expression)); $$->type = EXPR_OPERATION; $$->oper = TOK_MULT; $$->left = $1; $$->right = $3; }
         | expression TOK_DIV expression    { $$ = malloc(sizeof(Expression)); $$->type = EXPR_OPERATION; $$->oper = TOK_DIV; $$->left = $1; $$->right = $3; }
         | TOK_OPARAN expression TOK_CPARAN { $$ = $2; }
         | TOK_CAST expression { 
            $$ = $2; 
            $$->casted = 1;
            switch($1){
                case 0: 
                    $$->varType = 0;
                    printf("Cast la int\n"); 
                    break;
                case 1: 
                    $$->varType = 1;
                    printf("Cast la float\n");
                    break;
                case 2: 
                    $$->varType = 2; 
                    printf("Cast la double\n");
                    break;
            }

         }
         ;

term:   TOK_INT_VAL     { $$ = malloc(sizeof(Expression)); $$->varType = 0; $$->value.ival = $1; $$->type = EXPR_LITERAL; }
      | TOK_FLOAT_VAL   { $$ = malloc(sizeof(Expression)); $$->varType = 1; $$->value.fval = $1; $$->type = EXPR_LITERAL; }
      | TOK_DOUBLE_VAL  { $$ = malloc(sizeof(Expression)); $$->varType = 2; $$->value.dval = $1; $$->type = EXPR_LITERAL; 
        printf("Valoare double %lf\n", $1);
      }
      | TOK_ID
      {
          $$ = malloc(sizeof(Expression));
        //   Variable* var = findVariable($1);
        //   if(var == NULL) {
        //       yyerror("Variabila nedeclarată");
        //   }
            $$->type = EXPR_VARIABLE;
            // $$->varType = var->type;
            // switch(var->type) {
            //     case 0: $$->value.ival = var->value.ival; break;
            //     case 1: $$->value.fval = var->value.fval; break;
            //     case 2: $$->value.dval = var->value.dval; break;
            // }
            $$->varName = strdup($1);
      }
      ;

TOK_CAST: TOK_CAST_INT {$$ = 0;}
               | TOK_CAST_FLOAT {$$ = 1;}
               | TOK_CAST_DOUBLE {$$ = 2;}
               ;

if_statement: 
    TOK_IF TOK_OPARAN condition TOK_CPARAN block
    {
        // Condition cond = *$<cond>3;
        // if (cond.isTrue) {
        //     executeBlock($<block>5);
        // }
        $$ = malloc(sizeof(Statement));
        $$->type = STMT_IF;
        $$->data.ifStmt.condition = $3;
        $$->data.ifStmt.thenBlock = $5;
        $$->data.ifStmt.elseBlock = NULL;

    }
    | TOK_IF TOK_OPARAN condition TOK_CPARAN block TOK_ELSE block
    {
        // Condition cond = *$<cond>3;
        // if (cond.isTrue) {
        //     executeBlock($<block>5);
        // } else {
        //     executeBlock($<block>7);
        // }
        $$ = malloc(sizeof(Statement));
        $$->type = STMT_IF;
        $$->data.ifStmt.condition = $3;
        $$->data.ifStmt.thenBlock = $5;
        $$->data.ifStmt.elseBlock = $7;
    }
    ;

while_statement: 
    TOK_WHILE TOK_OPARAN condition TOK_CPARAN block
    {
        // Condition cond = *$<cond>3;
        
        // while (evaluateWhileCondition(&cond)) {
        //     executeBlock($<block>5);
        //     cond = evaluateCondition(&cond.leftExpr, cond.oper, &cond.rightExpr);
        // }
        $$ = malloc(sizeof(Statement));
        $$->type = STMT_WHILE;
        $$->data.whileStmt.condition = $3;
        $$->data.whileStmt.body = $5;

    }
    ;

condition:
    expression TOK_LT expression
    {
        $$ = malloc(sizeof(Condition));
        $$->leftExpr = *$1;
        $$->oper = TOK_LT;
        $$->rightExpr = *$3;
    }
    | expression TOK_GT expression
    {
        $$ = malloc(sizeof(Condition));
        $$->leftExpr = *$1;
        $$->oper = TOK_GT;
        $$->rightExpr = *$3;
    }
    | expression TOK_EQ expression
    {
        $$ = malloc(sizeof(Condition));
        $$->leftExpr = *$1;
        $$->oper = TOK_EQ;
        $$->rightExpr = *$3;
    }
    | expression TOK_NEQ expression
    {
        $$ = malloc(sizeof(Condition));
        $$->leftExpr = *$1;
        $$->oper = TOK_NEQ;
        $$->rightExpr = *$3;
    }
    | expression TOK_LE expression
    {
        $$ = malloc(sizeof(Condition));
        $$->leftExpr = *$1;
        $$->oper = TOK_LE;
        $$->rightExpr = *$3;
    }
    | expression TOK_GE expression
    {
        $$ = malloc(sizeof(Condition));
        $$->leftExpr = *$1;
        $$->oper = TOK_GE;
        $$->rightExpr = *$3;
    }
    ;

print_statement: TOK_PRINT TOK_OPARAN expression TOK_CPARAN 
    {
        $$ = malloc(sizeof(Statement));
        $$->type = STMT_PRINT;
        $$->data.print.value = $3;
        $$->next = NULL;
    }
    ;

read_statement: TOK_READ TOK_OPARAN TOK_ID TOK_CPARAN 
    {
        $$ = malloc(sizeof(Statement));
        $$->type = STMT_READ;
        $$->data.read.varName = strdup($3);
        $$->next = NULL;
    }
    ;

function_call: TOK_CALL TOK_ID TOK_OPARAN arguments TOK_CPARAN  
{
    // printf("Apelare funcție %s\n", $2);
    $$ = malloc(sizeof(Statement));
    if($$ == NULL) {
        yyerror("Eroare la alocare");
        exit(1);
    }
    $$->type = STMT_FUNCTION_CALL;
    $$->data.functionCall.funcName = strdup($2);
    $$->data.functionCall.argList = $4;
    $$->data.functionCall.argCount = 0;

    ListNode* current = $4;
    // printf("Apel functie complet\n");
}
;

arguments: /* empty */ {
                        // printf("\n\nDebug fara arg\n\n"); 
                        $$ = NULL;}
        | argument_list {
                        // printf("\n\nDebug cu args\n\n");  
                        $$ = $1; }
        ;

argument_list: expression 
            {
                // printf("Argument %d\n", $1->value.ival);
                ListNode* node = malloc(sizeof(ListNode));
                node->value = $1;
                node->next = NULL;
                $$ = node;
            }
            | argument_list TOK_SEP expression
            {
                // printf("Argument %d\n", $3->value.ival);
                ListNode* node = malloc(sizeof(ListNode));
                node->value = $3;
                node->next = NULL;
                
              
                ListNode* current = $1;
                while (current->next != NULL) {
                    current = current->next;
                }
                current->next = node;
                $$ = $1; 
            }
            ;

%%


void assignValueToVariable(Variable* var, ExpressionResult* result) {
    if (var == NULL) {
        yyerror("Variabilă nedeclarată");
        return;
    }
    
    if (var->type != result->type) {
        yyerror("Tip de date incompatibil");
        return;
    }
    
    switch (var->type) {
        case 0: var->value.ival = result->value.ival; break;
        case 1: var->value.fval = result->value.fval; break;
        case 2: var->value.dval = result->value.dval; break;
    }
}


ExpressionResult evaluateExpression(Expression* expr) {
    // printf("Evaluare expresie\n");
    ExpressionResult result;
    if (expr == NULL) {
        yyerror("Expresie invalidă");
        result.type = 0;
        result.value.ival = 0;
        return result;
    }
    
    switch (expr->type) {
        case EXPR_LITERAL:
            // printf("Literală %d\n", expr->varType);
            result.type = expr->varType;
            switch (result.type) {
                case 0: result.value.ival = expr->value.ival; break;
                case 1: result.value.fval = expr->value.fval; break;
                case 2: result.value.dval = expr->value.dval; break;
            }
            break;
            
        case EXPR_VARIABLE:
                Variable* var = findVariable(expr->varName);
                if (var == NULL) {
                    yyerror("Variabilă nedeclarată");
                    result.type = 0;
                    result.value.ival = 0;
                } 
                else {
                    if(!expr->casted){
                        result.type = var->type;
                        switch (result.type) {
                            case 0: result.value.ival = var->value.ival; break;
                            case 1: result.value.fval = var->value.fval; break;
                            case 2: result.value.dval = var->value.dval; break;
                        }
                    }
                    else{
                        result.type = expr->varType;
                        switch (expr->varType) {
                            case 0:
                                switch(var->type){
                                    case 0: result.value.ival = var->value.ival; break;
                                    case 1: result.value.ival = (int)var->value.fval; break;
                                    case 2: result.value.ival = (int)var->value.dval; break;
                                }
                                break;
                            case 1:
                                switch(var->type){
                                    case 0: result.value.fval = (float)var->value.ival; break;
                                    case 1: result.value.fval = var->value.fval; break;
                                    case 2: result.value.fval = (float)var->value.dval; break;
                                }
                                break;
                            case 2:
                                switch(var->type){
                                    case 0: result.value.dval = (double)var->value.ival; break;
                                    case 1: result.value.dval = (double)var->value.fval; break;
                                    case 2: result.value.dval = var->value.dval; break;
                                }
                                break;
                            
                        }
                    }
                }
                break;
            
        
            
        case EXPR_OPERATION:
            {
                ExpressionResult left = evaluateExpression(expr->left);
                ExpressionResult right = evaluateExpression(expr->right);
                
                if (left.type != right.type) {
                    yyerror("Tipuri de date incompatibile");
                    result.type = 0;
                    result.value.ival = 0;
                } else {
                    result.type = left.type;
                    switch (expr->oper) {
                        case TOK_PLUS:
                            switch (result.type) {
                                case 0: result.value.ival = left.value.ival + right.value.ival; break;
                                case 1: result.value.fval = left.value.fval + right.value.fval; break;
                                case 2: result.value.dval = left.value.dval + right.value.dval; break;
                            }
                            break;
                            
                        case TOK_MINUS:
                            switch (result.type) {
                                case 0: result.value.ival = left.value.ival - right.value.ival; break;
                                case 1: result.value.fval = left.value.fval - right.value.fval; break;
                                case 2: result.value.dval = left.value.dval - right.value.dval; break;
                            }
                            break;
                        case TOK_MULT:
                            switch (result.type) {
                                case 0: result.value.ival = left.value.ival * right.value.ival; break;
                                case 1: result.value.fval = left.value.fval * right.value.fval; break;
                                case 2: result.value.dval = left.value.dval * right.value.dval; break;
                            }
                            break;

                        case TOK_DIV:
                            if (right.value.ival == 0 || right.value.fval == 0.0 || right.value.dval == 0.0) {
                                yyerror("Împărțire la zero");
                                result.type = 0;
                                result.value.ival = 0;
                            } else {
                                switch (result.type) {
                                    case 0: result.value.ival = left.value.ival / right.value.ival; break;
                                    case 1: result.value.fval = left.value.fval / right.value.fval; break;
                                    case 2: result.value.dval = left.value.dval / right.value.dval; break;
                                }
                            }
                            break;
                        }
                    }
                }
                break;
        }
        // printf("Expresie evaluata\n");
        // switch(result.type) {
        //     case 0: printf("Rezultat: %d\n", result.value.ival); break;
        //     case 1: printf("Rezultat: %f\n", result.value.fval); break;
        //     case 2: printf("Rezultat: %lf\n", result.value.dval); break;
        // }
        
        return result;
    }
    


// Funcție pentru execuția unui bloc
void executeBlock(Block* block) {
    if (block == NULL) {
        yyerror("Bloc invalid");
        return;
    }

    enterScope();
    
    Statement* current = block->firstStmt;
    while (current != NULL) {
        switch (current->type) {
            case STMT_DECLARATION:
                executeDeclaration(current->data.declaration.varName,
                                 current->data.declaration.varType,
                                 current->data.declaration.initialValue);
                break;
                
            case STMT_ASSIGNMENT:
                executeAssignment(current->data.assignment.varName,
                                current->data.assignment.value);
                break;
                
            case STMT_IF:
                {
                    // Re-evaluate the condition each time using the original expressions
                    Condition *cond = evaluateCondition(&current->data.whileStmt.condition->leftExpr,
                                                    current->data.whileStmt.condition->oper,
                                                    &current->data.whileStmt.condition->rightExpr);
                    
                    if (cond->isTrue) {
                        executeBlock(current->data.ifStmt.thenBlock);
                    }else{
                        executeBlock(current->data.ifStmt.elseBlock);
                    }
                        free(cond);
                }
                break;
                
            case STMT_WHILE:
                {
                    while (1) {
                        // Re-evaluate the condition each time using the original expressions
                        Condition *cond = evaluateCondition(&current->data.whileStmt.condition->leftExpr,
                                                        current->data.whileStmt.condition->oper,
                                                        &current->data.whileStmt.condition->rightExpr);
                        
                        if (!cond->isTrue) {
                            free(cond);
                            break;
                        }
                        
                        executeBlock(current->data.whileStmt.body);
                        free(cond);
                    }
                }
                break;
                
            case STMT_PRINT:
                executePrint(current->data.print.value);
                break;
                
            case STMT_READ:
                executeRead(current->data.read.varName);
                break;
                
            case STMT_FUNCTION_CALL:
                
                executeFunctionCall(current->data.functionCall.funcName,
                                  current->data.functionCall.argList,
                                  current->data.functionCall.argCount 
                                  );
                break;
                
            case STMT_RETURN:
                // executeReturn(current->data.returnStmt.value);
                break;
            case STMT_COMMENT:
                break;
            case STMT_BLOCK:
                executeBlock(current->data.block);
                break;
        }
        current = current->next;
    }

    exitScope();
    
}

void executeFunctionCall(char* funcName, ListNode* arguments, int argCount) {
    printf("Am intrat in Function Call\n");
    Function* func = findFunction(funcName);
    if (func == NULL) {
        yyerror("Funcție nedefinită");
        return;
    }
    
    ListNode *currentNode = func->paramsList;
    while(currentNode != NULL){
        Variable* exp = (Variable*)currentNode->value;
        printf("Parametru %s de tip %d\n", exp->name, exp->type);
        currentNode = currentNode->next;
    }

    
    currentNode = arguments;
    while(currentNode != NULL){
        Expression* exp = (Expression*)currentNode->value;
        printf("Argument %d\n", exp->value.ival);
        currentNode = currentNode->next;
    }
    
    
    if (func->paramsList != NULL && arguments != NULL) {
        ListNode* currentParam = func->paramsList;
        ListNode* currentArg = arguments;
        
        while (currentParam != NULL && currentArg != NULL) {
            Variable* param = (Variable*)currentParam->value;
            ExpressionResult argResult = evaluateExpression((Expression*)currentArg->value);
            
            if (param->type != argResult.type) {
                yyerror("Tipuri de date incompatibile");
                return;
            }
            
            switch (param->type) {
                case 0: param->value.ival = argResult.value.ival; break;
                case 1: param->value.fval = argResult.value.fval; break;
                case 2: param->value.dval = argResult.value.dval; break;
            }
            
            currentParam = currentParam->next;
            currentArg = currentArg->next;
        }
    }
    
    enterScope();
    if (func->paramsList != NULL && arguments != NULL) {
        ListNode* currentParam = func->paramsList;
        ListNode* currentArg = arguments;
        while(currentParam != NULL && currentArg != NULL){
            Variable* param = (Variable*)currentParam->value;
            Expression* arg = (Expression*)currentArg->value;
            executeDeclaration(param->name, param->type, arg);
            currentParam = currentParam->next;
            currentArg = currentArg->next;
        }
    }
    executeBlock(func->block);
    
    exitScope();

 
}

void executeDeclaration(char* varName, int varType, Expression* initialValue) {
    ListNode* current = variables;
    Variable* var;

    while(current != NULL){
        var = (Variable*)current->value;
        if(strcmp(var->name, varName) == 0 && var->scope == currentScope){
            yyerror("Variabilă deja declarată");
            return;
        }
        current = current->next;
    }

    var = malloc(sizeof(Variable));
    var->name = strdup(varName);
    var->type = varType;
    if(initialValue != NULL){
        ExpressionResult result = evaluateExpression(initialValue);
        switch(varType) {
            case 0: var->value.ival = result.value.ival; break;
            case 1: var->value.fval = result.value.fval; break;
            case 2: var->value.dval = result.value.dval; break;
        }
    }
    var->scope = currentScope;
    addVariable(var);
}

void executeAssignment(char* varName, Expression* value) {
    Variable* var = findVariable(varName);
    if (var != NULL) {
        ExpressionResult result = evaluateExpression(value);
        assignValueToVariable(var, &result);
    } else {
        yyerror("Variabilă nedeclarată");
    }
}

void executePrint(Expression* value) {
    ExpressionResult result = evaluateExpression(value);
    switch (result.type) {
        case 0: printf("%d\n", result.value.ival); break;
        case 1: printf("%f\n", result.value.fval); break;
        case 2: printf("%lf\n", result.value.dval); break;
    }
}

void executeRead(char* varName) {
    Variable* var = findVariable(varName);
    if (var != NULL) {
        printf("Introdu valoarea pentru %s: ", varName);
        switch (var->type) {
            case 0: scanf("%d", &var->value.ival); break;
            case 1: scanf("%f", &var->value.fval); break;
            case 2: scanf("%lf", &var->value.dval); break;
        }
    } else {
        yyerror("Variabilă nedeclarată");
    }
}

Condition *evaluateCondition(Expression* left, int operator, Expression* right) {

    Condition* condition = malloc(sizeof(Condition));
    condition->isTrue = 0;

    condition->leftExpr = *left;
    condition->oper = operator;
    condition->rightExpr = *right;

    ExpressionResult leftResult = evaluateExpression(left);
    ExpressionResult rightResult = evaluateExpression(right);

    if (leftResult.type != rightResult.type) {
        yyerror("Tipuri de date incompatibile");
        return condition;
    }

    double leftValue, rightValue;

    switch (leftResult.type) {
        case 0: leftValue = leftResult.value.ival; rightValue = rightResult.value.ival; break;
        case 1: leftValue = leftResult.value.fval; rightValue = rightResult.value.fval; break;
        case 2: leftValue = leftResult.value.dval; rightValue = rightResult.value.dval; break;
    }

    switch(rightResult.type) {
        case 0: rightValue = rightResult.value.ival; break;
        case 1: rightValue = rightResult.value.fval; break;
        case 2: rightValue = rightResult.value.dval; break;
    }

    switch(operator) {
        case TOK_LT:
            condition->isTrue = (leftValue < rightValue);
            break;
        case TOK_GT:
            condition->isTrue = (leftValue > rightValue);
            break;
        case TOK_EQ:
            condition->isTrue = (fabs(leftValue - rightValue) < 1e-10);
            break;
        case TOK_NEQ:
            condition->isTrue = (fabs(leftValue - rightValue) >= 1e-10);
            break;
        case TOK_LE:
            condition->isTrue = (leftValue <= rightValue);
            break;
        case TOK_GE:
            condition->isTrue = (leftValue >= rightValue);
            break;
        default:
            yyerror("Operator de comparație invalid");
            condition->isTrue = 0;
    }

    
    return condition;
}

int evaluateWhileCondition(Condition* cond) {
    if (cond == NULL) {
        yyerror("Condiție while invalidă");
        return 0;
    }
    
    return cond->isTrue;
}


void printConditionResult(Condition* cond) {
    if (cond == NULL) {
        printf("Condiție invalidă\n");
        return;
    }
    printf("Rezultat condiție: %s\n", cond->isTrue ? "adevărat" : "fals");
}


void yyerror(const char* s) {
    fprintf(stderr, "Eroare la linia %d, coloana %d: %s\n", lineNo, colNo, s);
    exit(-1);
}



void enterScope() {
    currentScope++;
}

void exitScope() {

    ListNode* current = variables;
    ListNode* prev = NULL;

    while (current != NULL) {
        Variable* var = (Variable*)current->value;

        if (var->scope == currentScope) {
            ListNode* nextNode = current->next;  

            if (prev == NULL) {
                variables = nextNode;  
            } else {
                prev->next = nextNode;
            }

            if (var->name != NULL) {
                free(var->name);
            }
            free(var);
            free(current);

            current = nextNode;  
        } else {
            prev = current;
            current = current->next;
        }
    }

    currentScope--;
}


extern FILE* yyin;


int main(int argc, char** argv) {
    if(argc == 1){
        yyparse();
        return 0;
    }
    if (argc != 2) {
        fprintf(stderr, "Utilizare: %s <nume_fișier>\n", argv[0]);
        return 1;
    }
    char filename[256];
    strcpy(filename, argv[1]);
    yyin = fopen(filename, "r");
    if (!yyin) {
        perror("Error opening file");
        return 1;
    }

    printf("Rularea scriptului: %s\n", filename);
    yyparse();
    fclose(yyin);

    return 0;
}