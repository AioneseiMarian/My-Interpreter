#ifndef VARIABLES_H
#define VARIABLES_H

#include <string.h>
#include <stdlib.h>

void yyerror(char const *s);
struct Block;

typedef struct {
    char* name;
    int type;    // 0 pentru int, 1 pentru float, 2 pentru double
    union {
        int ival;
        float fval;
        double dval;
    } value;
    int scope;   // nivel de scope pentru variabile
} Variable;

typedef struct ListNode{
    void *value;
    struct ListNode *next;
}ListNode;


// Structură pentru funcții
typedef struct {
    char* name;
    int paramCount;
    ListNode* paramsList;
    struct Block* block;
} Function;

ListNode *variables;
ListNode *functions;

int varCount = 0;
int funcCount = 0;
int currentScope = 0;

// Structură pentru stocarea informațiilor despre variabile

void addFunction(Function* func){
    ListNode *currentNode = functions;
    if(currentNode == NULL){
        functions = (ListNode*)malloc(sizeof(ListNode));
        functions->value = func;
        functions->next = NULL;
        funcCount++;
        return;
    }

    while (currentNode != NULL) {
        if (currentNode->next == NULL) break;
        currentNode = currentNode->next;
    }

    currentNode->next = (ListNode*)malloc(sizeof(ListNode));
    if (currentNode->next == NULL) {
        yyerror("Memory allocation failed");
        exit(EXIT_FAILURE);
    }
    currentNode->next->value = func;
    currentNode->next->next = NULL;
    funcCount++;
}

Function* findFunction(char* name){
    // printf("Caut functia %s\n", name);
    ListNode *currentNode = functions;
    while(currentNode != NULL){
        Function* func = (Function*)currentNode->value;
        if(strcmp(func->name, name) == 0){
            // printf("Am gasit functia %s\n", name);
            return func;
        }
        currentNode = currentNode->next;
    }
    // printf("Nu am gasit functia %s\n", name);
    return NULL;
}

void printVariables(){
    ListNode *currentNode = variables;
    while(currentNode != NULL){
        Variable* var = (Variable*)currentNode->value;
        switch (var->type){
            case 0:
                printf("Variabila %s de tip int cu valoarea %d\n", var->name, var->value.ival);
                break;
            case 1:
                printf("Variabila %s de tip float cu valoarea %f\n", var->name, var->value.fval);
                break;
            case 2:
                printf("Variabila %s de tip double cu valoarea %lf\n", var->name, var->value.dval);
                break;
        }
        
        currentNode = currentNode->next;
    }
}

void addVariable(Variable* var) {
    ListNode *currentNode = variables;
    if(currentNode == NULL){
        variables = (ListNode*)malloc(sizeof(ListNode));
        variables->value = var;
        variables->next = NULL;
        varCount++;
        return;
    }

    if((strcmp(((Variable*)currentNode->value)->name, var->name) == 0) && ((Variable*)currentNode->value)->scope == currentScope){
            yyerror("Variabilă redeclarată");
            return;
        }

    while (currentNode != NULL) {
        Variable* existingVar = (Variable*)currentNode->value;
        if (strcmp(existingVar->name, var->name) == 0 && existingVar->scope == currentScope) {
            yyerror("Variabilă redeclarată");
            return;
        }
        if (currentNode->next == NULL) break;
        currentNode = currentNode->next;
    }

    currentNode->next = (ListNode*)malloc(sizeof(ListNode));
    if (currentNode->next == NULL) {
        yyerror("Memory allocation failed");
        exit(EXIT_FAILURE);
    }
    currentNode->next->value = var;
    currentNode->next->next = NULL;
    varCount++;
    // printVariables();
    
}



Variable* findVariable(char* name) {
    // printf("Caut variabila %s\n", name);
    if(variables == NULL){
        printf("Nu exista variabile\n");
        return NULL;
    }
    // Caută variabila începând cu scope-ul curent până la cel global
    ListNode *currentNode = variables;

    for(int scope = currentScope; scope > 0; scope--){
        while(currentNode != NULL){
            if((strcmp(((Variable*)currentNode->value)->name, name) == 0) && ((Variable*)currentNode->value)->scope == scope){
                // printf("Am gasit variabila %s\n", name);
                return (Variable*)currentNode->value;
            }
            currentNode = currentNode->next;
        }
        currentNode = variables;

    }
    // printf("Nu am gasit variabila %s\n", name);
    return NULL;
}





void checkDivisionByZero(int divisor) {
    if(divisor == 0) {
        yyerror("Împărțire la zero");
    }
}


#endif